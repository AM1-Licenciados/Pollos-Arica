# Arquitectura del sistema

## 1. Vista general

La rama de trabajo contiene una aplicación Flutter para clientes, ubicada en `pollosarica/`, que consume servicios de un proyecto Supabase.

```text
Pollos-Arica/
├── pollosarica/       Aplicación Flutter del cliente
├── docs/              Documentación del proyecto
└── README.md

Aplicación Flutter
        │
        ├── Supabase Auth
        ├── PostgreSQL mediante PostgREST
        ├── Funciones RPC
        └── Supabase Storage
```

Este diagrama representa los componentes identificados en el código de la aplicación del cliente. No certifica por sí solo que todas las funciones, políticas o recursos estén desplegados y configurados en el proyecto Supabase.

## 2. Aplicación del cliente

El código revisado contempla:

- Catálogo de productos, categorías, variantes y precios.
- Búsqueda escrita y búsqueda por voz.
- Carrito y confirmación de pedidos.
- Registro e inicio de sesión con Supabase Auth.
- Consulta y actualización del perfil del cliente.
- Carga de fotografía de perfil en Supabase Storage.
- Consulta de pedidos mediante credenciales de seguimiento locales.
- Navegación entre las secciones principales de la aplicación.

## 3. Acceso a datos

Los servicios de la aplicación separan las consultas de catálogo, autenticación, perfil y pedidos de las pantallas que presentan la información.

Entre las operaciones identificadas en el código están:

- Consulta de `categorias` y `productos`.
- Consulta de variantes relacionadas con cada producto.
- Registro e inicio de sesión mediante Supabase Auth.
- Consulta y actualización de `perfiles_clientes`.
- Carga de imágenes en el bucket `perfiles-clientes`.
- Creación de pedidos mediante `crear_pedido_con_seguimiento`.
- Consulta de pedidos mediante `obtener_mis_pedidos`.

Los nombres y parámetros de las funciones RPC deben contrastarse con las definiciones SQL desplegadas en Supabase antes de dar por verificada su implementación.

## 4. Flujo de creación de un pedido

1. El cliente selecciona productos y variantes.
2. La aplicación construye la lista de artículos con sus identificadores y cantidades.
3. La aplicación invoca la función RPC `crear_pedido_con_seguimiento`.
4. La respuesta esperada incluye identificador, código, total y token de seguimiento.
5. La aplicación intenta guardar las credenciales de seguimiento en el dispositivo.
6. El carrito se vacía después de completar el registro del pedido.

La validación de precios, disponibilidad y cantidades debe realizarse en el servidor. Es necesario revisar la definición SQL de la función para confirmar las reglas exactas.

## 5. Consulta de pedidos

La aplicación recupera las credenciales almacenadas localmente y las envía a `obtener_mis_pedidos`. La disponibilidad del historial depende de conservar esas credenciales en el dispositivo o navegador.

## 6. Seguridad

La aplicación utiliza una clave pública de Supabase configurada en tiempo de compilación. Las operaciones sensibles deben estar protegidas por políticas RLS y funciones seguras del backend.

La revisión del código cliente no reemplaza una auditoría de las políticas RLS, permisos de Storage, funciones SQL y configuración del proyecto Supabase.

## 7. Componentes pendientes de verificación

Antes de describir el sistema completo como desplegado, se debe verificar:

- Existencia y configuración de tablas, relaciones e índices.
- Definiciones SQL y permisos de las funciones RPC.
- Políticas RLS para cada tabla.
- Políticas de lectura y escritura del bucket `perfiles-clientes`.
- Triggers relacionados con la creación y actualización de perfiles.
- Estado real de cualquier panel administrativo independiente.
