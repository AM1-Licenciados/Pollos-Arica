-- Pollos Arica
-- BORRADOR DE ENDURECIMIENTO DE PERMISOS
-- No ejecutar junto con el flujo QR sin revisar el impacto en la base.
--
-- Objetivo:
-- Evitar que rls_auto_enable() aparezca como RPC ejecutable por anon o
-- authenticated. La funcion se utiliza como funcion de un EVENT TRIGGER
-- propiedad de postgres; no debe ser una API de la aplicacion.
--
-- La ejecucion del event trigger es gestionada por PostgreSQL. Este cambio
-- solo retira el permiso EXECUTE directo de los roles de la API.
-- No elimina ni modifica el event trigger ensure_rls.
--
-- Verificacion realizada en la base actual:
-- - ensure_rls existe, esta habilitado y apunta a public.rls_auto_enable().
-- - La funcion es SECURITY DEFINER, propiedad de postgres y usa
--   search_path = pg_catalog.
-- - Se ejecuto una prueba transaccional: se revocaron temporalmente los
--   permisos, se creo una tabla de prueba en public y se verifico que
--   el event trigger habilito RLS. La tabla y el REVOKE se revirtieron
--   con ROLLBACK; no quedan cambios persistentes.
--
begin;

revoke execute on function public.rls_auto_enable()
  from public, anon, authenticated;

commit;

-- Verificacion posterior:
-- SELECT has_function_privilege('anon', 'public.rls_auto_enable()', 'EXECUTE');
-- SELECT has_function_privilege('authenticated', 'public.rls_auto_enable()', 'EXECUTE');
-- Ambas deben ser false.
-- Confirmar que ensure_rls permanece habilitado y que una tabla nueva
-- creada en public recibe row level security automaticamente.

-- REVISION DE LOS RPC RESTANTES (2026-11-24):
-- - public.es_admin_activo(): conservar EXECUTE para authenticated.
--   Las politicas RLS de administracion dependen de esta funcion.
-- - public.obtener_mis_pedidos(jsonb): conservar anon y authenticated
--   temporalmente. La app recupera pedidos mediante pares pedido_id +
--   seguimiento_token; retirar anon ahora romperia el seguimiento local
--   cuando no exista sesion. Revisar este diseño en una mejora separada.
-- - public.crear_pedido(...): retirar EXECUTE de PUBLIC/anon/authenticated.
--   El codigo cliente llama al wrapper SECURITY DEFINER, no directamente
--   a esta funcion interna.
-- - public.crear_pedido_con_seguimiento(...): permitir solo authenticated.
--   La app exige sesion y el wrapper verifica perfil_clientes.
--   Estas dos restricciones ya estan incluidas en pagos_qr.sql.
-- - public.admin_actual_puede_crear_usuarios(): SECURITY DEFINER con
--   EXECUTE authenticated. La pantalla/modulo de administradores aun es
--   un modulo pendiente en el panel revisado; no se revoca todavia para
--   evitar romper una funcionalidad futura o codigo no inspeccionado.
--   Antes de implementarlo, revisar su necesidad y mantener su validacion
--   de admin activo + puede_crear_usuarios.
--
-- AUTH:
-- La proteccion contra contrasenas filtradas esta desactivada en el
-- proyecto. Debe habilitarse desde Supabase Dashboard > Authentication >
-- Settings / Password Security (nombre puede variar por version).
-- No se cambio desde SQL ni se modifico la configuracion de Auth.
