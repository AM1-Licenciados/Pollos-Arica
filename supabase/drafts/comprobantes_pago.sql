-- Pollos Arica: comprobantes privados para pagos QR
-- Este SQL documenta las migraciones aplicadas directamente al proyecto Supabase.
-- Bucket privado: 5 MB, solo JPEG/PNG/WEBP.
-- Ruta determinista: {auth.uid()}/{pedido.id}/comprobante

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'comprobantes-pago',
  'comprobantes-pago',
  false,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
set public = false,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists comprobantes_cliente_subir_pedido_propio on storage.objects;
create policy comprobantes_cliente_subir_pedido_propio
on storage.objects for insert to authenticated
with check (
  bucket_id = 'comprobantes-pago'
  and (storage.foldername(name))[1] = (select auth.uid())::text
  and (storage.foldername(name))[2] is not null
  and exists (
    select 1
    from public.pedidos p
    where p.id::text = (storage.foldername(name))[2]
      and p.auth_user_id = (select auth.uid())
      and p.metodo_pago = 'qr'
      and p.estado_pago = 'pendiente'
  )
);

drop policy if exists comprobantes_cliente_y_admin_leer on storage.objects;
create policy comprobantes_cliente_y_admin_leer
on storage.objects for select to authenticated
using (
  bucket_id = 'comprobantes-pago'
  and (
    (storage.foldername(name))[1] = (select auth.uid())::text
    or (select public.es_admin_activo())
  )
);

drop policy if exists comprobantes_cliente_eliminar_pendiente on storage.objects;
create policy comprobantes_cliente_eliminar_pendiente
on storage.objects for delete to authenticated
using (
  bucket_id = 'comprobantes-pago'
  and (storage.foldername(name))[1] = (select auth.uid())::text
  and exists (
    select 1
    from public.pedidos p
    where p.id::text = (storage.foldername(name))[2]
      and p.auth_user_id = (select auth.uid())
      and p.metodo_pago = 'qr'
      and p.estado_pago = 'pendiente'
  )
);

drop policy if exists pedidos_qr_notificacion_requiere_comprobante on public.pedidos;
create policy pedidos_qr_notificacion_requiere_comprobante
on public.pedidos as restrictive
for update to authenticated
using (true)
with check (
  metodo_pago <> 'qr'
  or estado_pago <> 'por_verificar'
  or exists (
    select 1
    from storage.objects o
    where o.bucket_id = 'comprobantes-pago'
      and o.name = (select auth.uid())::text || '/' ||
                   public.pedidos.id::text || '/comprobante'
  )
);
