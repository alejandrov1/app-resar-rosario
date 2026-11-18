# Mejora integral de "Santo Rosario" — Plan de implementación (índice)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Las tareas están en los archivos de cada fase (tabla de abajo) y se ejecutan **en orden numérico**: cada una deja la app compilando y con las pruebas en verde.

**Goal:** Dejar la app lista para Google Play y App Store: sin errores funcionales, sin duplicados ni código muerto, con modo oscuro y accesibilidad reales, dependencias al día y pruebas automáticas.

**Architecture:** Se trabaja por fases sobre el código existente (enfoque A del spec). El rezo pasa a ser una lista fija de 93 pasos (`RosarioSession`) con una sola pantalla (`RezoScreen`); los recordatorios usan una interfaz (`NotificationsGateway`) que permite probarlos sin dispositivo; todos los colores viven en `lib/theme/` (`SeccionesTema`, una `ThemeExtension` con variantes claro, oscuro y alto contraste). Se conserva `provider`.

**Tech Stack:** Flutter 3.47.9 / Dart 3.13.7, provider, shared_preferences, flutter_local_notifications 22.3.3, timezone + flutter_timezone, package_info_plus, flutter_localizations, GitHub Actions.

**Spec:** `docs/superpowers/specs/2026-11-09-mejora-integral-design.md`

## Global Constraints

- **Rama:** `mejora-integral`. Cada commit termina con `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. **`git push`, PR o merge solo con autorización explícita del usuario** (repo público `alejandrov1/app-resar-rosario`).
- **SDK:** Flutter 3.47.9, Dart 3.13.7; `environment: sdk: ^3.13.0`.
- **Plataformas:** solo Android (mín. API 24, `compileSdk` ≥ 36) e iOS (mín. el de la plantilla, ≥ 13).
- **Paquete:** `com.alejandrovaldez.santorosario` (desde la Task 26). Nombre visible "Santo Rosario".
- **Dependencias:** `flutter_local_notifications: ^22.3.3`, `flutter_timezone: ^5.1.1`, `timezone: ^0.11.2`, `shared_preferences: ^2.5.6`, `provider: ^6.1.5+1`, `package_info_plus: ^10.2.2`, `flutter_localizations`; dev: `flutter_lints: ^6.0.0`, `flutter_launcher_icons: ^0.14.4`. `permission_handler` solo hasta la Task 14. Prohibido agregar `intl`, `cupertino_icons`, `google_fonts`, Riverpod, BLoC o go_router.
- **Nombres:** pantallas, widgets, tema y lógica en español; modelos y servicios en inglés (patrón existente).
- **Colores:** solo en `lib/theme/` (desde la Task 9). Contraste mínimo 4.5:1 en texto (7:1 para el acento en alto contraste) y 3:1 en bordes.
- **Texto:** el escalado se aplica una sola vez en `MaterialApp.builder`; prohibido multiplicar `fontSize` por `textScaleFactor`. Interfaz en español (es-MX).
- **Recordatorios:** tipos `notification` y `alarm`; IDs 1…100000; ID de notificación = `id * 10 + día`; canales `rosario_notifications` y `rosario_alarms_v2`; permisos solo al entrar a "Agendar Rosario".
- **Secretos:** nunca en el repo (`android/key.properties`, `*.jks`, `*.keystore`); en CI solo como GitHub Secrets.
- **Cierre de tarea:** `flutter analyze` sin errores ni advertencias y `flutter test` en verde. **Cierre de fase:** además `flutter build apk --debug` y `graphify update .`. **Fase 6:** 0 avisos de cualquier nivel.

## Fases y archivos

| Fase | Archivo | Tareas | Resultado |
|---|---|---|---|
| 0. Base segura | `2026-11-09-mejora-integral-fase-0-1.md` | 1–2 | Rama, instantánea sin perder nada, servicio restaurado, solo Android/iOS |
| 1. Actualización | `2026-11-09-mejora-integral-fase-0-1.md` | 3–5 | Flutter 3.47.9, dependencias y Gradle al día, pruebas reparadas |
| 2A. Preferencias y rezo | `2026-11-09-mejora-integral-fase-2a.md` | 6–11 | Preferencias guardadas, oraciones únicas, `RosarioSession`, tema base, menú único, una sola pantalla de rezo |
| 2B. Recordatorios y estructura | `2026-11-09-mejora-integral-fase-2b.md` | 12–16 | Zona horaria, cálculo de fechas/IDs, servicio nuevo, `SantoRosarioApp`, Configuración, recordatorios |
| 3. Limpieza | `2026-11-09-mejora-integral-fase-3.md` | 17–20 | Letanías, plantillas rápidas, versión real, código muerto fuera |
| 4. Diseño | `2026-11-09-mejora-integral-fase-4.md` | 21–25 | Oscuro y alto contraste reales, Lora, progreso, accesibilidad, revisión visual |
| 5. Tiendas | `2026-11-09-mejora-integral-fase-5.md` | 26–30 | Paquete propio, firma, manifest, iOS, GitHub Actions, documentación |
| 6. Verificación | `2026-11-09-mejora-integral-fase-6.md` | 31–33 | Recorrido completo, cobertura, revisión de código, prueba en teléfono, cierre |

## Dónde se corrige cada error del diagnóstico (spec §3.1)

| Error | Tarea(s) |
|---|---|
| E1 zona horaria UTC | 12 |
| E2 menús anidados | 10, 15 |
| E3 preferencias no se guardan | 6 |
| E4 escalado doble del texto | 9, 11, 15 |
| E5 regresión del servicio sin commit | 1 (restaurar), 14 (reescribir) |
| E6 ícono de notificación a color | 14 |
| E7 sonido de alarma sin usar | 14 |
| E8 iOS sin delegado / permisos al arrancar | 14 (permisos), 28 (delegado) |
| E9 sin localización en español | 15 |
| E10 padding del teclado doble | 16 |
| E11 modo oscuro sin efecto | 9, 11, 21, 25 |
| E12 accesibilidad incompleta | 9, 21, 23, 24 |
| E13 errores silenciados | 14, 16 |

## Ajustes respecto al spec (decididos al escribir el plan)

1. **La pantalla única de rezo y las oraciones sin duplicar se adelantan de la Fase 3 a la Fase 2** (Tasks 7 y 11). Corregir E2 y E4 en las tres pantallas viejas para borrarlas después sería trabajo perdido.
2. **`flutter_local_notifications` 22.3.3 en lugar de 23.x.** La 23.0.0 salió el 6 de noviembre de 2026 y exige AGP 9.1.1 y `compileSdk` 37. La 22.3.3 ya trae `openAppNotificationSettings()` y la corrección del horario de verano. Se puede pasar a la 23 más adelante.
3. **Se eliminan `permission_handler`, `intl` y `cupertino_icons`.** Los dos últimos no se usaban, y la API de notificaciones ya cubre permisos y ajustes. Así también se evita la configuración extra que `permission_handler` exige en el Podfile de iOS.
4. **`android/app/build/` (637 archivos generados) sale del control de versiones** en la Task 1.
5. **Los receivers del plugin pasan a `android:exported="false"`** (Task 26), como pide la documentación del plugin. Hoy están expuestos a otras apps.
6. **Archivos nuevos que no estaban en el árbol del spec:**
   - `lib/screens/principal_screen.dart`, que alterna entre inicio y rezo.
   - `lib/services/zona_horaria.dart`.
   - `lib/widgets/progreso_rosario.dart`.
   - `android/app/src/main/res/raw/keep.xml`, para que R8 no borre el ícono ni el sonido.
7. **Botón de las oraciones finales en `#15803D`** (un tono más oscuro que el `#16A34A` actual). Con el tono actual, el texto blanco no llega al contraste AA (3.3:1).
8. **"Ave María n de 10" se muestra en la barra de progreso** (Task 23) en lugar de repetirse debajo de las cuentas.
9. **Se conserva el `<queries>` con `PROCESS_TEXT` de la plantilla de Flutter**, aunque el §4.5 del spec dice quitar `<queries>`: el motor de Flutter lo usa para la selección de texto.
10. **Al reprogramar solo se cancelan las notificaciones pendientes** (`cancelAllPendingNotifications`), no `cancelAll`, para que una alarma que ya está sonando no se descarte ni se silencie al abrir la app. Esto corrige el texto de la Task 14.

## Momentos en que se necesita al usuario

| Tarea | Qué hace el usuario |
|---|---|
| 3 | Aceptar las licencias de Android si `flutter doctor` las pide (`flutter doctor --android-licenses`) |
| 25 | Conectar un teléfono Android o crear un emulador para la revisión visual; decidir los ajustes de gusto |
| 27 | Crear la clave de subida con `keytool` (pide contraseñas) y respaldarla |
| 29 | Autorizar `git push` de la rama para que corran los workflows |
| 33 | Probar en su teléfono y elegir cómo cerrar la rama (PR, merge o dejarla) |
| — | Cuentas de Play Console y Apple Developer, y publicar la política de privacidad (ver `docs/publicacion.md`, Task 30) |

## Herramientas

- **Superpowers:** `subagent-driven-development` o `executing-plans` para ejecutar; `test-driven-development` en cada tarea con pruebas; `systematic-debugging` ante cualquier falla; `verification-before-completion` al cerrar cada tarea; `requesting-code-review` y `receiving-code-review` (Task 32); `finishing-a-development-branch` (Task 33).
- **Frontend Design** (`frontend-design:frontend-design`): toda la Fase 4. La dirección es pulir el estilo actual.
- **Graphify:** `graphify update .` al cerrar cada fase; `graphify explain`/`graphify path` en las Tasks 20 y 33.
- **Plugin Dart and Flutter** (opcional, cuando el usuario lo instale): sus skills `flutter-add-widget-test` y `dart-run-static-analysis` sirven de apoyo. Su servidor MCP funciona después de la Task 3 (requiere Dart ≥ 3.9).

## Estructura final de `lib/`

```
lib/
  main.dart                       arranque: zona horaria, licencia de Lora, preferencias, notificaciones
  app.dart                        SantoRosarioApp: proveedores, temas, idioma, escalado de texto
  data/oraciones.dart             textos únicos de oraciones y misterios
  logic/rosario_session.dart      PasoRosario, construirPasos, RosarioSession
  models/prayer_models.dart       Prayer, SeccionRosario, TipoMisterio
  models/reminder_model.dart      RosarioReminder, ReminderType, plantillas, renumberIfNeeded
  services/preferences_service.dart
  services/notification_service.dart
  services/notifications_gateway.dart
  services/schedule_calculator.dart
  services/zona_horaria.dart
  theme/app_tokens.dart
  theme/seccion_colores.dart
  theme/app_theme.dart
  screens/principal_screen.dart
  screens/inicio_screen.dart
  screens/rezo_screen.dart
  screens/agendar_rosario_screen.dart
  screens/configuracion_screen.dart
  widgets/app_drawer.dart
  widgets/paso_oracion_layout.dart
  widgets/progreso_rosario.dart
  widgets/rosary_beads_widget.dart
  widgets/letanias_widget.dart
  widgets/misterios_del_dia_modal.dart
  widgets/reminder_form.dart
  widgets/rosary_image_widget.dart
```

**Se borran:**
- Del código: `resar_rosario_app.dart`, `constants/`, `l10n/` y `utils/`.
- Las pantallas `oraciones_iniciales_screen.dart`, `misterios_screen.dart` y `oraciones_finales_screen.dart`.
- Los widgets `settings_drawer.dart`, `main_menu_drawer.dart`, `rosario_widget.dart`, `responsive*.dart` y `orientation_builder_widget.dart`.
- El script `lib/generate_icons.dart`.
- Las plataformas `web/`, `windows/`, `macos/` y `linux/`.
