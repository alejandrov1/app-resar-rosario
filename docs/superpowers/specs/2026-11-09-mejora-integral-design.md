# Mejora integral de "Santo Rosario" — Documento de diseño

- **Fecha:** 2026-11-09
- **Estado:** Aprobado en conversación (enfoque A por fases). Pendiente de revisión escrita.
- **Rama de trabajo:** `mejora-integral`
- **Siguiente paso:** plan de implementación en `docs/superpowers/plans/2026-11-09-mejora-integral.md`

---

## 1. Objetivo

Dejar la app lista para publicarse en **Google Play y App Store**: sin errores funcionales, sin código duplicado ni muerto, con un sistema de diseño coherente (modo oscuro y accesibilidad reales), dependencias al día y pruebas automáticas que permitan seguir evolucionándola con confianza.

## 2. Decisiones tomadas

| Tema | Decisión |
|---|---|
| Enfoque | **A — por fases sobre el código actual.** Cada fase termina compilando, con `flutter analyze` sin errores y pruebas en verde. Se conserva `provider` (no se migra a Riverpod/BLoC). |
| SDK | Actualizar Flutter **3.32.5 → 3.47.9** (Dart 3.8.1 → 3.13.7). Aplica a toda la máquina. |
| Plataformas | **Android + iOS.** Se eliminan `web/`, `windows/`, `macos/`, `linux/`. |
| Diseño | **Pulir el estilo actual**: color por sección (azul / morado / verde) unificado en un sistema de diseño, modo oscuro y accesibilidad completos. |
| Destino | **Play Store y App Store.** |
| iOS | **Compilación en la nube con GitHub Actions** (runner macOS; el repo `alejandrov1/app-resar-rosario` es público, los minutos son gratuitos). |
| Paquete | **`com.alejandrovaldez.santorosario`** (Android `applicationId`/`namespace` e iOS `PRODUCT_BUNDLE_IDENTIFIER`). |
| Tipos de recordatorio | Se reducen de 3 a **2**: *Notificación* y *Alarma*. "Notificación y Alarma" era idéntico a "Alarma" en la versión que funcionaba; los recordatorios guardados con ese tipo se migran a *Alarma*. |
| Tipografía | Interfaz con la fuente del sistema; **texto de las oraciones en serif empaquetada (Lora, licencia OFL)** para lectura pausada. Sin descargas en tiempo de ejecución. |

## 3. Diagnóstico (estado al 2026-11-09)

Análisis hecho con Graphify (786 nodos, 47 comunidades), lectura completa de `lib/` y `test/`, `flutter analyze`, `flutter test` y `flutter pub outdated`.

### 3.1 Errores funcionales

| # | Problema | Dónde | Efecto para el usuario |
|---|---|---|---|
| E1 | `tz.setLocalLocation(tz.local)` no detecta la zona del teléfono; `tz.local` vale UTC | `lib/services/notification_service.dart:40` | Recordatorios a hora equivocada (MST: uno de 7:00 suena a las 0:00) |
| E2 | Dos `Scaffold` anidados con `drawer`; el de inicio tapa al de Configuración | `lib/main.dart:130`, `lib/screens/inicio_screen.dart:81` | Configuración casi inaccesible |
| E3 | `PreferencesService` no persiste nada | `lib/services/preferences_service.dart` | Tamaño de letra, tema y contraste se pierden al cerrar |
| E4 | Escalado de texto doble: el tema multiplica por el factor y además `MediaQuery.textScaler` | `lib/constants/app_theme.dart`, `lib/main.dart:113`, todas las pantallas | Al 150 % el texto sale al 225 % |
| E5 | Cambios sin commit en el servicio de notificaciones retroceden: tipo "ambos" tratado como notificación simple, IDs `int.parse('${id % 10000}$dia')` con más colisiones, sin manejo de errores al guardar | `lib/services/notification_service.dart` (diff vs `HEAD`) | Alarmas que no suenan, recordatorios que se pisan |
| E6 | Ícono de notificación a color (`@mipmap/launcher_icon`) | `notification_service.dart:43,180,189` | En Android se ve como cuadro blanco |
| E7 | `alarm_sound.mp3` existe pero ningún canal lo usa | `android/app/src/main/res/raw/` | La "alarma" suena como notificación normal |
| E8 | iOS: falta asignar el delegado de `UNUserNotificationCenter`; los permisos se piden al arrancar | `ios/Runner/AppDelegate.swift`, `DarwinInitializationSettings` | Sin notificaciones con la app abierta; mala primera impresión |
| E9 | Sin `flutter_localizations` | `lib/main.dart` | Selector de hora y diálogos en inglés |
| E10 | Padding del teclado aplicado dos veces | `agendar_rosario_screen.dart:42` + `reminder_form.dart:92` | Hueco enorme al escribir |
| E11 | Modo oscuro sin efecto: fondos y textos blancos/grises fijos | todas las pantallas | Tema "Oscuro" no cambia casi nada |
| E12 | Oraciones iniciales y finales ignoran *botones grandes* y *alto contraste*; el alto contraste solo cambia un texto | `oraciones_*_screen.dart`, `misterios_screen.dart:216` | Accesibilidad incompleta |
| E13 | Errores de recordatorios silenciados (`debugPrint`), permisos sin explicación ni estado "denegado" | `agendar_rosario_screen.dart:29,50` | El usuario cree que su recordatorio quedó programado |

### 3.2 Duplicados

- Tres pantallas de oración casi idénticas (~600 renglones) con colores y medidas escritos a mano: `oraciones_iniciales_screen.dart`, `misterios_screen.dart`, `oraciones_finales_screen.dart`.
- Textos repetidos en `prayer_models.dart`: Padre Nuestro, Ave María y Gloria (2 veces cada uno), Señal de la Cruz (2 veces).
- Tres configuraciones de íconos (`pubspec.yaml`, `flutter_launcher_icons.yaml`, `flutter_launcher_icons safe.yaml`) y `flutter_launcher_icons` declarado en `dependencies` **y** `dev_dependencies`.
- Versión "1.0.0" escrita a mano en 3 lugares.
- AGP declarado en `android/build.gradle.kts` (buildscript) y en `android/settings.gradle.kts` (plugins).

### 3.3 Código muerto (~1,200 renglones)

`widgets/letanias_widget.dart` (dos variantes; además su detector de respuestas busca mayúsculas que el texto no tiene), `widgets/rosario_widget.dart`, `ParallaxRosaryImage` e `InteractiveRosaryImage` en `rosary_image_widget.dart`, `widgets/responsive_builder.dart`, `responsive_container.dart`, `orientation_builder_widget.dart`, `responsive.dart`, `utils/responsive_utils.dart`, `l10n/app_localizations.dart`, `ReminderTemplates`/`ReminderTemplate`, constantes `animation*`, `lib/generate_icons.dart` (script dentro de `lib/` que importa un paquete no declarado), `Hero(tag: 'start-button')` sin pareja, `InkWell` sin acción en el modal de misterios.

### 3.4 Pruebas

11 pasan, 3 fallan: `widget_test.dart` (plantilla del contador), `responsive_utils_test.dart` (no compila: `MediaQueryData.orientation` ya no existe), `rosary_beads_widget_test.dart` (cuenta `Container`s, frágil). Sin pruebas para el recorrido del rosario ni para recordatorios.

### 3.5 Dependencias y plataforma

- Flutter 3.32.5 (estable actual 3.47.9). `flutter_local_notifications` 17.2.4 → 23.x, `permission_handler` 11 → 13, `timezone` 0.9 → 0.11, `intl` 0.19 → 0.20, `flutter_lints` 3 → 6, `flutter_launcher_icons` 0.13 → 0.14.
- 36 usos de `withOpacity` (obsoleto).
- Gradle subido hoy a 9.7.1 y AGP a 8.10.1 sin verificar compilación; `enableJetifier=true` innecesario.
- `AndroidManifest.xml`: meta-data de AdMob de prueba (la app no usa anuncios), `USE_EXACT_ALARM` + `SCHEDULE_EXACT_ALARM` juntos, `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`, `usesCleartextTraffic`, `requestLegacyExternalStorage`, `INTERNET` y `<queries>` innecesarios.
- `applicationId`/bundle `com.example…` (las tiendas no lo aceptan). iOS con `IPHONEOS_DEPLOYMENT_TARGET = 12.0`.

### 3.6 Contenido

Erratas en oraciones: "Sagrado corazon de jesus. En vos confio" → "Sagrado Corazón de Jesús, en vos confío"; "amparanos" → "ampáranos"; "Espíritu Santo.Amén" → "Espíritu Santo. Amén."; título "Sagrado corazon" → "Sagrado Corazón".

## 4. Arquitectura objetivo

Se sigue el patrón actual: pantallas y widgets con nombres en español, modelos y servicios en inglés.

```
lib/
  main.dart                     Arranque: bindings, zona horaria, preferencias, notificaciones, runApp
  app.dart                      SantoRosarioApp: MaterialApp, temas, locale es, menú único
  theme/
    app_tokens.dart             Colores base, espaciados, radios, tamaños táctiles (reemplaza constants/app_constants.dart)
    seccion_colores.dart        ThemeExtension con los colores de cada sección (claro / oscuro / alto contraste)
    app_theme.dart              ThemeData claro, oscuro y alto contraste
  data/
    oraciones.dart              Textos únicos (const) de oraciones y misterios; listas que los reutilizan
  models/
    prayer_models.dart          Prayer, SeccionRosario, TipoMisterio
    reminder_model.dart         RosarioReminder, ReminderType {notification, alarm}, plantillas rápidas
  logic/
    rosario_session.dart        Recorrido del rosario como lista fija de 93 pasos (ChangeNotifier)
  services/
    preferences_service.dart    Preferencias persistentes (shared_preferences)
    notification_service.dart   Recordatorios: guardar, programar, cancelar, permisos
    notifications_gateway.dart  Interfaz delgada sobre flutter_local_notifications (permite pruebas con un doble)
    schedule_calculator.dart    Funciones puras: próxima fecha por día de semana, IDs de notificación
  screens/
    inicio_screen.dart
    rezo_screen.dart            Una sola pantalla para todo el recorrido (reemplaza las 3 actuales)
    agendar_rosario_screen.dart
    configuracion_screen.dart   Antes settings_drawer.dart
  widgets/
    app_drawer.dart             Menú único (antes main_menu_drawer.dart + acceso a Configuración)
    paso_oracion_layout.dart    Estructura común de cada paso (encabezado, progreso, texto, botones)
    progreso_rosario.dart       "Misterio 2/5 · Ave María 4/10" + barra global
    rosary_beads_widget.dart
    letanias_widget.dart        Una sola variante, reparada
    misterios_del_dia_modal.dart
    reminder_form.dart
    rosary_image_widget.dart    Solo el widget base
```

**Se eliminan:** `resar_rosario_app.dart`, `screens/oraciones_iniciales_screen.dart`, `screens/misterios_screen.dart`, `screens/oraciones_finales_screen.dart`, `widgets/settings_drawer.dart`, `widgets/main_menu_drawer.dart`, `widgets/rosario_widget.dart`, `widgets/responsive*.dart`, `widgets/orientation_builder_widget.dart`, `utils/responsive_utils.dart` (y su prueba), `l10n/app_localizations.dart`, `constants/`, `lib/generate_icons.dart`. En tabletas basta un ancho máximo de 600 px dentro de `paso_oracion_layout.dart`.

### 4.1 Recorrido del rosario (`RosarioSession`)

- Se construye una **lista plana de pasos** a partir de los datos: 3 oraciones iniciales + 5 misterios × (anuncio, Padre Nuestro, 10 Ave María, Gloria, María Madre de gracia, Sagrado Corazón, Oh Jesús mío) + 10 oraciones finales = **93 pasos**.
- Cada paso conoce su sección (`iniciales`, `misterio`, `finales`), su número de misterio (0–4), su número de Ave María (0–9) y su oración.
- API: `siguiente()`, `anterior()`, `reiniciar()`, `pasoActual`, `progreso` (0.0–1.0), `esUltimo`. Al terminar el último paso se vuelve al inicio.
- El tipo de misterio del día se calcula con `DateTime.weekday` y la tabla de `data/oraciones.dart`.
- Reemplaza los `switch` con textos `'inicio'`, `'misterios'`, etc. de `resar_rosario_app.dart`.

### 4.2 Recordatorios

- **Zona horaria:** `flutter_timezone` obtiene la zona del teléfono → `tz.setLocalLocation(tz.getLocation(nombre))`. Si falla, se usa UTC y se registra el error.
- **IDs:** cada recordatorio recibe un ID secuencial pequeño (`máximo existente + 1`). ID de notificación = `idRecordatorio * 10 + díaSemana` (1–7). Al cargar, los recordatorios con IDs aleatorios antiguos (≥ 1,000,000) se renumeran y se reprograman.
- **Cancelación:** siempre los 7 días posibles del recordatorio (cubre cambios de días al editar).
- **Tipos:** *Notificación* usa el canal `rosario_notifications` (sonido del sistema). *Alarma* usa un canal nuevo `rosario_alarms_v2` con `alarm_sound.mp3`, `fullScreenIntent`, categoría alarma y audio de alarma. El canal se renombra porque Android no permite cambiar el sonido de un canal existente.
- **Ícono:** drawable monocromático `ic_notification` para el ícono pequeño. El ícono grande es el de la app.
- **Alarmas exactas:** si el sistema las permite se usa `exactAllowWhileIdle`. Si no, se usa `inexactAllowWhileIdle` y la pantalla muestra un aviso con botón para abrir el ajuste. Se elimina `USE_EXACT_ALARM`.
- **Permisos:** se piden al entrar a "Agendar Rosario", no al arrancar la app (también en iOS). Si se niegan, la pantalla lo muestra y ofrece abrir los ajustes.
- **Errores:** cada operación devuelve éxito o fallo; la pantalla muestra un `SnackBar` con el resultado.
- **Plantillas rápidas:** el formulario ofrece las plantillas existentes (Matutino 7:00, Vespertino 19:00, Mediodía 12:00 L–V, Dominical 10:00) como atajos.

### 4.3 Preferencias y accesibilidad

- `PreferencesService` carga y guarda con `shared_preferences` (tamaño de texto, alto contraste, botones grandes, tema). Se carga antes de `runApp`. Deja de ser singleton; se crea en `main` y se entrega con `provider`.
- **Escalado de texto una sola vez:** el factor de la app se aplica sobre el escalado del sistema en el `builder` de `MaterialApp`. Desaparecen todas las multiplicaciones manuales `fontSize * textScaleFactor`.
- **Alto contraste:** tema propio (claro y oscuro) seleccionado explícitamente según la preferencia.
- **Botones grandes:** el tema define la altura mínima de los botones (48 dp normal / 64 dp grande); todas las pantallas lo heredan.
- Etiquetas `Semantics` y `tooltip` en botones de solo ícono; objetivos táctiles ≥ 48 dp; contraste de texto WCAG AA (4.5:1) en claro, oscuro y alto contraste.

### 4.4 Sistema de diseño (estilo actual pulido)

- `app_tokens.dart`: paleta base (azules, morados, verdes y ámbar actuales), espaciados 4/8/16/24/32, radios 12/16/24, tamaños táctiles.
- `SeccionColores` (ThemeExtension) por sección: azul para inicio e iniciales, morado para misterios, verde para finales; cada una con su variante clara, oscura y de alto contraste. Las cuentas del rosario usan el ámbar actual.
- Las pantallas solo leen el tema (`Theme.of(context)`, `context.seccion`); no quedan colores `Color(0x…)` dentro de pantallas ni widgets.
- Oraciones en Lora (serif); interfaz con la fuente del sistema.
- `progreso_rosario.dart`: encabezado con sección, "Misterio n/5", "Ave María n/10" y barra de progreso global.
- La Fase 4 se ejecuta con la skill **Frontend Design** para la dirección visual y la revisión de cada pantalla en claro, oscuro y alto contraste.

### 4.5 Plataforma y publicación

- **Android:** `namespace`/`applicationId` = `com.alejandrovaldez.santorosario`; `MainActivity.kt` se mueve al paquete nuevo. Versiones de Gradle, AGP, Kotlin y Java alineadas con la plantilla de Flutter 3.47 (se comparan contra un `flutter create` de referencia). `versionCode`/`versionName` desde `flutter.versionCode`/`flutter.versionName`. `targetSdk` = el exigido por Google Play al publicar (se verifica en la Fase 5). Firma de release leída de `android/key.properties` (ignorado en git); el keystore vive fuera del repo. Release con R8 probado programando un recordatorio.
- **Manifest:** se quitan AdMob, `USE_EXACT_ALARM`, `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`, `usesCleartextTraffic`, `requestLegacyExternalStorage`, `INTERNET` y `<queries>`. Se conservan `POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`, `RECEIVE_BOOT_COMPLETED`, `VIBRATE`, `WAKE_LOCK`, `USE_FULL_SCREEN_INTENT` y los receivers del plugin.
- **iOS:** `PRODUCT_BUNDLE_IDENTIFIER` = `com.alejandrovaldez.santorosario`, `IPHONEOS_DEPLOYMENT_TARGET` = el mínimo que exija Flutter 3.47, delegado de notificaciones en `AppDelegate.swift`, nombre visible "Santo Rosario", íconos regenerados.
- **CI (GitHub Actions):** `ci.yml` en Ubuntu (`flutter analyze`, `flutter test`, `flutter build appbundle` sin firma) y `ios.yml` en macOS (`flutter build ipa --no-codesign`). La firma para TestFlight/App Store y la subida a Play se agregan al tener las cuentas de desarrollador; los certificados y claves van **solo** en GitHub Secrets.
- **Versión visible** leída con `package_info_plus` (menú y "Acerca de").

## 5. Fases y criterios de aceptación

Cada fase cierra con: `flutter analyze` sin errores ni advertencias, `flutter test` en verde, `flutter build apk --debug` exitoso, commit en `mejora-integral` y `graphify update .`. La Fase 6 exige además 0 avisos de cualquier nivel (incluidos los informativos como `deprecated_member_use`).

| Fase | Contenido | Se acepta cuando |
|---|---|---|
| **0. Base segura** | Rama `mejora-integral`. Restaurar `lib/services/notification_service.dart` a `HEAD`. Commit "instantánea" del resto de cambios pendientes (íconos regenerados, manifest, Gradle, pubspec, `reminder_model.dart`, `reminder_form.dart`). Eliminar `web/`, `windows/`, `macos/`, `linux/` y `flutter_launcher_icons safe.yaml`. `.gitignore`: `android/build/`, `android/app/.cxx/`, `graphify-out/`, `.github/modernize/`, `android/key.properties`, `*.jks`, `*.keystore`. | Árbol limpio; nada se pierde (todo queda en commits) |
| **1. Actualización** | Flutter 3.47.9. Dependencias a versiones actuales + `flutter_timezone`, `flutter_localizations`, `package_info_plus`. `flutter_launcher_icons` solo en `dev_dependencies` con un único `flutter_launcher_icons.yaml`. Gradle/AGP/Kotlin/Java según plantilla. Reparar las 3 pruebas rotas (la del contador pasa a ser una prueba de humo real de la app). | Compila en Android con Flutter 3.47.9; 0 errores y 0 advertencias de análisis |
| **2. Errores críticos (TDD)** | E1–E7, E9, E10 y E13, con `RosarioSession`, `schedule_calculator.dart`, `notifications_gateway.dart`, preferencias persistentes, menú único, localización `es`. Cada error primero con una prueba que falla. | Pruebas nuevas cubren recorrido, cálculo de fechas/IDs, migración de recordatorios y persistencia |
| **3. Limpieza y duplicados** | `rezo_screen.dart` + `paso_oracion_layout.dart` reemplazan las 3 pantallas. `data/oraciones.dart` sin textos repetidos. Borrar código muerto (§3.3). Integrar letanías reparadas y plantillas rápidas. Corregir erratas (§3.6). Versión desde `package_info_plus`. | Graphify sin widgets huérfanos; ningún texto de oración duplicado |
| **4. Sistema de diseño** | E11 y E12. Tokens, `SeccionColores`, temas claro/oscuro/alto contraste, botones grandes vía tema, Lora para oraciones, `progreso_rosario.dart`, `Semantics`. Reemplazar `withOpacity` por `withValues` en los archivos que sobreviven. Revisión visual con Frontend Design. | Ningún `Color(0x…)` fuera de `theme/`; sin APIs obsoletas; cada pantalla revisada en los 3 temas y al 200 % de texto |
| **5. Tiendas** | E8 (iOS). Paquete `com.alejandrovaldez.santorosario`, firma de release, manifest limpio (§4.5), R8, iOS configurado, workflows `ci.yml` e `ios.yml`. | `flutter build appbundle --release` firmado localmente; ambos workflows en verde |
| **6. Verificación** | Prueba de recorrido completo (93 pasos), revisión de código (`requesting-code-review`), checklist manual en dispositivo real, `graphify update .` final. | Checklist manual completo; revisión sin hallazgos críticos abiertos |

## 6. Estrategia de pruebas

- **Unitarias:** `RosarioSession` (93 pasos, ida y vuelta, límites, reinicio), datos (5 misterios por tipo, tabla por día, sin textos duplicados), `RosarioReminder` (`toMap`/`fromMap`, migración `both → alarm`, renumeración de IDs), `schedule_calculator` (próxima fecha en cada día de la semana, cruce de semana, horario de verano con `tz`), `PreferencesService` con `SharedPreferences.setMockInitialValues`.
- **Servicio de notificaciones** con un doble de `NotificationsGateway`: IDs programados, canal según tipo, modo exacto/inexacto según permiso, cancelación de los 7 días.
- **Widgets:** inicio → comenzar → avanzar/retroceder; menú único abre Configuración; cambios de preferencias se reflejan; validación del formulario; plantillas rápidas.
- **Recorrido completo** como prueba de widget sin dispositivo (corre en CI).
- **Manual (dispositivo Android real):** recordatorio a +2 min con la app cerrada; alarma con sonido propio; reinicio del teléfono y el recordatorio sigue; permiso de alarma exacta negado → aviso + alarma inexacta; tema oscuro, alto contraste y texto al 200 % en todas las pantallas.

## 7. Manejo de errores

- Fallos de inicialización de notificaciones: la app arranca igual; la pantalla de recordatorios muestra el estado "no disponible" con el motivo.
- Fallos al guardar o programar: `SnackBar` con mensaje claro; el estado en memoria se revierte si no se guardó.
- Datos corruptos en `shared_preferences`: se descartan solo los registros inválidos y se registra el error; el resto se conserva.
- Zona horaria desconocida: UTC con registro del error (no bloquea la app).

## 8. Riesgos y mitigación

| Riesgo | Mitigación |
|---|---|
| La actualización de Flutter rompe Gradle o plugins | Fase 1 aislada; comparar con un `flutter create` de referencia; Gradle 9.7.1 se ajusta a lo que pida la plantilla |
| La actualización de Flutter afecta otros proyectos de la máquina | Aceptado por el usuario. Alternativa si molesta: FVM por proyecto |
| Comportamiento de notificaciones distinto por fabricante (ahorro de batería) | Checklist manual en dispositivo real; aviso en la app si las alarmas exactas están bloqueadas |
| iOS no se puede compilar en Windows | Workflow `ios.yml` en macOS desde la Fase 5 |
| Repo público | Claves y keystore solo en GitHub Secrets; `.gitignore` reforzado en la Fase 0 |
| R8 en release elimina clases que usa el plugin de notificaciones | Probar un recordatorio real con la compilación de release; agregar reglas `proguard` si hace falta |

## 9. Herramientas por fase

| Herramienta | Uso |
|---|---|
| Superpowers | `writing-plans` (plan), `subagent-driven-development` o `executing-plans` (ejecución), `test-driven-development` (Fases 2–3), `systematic-debugging` (cualquier falla), `verification-before-completion` (cierre de cada fase), `requesting-code-review` (Fases 3 y 6), `finishing-a-development-branch` (final) |
| Frontend Design | Fase 4 completa y componentes compartidos de la Fase 3 |
| Graphify | `graphify update .` al cerrar cada fase; comparar reporte inicial vs final (código muerto eliminado, comunidades más cohesivas) |
| Plugin Dart and Flutter (pendiente de instalar) | Skills `flutter-add-widget-test`, `flutter-setup-localization`, `dart-run-static-analysis`, `flutter-build-responsive-layout`; servidor MCP de Dart tras la Fase 1 (requiere Dart ≥ 3.9) |

## 10. Prerrequisitos que dependen del usuario

- Cuenta de **Google Play Console** (pago único) para publicar en Android.
- Cuenta de **Apple Developer Program** (anual) para TestFlight/App Store.
- Generar y resguardar el **keystore de Android** (se documenta el comando en el plan; nunca se sube al repo).
- Página de **política de privacidad** (puede alojarse en GitHub Pages) para las fichas de las tiendas.
- Aprobar la instalación del plugin **Dart and Flutter**.

## 11. Fuera de alcance

Otros idiomas además del español, audio o rezo guiado por voz, estadísticas o rachas, sincronización en la nube, anuncios, widgets de pantalla de inicio, cambio a Riverpod/BLoC/go_router.
