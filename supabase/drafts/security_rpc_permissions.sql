
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
