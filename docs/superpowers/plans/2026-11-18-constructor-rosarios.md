# Constructor de rosarios, biblioteca de oraciones y cámara — Plan de implementación (índice)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Las tareas están en los archivos de cada etapa (tabla de abajo) y se ejecutan **en orden numérico**. Para extraer el brief de una tarea usar `task-brief <archivo-de-la-etapa> <N> <salida>` con salida explícita en el workspace de este índice.

**Goal:** Agregar a "Santo Rosario" rosarios editables, una biblioteca de oraciones, lectura de oraciones impresas con la cámara y compartir oraciones con otras apps, sin tocar el Rosario tradicional.

**Architecture:** El rezo pasa a generarse desde datos (`Rosario` → `ParteRosario` → `ElementoParte`) con un solo motor. Lo protegido (tradicional, plantillas y oraciones de la app) vive en el código; lo del usuario vive en un archivo JSON con escritura atómica, administrado por `BibliotecaService`. Cámara, lector, compartir y recepción de texto quedan detrás de interfaces para probarlos con dobles, igual que `NotificationsGateway`.

**Tech Stack:** Flutter 3.47.9 / Dart 3.13.7, provider, path_provider, google_mlkit_text_recognition, image_picker, share_plus, receive_sharing_intent.

**Spec:** `docs/superpowers/specs/2026-11-18-constructor-rosarios-design.md`

## Cómo empezar en una sesión nueva

1. Rama de trabajo: `constructor-rosarios` (ya existe, contiene el spec y este plan).
2. Leer el spec y este índice completos.
3. Ejecutar con **superpowers:subagent-driven-development**, desde la Task 1.
4. **La Etapa 0 es una compuerta:** si la Task 1 o la 2 no se pueden completar, detenerse y presentar opciones al usuario. No continuar con la Etapa 1.

## Global Constraints

- **Rama:** `constructor-rosarios`. `git push`, PR o merge **solo con autorización explícita del usuario** (el repo `alejandrov1/app-resar-rosario` es público).
- **Commits:** terminan con la línea de atribución que indique la sesión. Agregar archivos con rutas explícitas; **nunca `git add -A`**.
- **SDK:** Flutter 3.47.9, Dart 3.13.7. Android mínimo API 24; iOS mínimo **15.5** (desde la Task 2).
- **Dependencias permitidas (nuevas):** `google_mlkit_text_recognition`, `image_picker`, `share_plus`, `path_provider`, `receive_sharing_intent`. Ninguna otra sin aprobación del usuario.
- **Rosario tradicional:** `construirPasos()` debe seguir produciendo exactamente los 93 pasos del archivo `test/fixtures/pasos_tradicional.json`. El tradicional, las plantillas y las oraciones de la app no se pueden modificar desde la interfaz.
- **Límites:** título de oración 80; texto de oración 10 000; nombre de rosario o parte 60; 30 partes por rosario; 50 oraciones por parte; 99 veces por oración; 20 vueltas o meditaciones; 1 000 pasos por rosario.
- **Colores:** solo en `lib/theme/` (se permite `Colors.transparent`). Contraste mínimo 4.5:1 en texto y 3:1 en texto grande (≥ 24 px, o ≥ 18.66 px en negrita).
- **Texto:** el escalado se aplica una sola vez en `MaterialApp.builder`. Prohibido multiplicar `fontSize` por un factor. Interfaz en español (es-MX).
- **Nombres:** pantallas, widgets, tema y lógica en español; `Oracion` y `Rosario` también.
- **Toques:** 48 dp como mínimo y con etiqueta o tooltip.
- **Privacidad:** la foto no se conserva y nada se guarda sin que el usuario lo confirme.
- **Cierre de cada tarea:** `flutter analyze` termina con `No issues found!` y `flutter test` pasa completo. No se relaja ninguna prueba y no se usa `// ignore:`.

## Reglas aprendidas en este proyecto (obligatorias)

Cada una viene de un error real de las rondas anteriores:

1. **No correr `dart format` ni ningún formateador.** El proyecto usa líneas de unos 120 columnas; un formateador reescribió 53 archivos.
2. **Botones:** toda etiqueta de texto de un botón usa `EtiquetaBoton` (`lib/widgets/etiqueta_boton.dart`), para que ninguna palabra se parta.
3. **`Semantics(excludeSemantics: true)` sobre un `InkWell` debe llevar `onTap:`.** Sin eso, el lector de pantalla anuncia el botón pero no lo puede activar. Probarlo con `tester.semantics.tap(...)`, no con `tester.tap`.
4. **Diálogos:** todo `AlertDialog` lleva `scrollable: true`.
5. **Listas:** el relleno inferior suma `MediaQuery.paddingOf(context).bottom`, y el horizontal suma `AppTokens.margenLateral(ancho)`. La app dibuja de borde a borde en Android 15.
6. **Formularios a pantalla completa:** copiar el patrón de `lib/screens/recordatorio_form_screen.dart`: ✕ con tooltip "Cerrar", título y "Guardar" con `MediaQuery.withClampedTextScaling(maxScaleFactor: 1.3)`, `PopScope` con "¿Descartar los cambios?".
7. **Contadores:** "1 de 10" usa espacios duros: `'1 de 10'`.
8. **Fuente de pruebas:** `flutter_test` dibuja texto cuadrado, casi el doble de ancho que el real. Un desborde en pruebas puede no existir en el teléfono; confirmar con el teléfono antes de cambiar el diseño.
9. **Handles de semántica en pruebas:** liberar con `try/finally`, no con `addTearDown`.
10. **API obsoleta en Flutter 3.47:** usar `RadioGroup` en lugar de `groupValue` en cada `Radio`, y `initialValue` en `DropdownButtonFormField`. Si el analizador marca `onReorder` como obsoleto, usar `onReorderItem`, que entrega el índice ya ajustado.
11. **Windows:** PowerShell 5.1 no tiene `&&`. Para subir a GitHub: `git -c http.sslBackend=schannel push`.
12. **Secretos:** nunca imprimir ni subir `android/key.properties`, `*.jks` ni `*.keystore`.

## Etapas y archivos

| Etapa | Archivo | Tareas | Resultado |
|---|---|---|---|
| 0. Viabilidad | `2026-11-18-constructor-rosarios-etapa-0-1.md` | 1–2 | ML Kit compila y funciona en Android e iOS, con mediciones |
| 1. Motor de datos | `2026-11-18-constructor-rosarios-etapa-0-1.md` | 3–7 | Modelos, motor único, almacén y biblioteca; el tradicional queda igual |
| 2. Mis oraciones | `2026-11-18-constructor-rosarios-etapa-2-3.md` | 8–9 | Crear, editar, pegar, copiar y compartir oraciones |
| 3. Mis rosarios | `2026-11-18-constructor-rosarios-etapa-2-3.md` | 10–14 | Constructor de camino de cuentas y rezo de rosarios propios |
| 4. Plantillas | `2026-11-18-constructor-rosarios-etapa-4-6.md` | 15 | Tres plantillas con validación de textos |
| 5. Cámara | `2026-11-18-constructor-rosarios-etapa-4-6.md` | 16–17 | Leer oraciones impresas y guardarlas |
| 6. Recibir en Android | `2026-11-18-constructor-rosarios-etapa-4-6.md` | 18 | "Compartir con Santo Rosario" desde otras apps |
| 7. Cierre | `2026-11-18-constructor-rosarios-etapa-7-8.md` | 19–20 | Privacidad, tiendas, pruebas en el teléfono y revisión final |
| 8. iPhone (posterior) | `2026-11-18-constructor-rosarios-etapa-7-8.md` | 21 | Recibir texto en iPhone; no se ejecuta sin Mac y cuenta de Apple |

## Ajustes respecto al spec (decididos al escribir el plan)

1. **Mover oraciones y partes:** además del arrastre, la alternativa accesible está en el menú de cada elemento ("Mover arriba" y "Mover abajo"), para que quepa con letra grande.
2. **`Prayer` y `PasoRosario` se conservan** como estructura de cada paso del rezo. Así no se reescribe la pantalla de rezo ni sus pruebas.
3. **`construirPasos` conserva sus valores por omisión** (el tradicional), porque muchas pruebas lo llaman sin argumentos.

## Momentos en que se necesita al usuario

| Tarea | Qué hace el usuario |
|---|---|
| 1 | Conectar el teléfono con depuración USB para probar la lectura real |
| 2 | Autorizar `git push` para compilar iOS en GitHub Actions |
| 15 | Validar los textos de las 3 plantillas (`docs/plantillas-para-validar.md`) |
| 17, 18, 20 | Probar en el teléfono |
| 20 | Elegir cómo cerrar la rama (PR, merge o dejarla) |
| 21 | Contar con Mac y cuenta de Apple Developer |

## Herramientas

- **Superpowers:** `subagent-driven-development`, `test-driven-development`, `systematic-debugging`, `verification-before-completion`, `requesting-code-review`, `receiving-code-review`, `finishing-a-development-branch`.
- **Frontend Design** (`frontend-design:frontend-design`): Tasks 9, 11, 12, 13 y 17, y la revisión en el teléfono. La dirección es pulir el estilo actual, sin paleta nueva.
- **Graphify:** `graphify update .` al cerrar cada etapa.
- **Teléfono:** `adb` está en `%LOCALAPPDATA%\Android\Sdk\platform-tools`. Si se cambian ajustes del teléfono para probar, pedir permiso antes y restaurarlos al terminar.

## Estructura final de archivos nuevos

```
lib/
  models/oracion.dart                    Oracion, LimitesBiblioteca
  models/rosario.dart                    Rosario, ParteRosario, ElementoParte, FuenteMisterios
  data/rosario_tradicional.dart          oracionesDeLaApp, rosarioTradicional
  data/plantillas_rosario.dart           PlantillaRosario, plantillasRosario, oracionesDePlantillas
  logic/edicion_rosario.dart             operaciones puras de edición
  logic/limpieza_texto.dart              limpieza del texto leído
  services/almacen_rosarios.dart         DatosUsuario, AlmacenRosarios, AlmacenArchivo
  services/biblioteca_service.dart       estado de oraciones y rosarios
  services/compartir_texto.dart          compartir, copiar y pegar
  services/lector_texto.dart             lector con ML Kit
  services/selector_imagen.dart          cámara y galería
  services/texto_recibido.dart           texto compartido desde otras apps
  services/servicios_dispositivo.dart    agrupa los cuatro servicios anteriores
  screens/mis_oraciones_screen.dart
  screens/oracion_form_screen.dart
  screens/mis_rosarios_screen.dart
  screens/constructor_rosario_screen.dart
  screens/editor_parte_screen.dart
  screens/leer_oracion_screen.dart
  widgets/camino_cuentas.dart
  widgets/selector_numero.dart
  widgets/pedir_nombre.dart
```
