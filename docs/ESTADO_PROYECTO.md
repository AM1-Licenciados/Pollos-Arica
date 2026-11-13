# Estado del proyecto

**Corte de documentación:** noviembre de 2026.

Este documento distingue los avances implementados, las limitaciones conocidas y las mejoras previstas. No representa una certificación de producción.

## Avances implementados según el desarrollo documentado

### Aplicación del cliente
- Bienvenida y registro local de nombre y celular.
- Catálogo conectado a Supabase.
- Productos, categorías, variantes y precios.
- Carrito de compras.
- Confirmación y creación de pedidos mediante RPC.
- Selección de modalidad de atención y método de pago.
- Código de pedido y credenciales de seguimiento.
- Sección Mis pedidos con consulta y actualización manual.

### Panel administrativo web
- Proyecto Flutter Web independiente.
- Inicio de sesión con Supabase Auth.
- Dashboard y navegación administrativa.
- Módulo de pedidos.
- Consulta de información general y detalles.
- Actualización de estado del pedido y del pago.

### Backend
- Base de datos relacional PostgreSQL.
- Funciones RPC para crear y consultar pedidos.
- Almacenamiento de credenciales de seguimiento en el dispositivo cliente.
- Políticas RLS y validación de administrador activo.
- Bucket público de imágenes de productos.

## Limitaciones conocidas

- La recuperación de Mis pedidos está vinculada al navegador o dispositivo donde se guardaron las credenciales.
- No se implementó recuperación de historial mediante SMS.
- La verificación de pagos QR se realiza manualmente.
- La entrega a domicilio todavía no forma parte del flujo operativo implementado.
- Las notificaciones automáticas al administrador y al cliente están previstas, pero no deben considerarse terminadas.
- El código fuente de las dos aplicaciones y las migraciones SQL originales todavía deben recuperarse e incorporarse a este repositorio.

## Próximas actividades

1. Recuperar la versión actual del código fuente desde el equipo principal.
2. Incorporar los proyectos Flutter del cliente y del administrador.
3. Incorporar y ordenar las migraciones y scripts SQL.
4. Revisar las políticas RLS y los permisos con pruebas específicas.
5. Ejecutar `flutter pub get`, `flutter analyze` y pruebas funcionales en ambos proyectos.
6. Documentar capturas de las pantallas y del panel Supabase.
7. Evaluar notificaciones, recuperación de pedidos y entrega a domicilio.

## Criterio de publicación

Cada nueva versión deberá probarse antes de considerarse estable. No se deben subir claves privadas, contraseñas, tokens ni archivos de firma al repositorio.
