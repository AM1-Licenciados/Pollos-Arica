-- Pollos Arica
-- OPTIMIZACIONES APLICADAS EN SUPABASE (2026-11-24). Referencia SQL. DE OPTIMIZACION DE INDICES Y POLITICAS
-- No ejecutado en la base de datos.
--
-- Los dos indices cubren las FK que el Performance Advisor identifico
-- sin indice. Se conservan las FK y el indice existente de pedido_id.
--
-- En configuracion_negocio hay dos politicas SELECT permisivas con
-- la misma expresion true y los mismos roles anon/authenticated.
-- Se elimina solo la duplicada configuracion_publica_lectura.

begin;

create index if not exists idx_detalle_pedidos_producto_id
  on public.detalle_pedidos (producto_id);

create index if not exists idx_detalle_pedidos_variante_id
  on public.detalle_pedidos (variante_id);

drop policy if exists configuracion_publica_lectura
  on public.configuracion_negocio;

commit;

-- Verificacion posterior:
-- 1. Confirmar ambos indices en pg_indexes.
-- 2. Confirmar que configuracion_negocio conserva
--    configuracion_negocio_lectura_publica para anon/authenticated.
-- 3. Repetir Performance Advisor.

--
-- APLICADO:
-- - idx_detalle_pedidos_producto_id
-- - idx_detalle_pedidos_variante_id
-- - idx_pagos_qr_auditoria_pedido_id (FK de auditoria QR)
-- - Eliminada politica duplicada configuracion_publica_lectura.
--
-- No se eliminaron indices marcados como unused: requieren observacion
-- de uso real antes de decidir si se pueden retirar.
-- Las politicas SELECT de admin y cliente en pedidos/detalles se conservan
-- porque protegen grupos de acceso diferentes.
-- La politica UPDATE clientes_notificar_pago_qr se conserva por el flujo QR.
