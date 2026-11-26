# Seguridad de Supabase y RLS

## Principios
- Usar únicamente la clave pública `publishable` o `anon` en las aplicaciones cliente.
- Nunca incluir `service_role`, contraseña de PostgreSQL, JWT secret ni secretos de OAuth en Flutter, Flutter Web, APK, repositorio o documentación.
- Habilitar Row Level Security (RLS) en tablas expuestas por la API.
- Aplicar autorización en PostgreSQL/Supabase; ocultar botones en la UI no es control de acceso.
- Validar datos y precios en funciones de servidor.
- Mantener funciones RPC con permisos mínimos y validar sus parámetros.

## Áreas a revisar
- Productos y categorías: lectura pública solo de productos publicados/disponibles; escritura solo de administradores autorizados.
- Variantes/precios: lectura de catálogo; escritura administrativa.
- Clientes: limitar lectura de datos personales.
- Pedidos y detalles: el cliente solo debe consultar los pedidos para los que presenta credenciales válidas; personal/admin autorizado puede operar pedidos según rol.
- Configuración del negocio y QR: lectura de la configuración pública necesaria; escritura solo administrativa.
- Storage: separar buckets públicos de imágenes de catálogo de archivos privados, como comprobantes de pago.
- Comprobantes: si se almacenan en Storage, validar acceso y no exponerlos públicamente salvo decisión explícita y justificada.

## Funciones administrativas
La función `es_admin_activo` se documenta como verificación del perfil administrativo activo. Revisar su implementación para:
- evitar recursión de políticas RLS;
- no confiar en valores enviados por el cliente;
- limitar permisos de ejecución;
- comprobar el estado activo del usuario;
- no exponer datos personales a usuarios no autorizados.

## RPC de pedidos
Las funciones documentadas incluyen `crear_pedido`, `crear_pedido_con_seguimiento` y `obtener_mis_pedidos`. Contrastar nombres, parámetros y comportamiento con el SQL real antes de una auditoría formal.

Revisar:
- validación de cantidades y disponibilidad;
- cálculo de precio/total desde tablas;
- transacciones y manejo de errores;
- generación de tokens de seguimiento no predecibles;
- comparación segura de credenciales;
- límites de frecuencia y prevención de pedidos abusivos;
- permisos `EXECUTE` para `anon` y `authenticated`.

## Lista de verificación para el ingeniero
- [ ] RLS habilitado en todas las tablas expuestas.
- [ ] Políticas probadas con anon, cliente autenticado y administrador.
- [ ] Ninguna clave secreta en el repositorio ni en el APK.
- [ ] Storage de comprobantes privado y con autorización.
- [ ] Storage de imágenes públicas limitado a recursos del catálogo.
- [ ] RPC con permisos mínimos y validación de parámetros.
- [ ] Revisión de logs para evitar tokens, comprobantes o datos personales.
- [ ] Rotación de credenciales si alguna clave privada se compartió accidentalmente.
- [ ] Confirmación de reglas de respaldo y retención de datos.
- [ ] Pruebas de acceso cruzado: un cliente no debe ver pedidos de otro.
