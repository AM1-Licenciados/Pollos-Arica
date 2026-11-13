# Arquitectura del sistema

## 1. Vista general

Pollos Arica está organizado en dos aplicaciones Flutter independientes que consumen servicios del mismo proyecto Supabase:

```text
PollosArica
├── pollosarica/          Aplicación orientada al cliente
├── pollosarica_admin/    Panel administrativo web
├── supabase/             Scripts y documentación SQL
└── docs/                 Documentación técnica
          │
          ▼
     Supabase compartido
     ├── PostgreSQL
     ├── Auth
     ├── Storage
     ├── Funciones RPC
     └── Políticas RLS
```

Esta es la estructura objetivo del repositorio. Los directorios de código y scripts se incorporarán cuando se recupere la copia de trabajo.

## 2. Aplicación del cliente

La aplicación permite:

- Consultar el catálogo y sus categorías.
- Revisar productos, variantes y precios.
- Agregar, quitar y modificar productos en el carrito.
- Registrar los datos básicos del cliente localmente.
- Confirmar pedidos y seleccionar el método de pago y modalidad de atención.
- Consultar el historial en **Mis pedidos** mediante credenciales de seguimiento guardadas en el dispositivo.

La versión de seguimiento documentada no utiliza verificación SMS. Por ello, el historial está asociado al dispositivo o navegador donde se guardaron las credenciales.

## 3. Panel administrativo web

Es una aplicación Flutter Web independiente. El administrador inicia sesión mediante Supabase Auth. El acceso a datos administrativos está condicionado por la validación de administrador activo y las políticas RLS.

El módulo de pedidos permite consultar los pedidos, revisar sus detalles y actualizar estados del pedido y del pago.

## 4. Backend compartido

Supabase centraliza la base de datos PostgreSQL, la autenticación, el almacenamiento de imágenes y las funciones RPC. Las dos aplicaciones utilizan el mismo backend, por lo que los cambios realizados desde el panel administrativo pueden reflejarse en las consultas de la aplicación del cliente.

## 5. Flujo de creación de un pedido

1. El cliente selecciona productos y variantes en el catálogo.
2. La aplicación envía los datos del cliente y los artículos a una función RPC.
3. La función valida la disponibilidad, las cantidades y los precios usando los datos del servidor.
4. Se registra o actualiza el cliente y se crea el pedido.
5. Se registran los artículos en el detalle del pedido.
6. Se devuelve el código del pedido y las credenciales de seguimiento.
7. La aplicación guarda localmente las credenciales para permitir la consulta posterior.

## 6. Flujo administrativo

1. El administrador inicia sesión.
2. Supabase Auth autentica al usuario.
3. Las políticas RLS y la validación de administrador activo controlan el acceso.
4. El panel consulta pedidos, clientes y detalles autorizados.
5. El administrador actualiza el estado del pedido o del pago.
6. La aplicación del cliente puede consultar el estado actualizado.

## 7. Decisiones de diseño

- Separar la aplicación del cliente del panel administrativo permite adaptar cada interfaz a su usuario.
- Compartir Supabase evita mantener bases de datos duplicadas.
- Las validaciones críticas del pedido se ejecutan en el servidor.
- RLS aplica controles de acceso directamente en PostgreSQL.
