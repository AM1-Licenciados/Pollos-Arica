
-- REVISION ADICIONAL DE PRIVILEGIOS DE TABLA (2026-11-24):
-- Hallazgo: public.perfiles_clientes concede TRUNCATE, REFERENCES y TRIGGER
-- a anon y authenticated a nivel de tabla. RLS no protege TRUNCATE.
-- No se encontro una necesidad de la app para esos privilegios.
-- authenticated conserva SELECT y UPDATE por columnas permitidas;
-- anon no necesita acceso a esta tabla.
--
-- Aplicar solo despues de confirmar que ningun proceso externo depende
-- de estos privilegios. Este bloque es independiente del bloque anterior.
--
begin;
revoke truncate, references, trigger
  on table public.perfiles_clientes
  from anon, authenticated;
commit;
--
-- Verificar:
-- select has_table_privilege('anon','public.perfiles_clientes','TRUNCATE');
-- select has_table_privilege('authenticated','public.perfiles_clientes','TRUNCATE');
-- select has_table_privilege('anon','public.perfiles_clientes','REFERENCES');
-- select has_table_privilege('authenticated','public.perfiles_clientes','TRIGGER');
-- Todas deben devolver false.
-- No revocar SELECT ni UPDATE por columnas en este bloque.

--
-- APLICADO en migracion secure_qr_payment_flow_and_database_hardening:
-- - REVOKE EXECUTE de rls_auto_enable para PUBLIC, anon y authenticated.
-- - REVOKE TRUNCATE, REFERENCES y TRIGGER de perfiles_clientes para
--   anon y authenticated.
-- - DEFAULT PRIVILEGES de postgres en public: se retiran esos tres
--   privilegios a anon/authenticated para tablas futuras.
-- Verificacion: los permisos efectivos consultados devolvieron false.
--
-- RPCs con avisos restantes:
-- - obtener_mis_pedidos: acceso anon intencional por token de seguimiento.
-- - crear_pedido_con_seguimiento: acceso authenticated necesario para crear
--   pedidos y validado en transaccion real; inner crear_pedido queda cerrado.
-- - es_admin_activo y admin_actual_puede_crear_usuarios: helpers booleanos
--   usados por politicas RLS; no devuelven registros ni datos personales.
-- Auth leaked password protection sigue pendiente en Dashboard.
