# Configuración y seguridad

## Configuración de Supabase

Las aplicaciones requieren la URL del proyecto Supabase y una clave pública (publishable o anon, según la configuración del proyecto).

En el proyecto cliente se documentó el uso de variables de compilación:

- `SUPABASE_URL`
- `SUPABASE_PUBLISHABLE_KEY`

Los nombres exactos de variables deben coincidir con los archivos de configuración de cada aplicación cuando se incorpore el código.

## Reglas importantes

- No subir la clave `service_role` a GitHub.
- No subir contraseñas de base de datos ni credenciales personales.
- No almacenar secretos privados dentro del código Flutter.
- Mantener RLS habilitado en las tablas que contienen datos de clientes y pedidos.
- Revisar que las políticas públicas permitan únicamente las operaciones necesarias.
- No asumir que ocultar una pantalla equivale a proteger los datos: los permisos deben aplicarse en Supabase.

## Al recuperar el código

1. Crear archivos locales de configuración a partir de ejemplos sin secretos.
2. Revisar `.gitignore` antes de realizar el primer commit.
3. Verificar que ningún archivo de entorno o credencial esté incluido en el control de versiones.
4. Ejecutar análisis estático y pruebas.
5. Confirmar que las claves utilizadas por las aplicaciones sean las públicas y que las políticas RLS estén correctamente configuradas.
