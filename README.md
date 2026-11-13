# Pollos Arica

**Sistema de consulta de menú y gestión de pedidos para un negocio gastronómico.**

Pollos Arica es un proyecto académico desarrollado con Flutter y Supabase. Su objetivo es facilitar a los clientes la consulta del menú y la realización de pedidos, y ofrecer al administrador una interfaz web para revisar y gestionar las solicitudes.

> **Estado del repositorio:** esta primera publicación contiene documentación del proyecto. El código fuente de las aplicaciones todavía no está incorporado. La versión de trabajo más reciente permanece en el equipo de desarrollo y deberá añadirse cuando esté disponible.

## Componentes del sistema

| Componente | Tecnología | Propósito |
|---|---|---|
| Aplicación del cliente | Flutter / Dart | Catálogo, carrito, confirmación y consulta de pedidos |
| Panel administrativo | Flutter Web / Dart | Acceso del administrador y gestión de pedidos |
| Backend compartido | Supabase | Servicios y conexión de ambas aplicaciones |
| Base de datos | PostgreSQL | Productos, categorías, clientes y pedidos |
| Almacenamiento | Supabase Storage | Imágenes de productos |
| Autenticación | Supabase Auth | Inicio de sesión administrativo |

## Funcionalidades desarrolladas hasta el avance documentado

- Catálogo de productos organizado por categorías, variantes y precios.
- Carrito de compras y confirmación de pedidos.
- Registro de datos básicos del cliente en el dispositivo.
- Creación de pedidos mediante una función RPC que valida productos, cantidades y precios en el servidor.
- Código y token de seguimiento para consultar pedidos.
- Sección **Mis pedidos**, con historial disponible en el mismo dispositivo o navegador donde se guardaron las credenciales.
- Panel administrativo web con autenticación y módulo de consulta y actualización de pedidos.
- Separación entre estado del pedido y estado del pago.
- Políticas de seguridad mediante Row Level Security (RLS).

## Arquitectura

Las dos aplicaciones son proyectos Flutter independientes y utilizan el mismo proyecto Supabase. Consulta [docs/ARQUITECTURA.md](docs/ARQUITECTURA.md).

## Base de datos

La estructura relacional y las responsabilidades de las tablas se describen en [docs/BASE_DE_DATOS.md](docs/BASE_DE_DATOS.md).

## Documentación

- [Arquitectura del sistema](docs/ARQUITECTURA.md)
- [Modelo de datos](docs/BASE_DE_DATOS.md)
- [Estado y próximos pasos](docs/ESTADO_PROYECTO.md)
- [Configuración y seguridad](docs/CONFIGURACION_Y_SEGURIDAD.md)

## Tecnologías

- Flutter y Dart
- Supabase
- PostgreSQL
- Supabase Auth
- Supabase Storage
- Row Level Security (RLS)

## Ejecución

Cuando el código fuente sea incorporado, cada aplicación tendrá sus propias instrucciones de instalación y ejecución. Las credenciales de Supabase deberán configurarse mediante variables de compilación o un mecanismo local seguro.

No publiques contraseñas, tokens privados ni la clave `service_role` en este repositorio.

## Estado del desarrollo

El proyecto continúa en desarrollo. Las funciones futuras y las limitaciones conocidas están descritas en [docs/ESTADO_PROYECTO.md](docs/ESTADO_PROYECTO.md).

---
**Proyecto académico — Pollos Arica**  
**Organización:** AM1-Licenciados
