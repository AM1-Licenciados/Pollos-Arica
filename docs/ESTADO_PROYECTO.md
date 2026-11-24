# Estado del proyecto

**Corte de documentación:** 23 de noviembre de 2026.  
**Rama revisada:** `feature/busqueda-por-voz`.

Este documento separa las funcionalidades identificadas en el código, las verificaciones reportadas y los pendientes. No representa una certificación de producción ni una auditoría del backend.

## 1. Aplicación del cliente

En el código de la rama se identifican:

- Bienvenida y catálogo conectado a Supabase.
- Consulta de categorías, productos, variantes y precios.
- Búsqueda escrita y búsqueda por voz.
- Carrito y confirmación de pedidos.
- Registro e inicio de sesión mediante Supabase Auth.
- Recuperación de contraseña.
- Perfil del cliente con edición de datos.
- Actualización de fotografía de perfil mediante Supabase Storage.
- Creación de pedidos mediante `crear_pedido_con_seguimiento`.
- Consulta de pedidos mediante `obtener_mis_pedidos`.
- Sección Mis pedidos con filtros y actualización manual.
- Navegación inferior entre Inicio, Mis pedidos y Perfil.

## 2. Verificaciones de desarrollo reportadas

En la sincronización de la rama se informó que:

- `flutter analyze` finalizó sin problemas.
- `flutter test` finalizó correctamente.
- Los cambios de interfaz y búsqueda por voz se publicaron en GitHub.

Estas comprobaciones corresponden a la ejecución local reportada. No equivalen a pruebas completas de integración, seguridad, rendimiento o aceptación con usuarios.

## 3. Integraciones identificadas en el código

- Supabase Auth para autenticación.
- PostgreSQL mediante consultas Supabase.
- Supabase Storage para fotografías de perfil.
- Funciones RPC para crear y consultar pedidos.
- Variables de compilación para URL y clave pública de Supabase.

Es necesario verificar en el proyecto Supabase que las tablas, funciones, triggers, políticas RLS y permisos de Storage estén desplegados y configurados correctamente.

## 4. Limitaciones y aspectos pendientes

- La consulta del historial depende de las credenciales de seguimiento guardadas localmente.
- No se ha acreditado recuperación del historial mediante SMS.
- La verificación de pagos QR debe validarse como flujo real; la existencia de una imagen QR no equivale a una integración con una API de cobro.
- La integración con una API externa de cobro por QR está pendiente de diseño, implementación y pruebas.
- La generación y validación de una APK de lanzamiento están pendientes.
- Las pruebas de aceptación con usuarios deben documentarse con participantes, tareas, resultados y observaciones.
- La auditoría de RLS, funciones SQL, triggers y Storage está pendiente.
- La documentación del esquema debe contrastarse con las migraciones o el esquema real de Supabase.
- El estado de un panel administrativo independiente debe verificarse antes de presentarlo como entregable terminado.

## 5. Próximas actividades del proyecto integrador

1. Verificar el estado real de Supabase y documentar el esquema desplegado.
2. Diseñar la integración con la API de cobro por QR y sus medidas de seguridad.
3. Implementar y probar el flujo de pago en un entorno de pruebas.
4. Ejecutar pruebas funcionales y de aceptación con usuarios.
5. Generar la APK de lanzamiento y comprobar su instalación y funcionamiento.
6. Completar el informe técnico, resultados de pruebas y bitácora de IA.
7. Preparar la defensa en video de 10 minutos.
8. Revisar el repositorio, sus ramas y el historial antes de la entrega final.

## 6. Criterio de publicación

Una funcionalidad se considerará terminada cuando esté implementada, probada y respaldada por evidencia verificable. No se deben publicar claves privadas, contraseñas, tokens ni archivos de firma.
