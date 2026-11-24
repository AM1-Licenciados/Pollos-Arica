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
-- Verificacion previa:
-- - ensure_rls existe y apunta a public.rls_auto_enable().
-- - La funcion es SECURITY DEFINER, propiedad de postgres y usa
--   search_path = pg_catalog.
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
