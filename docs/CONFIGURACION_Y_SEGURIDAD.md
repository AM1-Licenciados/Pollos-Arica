# Configuración y seguridad

## 1. Variables de configuración

La aplicación cliente obtiene la URL del proyecto Supabase y la clave pública mediante variables de compilación:

- `SUPABASE_URL`
- `SUPABASE_PUBLISHABLE_KEY`

El archivo `pollosarica/lib/core/config/supabase_config.dart` define estas variables mediante `String.fromEnvironment`.

Ejemplo para ejecutar en Chrome:

```bash
flutter run -d chrome \
  --dart-define=SUPABASE_URL=TU_URL \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=TU_CLAVE_PUBLICA
```

Utilizar la clave pública (publishable o anon, según la configuración del proyecto). Nunca utilizar la clave secreta `service_role` en una aplicación cliente.

## 2. Reglas de seguridad

- No subir claves secretas, contraseñas de base de datos, tokens privados ni credenciales personales.
- No incluir archivos de firma ni contraseñas de firma en el repositorio.
- Mantener RLS habilitado en las tablas que contienen información de clientes y pedidos.
- Aplicar privilegios mínimos a usuarios anónimos y autenticados.
- Validar en el servidor precios, cantidades, disponibilidad y transiciones sensibles de pedidos.
- No considerar que ocultar una pantalla o un botón sea una medida de autorización.
- Revisar los permisos de lectura y escritura de cada bucket de Storage.

## 3. Recursos de Supabase utilizados por el código

La aplicación cliente referencia:

- Supabase Auth para registro, inicio de sesión y recuperación de contraseña.
- Tabla `perfiles_clientes` para datos del perfil.
- Bucket `perfiles-clientes` para fotografías de perfil.
- Tablas `categorias`, `productos` y `variantes_producto` para el catálogo.
- Tabla `configuracion_negocio` para recuperar la URL del QR.
- Funciones RPC `crear_pedido_con_seguimiento` y `obtener_mis_pedidos`.

La presencia de estas referencias en el código no demuestra que los recursos y políticas estén correctamente desplegados. Deben verificarse en el proyecto Supabase.

## 4. Verificación previa a una publicación

1. Confirmar que las variables de compilación correspondan al proyecto correcto.
2. Revisar que no se haya incluido ninguna clave secreta en el código o historial Git.
3. Revisar RLS, privilegios SQL y políticas de Storage.
4. Verificar triggers de creación y actualización de perfiles.
5. Probar registro, inicio de sesión, actualización de perfil, fotografía y pedidos.
6. Ejecutar `flutter analyze` y `flutter test`.
7. Probar la aplicación en un dispositivo físico y en el entorno de publicación.

## 5. Manejo de incidentes

Si una clave secreta se publica accidentalmente, debe revocarse o rotarse desde Supabase. Eliminarla de un commit posterior no invalida la exposición que ocurrió en el historial.
