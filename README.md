# Pollos Arica

**Aplicación móvil para consultar el menú y realizar pedidos de un negocio gastronómico local.**

Pollos Arica es un proyecto académico desarrollado con Flutter y Supabase. Su objetivo es facilitar la consulta del menú, la gestión del carrito y la realización y seguimiento de pedidos.

> **Estado:** la rama `feature/busqueda-por-voz` contiene el código de la aplicación del cliente en `pollosarica/`. El estado de los componentes administrativos y de los scripts SQL debe verificarse por separado antes de considerarlos parte de esta entrega.

## Funcionalidades presentes en la aplicación del cliente

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

## Tecnologías

| Componente | Tecnología |
|---|---|
| Aplicación del cliente | Flutter y Dart |
| Backend | Supabase |
| Base de datos | PostgreSQL |
| Autenticación | Supabase Auth |
| Archivos e imágenes | Supabase Storage |
| Seguridad de datos | Row Level Security (RLS) |

## Estructura documentada

```text
Pollos-Arica/
├── pollosarica/       Aplicación Flutter del cliente
├── docs/              Documentación técnica y evidencias
└── README.md
```

La presencia y el estado de otros proyectos o scripts deben confirmarse en la rama antes de utilizarlos como evidencia de entrega.

## Documentación

- [Arquitectura del sistema](docs/ARQUITECTURA.md)
- [Modelo de base de datos](docs/BASE_DE_DATOS.md)
- [Estado del proyecto y próximos pasos](docs/ESTADO_PROYECTO.md)
- [Configuración y seguridad](docs/CONFIGURACION_Y_SEGURIDAD.md)
- [Evidencias de la actividad 4](docs/ACTIVIDAD_4_EVIDENCIAS_POLLOS_ARICA.md)

## Configuración local

Desde el directorio `pollosarica/`:

```bash
flutter pub get
flutter run
```

La aplicación requiere las variables de compilación `SUPABASE_URL` y `SUPABASE_PUBLISHABLE_KEY`. No se deben incluir claves secretas, contraseñas, tokens privados ni archivos de firma en el repositorio.

Ejemplo de ejecución web:

```bash
flutter run -d chrome --dart-define=SUPABASE_URL=TU_URL --dart-define=SUPABASE_PUBLISHABLE_KEY=TU_CLAVE_PUBLICA
```

## Validación

Antes de integrar cambios a `main`, ejecutar desde `pollosarica/`:

```bash
flutter pub get
flutter analyze
flutter test
```

La aprobación de estas comprobaciones locales no sustituye las pruebas funcionales con Supabase ni las pruebas en dispositivos físicos.

## Estado y alcance

El proyecto continúa en desarrollo. Las integraciones externas, el cobro por QR, la generación de la APK de lanzamiento y las pruebas con usuarios deben registrarse como completadas únicamente cuando existan evidencias verificables.

---

**Proyecto académico — Pollos Arica**  
**Organización:** AM1-Licenciados
