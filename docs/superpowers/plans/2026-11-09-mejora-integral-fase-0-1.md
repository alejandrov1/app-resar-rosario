# Mejora integral — Fases 0 y 1: Base segura y actualización

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Dejar el repositorio limpio en la rama `mejora-integral` (sin perder nada), solo con Android e iOS, y con Flutter 3.47.9, dependencias y Gradle al día y todas las pruebas en verde.

**Architecture:** No cambia la arquitectura de la app. Se toma un proyecto de referencia generado con `flutter create` (Flutter 3.47.9) como fuente de verdad para Gradle y se adaptan las 4 llamadas a la API nueva de notificaciones (parámetros con nombre).

**Tech Stack:** Flutter 3.47.9 / Dart 3.13.7, Gradle (Kotlin DSL), flutter_local_notifications 22.3.3, flutter_launcher_icons 0.14.4.

**Spec:** `docs/superpowers/specs/2026-11-09-mejora-integral-design.md` · **Índice del plan:** `docs/superpowers/plans/2026-11-09-mejora-integral.md`

## Global Constraints

- Rama de trabajo: `mejora-integral`. Cada commit termina con la línea `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Nada de `git push` sin autorización explícita del usuario.
- Plataformas: solo `android/` e `ios/`.
- SDK: Flutter **3.47.9**, Dart **3.13.7**; `environment: sdk: ^3.13.0`.
- Dependencias fijadas: `flutter_local_notifications: ^22.3.3`, `flutter_timezone: ^5.1.1`, `timezone: ^0.11.2`, `shared_preferences: ^2.5.6`, `provider: ^6.1.5+1`, `package_info_plus: ^10.2.2`; dev: `flutter_lints: ^6.0.0`, `flutter_launcher_icons: ^0.14.4`. `permission_handler: ^13.0.2` solo hasta la Tarea 14. Prohibido agregar `intl`, `cupertino_icons`, `google_fonts`, Riverpod, BLoC o go_router.
- Android: `minSdk` ≥ 24, `compileSdk` ≥ 36, desugaring con `com.android.tools:desugar_jdk_libs:2.1.4`.
- Secretos fuera del repo (`android/key.properties`, `*.jks`, `*.keystore`).
- Red corporativa: si `git` falla con "SSL certificate problem", usar `-c http.sslBackend=schannel` en ese comando (no cambiar la configuración global sin permiso del usuario).

---

## Fase 0 — Base segura

### Task 1: Rama de trabajo, `.gitignore` e instantánea del estado actual

**Files:**
- Modify: `.gitignore` (agregar al final)
- Untrack: `android/app/build/` (637 archivos generados que hoy están en git; se quedan en disco)
- Restore: `lib/services/notification_service.dart` (a la versión del commit `585cebe`)

**Interfaces:**
- Consumes: —
- Produces: rama `mejora-integral` con dos commits: la instantánea y la restauración del servicio. Nada pendiente en `git status`.

- [ ] **Step 1: Confirmar el punto de partida**

Run: `git status -sb | head -5`
Expected: primera línea `## main...origin/main [ahead 3]` y archivos modificados (`AndroidManifest.xml`, `pubspec.yaml`, `lib/services/notification_service.dart`, …).

- [ ] **Step 2: Crear la rama**

Run: `git switch -c mejora-integral`
Expected: `Switched to a new branch 'mejora-integral'`

- [ ] **Step 3: Agregar reglas al final de `.gitignore`**

Agregar exactamente este bloque al final del archivo:

```gitignore

# Compilación de Android (se genera sola)
/android/app/build/
/android/build/
/android/app/.cxx/

# Salidas locales de herramientas
/graphify-out/
/.github/modernize/
/.vscode/

# Firma de release: nunca al repositorio
/android/key.properties
*.jks
*.keystore
```

- [ ] **Step 4: Sacar de git la carpeta de compilación (sin borrarla del disco)**

Run: `git rm -r --cached --quiet android/app/build && git status --short | grep -c "^D  android/app/build/"`
Expected: `637`

- [ ] **Step 5: Revisar y guardar la instantánea de todo lo pendiente**

Run: `git add -A && git status --short | grep -v "^D  android/app/build/"`
Expected: aparecen `.gitignore`, `docs/superpowers/...`, `flutter_launcher_icons.yaml`, `flutter_launcher_icons safe.yaml`, `lib/generate_icons.dart`, los íconos regenerados y los archivos modificados. **No** deben aparecer `graphify-out/`, `.vscode/`, `.github/modernize/` ni `android/build/`. Si aparece alguno, revisar el Step 3.

```bash
git commit -m "chore: instantánea del estado previo a la mejora integral" -m "Incluye íconos regenerados, ajustes de Gradle y manifest pendientes, el spec y el plan. Saca android/app/build del control de versiones." -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

- [ ] **Step 6: Restaurar el servicio de notificaciones que funcionaba**

La versión sin commit trataba "Notificación y Alarma" como notificación simple, usaba IDs con más colisiones y quitó el manejo de errores (spec §3.1 E5).

Run: `git checkout 585cebe -- lib/services/notification_service.dart && grep -n "ReminderType.both\|% 100000" lib/services/notification_service.dart`
Expected: dos coincidencias: `final isAlarm = type == ReminderType.alarm || type == ReminderType.both;` y `return (reminderId % 100000) * 10 + dayOfWeek;`

```bash
git commit -m "fix: restaurar el servicio de notificaciones previo" -m "La versión sin commit tenía regresiones: el tipo 'ambos' no sonaba como alarma, IDs con más colisiones y sin manejo de errores al guardar." -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

- [ ] **Step 7: Verificar árbol limpio**

Run: `git status --short`
Expected: sin salida.

---

### Task 2: Quitar plataformas sin uso y la configuración de íconos duplicada

**Files:**
- Delete: `web/`, `windows/`, `macos/`, `linux/`, `flutter_launcher_icons safe.yaml`

**Interfaces:**
- Consumes: rama `mejora-integral` limpia (Task 1).
- Produces: el proyecto solo contiene `android/` e `ios/` como plataformas.

- [ ] **Step 1: Borrar las carpetas y el archivo duplicado**

Run: `git rm -r --quiet web windows macos linux "flutter_launcher_icons safe.yaml" && ls -d */`
Expected: la lista de carpetas incluye `android/`, `assets/`, `docs/`, `ios/`, `lib/`, `test/` y **no** incluye `web/`, `windows/`, `macos/` ni `linux/`.

- [ ] **Step 2: Comprobar que el proyecto sigue resolviendo dependencias**

Run: `flutter pub get`
Expected: termina con `Got dependencies!` (o `Changed N dependencies!`) sin errores.

- [ ] **Step 3: Commit**

```bash
git commit -m "chore: quitar web, Windows, macOS y Linux" -m "La app se publica solo en Android e iOS y los recordatorios no funcionan en las otras plataformas." -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

**Cierre de la Fase 0:** `git status --short` vacío, `git log --oneline -3` muestra los tres commits de esta fase.

---

## Fase 1 — Actualización

### Task 3: Actualizar el SDK de Flutter a 3.47.9

**Files:** ninguno del repositorio (cambia el SDK instalado en la máquina; el usuario ya lo aprobó).

**Interfaces:**
- Consumes: —
- Produces: `flutter` 3.47.9 y `dart` 3.13.7 disponibles en el PATH; `dart mcp-server` disponible (lo usa el plugin Dart and Flutter).

- [ ] **Step 1: Ver la versión actual**

Run: `flutter --version`
Expected: `Flutter 3.32.5 • channel stable`

- [ ] **Step 2: Actualizar**

Run: `git config --global --get http.sslBackend`
- Si imprime `schannel`: Run `flutter upgrade`
- Si no imprime nada u otro valor (git no confía en el proxy corporativo), inyectar la opción solo para este comando:

Run: `GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=http.sslBackend GIT_CONFIG_VALUE_0=schannel flutter upgrade`

Expected: termina con `Flutter 3.47.9 • channel stable` (o un parche posterior de la 3.47).

- [ ] **Step 3: Fijar exactamente 3.47.9 si `upgrade` llevó a otra versión**

Solo si el Step 2 no dejó 3.47.9:

```bash
FLUTTER_ROOT="$(dirname "$(dirname "$(which flutter)")")"
git -C "$FLUTTER_ROOT" -c http.sslBackend=schannel fetch --tags
git -C "$FLUTTER_ROOT" checkout 3.47.9
flutter --version
```

Expected: `Flutter 3.47.9 • channel [user-branch]` y `Dart 3.13.7`.

- [ ] **Step 4: Revisar herramientas de Android**

Run: `flutter doctor -v`
Expected: `[✓] Android toolchain` y una línea `Java binary at:` con Java 17 o superior. Si pide licencias de Android, pedir al usuario que ejecute `flutter doctor --android-licenses` (es interactivo). Anotar la versión de Java que reporta: se usa en la Task 29.

- [ ] **Step 5: Confirmar que existe el servidor MCP de Dart**

Run: `dart mcp-server --help`
Expected: imprime el uso del comando (ya no dice `Could not find a command named "mcp-server"`).

---

### Task 4: Dependencias, Gradle e íconos alineados a Flutter 3.47

**Files:**
- Modify: `pubspec.yaml` (reemplazo completo)
- Modify: `flutter_launcher_icons.yaml` (reemplazo completo)
- Replace from reference: `android/settings.gradle.kts`, `android/build.gradle.kts`, `android/gradle.properties`, `android/gradle/wrapper/gradle-wrapper.properties`
- Modify: `android/app/build.gradle.kts` (reemplazo completo)
- Modify: `lib/services/notification_service.dart` (4 llamadas a la API v22)
- Regenerated: `pubspec.lock`, íconos en `android/app/src/main/res/mipmap-*` y `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

**Interfaces:**
- Consumes: Flutter 3.47.9 (Task 3).
- Produces: `flutter build apk --debug` funciona; las dependencias nuevas (`flutter_timezone`, `flutter_localizations`, `package_info_plus`) quedan disponibles para las fases siguientes.

- [ ] **Step 1: Generar el proyecto de referencia de Flutter 3.47.9**

Run: `flutter create --platforms=android,ios --org com.alejandrovaldez --project-name app_resar_rosario "$TEMP/santorosario-ref"`
Expected: `All done!`. Esta carpeta es la referencia para Gradle (aquí) y para iOS (Task 28). No borrarla hasta terminar la Fase 5; si se pierde, se regenera con el mismo comando.

- [ ] **Step 2: Copiar los archivos de Gradle de la plantilla**

```bash
REF="$TEMP/santorosario-ref/android"
cp "$REF/settings.gradle.kts" android/settings.gradle.kts
cp "$REF/build.gradle.kts" android/build.gradle.kts
cp "$REF/gradle.properties" android/gradle.properties
cp "$REF/gradle/wrapper/gradle-wrapper.properties" android/gradle/wrapper/gradle-wrapper.properties
grep -n "com.android.application\|kotlin" android/settings.gradle.kts
grep -n "distributionUrl" android/gradle/wrapper/gradle-wrapper.properties
```

Expected: versiones de AGP, Kotlin y Gradle de la plantilla (reemplazan las 8.10.1 / 9.7.1 que se pusieron a mano). `android/build.gradle.kts` ya no tiene bloque `buildscript`; `gradle.properties` ya no tiene `android.enableJetifier=true`.

- [ ] **Step 3: Escribir `android/app/build.gradle.kts`**

Partir de `$TEMP/santorosario-ref/android/app/build.gradle.kts`. El resultado esperado es este archivo; si la plantilla difiere en forma (por ejemplo, sin `kotlinOptions` porque usa Kotlin integrado, u otra versión de Java), **se conserva la forma de la plantilla** y solo se aplican estos cambios: (1) `namespace` y `applicationId` siguen siendo `com.example.app_resar_rosario` hasta la Fase 5; (2) `isCoreLibraryDesugaringEnabled = true`; (3) `compileSdk` mínimo 36 y `minSdk` mínimo 24; (4) release con `isMinifyEnabled` e `isShrinkResources`; (5) dependencia de desugaring.

```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    // El plugin de Flutter debe ir después de los de Android y Kotlin.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.app_resar_rosario"
    // flutter_local_notifications 22 exige compileSdk 36 o más.
    compileSdk = maxOf(flutter.compileSdkVersion, 36)
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Necesario para las notificaciones programadas.
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.app_resar_rosario"
        // flutter_local_notifications 21+ exige Android 7.0 (API 24).
        minSdk = maxOf(flutter.minSdkVersion, 24)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Firma provisional con la clave de depuración; la firma real llega en la Fase 5.
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = true
            isShrinkResources = true
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
```

- [ ] **Step 4: Reemplazar `pubspec.yaml`**

```yaml
name: app_resar_rosario
description: "Una aplicación para rezar el Santo Rosario."
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: ^3.13.0

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  flutter_local_notifications: ^22.3.3
  flutter_timezone: ^5.1.1
  package_info_plus: ^10.2.2
  # Se elimina en la Tarea 14, cuando el servicio de notificaciones deje de usarlo.
  permission_handler: ^13.0.2
  provider: ^6.1.5+1
  shared_preferences: ^2.5.6
  timezone: ^0.11.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_launcher_icons: ^0.14.4
  flutter_lints: ^6.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/images/
    - assets/icons/
```

- [ ] **Step 5: Reemplazar `flutter_launcher_icons.yaml` (única configuración de íconos)**

```yaml
flutter_launcher_icons:
  image_path: "assets/icons/icono-rosario.png"

  android: "launcher_icon"
  min_sdk_android: 24
  adaptive_icon_background: "#FFFFFF"
  adaptive_icon_foreground: "assets/icons/icono-rosario.png"

  ios: true
  remove_alpha_ios: true
```

- [ ] **Step 6: Adaptar `lib/services/notification_service.dart` a la API v22 (parámetros con nombre)**

Reemplazar cada fragmento exactamente:

```dart
// ANTES
      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
// DESPUÉS
      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
```

```dart
// ANTES
      await _notificationsPlugin.zonedSchedule(
        notificationId,
        reminder.title,
        reminder.description,
        scheduledDate,
        _getNotificationDetails(reminder.type),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: 'reminder_${reminder.id}',
      );
// DESPUÉS
      await _notificationsPlugin.zonedSchedule(
        id: notificationId,
        title: reminder.title,
        body: reminder.description,
        scheduledDate: scheduledDate,
        notificationDetails: _getNotificationDetails(reminder.type),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: 'reminder_${reminder.id}',
      );
```

```dart
// ANTES
      await _notificationsPlugin.cancel(notificationId);
// DESPUÉS
      await _notificationsPlugin.cancel(id: notificationId);
```

```dart
// ANTES
      await _notificationsPlugin.show(
        999999,
        '¡Prueba de Notificación del Rosario!',
        'Si ves y escuchas esto, las notificaciones funcionan correctamente.',
        _getNotificationDetails(ReminderType.alarm),
        payload: 'test_notification',
      );
// DESPUÉS
      await _notificationsPlugin.show(
        id: 999999,
        title: '¡Prueba de Notificación del Rosario!',
        body: 'Si ves y escuchas esto, las notificaciones funcionan correctamente.',
        notificationDetails: _getNotificationDetails(ReminderType.alarm),
        payload: 'test_notification',
      );
```

- [ ] **Step 7: Resolver dependencias y regenerar íconos**

Run: `flutter pub get && dart run flutter_launcher_icons`
Expected: `Got dependencies!` y `✓ Successfully generated launcher icons`. Debe existir `android/app/src/main/res/mipmap-hdpi/launcher_icon.png`.

- [ ] **Step 8: Analizar**

Run: `flutter analyze`
Expected: **0 errores y 0 advertencias**, salvo los 2 errores conocidos de `test/utils/responsive_utils_test.dart` (parámetro `orientation`), que se corrigen en la Task 5. Los avisos `info` se permiten hasta la Fase 6. Si aparecen otros errores o advertencias por APIs retiradas en Flutter 3.47, corregirlos con estos reemplazos: `x.withOpacity(a)` → `x.withValues(alpha: a)`; `Switch(activeColor: c)` → `Switch(activeThumbColor: c)`; cualquier otra advertencia nueva de `flutter_lints` 6 se corrige según el mensaje del analizador (son cambios mecánicos de una línea). No se cambia comportamiento.

- [ ] **Step 9: Compilar Android**

Run: `flutter build apk --debug`
Expected: `✓ Built build/app/outputs/flutter-apk/app-debug.apk`.
Si Gradle falla con `PKIX path building failed` (proxy corporativo), agregar a `%USERPROFILE%\.gradle\gradle.properties` (fuera del repo) la línea `systemProp.javax.net.ssl.trustStoreType=Windows-ROOT` y repetir.

- [ ] **Step 10: Commit**

```bash
git add pubspec.yaml pubspec.lock flutter_launcher_icons.yaml android lib/services/notification_service.dart ios/Runner/Assets.xcassets
git commit -m "build: actualizar a Flutter 3.47.9, dependencias y Gradle" -m "Gradle, AGP y Kotlin tomados de la plantilla de Flutter 3.47.9. flutter_local_notifications 22.3.3 con parámetros con nombre. Sin intl ni cupertino_icons (no se usaban). Una sola configuración de íconos." -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5: Reparar las pruebas rotas y cerrar la Fase 1

**Files:**
- Modify: `lib/widgets/rosary_beads_widget.dart` (agregar `key` a cada cuenta)
- Rewrite: `test/widgets/rosary_beads_widget_test.dart`
- Modify: `test/utils/responsive_utils_test.dart` (quitar el parámetro `orientation`, que ya no existe)
- Rewrite: `test/widget_test.dart` (la prueba del contador era de la plantilla)

**Interfaces:**
- Consumes: app compilando con Flutter 3.47.9 (Task 4).
- Produces: cada cuenta del rosario tiene la clave `ValueKey('cuenta-$i')` (la usan pruebas posteriores). `flutter test` en verde.

- [ ] **Step 1: Escribir la prueba nueva de las cuentas**

`test/widgets/rosary_beads_widget_test.dart`:

```dart
import 'package:app_resar_rosario/widgets/rosary_beads_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> mostrar(WidgetTester tester, {required int actual}) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: RosaryBeadsWidget(current: actual, total: 10)),
      ),
    );
  }

  testWidgets('muestra una cuenta por cada Ave María', (tester) async {
    await mostrar(tester, actual: 3);
    for (var i = 0; i < 10; i++) {
      expect(find.byKey(ValueKey('cuenta-$i')), findsOneWidget);
    }
  });

  testWidgets('las cuentas hasta la actual se ven distintas a las pendientes', (tester) async {
    await mostrar(tester, actual: 3);
    BoxDecoration decoracion(int i) =>
        tester.widget<Container>(find.byKey(ValueKey('cuenta-$i'))).decoration! as BoxDecoration;
    expect(decoracion(3).color, equals(decoracion(0).color));
    expect(decoracion(3).color, isNot(equals(decoracion(4).color)));
  });
}
```

- [ ] **Step 2: Correr la prueba y ver que falla**

Run: `flutter test test/widgets/rosary_beads_widget_test.dart`
Expected: FAIL — `Expected: exactly one matching candidate` para `cuenta-0` (las cuentas aún no tienen clave).

- [ ] **Step 3: Agregar la clave a cada cuenta**

En `lib/widgets/rosary_beads_widget.dart`, dentro de `List.generate(total, (index) {`, el `Container` que se devuelve recibe la clave:

```dart
            return Container(
              key: ValueKey('cuenta-$index'),
              width: 12,
              height: 12,
```

- [ ] **Step 4: Correr la prueba y ver que pasa**

Run: `flutter test test/widgets/rosary_beads_widget_test.dart`
Expected: `All tests passed!`

- [ ] **Step 5: Quitar `orientation` de `test/utils/responsive_utils_test.dart`**

`MediaQueryData` calcula la orientación a partir de `size`. Borrar las dos líneas `orientation: Orientation.portrait,` y `orientation: Orientation.landscape,`. Los tamaños `Size(400, 800)` (vertical) y `Size(800, 400)` (horizontal) se quedan igual.

Run: `flutter test test/utils/responsive_utils_test.dart`
Expected: `All tests passed!`

- [ ] **Step 6: Reemplazar la prueba de la plantilla por una prueba de arranque real**

`test/widget_test.dart`:

```dart
import 'package:app_resar_rosario/main.dart';
import 'package:app_resar_rosario/services/notification_service.dart';
import 'package:app_resar_rosario/services/preferences_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('la app arranca en la pantalla de inicio', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => PreferencesService()),
          ChangeNotifierProvider(create: (_) => NotificationService()),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Santo Rosario'), findsWidgets);
    expect(find.text('Comenzar a Rezar'), findsOneWidget);
  });
}
```

- [ ] **Step 7: Correr todas las pruebas**

Run: `flutter test`
Expected: `All tests passed!` (las 3 que fallaban ahora pasan).

- [ ] **Step 8: Cierre de fase**

Run: `flutter analyze && flutter build apk --debug`
Expected: 0 errores y 0 advertencias; `✓ Built build/app/outputs/flutter-apk/app-debug.apk`.

```bash
git add lib/widgets/rosary_beads_widget.dart test
git commit -m "test: reparar las pruebas rotas" -m "Prueba de arranque real en lugar de la del contador, cuentas del rosario con clave y sin el parámetro orientation retirado de MediaQueryData." -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
graphify update .
```

Expected de `graphify update .`: termina sin error y actualiza `graphify-out/graph.json` (ignorado por git).

**Cierre de la Fase 1:** Flutter 3.47.9, `flutter analyze` sin errores ni advertencias, `flutter test` en verde, APK de depuración compila.
