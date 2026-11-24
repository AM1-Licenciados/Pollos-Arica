-- Permite a administradores activos registrar la variante/precio inicial
-- de productos que aún no tienen presentación en variantes_producto.
begin;

grant insert (
  producto_id,
  nombre,
  precio,
  es_predeterminada,
  activa,
  orden,
  disponible
) on public.variantes_producto to authenticated;

drop policy if exists variantes_producto_admin_insert_precio_inicial
  on public.variantes_producto;

create policy variantes_producto_admin_insert_precio_inicial
  on public.variantes_producto
  for insert
  to authenticated
  with check (
    (select public.es_admin_activo())
    and exists (
      select 1 from public.productos p
      where p.id = producto_id and p.activo = true
    )
  );

commit;
