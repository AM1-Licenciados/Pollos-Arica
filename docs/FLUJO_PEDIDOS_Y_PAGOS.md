# Flujo de pedidos y pagos

## 1. Preparación del pedido
1. El cliente consulta productos y precios desde el catálogo.
2. Selecciona variantes y cantidades.
3. El carrito calcula una vista previa del importe.
4. El cliente completa nombre y celular, modalidad de atención y forma de pago.
5. La aplicación envía la solicitud al backend.

## 2. Creación en Supabase
La creación se realiza mediante una función RPC. El backend debe:
- Validar producto y variante.
- Comprobar disponibilidad y cantidades.
- Obtener precios desde la base de datos.
- Calcular subtotales y total en el servidor.
- Registrar/actualizar al cliente.
- Crear el pedido y sus detalles en una transacción.
- Devolver identificador/código y los datos necesarios para seguimiento.

No confiar en el total enviado por el cliente.

## 3. Estados operativos del pedido
Los estados documentados son:
- `pendiente`
- `aceptado`
- `en_preparacion`
- `listo`
- `entregado`
- `rechazado`
- `cancelado`

El administrador/personal autorizado actualiza el estado desde el panel. La aplicación cliente consulta el estado actualizado.

## 4. Estados del pago
El pago tiene un ciclo independiente:
- `pendiente`
- `por_verificar`
- `pagado`
- `rechazado`

Un pedido puede estar aceptado o en preparación mientras el pago todavía está pendiente de verificación.

## 5. Efectivo
El cliente selecciona efectivo al retirar el pedido. El pago se confirma en el local y el personal autorizado actualiza el estado de pago.

## 6. QR
1. El cliente selecciona pago QR.
2. La app muestra el QR configurado por el administrador.
3. El cliente realiza el pago desde su aplicación bancaria.
4. El cliente adjunta el comprobante si la interfaz lo solicita.
5. La acción de confirmar que pagó se habilita cuando se cumplen las condiciones de la interfaz, incluyendo el comprobante cuando corresponde.
6. El pedido queda pendiente de revisión.
7. El personal verifica el comprobante y actualiza el estado a pagado o rechazado.

**Importante:** subir una imagen no verifica por sí mismo una transacción bancaria. La comprobación del pago es manual en el flujo actual.

## 7. Cancelación y cambios
La regla de negocio acordada permite editar o cancelar antes de que el personal acepte el pedido. Confirmar que la validación se aplica en backend/RLS/RPC y no únicamente ocultando botones en la interfaz.

## 8. Seguimiento
El cliente obtiene un código y credenciales de seguimiento al registrar el pedido. La app guarda localmente los datos necesarios para consultar Mis pedidos. La recuperación depende del dispositivo o navegador donde se guardaron; no se debe prometer recuperación desde otro dispositivo si no existe un mecanismo adicional.

## 9. Atención y horario
La operación actual es retiro en local; delivery está previsto para una etapa posterior. Los pedidos deben aceptarse únicamente dentro del horario configurado en el sistema. Verificar la configuración activa antes de publicar horarios en producción.
