# Pollos Arica

**Sistema de consulta de menú y gestión de pedidos para un negocio gastronómico.**

Pollos Arica es un proyecto académico desarrollado con Flutter/Dart y Supabase. La solución comprende una aplicación móvil para clientes y un panel web administrativo, conectados a un backend compartido.

> **Estado del repositorio:** este repositorio contiene documentación técnica del proyecto. La copia de trabajo más reciente de las aplicaciones y las migraciones SQL debe incorporarse desde el equipo de desarrollo. Los documentos describen las funcionalidades trabajadas, pero los nombres exactos de tablas, RPC, variables y políticas deben cotejarse con el código/SQL vigente antes de una auditoría formal.

## Componentes

| Componente | Tecnología | Propósito |
|---|---|---|
| App cliente | Flutter / Dart | Catálogo, búsqueda, carrito, pedido, pagos y seguimiento |
| Panel administrador | Flutter Web / Dart | Gestión de catálogo, pedidos, estados y configuración |
| Backend | Supabase | API, Auth, Storage y funciones RPC |
| Base de datos | PostgreSQL | Productos, variantes, clientes, pedidos y detalles |
| Seguridad | Supabase RLS | Control de acceso a los datos |

## Funcionalidades principales

- Catálogo por categorías con productos, variantes, precios y disponibilidad.
- Búsqueda de productos, incluida búsqueda por voz en la versión desarrollada.
- Carrito y registro de pedido mediante RPC con validación de precios en el servidor.
- Código/credenciales de seguimiento y sección Mis pedidos.
- Modalidades y métodos de pago configurados en la app, incluidos efectivo y QR.
- Adjuntar comprobante de pago QR para revisión manual.
- Panel administrativo autenticado para revisar pedidos y actualizar estados.
- Gestión administrativa de productos/precios y configuración del QR de pago.
- Separación entre estado operativo del pedido y estado del pago.

## Documentación

Comienza por el [índice de documentación](docs/README.md).

- [Arquitectura](docs/ARQUITECTURA.md)
- [Funcionalidades y reglas de negocio](docs/OPERACION_Y_FUNCIONALIDADES.md)
- [Instalación y ejecución](docs/INSTALACION_Y_EJECUCION.md)
- [Flujo de pedidos y pagos](docs/FLUJO_PEDIDOS_Y_PAGOS.md)
- [Modelo de base de datos](docs/BASE_DE_DATOS.md)
- [Seguridad de Supabase y RLS](docs/SEGURIDAD_SUPABASE_RLS.md)
- [Pruebas y publicación](docs/PRUEBAS_Y_PUBLICACION.md)
- [Configuración y seguridad](docs/CONFIGURACION_Y_SEGURIDAD.md)
- [Estado del proyecto](docs/ESTADO_PROYECTO.md)

## Tecnologías

Flutter, Dart, Supabase, PostgreSQL, Supabase Auth, Supabase Storage y Row Level Security (RLS).

## Configuración segura

Las aplicaciones cliente deben utilizar únicamente la URL del proyecto y una clave pública publishable/anon. Nunca incluir `service_role`, contraseñas, tokens privados o archivos de firma en el repositorio, APK o documentación.

## Alcance operativo

La operación actual contempla pedidos para retiro en local. La entrega a domicilio, notificaciones automáticas y otras funciones futuras no deben anunciarse como operativas hasta que estén implementadas y verificadas.

---

**Proyecto académico — Pollos Arica**  
**Organización:** AM1-Licenciados
