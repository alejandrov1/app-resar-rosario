# Mejora integral — Fase 5: Preparación para Play Store y App Store

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Paquete propio `com.alejandrovaldez.santorosario`, firma de release, manifest que cumpla las políticas de Google, iOS configurado (E8) y compilación automática de Android e iOS en GitHub Actions, más la documentación para publicar.

**Architecture:** El proyecto de referencia de Flutter 3.47.9 (`$TEMP/santorosario-ref`, Task 4) es la fuente de verdad para la carpeta `ios/` y para los atributos estándar del manifest. Pruebas de "plataforma" leen los archivos de configuración como texto y fallan si vuelve un permiso prohibido o se pierde el paquete.

**Tech Stack:** Gradle Kotlin DSL, Xcode project (vía plantilla), GitHub Actions (`actions/checkout@v7`, `actions/setup-java@v6`, `actions/upload-artifact@v7`, `subosito/flutter-action@v2`).

**Spec:** `docs/superpowers/specs/2026-11-09-mejora-integral-design.md` (§4.5, §10) · **Índice:** `docs/superpowers/plans/2026-11-09-mejora-integral.md`

## Global Constraints

- Rama `mejora-integral`; cada commit termina con `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. **`git push` solo con autorización explícita del usuario** (el repo `alejandrov1/app-resar-rosario` es público).
- Paquete Android e iOS: `com.alejandrovaldez.santorosario`. Nombre visible: "Santo Rosario".
- Keystore, contraseñas y certificados **nunca** en el repo: `android/key.properties`, `*.jks`, `*.keystore` ya están en `.gitignore`; en CI van solo como GitHub Secrets.
- Permisos de Android permitidos: `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`, `SCHEDULE_EXACT_ALARM`, `USE_FULL_SCREEN_INTENT`, `VIBRATE`, `WAKE_LOCK`. Ningún otro.
- Cierre de cada tarea: `flutter analyze` sin errores ni advertencias y `flutter test` en verde.

---

### Task 26: Paquete propio y manifest limpio

**Files:**
- Modify: `android/app/build.gradle.kts` (`namespace` y `applicationId`)
- Move: `android/app/src/main/kotlin/com/example/app_resar_rosario/MainActivity.kt` → `android/app/src/main/kotlin/com/alejandrovaldez/santorosario/MainActivity.kt`
- Rewrite: `android/app/src/main/AndroidManifest.xml`
- Create: `test/plataforma/android_config_test.dart`

**Interfaces:**
- Consumes: Gradle de la Task 4; recursos `ic_notification`, `keep.xml` (Task 14).
- Produces: app Android con id `com.alejandrovaldez.santorosario`; receivers del plugin con `exported="false"`.

- [ ] **Step 1: Escribir la prueba de configuración**

`test/plataforma/android_config_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
  final gradle = File('android/app/build.gradle.kts').readAsStringSync();

  test('paquete propio', () {
    expect(gradle, contains('namespace = "com.alejandrovaldez.santorosario"'));
    expect(gradle, contains('applicationId = "com.alejandrovaldez.santorosario"'));
    expect(File('android/app/src/main/kotlin/com/alejandrovaldez/santorosario/MainActivity.kt').existsSync(), isTrue);
  });

  test('solo los permisos necesarios', () {
    final permisos = RegExp(r'uses-permission android:name="android\.permission\.([A-Z_]+)"')
        .allMatches(manifest)
        .map((m) => m.group(1))
        .toSet();
    expect(permisos, {
      'POST_NOTIFICATIONS',
      'RECEIVE_BOOT_COMPLETED',
      'SCHEDULE_EXACT_ALARM',
      'USE_FULL_SCREEN_INTENT',
      'VIBRATE',
      'WAKE_LOCK',
    });
  });

  test('sin configuraciones que las tiendas rechazan', () {
    for (final prohibido in [
      'usesCleartextTraffic',
      'requestLegacyExternalStorage',
      'com.google.android.gms.ads',
      'FLUTTER_NOTIFICATION_CLICK',
    ]) {
      expect(manifest, isNot(contains(prohibido)), reason: prohibido);
    }
  });

  test('los receivers del plugin no se exponen a otras apps', () {
    final receivers = RegExp(r'<receiver[^>]*>').allMatches(manifest).map((m) => m.group(0)!).toList();
    expect(receivers, hasLength(2));
    expect(receivers.every((r) => r.contains('android:exported="false"')), isTrue);
  });
}
```

- [ ] **Step 2: Correr y ver que falla**

Run: `flutter test test/plataforma/android_config_test.dart`
Expected: FAIL — falta el paquete propio, sobran permisos y los receivers tienen `exported="true"`.

- [ ] **Step 3: Cambiar el paquete**

En `android/app/build.gradle.kts`:

```kotlin
// ANTES
    namespace = "com.example.app_resar_rosario"
// DESPUÉS
    namespace = "com.alejandrovaldez.santorosario"
```

```kotlin
// ANTES
        applicationId = "com.example.app_resar_rosario"
// DESPUÉS
        applicationId = "com.alejandrovaldez.santorosario"
```

Mover la actividad:

```bash
mkdir -p android/app/src/main/kotlin/com/alejandrovaldez/santorosario
git mv android/app/src/main/kotlin/com/example/app_resar_rosario/MainActivity.kt android/app/src/main/kotlin/com/alejandrovaldez/santorosario/MainActivity.kt
```

Y dejar su contenido así:

```kotlin
package com.alejandrovaldez.santorosario

import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity()
```

- [ ] **Step 4: Reescribir el manifest**

`android/app/src/main/AndroidManifest.xml` (comparar con `$TEMP/santorosario-ref/android/app/src/main/AndroidManifest.xml`: si la plantilla trae atributos estándar adicionales en `<activity>` o `<queries>`, se conservan):

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <!-- Solo lo que necesitan los recordatorios. -->
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
    <uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT" />
    <uses-permission android:name="android.permission.VIBRATE" />
    <uses-permission android:name="android.permission.WAKE_LOCK" />

    <application
        android:label="Santo Rosario"
        android:name="${applicationName}"
        android:icon="@mipmap/launcher_icon"
        android:roundIcon="@mipmap/launcher_icon"
        android:enableOnBackInvokedCallback="true">

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:taskAffinity=""
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize"
            android:showWhenLocked="true"
            android:turnScreenOn="true">
            <meta-data
                android:name="io.flutter.embedding.android.NormalTheme"
                android:resource="@style/NormalTheme" />
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>

        <!-- Receivers de flutter_local_notifications: programan y restauran los avisos tras reiniciar. -->
        <receiver
            android:exported="false"
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
        <receiver
            android:exported="false"
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED" />
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED" />
                <action android:name="android.intent.action.QUICKBOOT_POWERON" />
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON" />
            </intent-filter>
        </receiver>

        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>

    <!-- Requerido por el motor de Flutter para el menú "procesar texto". -->
    <queries>
        <intent>
            <action android:name="android.intent.action.PROCESS_TEXT" />
            <data android:mimeType="text/plain" />
        </intent>
    </queries>
</manifest>
```

- [ ] **Step 5: Correr y ver que pasa; comprobar el paquete del APK**

Run: `flutter test && flutter build apk --debug`
Expected: `All tests passed!`; APK compila.

Run:

```bash
SDK="${ANDROID_HOME:-$LOCALAPPDATA/Android/Sdk}"
AAPT2="$(ls -d "$SDK"/build-tools/*/ | tail -1)aapt2"
"$AAPT2" dump packagename build/app/outputs/flutter-apk/app-debug.apk
```

Expected: `com.alejandrovaldez.santorosario`

Run: `"$AAPT2" dump badging build/app/outputs/flutter-apk/app-debug.apk | grep -o "targetSdkVersion:'[0-9]*'"`
Comparar con el nivel exigido para apps nuevas en https://developer.android.com/google/play/requirements/target-sdk (spec §4.5). Si el del APK es menor, fijar `targetSdk = <nivel exigido>` en `android/app/build.gradle.kts` (en lugar de `flutter.targetSdkVersion`), volver a compilar y repetir la comprobación.

- [ ] **Step 6: Commit**

Run: `flutter analyze` → sin errores ni advertencias.

```bash
git add android test/plataforma
git commit -m "build: paquete com.alejandrovaldez.santorosario y manifest limpio" -m "Sin AdMob de prueba, sin permisos que Play rechaza, sin tráfico sin cifrar y con los receivers no exportados." -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 27: Firma de release y compilación optimizada

**Files:**
- Modify: `android/app/build.gradle.kts` (configuración de firma)
- Create (fuera de git): `android/key.properties`, keystore en `%USERPROFILE%\keys\santorosario-upload.jks`
- Modify: `test/plataforma/android_config_test.dart` (una prueba más)

**Interfaces:**
- Consumes: paquete de la Task 26.
- Produces: `flutter build appbundle --release` firmado con la clave de subida si existe `android/key.properties`; sin ese archivo (CI) se firma con la clave de depuración.

- [ ] **Step 1: Agregar la prueba**

Al final de `main()` en `test/plataforma/android_config_test.dart`:

```dart
  test('la firma de release se lee de key.properties, que no está en git', () {
    expect(gradle, contains('rootProject.file("key.properties")'));
    expect(gradle, contains('signingConfigs.getByName("release")'));
    expect(File('.gitignore').readAsStringSync(), contains('/android/key.properties'));
  });
```

Run: `flutter test test/plataforma/android_config_test.dart`
Expected: FAIL — `rootProject.file("key.properties")` no está en el Gradle.

- [ ] **Step 2: Configurar la firma en `android/app/build.gradle.kts`**

Agregar al inicio del archivo (antes de `plugins {`):

```kotlin
import java.io.FileInputStream
import java.util.Properties

// Clave de subida a Play. El archivo vive solo en la máquina del desarrollador (está en .gitignore).
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) load(FileInputStream(keystorePropertiesFile))
}
```

Dentro de `android { ... }`, antes de `buildTypes`, agregar:

```kotlin
    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }
```

Y en `buildTypes { release { ... } }`:

```kotlin
// ANTES
            signingConfig = signingConfigs.getByName("debug")
// DESPUÉS
            // Sin key.properties (por ejemplo en CI) se firma con la clave de depuración.
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
```

Run: `flutter test test/plataforma/android_config_test.dart && flutter build appbundle --release`
Expected: pruebas en verde; `✓ Built build/app/outputs/bundle/release/app-release.aab` (firmado con depuración porque aún no hay clave).

- [ ] **Step 3: El usuario crea la clave de subida (interactivo; pide contraseñas)**

Pedir al usuario que ejecute en PowerShell y guarde las contraseñas en su gestor de contraseñas:

```powershell
New-Item -ItemType Directory -Force "$env:USERPROFILE\keys" | Out-Null
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -genkey -v -keystore "$env:USERPROFILE\keys\santorosario-upload.jks" -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Si `keytool.exe` no está en esa ruta, usar el que reporta `flutter doctor -v` en "Java binary at" (misma carpeta). Recordarle que **haga una copia de seguridad del `.jks`**: si se pierde, no se puede actualizar la app en Play (salvo con el proceso de restablecimiento de clave de Play App Signing).

Luego crear `android/key.properties` (no se sube a git), con las contraseñas que eligió:

```properties
storePassword=<la contraseña del almacén que eligió el usuario>
keyPassword=<la contraseña de la clave que eligió el usuario>
keyAlias=upload
storeFile=C:\\Users\\Alejandro\\keys\\santorosario-upload.jks
```

Run: `git status --short android/key.properties`
Expected: sin salida (el archivo está ignorado).

- [ ] **Step 4: Compilar firmado y comprobar la firma**

Run: `flutter build appbundle --release`
Expected: `✓ Built build/app/outputs/bundle/release/app-release.aab`.

Run: `keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab | head -5` (con el `keytool` del Step 3)
Expected: el propietario del certificado es el que se dio al crear la clave (no `CN=Android Debug`).

- [ ] **Step 5: Probar la compilación de release en un teléfono**

Run: `flutter build apk --release && flutter install --release`
Expected: la app instalada abre. En "Agendar Rosario", crear un recordatorio para dentro de 2 minutos con la app cerrada: debe llegar con el ícono de la cruz (comprueba que R8 no borró `ic_notification` ni `alarm_sound`; si no llega o falta el ícono, revisar `android/app/src/main/res/raw/keep.xml`).

- [ ] **Step 6: Commit**

```bash
git add android/app/build.gradle.kts test/plataforma/android_config_test.dart
git commit -m "build: firma de release con clave de subida fuera del repositorio" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 28: iOS listo para compilar (E8)

**Files:**
- Replace: `ios/` completo por la plantilla de Flutter 3.47.9 (ciclo de vida UIScene)
- Modify: `ios/Runner.xcodeproj/project.pbxproj` (identificador), `ios/Runner/Info.plist` (nombre visible), `ios/Runner/AppDelegate.swift` (delegado de notificaciones)
- Regenerated: `ios/Runner/Assets.xcassets/AppIcon.appiconset/*`
- Create: `test/plataforma/ios_config_test.dart`

**Interfaces:**
- Consumes: proyecto de referencia (Task 4); `flutter_launcher_icons.yaml` (Task 4).
- Produces: `ios/` con `PRODUCT_BUNDLE_IDENTIFIER = com.alejandrovaldez.santorosario`, nombre "Santo Rosario" y notificaciones visibles con la app abierta. Se compila en la Task 29 (en Windows no se puede).

- [ ] **Step 1: Escribir la prueba de configuración**

`test/plataforma/ios_config_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('identificador propio en todos los destinos', () {
    final proyecto = File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
    final ids = RegExp(r'PRODUCT_BUNDLE_IDENTIFIER = ([^;]+);').allMatches(proyecto).map((m) => m.group(1)).toSet();
    expect(ids, {'com.alejandrovaldez.santorosario', 'com.alejandrovaldez.santorosario.RunnerTests'});
  });

  test('nombre visible "Santo Rosario"', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    expect(plist, matches(RegExp(r'<key>CFBundleDisplayName</key>\s*<string>Santo Rosario</string>')));
  });

  test('muestra notificaciones con la app abierta', () {
    final delegado = File('ios/Runner/AppDelegate.swift').readAsStringSync();
    expect(delegado, contains('UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate'));
  });
}
```

Run: `flutter test test/plataforma/ios_config_test.dart`
Expected: FAIL — el identificador es `com.example.appResarRosario` y falta el delegado.

- [ ] **Step 2: Reemplazar `ios/` por la plantilla actual**

```bash
REF="$TEMP/santorosario-ref"
[ -d "$REF/ios" ] || flutter create --platforms=android,ios --org com.alejandrovaldez --project-name app_resar_rosario "$REF"
git rm -r -q ios
cp -r "$REF/ios" ios
sed -i 's/com\.alejandrovaldez\.appResarRosario/com.alejandrovaldez.santorosario/g' ios/Runner.xcodeproj/project.pbxproj
grep -n "PRODUCT_BUNDLE_IDENTIFIER" ios/Runner.xcodeproj/project.pbxproj
grep -n -A1 "CFBundleDisplayName" ios/Runner/Info.plist
grep -n "IPHONEOS_DEPLOYMENT_TARGET" ios/Runner.xcodeproj/project.pbxproj | head -2
```

Expected: identificadores `com.alejandrovaldez.santorosario` y `…santorosario.RunnerTests`; `CFBundleDisplayName` con el nombre de la plantilla ("App Resar Rosario"); `IPHONEOS_DEPLOYMENT_TARGET` igual o mayor a 13.0.

- [ ] **Step 3: Nombre visible y delegado de notificaciones**

En `ios/Runner/Info.plist`, reemplazar el valor de `CFBundleDisplayName`:

```xml
	<key>CFBundleDisplayName</key>
	<string>Santo Rosario</string>
```

En `ios/Runner/AppDelegate.swift`: agregar `import UserNotifications` debajo de `import UIKit` y, dentro de `application(_:didFinishLaunchingWithOptions:)`, justo antes de `return super.application(...)`, la línea del delegado. Con la plantilla UIScene de Flutter 3.47 el archivo queda así (si la plantilla difiere, se conserva la plantilla y solo se agregan el import y esa línea):

```swift
import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Permite mostrar los recordatorios aunque la app esté abierta.
    UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
```

- [ ] **Step 4: Regenerar los íconos de iOS y verificar**

Run: `dart run flutter_launcher_icons && flutter test`
Expected: `✓ Successfully generated launcher icons`; `All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add ios test/plataforma/ios_config_test.dart
git commit -m "build: iOS con la plantilla de Flutter 3.47 e identificador propio" -m "Ciclo de vida UIScene, nombre 'Santo Rosario' y delegado de notificaciones para mostrarlas con la app abierta (E8)." -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 29: Compilación automática en GitHub Actions (Android e iOS)

**Files:**
- Create: `.github/workflows/ci.yml`
- Create: `.github/workflows/ios.yml`

**Interfaces:**
- Consumes: app completa; versión de Java anotada en la Task 3 (17 si no se anotó otra).
- Produces: en cada push a `main` o `mejora-integral`: análisis, pruebas y `.aab` (artefacto `santorosario-android`); compilación de iOS sin firma en macOS.

- [ ] **Step 1: Workflow de Android**

`.github/workflows/ci.yml`:

```yaml
name: CI

on:
  push:
    branches: [main, mejora-integral]
  pull_request:
  workflow_dispatch:

jobs:
  android:
    name: Análisis, pruebas y Android
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
      - uses: actions/setup-java@v6
        with:
          distribution: temurin
          java-version: '17'
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.47.9'
          channel: stable
          cache: true
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test
      # Sin key.properties se firma con la clave de depuración: sirve para verificar, no para publicar.
      - run: flutter build appbundle --release
      - uses: actions/upload-artifact@v7
        with:
          name: santorosario-android
          path: build/app/outputs/bundle/release/app-release.aab
          retention-days: 14
```

- [ ] **Step 2: Workflow de iOS**

`.github/workflows/ios.yml`:

```yaml
name: iOS

on:
  push:
    branches: [main, mejora-integral]
  workflow_dispatch:

jobs:
  ios:
    name: Compilación iOS (sin firma)
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v7
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.47.9'
          channel: stable
          cache: true
      - run: flutter pub get
      - run: flutter build ios --release --no-codesign
```

- [ ] **Step 3: Commit**

```bash
git add .github/workflows
git commit -m "ci: compilar y probar Android e iOS en GitHub Actions" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

- [ ] **Step 4: Publicar la rama y ver los workflows (requiere autorización)**

**Pedir permiso al usuario** antes de este paso: publica la rama en el repositorio público.

Run: `git -c http.sslBackend=schannel push -u origin mejora-integral`
Run: `gh run list --branch mejora-integral --limit 2` y luego `gh run watch <id>` para cada uno.
Expected: `CI` y `iOS` terminan en `success`. Si `iOS` falla, revisar el log (`gh run view <id> --log-failed`) y corregir en `ios/` (lo más común: versión mínima de iOS que pide algún plugin → ajustar `IPHONEOS_DEPLOYMENT_TARGET` en el `project.pbxproj` al valor que indica el error).

---

### Task 30: Documentación para publicar y política de privacidad

**Files:**
- Rewrite: `README.md`
- Create: `docs/publicacion.md`
- Create: `docs/privacidad.md`

**Interfaces:**
- Consumes: todo lo anterior.
- Produces: guía de publicación paso a paso y una política de privacidad publicable (por ejemplo con GitHub Pages).

- [ ] **Step 1: `README.md`**

```markdown
# Santo Rosario

App para rezar el Santo Rosario de forma guiada, con los misterios del día, letanías, recordatorios
y opciones de accesibilidad (tamaño de texto, alto contraste, botones grandes y modo oscuro).

- **Plataformas:** Android 7.0+ e iOS 13+.
- **Paquete:** `com.alejandrovaldez.santorosario`.
- **Privacidad:** no recopila ni envía datos; todo se guarda en el teléfono ([política](docs/privacidad.md)).

## Desarrollo

Requiere Flutter 3.47.9.

    flutter pub get
    flutter run            # en un teléfono o emulador
    flutter analyze
    flutter test

## Estructura

- `lib/data/` — textos de las oraciones y misterios (cada uno escrito una vez).
- `lib/logic/` — recorrido del rosario (`RosarioSession`, 93 pasos).
- `lib/services/` — preferencias, recordatorios y zona horaria.
- `lib/theme/` — colores, medidas y temas (claro, oscuro y alto contraste).
- `lib/screens/` y `lib/widgets/` — interfaz.

## Publicación

Ver [docs/publicacion.md](docs/publicacion.md).
```

- [ ] **Step 2: `docs/privacidad.md`**

```markdown
# Política de privacidad — Santo Rosario

Vigente desde el 9 de noviembre de 2026.

**Santo Rosario no recopila, no envía y no comparte datos personales.**

- **Qué guarda la app:** tus preferencias (tamaño de texto, contraste, botones, tema) y los recordatorios
  que crees (título, hora, días y tipo). Todo se guarda **solo en tu teléfono** y se borra al desinstalar la app.
- **Internet:** la app no se conecta a internet.
- **Permisos:** las notificaciones y las alarmas se usan únicamente para avisarte a la hora de rezar que tú elegiste.
- **Publicidad y análisis:** la app no tiene anuncios ni herramientas de análisis o rastreo.
- **Menores:** la app es apta para todo público y no pide datos a nadie.

Si tienes dudas, abre un reporte en https://github.com/alejandrov1/app-resar-rosario/issues
```

- [ ] **Step 3: `docs/publicacion.md`**

```markdown
# Publicación de Santo Rosario

## Antes de empezar (lo hace el dueño de la app)

- [ ] Cuenta de Google Play Console (pago único).
- [ ] Cuenta del Apple Developer Program (pago anual).
- [ ] Clave de subida de Android creada y respaldada (Task 27 del plan). Sin ella no se puede actualizar la app.
- [ ] Política de privacidad publicada en una URL: activar GitHub Pages del repositorio y usar la página de `docs/privacidad.md`.

## Google Play

1. Compilar: `flutter build appbundle --release` (con `android/key.properties` presente).
2. Play Console → Crear app → nombre "Santo Rosario", idioma Español (México), app gratuita.
3. Activar **Play App Signing** y subir el `.aab` de `build/app/outputs/bundle/release/`.
4. Ficha de Play Store:
   - Ícono 512 × 512: `android/app/src/main/ic_launcher-playstore.png`.
   - Gráfico de funciones 1024 × 500 y al menos 2 capturas de teléfono (tomarlas en claro y oscuro).
   - Descripción corta y completa.
5. Contenido de la app:
   - Política de privacidad: la URL publicada.
   - Seguridad de los datos: "La app no recopila ni comparte datos".
   - Clasificación de contenido: cuestionario (sin contenido sensible).
   - Público objetivo: todas las edades.
   - Declaración de **intent de pantalla completa** (`USE_FULL_SCREEN_INTENT`): la usa la opción "Alarma" para que el recordatorio aparezca con el teléfono bloqueado.
6. Las cuentas personales nuevas deben hacer una **prueba cerrada** antes de producción (Play exige un número mínimo de testers durante un periodo; Play Console indica los requisitos vigentes de la cuenta).
7. Prueba interna → prueba cerrada → producción.

## App Store

1. App Store Connect → Apps → Nueva app con el identificador `com.alejandrovaldez.santorosario`.
2. Certificado "Apple Distribution", perfil de aprovisionamiento "App Store" y una clave de API de App Store Connect.
3. Guardar en GitHub (Settings → Secrets and variables → Actions) el certificado `.p12` en base64, su contraseña,
   el perfil en base64 y la clave de API. Después ampliar `.github/workflows/ios.yml` para firmar con
   `flutter build ipa --export-options-plist` y subir a TestFlight.
4. Privacidad de la app: "Datos no recopilados".
5. Capturas de iPhone (6.9" y 6.5"), descripción y palabras clave.
6. Probar en TestFlight: que el recordatorio llegue con la app cerrada y también con la app abierta.
7. Enviar a revisión.
```

- [ ] **Step 4: Commit y cierre de fase**

Run: `flutter analyze && flutter test`
Expected: sin errores ni advertencias; `All tests passed!`

```bash
git add README.md docs/publicacion.md docs/privacidad.md
git commit -m "docs: README, guía de publicación y política de privacidad" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
graphify update .
```

**Cierre de la Fase 5:** `.aab` firmado localmente; workflows `CI` e `iOS` en verde; documentación lista.
