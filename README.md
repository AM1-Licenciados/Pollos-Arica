# Pollos Arica

**Aplicación móvil para consultar el menú y realizar pedidos de un negocio gastronómico local, acompañada de un panel web administrativo.**

Pollos Arica es un proyecto académico desarrollado con Flutter/Dart y Supabase. Su objetivo es facilitar la consulta del menú, la gestión del carrito, la realización y seguimiento de pedidos, así como la administración del negocio.

## Estado del proyecto

El repositorio contiene documentación técnica del proyecto y se encuentra en proceso de integración del código fuente de las aplicaciones y las migraciones SQL.

Los documentos describen las funcionalidades trabajadas. Los nombres exactos de tablas, funciones RPC, variables y políticas deben cotejarse con el código y SQL vigentes antes de una auditoría formal.

## Componentes

| Componente | Tecnología | Propósito |
|---|---|---|
| Aplicación del cliente | Flutter / Dart | Catálogo, búsqueda, carrito, pedidos, pagos y seguimiento |
| Panel administrativo | Flutter Web / Dart | Gestión de catálogo, pedidos, estados y configuración |
| Backend | Supabase | API, Auth, Storage y funciones RPC |
| Base de datos | PostgreSQL | Productos, variantes, clientes, pedidos y detalles |
| Seguridad | Supabase RLS | Control de acceso a los datos |

## Funcionalidades de la aplicación del cliente

- Catálogo conectado a Supabase, con categorías, productos, variantes y precios.
- Búsqueda escrita y búsqueda por voz en el catálogo.
- Carrito de compras y confirmación de pedidos.
- Registro e inicio de sesión mediante Supabase Auth.
- Perfil del cliente, edición de datos y fotografía de perfil mediante Supabase Storage.
- Creación de pedidos mediante la función RPC `crear_pedido_con_seguimiento`.
- Consulta de pedidos mediante la función RPC `obtener_mis_pedidos`.
- Estados del pedido y del pago presentados por separado.
- Navegación entre Inicio, Mis pedidos y Perfil.

La consulta del historial utiliza credenciales de seguimiento almacenadas localmente en el dispositivo o navegador. Si se pierde ese almacenamiento, no debe asumirse que el historial se recuperará automáticamente en otro dispositivo.

## Funcionalidades administrativas

- Panel web administrativo.
- Gestión de productos y precios.
- Consulta y gestión de pedidos.
- Actualización de estados operativos.
- Configuración del QR de pago.
- Revisión manual de comprobantes de pago.

## Flujo de pedidos y pagos

El sistema contempla el registro de pedidos y el seguimiento de su estado. Entre las modalidades y métodos de pago trabajados se encuentran el efectivo y el pago mediante QR.

El comprobante de pago QR puede adjuntarse para su revisión manual.

La operación actual contempla pedidos para retiro en local. La entrega a domicilio, las notificaciones automáticas y otras funciones futuras no deben anunciarse como operativas hasta que estén implementadas y verificadas.

## Estructura documentada

```text
Pollos-Arica/
├── pollosarica/          Aplicación Flutter del cliente
├── pollosarica_admin/    Panel administrativo
├── docs/                 Documentación técnica y evidencias
└── README.md
```

La presencia y el estado de los proyectos y scripts SQL deben confirmarse en la rama antes de utilizarlos como evidencia de entrega.

## Tecnologías

- Flutter y Dart.
- Supabase.
- PostgreSQL.
- Supabase Auth.
- Supabase Storage.
- Row Level Security (RLS).

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

## Configuración local

Desde el directorio `pollosarica/`:

```bash
flutter pub get
flutter run
```

La aplicación requiere las variables de compilación `SUPABASE_URL` y `SUPABASE_PUBLISHABLE_KEY`.

Ejemplo de ejecución web:

```bash
flutter run -d chrome --dart-define=SUPABASE_URL=TU_URL --dart-define=SUPABASE_PUBLISHABLE_KEY=TU_CLAVE_PUBLICA
```

Las aplicaciones cliente deben utilizar únicamente la URL del proyecto y una clave pública publishable/anon. Nunca incluir `service_role`, contraseñas, tokens privados o archivos de firma en el repositorio, APK o documentación.

## Validación

Antes de integrar cambios a `main`, ejecutar desde el directorio correspondiente:

```bash
flutter pub get
flutter analyze
flutter test
```

La aprobación de estas comprobaciones locales no sustituye las pruebas funcionales con Supabase ni las pruebas en dispositivos físicos.

## Estado y alcance

El proyecto continúa en desarrollo. Las funcionalidades, integraciones y publicaciones deben registrarse como completadas únicamente cuando existan evidencias verificables.

---

**Proyecto académico — Pollos Arica**  
**Organización:** AM1-Licenciados