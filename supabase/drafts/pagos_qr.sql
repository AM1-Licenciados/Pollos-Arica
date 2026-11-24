-- Pollos Arica
-- BORRADOR NO EJECUTABLE EN PRODUCCION
-- Flujo de verificacion manual de pagos QR.
--
-- Objetivo:
-- 1. El cliente autenticado solo puede notificar que realizo el pago:
--    pendiente -> por_verificar.
-- 2. Solo un administrador activo puede confirmar/rechazar:
--    por_verificar -> pagado | rechazado.
-- 3. Un pedido QR no puede avanzar a preparacion/listo/entregado
--    mientras estado_pago <> 'pagado'.
-- 4. Registrar cada cambio de estado de pago en una auditoria.
--
-- IMPORTANTE:
-- - Este archivo NO ha sido aplicado.
-- - Requiere pruebas en un entorno PostgreSQL aislado antes de produccion.
-- - Se basa en el esquema inspeccionado el 2026-11-23.
-- - No cambia los permisos de crear_pedido, crear_pedido_con_seguimiento
--   ni obtener_mis_pedidos.
-- - No resuelve la integracion automatica con BCP. La verificacion sigue
--   siendo manual desde la banca del negocio.
--
-- PRECONDICIONES A VALIDAR:
-- - public.pedidos tiene auth_user_id, metodo_pago, estado_pago, estado,
--   updated_at y seguimiento_token.
-- - public.es_admin_activo() identifica administradores activos.
-- - La politica clientes_ver_sus_pedidos permite SELECT propio.
-- - La politica admin_actualizar_pedidos permite UPDATE administrativo.
--
-- No ejecutar hasta revisar las precondiciones y completar pruebas.

begin;

-- 1. Esquema privado para funciones internas (no exponer por Data API).
create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

-- 2. Auditoria de cambios de pago.
create table if not exists public.pagos_qr_auditoria (
  id uuid primary key default gen_random_uuid(),
  pedido_id uuid not null references public.pedidos(id) on delete restrict,
  actor_user_id uuid null,
  accion text not null check (
    accion in ('notificacion_cliente', 'confirmacion_admin', 'rechazo_admin')
  ),
  estado_anterior text not null,
  estado_nuevo text not null,
  observacion text null,
  creado_at timestamptz not null default now()
);

alter table public.pagos_qr_auditoria enable row level security;

revoke all on public.pagos_qr_auditoria from public, anon, authenticated;
grant select on public.pagos_qr_auditoria to authenticated;

drop policy if exists pagos_qr_auditoria_admin_select
  on public.pagos_qr_auditoria;

create policy pagos_qr_auditoria_admin_select
  on public.pagos_qr_auditoria
  for select
  to authenticated
  using ((select public.es_admin_activo()));

-- 3. Funcion interna para auditar; SECURITY DEFINER se limita a insertar
--    los campos del evento. El search_path esta fijado y los objetos
--    estan cualificados por esquema.
create or replace function private.registrar_auditoria_pago_qr()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog
as $$
declare
  v_accion text;
begin
  if new.estado_pago is distinct from old.estado_pago then
    if old.estado_pago = 'pendiente'
       and new.estado_pago = 'por_verificar' then
      v_accion := 'notificacion_cliente';
    elsif old.estado_pago = 'por_verificar'
       and new.estado_pago = 'pagado' then
      v_accion := 'confirmacion_admin';
    elsif old.estado_pago = 'por_verificar'
       and new.estado_pago = 'rechazado' then
      v_accion := 'rechazo_admin';
    else
      v_accion := null;
    end if;

    if v_accion is not null then
      insert into public.pagos_qr_auditoria (
        pedido_id, actor_user_id, accion,
        estado_anterior, estado_nuevo
      )
      values (
        new.id, (select auth.uid()), v_accion,
        old.estado_pago, new.estado_pago
      );
    end if;
  end if;

  return new;
end;
$$;

revoke all on function private.registrar_auditoria_pago_qr()
  from public, anon, authenticated;

-- 4. Validador de transiciones. SECURITY INVOKER: conserva el contexto
--    de identidad de la solicitud; no concede privilegios adicionales.
create or replace function private.validar_transicion_pedido_qr()
returns trigger
language plpgsql
security invoker
set search_path = pg_catalog
as $$
declare
  v_es_admin boolean;
  v_uid uuid;
begin
  v_uid := (select auth.uid());
  v_es_admin := coalesce((select public.es_admin_activo()), false);

  -- El metodo de pago no se puede cambiar despues de crear el pedido.
  if new.metodo_pago is distinct from old.metodo_pago then
    raise exception 'No se permite cambiar el metodo de pago de un pedido.';
  end if;

  -- Cualquier usuario que no sea administrador activo solo puede
  -- notificar el pago de su propio pedido QR.
  if not v_es_admin then
    if v_uid is null
       or old.auth_user_id is distinct from v_uid
       or old.metodo_pago <> 'qr'
       or old.estado_pago <> 'pendiente'
       or new.estado_pago <> 'por_verificar'
       or new.estado is distinct from old.estado then
      raise exception 'No tienes permiso para realizar este cambio.';
    end if;
  else
    -- El administrador solo puede resolver pagos que esperan verificacion.
    if new.estado_pago is distinct from old.estado_pago then
      if old.metodo_pago <> 'qr'
         or old.estado_pago <> 'por_verificar'
         or new.estado_pago not in ('pagado', 'rechazado') then
        raise exception 'Transicion de pago no permitida.';
      end if;
    end if;
  end if;

  -- Bloqueo de avance operativo de pedidos QR no pagados.
  if new.metodo_pago = 'qr'
     and new.estado in ('en_preparacion', 'listo', 'entregado')
     and new.estado_pago <> 'pagado' then
    raise exception 'No se puede preparar ni entregar un pedido QR sin confirmar el pago.';
  end if;

  return new;
end;
$$;

-- La funcion invoker se ejecuta con los permisos del solicitante.
revoke all on function private.validar_transicion_pedido_qr()
  from public, anon;
grant usage on schema private to authenticated;
grant execute on function private.validar_transicion_pedido_qr()
  to authenticated;

-- 5. Cliente puede actualizar su propia fila para notificar el pago.
--    El trigger limita el cambio permitido a pendiente -> por_verificar.
drop policy if exists clientes_notificar_pago_qr
  on public.pedidos;

create policy clientes_notificar_pago_qr
  on public.pedidos
  for update
  to authenticated
  using (
    auth_user_id = (select auth.uid())
    and metodo_pago = 'qr'
    and estado_pago = 'pendiente'
  )
  with check (
    auth_user_id = (select auth.uid())
    and metodo_pago = 'qr'
    and estado_pago = 'por_verificar'
  );

-- El permiso por columna evita conceder UPDATE irrestricto sobre pedidos.
grant update (estado_pago, updated_at) on public.pedidos to authenticated;
grant update (estado, updated_at) on public.pedidos to authenticated;

-- 6. Triggers.
drop trigger if exists validar_transicion_pedido_qr
  on public.pedidos;

create trigger validar_transicion_pedido_qr
before update of estado, estado_pago, metodo_pago
on public.pedidos
for each row
execute function private.validar_transicion_pedido_qr();

drop trigger if exists registrar_auditoria_pago_qr
  on public.pedidos;

create trigger registrar_auditoria_pago_qr
after update of estado_pago
on public.pedidos
for each row
when (old.estado_pago is distinct from new.estado_pago)
execute function private.registrar_auditoria_pago_qr();

commit;

-- 7. PRUEBAS MANUALES OBLIGATORIAS ANTES DE PRODUCCION:
-- A. Cliente autenticado propio: QR pendiente -> por_verificar permitido.
-- B. Cliente autenticado propio: QR pendiente -> pagado debe fallar.
-- C. Cliente autenticado ajeno: cualquier notificacion debe fallar.
-- D. Cliente: cambiar estado del pedido debe fallar.
-- E. Admin activo: por_verificar -> pagado permitido.
-- F. Admin activo: por_verificar -> rechazado permitido.
-- G. Admin: QR no pagado -> en_preparacion/listo/entregado debe fallar.
-- H. Admin: QR pagado -> en_preparacion permitido.
-- I. Efectivo: flujo actual debe seguir funcionando.
-- J. Pedidos historicos: revisar estados existentes antes de habilitar.
--
-- REVISIONES PENDIENTES:
-- - Confirmar si los administradores actuales actualizan pedidos desde
--   Flutter usando UPDATE directo y validar que las politicas/grants
--   existentes cubren esas operaciones.
-- - La politica admin_actualizar_pedidos existente debe seguir activa.
-- - Confirmar comportamiento para pedidos QR historicos que ya esten
--   en preparacion o entregados con estado_pago distinto de pagado.
-- - Probar que los triggers privados pueden ejecutarse con los permisos
--   efectivos del rol propietario en el proyecto objetivo.
-- - Ejecutar Supabase Security Advisor despues de aplicar en entorno de prueba.
