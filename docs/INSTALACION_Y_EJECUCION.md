# Instalación y ejecución

## Requisitos
- Flutter SDK compatible con la versión usada por el proyecto.
- Dart incluido con Flutter.
- Git.
- Visual Studio Code o IDE equivalente.
- Chrome para ejecutar el panel web.
- Android SDK y dispositivo/emulador Android para la app cliente.
- Acceso al proyecto Supabase de Pollos Arica.

Verificar el entorno con:

```powershell
flutter doctor
flutter --version
```

## Estructura esperada de trabajo
El repositorio contiene dos aplicaciones Flutter independientes:
- `pollosarica/`: aplicación móvil del cliente.
- `pollosarica_admin/`: panel administrativo Flutter Web.

Ejecutar los comandos dentro de la carpeta correspondiente.

## Dependencias
Para cada aplicación:

```powershell
flutter pub get
flutter analyze
flutter test
```

Si no existe una carpeta `test/` con pruebas relevantes, registrar que no hay pruebas automatizadas disponibles; no interpretar una ejecución sin tests como cobertura completa.

## Variables de configuración
La app cliente usa configuración de Supabase mediante defines de compilación. Los nombres documentados son:
- `SUPABASE_URL`
- `SUPABASE_PUBLISHABLE_KEY`

Ejemplo (reemplazar por los valores públicos del proyecto, sin pegar secretos en documentación):

```powershell
flutter run -d chrome --dart-define=SUPABASE_URL="https://<project-ref>.supabase.co" --dart-define=SUPABASE_PUBLISHABLE_KEY="<publishable-key>"
```

Para Android:

```powershell
flutter run --dart-define=SUPABASE_URL="https://<project-ref>.supabase.co" --dart-define=SUPABASE_PUBLISHABLE_KEY="<publishable-key>"
```

Confirmar los nombres exactos de defines en el `main.dart` de cada aplicación al recuperar o revisar la copia fuente. Nunca registrar claves privadas o `service_role`.

## Ejecutar el panel administrador en Chrome

```powershell
cd pollosarica_admin
flutter pub get
flutter run -d chrome
```

Si la app requiere defines de Supabase, agregar los mismos parámetros `--dart-define` indicados arriba.

## Generar APK de cliente

Desde `pollosarica/`:

```powershell
flutter build apk --release --dart-define=SUPABASE_URL="https://<project-ref>.supabase.co" --dart-define=SUPABASE_PUBLISHABLE_KEY="<publishable-key>"
```

Salida habitual:
`build/app/outputs/flutter-apk/app-release.apk`

## Compilar el panel web

Desde `pollosarica_admin/`:

```powershell
flutter build web --release
```

Publicar el contenido de `build/web/` en el hosting web elegido, configurando las variables necesarias en el proceso de build.

## Solución de problemas
- **Dependencias cambiaron:** revisar el diff de `pubspec.lock` antes de confirmar cambios.
- **Analyze muestra info/warnings:** distinguirlos de errores; registrar la versión de Flutter y no hacer migraciones masivas sin revisar.
- **Chrome no aparece:** verificar `flutter devices` y que Chrome esté instalado.
- **No conecta a Supabase:** verificar URL y publishable/anon key, conectividad y políticas RLS.
- **Auth no funciona:** revisar proveedores habilitados, redirect URLs y configuración de la plataforma.
- **No se debe copiar** una clave `service_role` a la app Flutter ni al navegador.
