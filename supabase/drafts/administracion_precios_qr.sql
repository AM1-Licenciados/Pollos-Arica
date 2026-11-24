-- Pollos Arica: administración de precios y QR de pago.
-- Aplicado al proyecto Supabase axkesljaxhfnhvbikwsj.
-- Los permisos se restringen a usuarios authenticated que sean
-- administradores activos mediante public.es_admin_activo().

begin;

grant update (precio) on public.variantes_producto to authenticated;

drop policy if exists variantes_producto_admin_actualizar_precio
  on public.variantes_producto;

create policy variantes_producto_admin_actualizar_precio
  on public.variantes_producto
  for update
  to authenticated
  using ((select public.es_admin_activo()))
  with check ((select public.es_admin_activo()));

grant update (
  nombre_negocio,
  telefono_whatsapp,
  telefono_llamadas,
  direccion,
  latitud,
  longitud,
  qr_imagen_url,
  updated_at
) on public.configuracion_negocio to authenticated;

drop policy if exists pagos_qr_admin_select on storage.objects;
create policy pagos_qr_admin_select
  on storage.objects
  for select
  to authenticated
  using (
    bucket_id = 'pagos-qr'
    and (select public.es_admin_activo())
  );

drop policy if exists pagos_qr_admin_insert on storage.objects;
create policy pagos_qr_admin_insert
  on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'pagos-qr'
    and (select public.es_admin_activo())
    and storage.extension(name) = 'png'
  );

drop policy if exists pagos_qr_admin_update on storage.objects;
create policy pagos_qr_admin_update
  on storage.objects
  for update
  to authenticated
  using (
    bucket_id = 'pagos-qr'
    and (select public.es_admin_activo())
  )
  with check (
    bucket_id = 'pagos-qr'
    and (select public.es_admin_activo())
    and storage.extension(name) = 'png'
  );

commit;
