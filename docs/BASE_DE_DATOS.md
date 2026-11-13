# Modelo de base de datos

Pollos Arica utiliza PostgreSQL mediante Supabase. La información se organiza en tablas relacionadas mediante claves primarias y foráneas.

## Tablas principales

| Tabla | Responsabilidad |
|---|---|
| `categorias` | Categorías del menú, descripción, estado y orden |
| `productos` | Datos generales de los productos, categoría, imagen y disponibilidad |
| `variantes_producto` | Presentaciones o variantes, precios y disponibilidad |
| `clientes` | Nombre y número de celular del cliente |
| `pedidos` | Información general de la compra, cliente, código, estados, pago y total |
| `detalle_pedidos` | Productos, variantes, cantidades, precios y subtotales de cada pedido |
| `configuracion_negocio` | Datos configurables del negocio, incluida la URL de la imagen del QR |

## Relaciones

- Una categoría puede tener varios productos.
- Un producto puede tener varias variantes.
- Un cliente puede realizar varios pedidos.
- Un pedido puede contener varios registros en `detalle_pedidos`.
- Cada detalle puede referenciar un producto y una variante.

## ¿Por qué clientes, pedidos y detalles están separados?

La tabla `clientes` almacena los datos de la persona una sola vez. La tabla `pedidos` representa cada compra y referencia al cliente. La tabla `detalle_pedidos` almacena cada artículo incluido en esa compra.

Así, un cliente puede realizar múltiples pedidos y un pedido puede incluir múltiples productos, sin repetir toda la información del cliente o crear un pedido independiente por artículo.

## Estados del pedido

Los estados contemplados son:

- `pendiente`
- `aceptado`
- `en_preparacion`
- `listo`
- `entregado`
- `rechazado`
- `cancelado`

## Estados del pago

El estado del pago se gestiona por separado:

- `pendiente`
- `por_verificar`
- `pagado`
- `rechazado`

Esta separación permite conocer el avance operativo de la compra sin confundirlo con la confirmación del pago.

## Funciones de base de datos

- `crear_pedido`: valida y registra un pedido, calculando los importes con información de la base de datos.
- `crear_pedido_con_seguimiento`: amplía el flujo de creación para devolver credenciales de seguimiento.
- `obtener_mis_pedidos`: consulta pedidos a partir de los identificadores y tokens de seguimiento enviados por el cliente.
- `es_admin_activo`: verifica si el usuario autenticado tiene un perfil administrativo activo.

Los nombres y parámetros deben contrastarse con las migraciones SQL definitivas cuando se recupere el código y los scripts originales.

## Seguridad

Se utiliza Row Level Security (RLS) para restringir las operaciones sobre datos sensibles. El acceso administrativo a pedidos, detalles y clientes requiere autenticación y la validación del perfil administrador.

La aplicación cliente no debe incluir la clave secreta `service_role`. Las operaciones públicas deben limitarse mediante políticas y funciones seguras del servidor.
