# Actividad 4 — Pollos Arica
## Evidencias de desarrollo y despliegue

**Asignatura:** Aplicaciones Móviles I  
**Proyecto:** Pollos Arica  
**Estudiante:** Jhoan Sebastian Davila Tudó  
**Dispositivo de prueba de voz:** Honor 50 (Android)

## Evidencias documentadas
- **E1 — Entorno de desarrollo:** diagnóstico de Flutter y Android.
- **E2 — Aplicación en ejecución:** catálogo, consulta y pedidos.
- **E3 — Búsqueda por voz:** reconocimiento y filtrado del catálogo.
- **E4 — Autenticación:** inicio de sesión y registro.
- **E5 — Validación:** validación de campos del formulario.
- **E6 — Confirmación de correo:** aviso en la aplicación y correo recibido.
- **E7 — Perfil del cliente:** datos personales y opciones de cuenta.
- **E8 — Fotografía de perfil:** actualización de la fotografía personal mediante Supabase Storage.
- **E9 — Carrito y pedido:** revisión y confirmación del pedido.
- **E10 — Autocompletado:** recuperación de datos del cliente desde Supabase.
- **E11 — Gestión del pedido:** vista administrativa y vista del cliente.

## Pruebas complementarias en Android
En un Honor 50 se documentaron:
1. Solicitud del permiso de micrófono de Android.
2. Búsqueda por voz exitosa con la frase “pollo a la leña”, que filtra el catálogo.
3. Mensaje cuando no se puede reconocer la voz.
4. Mensaje cuando el reconocimiento no está disponible, manteniendo la búsqueda escrita.

## Decisiones de alcance
- La fotografía que se actualiza en Pollos Arica es la **fotografía de perfil del cliente**.
- No se implementa cambio del logotipo ni de la fotografía comercial del restaurante.
- La búsqueda por voz filtra el catálogo; no ejecuta comandos ni modifica datos del backend.

## Cambios de interfaz incluidos en esta rama
- Catálogo con logotipo en el encabezado y sin el banner promocional superior.
- Espaciado superior más uniforme.
- Distribución adaptable de productos con altura natural mediante Wrap.
- Navegación inferior flotante en cápsula blanca.
- Perfil con espacio inferior para acceder al final del contenido.
- Botón “Cerrar sesión” rojo con texto e icono blancos.

## Verificación local antes de integrar a main
Ejecutar desde `pollosarica/`:
```bash
flutter analyze
flutter test
flutter run -d chrome
``
Y repetir la prueba en Android físico. Este registro no afirma que esas comprobaciones se hayan ejecutado durante la actualización remota.

## Archivos finales
El informe IMRyD y la presentación con capturas se mantienen como entregables adjuntos de la actividad. Esta nota registra su contenido y el estado de la rama.
