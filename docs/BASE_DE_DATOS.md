# Modelo de base de datos

Pollos Arica utiliza Supabase como backend y PostgreSQL como base de datos. Este documento resume las entidades y operaciones referenciadas por el código de la aplicación del cliente. **No sustituye las migraciones SQL ni representa una inspección directa del esquema desplegado.**

## Tablas referenciadas por la aplicación

| Tabla | Uso identificado en el código |
|---|---|
| `categorias` | Consulta de categorías activas y su orden |
| `productos` | Consulta de productos activos y sus datos de catálogo |
| `variantes_producto` | Variantes, precios, disponibilidad y presentación de productos |
| `perfiles_clientes` | Consulta y actualización de datos y fotografía del perfil |
| `configuracion_negocio` | Consulta de la URL de la imagen QR |

El flujo de pedidos también utiliza funciones RPC y estructuras de respuesta que hacen referencia a pedidos y sus detalles. La estructura exacta de esas tablas debe verificarse con el esquema SQL desplegado.

## Relaciones conceptuales

De acuerdo con las consultas del catálogo:

- Una categoría puede agrupar varios productos.
- Un producto puede tener varias variantes.

En el modelo de pedidos descrito por las respuestas de la aplicación:

- Un pedido puede incluir varios detalles.
- Cada detalle representa un producto, una variante, una cantidad y sus importes.

Estas relaciones deben confirmarse con las claves foráneas reales de PostgreSQL.

## Funciones RPC referenciadas

| Función | Uso desde la aplicación |
|---|---|
| `crear_pedido_con_seguimiento` | Registrar un pedido y obtener datos y credenciales de seguimiento |
| `obtener_mis_pedidos` | Recuperar pedidos usando credenciales de seguimiento |

La aplicación espera que la función de creación devuelva al menos el identificador del pedido, código, total y token de seguimiento. Los nombres y tipos de parámetros deben verificarse contra la definición SQL real.

## Estados de pedidos y pagos

La interfaz contempla estados de pedido como:

- `pendiente`
- `aceptado`
- `en_preparacion`
- `listo`
- `entregado`
- `rechazado`
- `cancelado`

El estado de pago se presenta por separado y contempla:

- `pendiente`
- `por_verificar`
- `pagado`
- `rechazado`

La lista definitiva de valores permitidos debe contrastarse con las restricciones o tipos definidos en PostgreSQL.

## Seguridad

El acceso a las tablas y funciones debe protegerse mediante Row Level Security (RLS), privilegios SQL y validaciones del lado servidor. La clave `service_role` nunca debe incluirse en una aplicación Flutter cliente.

## Verificaciones necesarias

Para cerrar este modelo como documentación técnica definitiva, incorporar o consultar:

1. Migraciones SQL del esquema actual.
2. Claves primarias, foráneas, índices y restricciones.
3. Políticas RLS por tabla.
4. Definiciones y permisos de las funciones RPC.
5. Políticas de Storage para las imágenes.
6. Triggers que relacionan usuarios autenticados con perfiles de cliente.
