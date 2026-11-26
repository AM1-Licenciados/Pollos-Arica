# Pruebas y publicación

## Estado
La aplicación cliente y el panel administrador fueron desarrollados y probados durante el trabajo. La cobertura automatizada debe confirmarse ejecutando las pruebas existentes en la copia fuente actual. No asumir que todos los casos de esta lista ya cuentan con tests automatizados.

## Pruebas estáticas
Para cada proyecto Flutter:

```powershell
flutter analyze
```

Registrar:
- versión de Flutter/Dart;
- errores, warnings e info;
- cambios en dependencias;
- resultado final.

Los mensajes de deprecación `info` no equivalen por sí solos a errores de compilación.

## Pruebas automatizadas
```powershell
flutter test
```

Casos unitarios recomendados:
- validación de campos de cliente;
- cálculo de cantidades/subtotales en la vista de carrito;
- conversión/validación de estados;
- manejo de errores de RPC y conectividad.

Casos de widgets recomendados:
- catálogo y estado vacío;
- agregar/quitar unidades en carrito;
- formulario de confirmación y validaciones;
- pantalla de pedido registrado;
- carga de comprobante QR y estado del botón de confirmación;
- Mis pedidos y filtros;
- login/logout del administrador;
- estados de carga, error y sin resultados.

## Pruebas funcionales manuales
- [ ] Cliente abre la app y carga catálogo.
- [ ] Categorías y productos disponibles se muestran correctamente.
- [ ] Búsqueda de texto y búsqueda por voz.
- [ ] Carrito permite modificar cantidades y eliminar artículos.
- [ ] Pedido se registra en Supabase con total correcto.
- [ ] Datos de cliente y detalles del pedido se guardan correctamente.
- [ ] Cliente puede consultar su pedido desde Mis pedidos.
- [ ] Cancelación/edición solo antes de aceptación.
- [ ] Pago en efectivo.
- [ ] Pago QR: visualización QR, selección/subida de comprobante y confirmación.
- [ ] Administrador inicia sesión y puede cerrar sesión.
- [ ] Administrador consulta pedidos y detalles.
- [ ] Administrador actualiza estado de pedido y pago.
- [ ] Administrador puede modificar catálogo/precios y configuración QR.
- [ ] Comportamiento correcto sin conexión o ante error de Supabase.
- [ ] Restricciones de horario verificadas.

## Pruebas de seguridad
- [ ] Cliente no puede modificar precios ni totales arbitrariamente.
- [ ] Cliente A no puede consultar pedidos de Cliente B.
- [ ] Usuario no administrador no puede modificar catálogo ni estados.
- [ ] Archivos de comprobante no son accesibles públicamente sin autorización.
- [ ] No hay `service_role` ni secretos en artefactos cliente.
- [ ] Validar límites y entradas de RPC.

## Pruebas de rendimiento
Medir en dispositivo real:
- tiempo de inicio;
- tiempo de carga del catálogo;
- tiempo de envío de pedido;
- consumo de memoria;
- respuesta con red lenta;
- tamaño del APK y recursos.

## Proceso de publicación
1. Confirmar branch y revisar `git status`.
2. Revisar cambios en `pubspec.lock`.
3. Ejecutar `flutter pub get`, `flutter analyze` y `flutter test`.
4. Probar los flujos críticos en Android y Chrome.
5. Compilar release con defines públicos correctos.
6. Verificar el APK/web build generado.
7. No incluir archivos locales, claves privadas, keystores o secretos.
8. Guardar versión, fecha, commit y resultados de pruebas.

## Incidencias conocidas / pendientes de confirmar
- Validar la configuración final del servicio de pago QR y sus políticas Storage.
- Verificar los nombres y parámetros de RPC con las migraciones SQL definitivas.
- Confirmar las reglas RLS en el proyecto Supabase activo.
- Delivery y notificaciones automáticas no deben considerarse operativos hasta su implementación y prueba.
