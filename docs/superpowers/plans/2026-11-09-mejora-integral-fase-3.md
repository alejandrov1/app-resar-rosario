# Mejora integral — Fase 3: Limpieza y complementos

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Aprovechar las dos piezas sin uso que sí suman (letanías con invocación y respuesta, plantillas rápidas de recordatorio), mostrar la versión real de la app y borrar todo el código muerto restante.

**Architecture:** Sin cambios de arquitectura. `analizarLetanias()` es una función pura que convierte el texto de las letanías en grupos de líneas; `LetaniasWidget` solo las pinta. La versión sale de `package_info_plus`.

**Tech Stack:** Flutter 3.47.9, package_info_plus 10.2.2, flutter_test.

**Spec:** `docs/superpowers/specs/2026-11-09-mejora-integral-design.md` (§3.3, §4.2 "Plantillas rápidas", §4.5 "Versión visible") · **Índice:** `docs/superpowers/plans/2026-11-09-mejora-integral.md`

## Global Constraints

- Rama `mejora-integral`; cada commit termina con `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; sin `git push` sin autorización.
- Colores solo en `lib/theme/`; el acento sobre la tarjeta es `colores.acento`.
- Sin multiplicar tamaños de letra por `textScaleFactor`.
- Cierre de cada tarea: `flutter analyze` sin errores ni advertencias y `flutter test` en verde.

---

### Task 17: Letanías con invocación y respuesta

**Files:**
- Rewrite: `lib/widgets/letanias_widget.dart`
- Modify: `lib/screens/rezo_screen.dart` (usar el widget en el paso de letanías)
- Create: `test/widgets/letanias_widget_test.dart`

**Interfaces:**
- Consumes: `oracionesFinales` (Task 7); `SeccionColores`, `AppTokens`, `AppTheme.oracion` (Task 9); `RezoScreen` (Task 11).
- Produces: `class LineaLetania { const LineaLetania(String invocacion, [String? respuesta]); }` (con `==`); `List<List<LineaLetania>> analizarLetanias(String texto)`; `class LetaniasWidget` (`const LetaniasWidget({required String texto, required SeccionColores colores})`).

- [ ] **Step 1: Escribir las pruebas**

`test/widgets/letanias_widget_test.dart`:

```dart
import 'package:app_resar_rosario/data/oraciones.dart';
import 'package:app_resar_rosario/logic/rosario_session.dart';
import 'package:app_resar_rosario/screens/rezo_screen.dart';
import 'package:app_resar_rosario/theme/app_theme.dart';
import 'package:app_resar_rosario/theme/seccion_colores.dart';
import 'package:app_resar_rosario/widgets/letanias_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final texto = oracionesFinales.first.text;

  test('agrupa las letanías en 4 bloques', () {
    final grupos = analizarLetanias(texto);
    expect(grupos, hasLength(4));
    expect(grupos[0].map((l) => l.invocacion), ['Señor, ten piedad', 'Cristo, ten piedad', 'Señor, ten piedad']);
    expect(grupos[0].every((l) => l.respuesta == null), isTrue);
  });

  test('separa la invocación de la respuesta', () {
    final grupos = analizarLetanias(texto);
    expect(grupos[2].first, const LineaLetania('Dios, Padre celestial,', 'Ten misericordia de nosotros.'));
    expect(grupos[3].first, const LineaLetania('Santa María,', 'Ruega por nosotros.'));
    expect(grupos[3].last, const LineaLetania('Reina de la paz,', 'Ruega por nosotros.'));
  });

  test('no pierde ninguna línea', () {
    final lineas = texto.split('\n').where((l) => l.trim().isNotEmpty).length;
    expect(analizarLetanias(texto).expand((g) => g), hasLength(lineas));
  });

  testWidgets('muestra las respuestas', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.claro(),
      home: Scaffold(
        body: SingleChildScrollView(child: LetaniasWidget(texto: texto, colores: SeccionesTema.claro.finales)),
      ),
    ));
    expect(find.textContaining('Ruega por nosotros.', findRichText: true), findsWidgets);
  });

  testWidgets('la pantalla de rezo usa el formato de letanías', (tester) async {
    final sesion = RosarioSession(reloj: () => lunes)..comenzar();
    for (var i = 0; i < 83; i++) {
      sesion.siguiente();
    }
    await tester.pumpWidget(envolver(const RezoScreen(), preferencias: await preferenciasDePrueba(), sesion: sesion));
    await tester.pumpAndSettle();
    expect(find.byType(LetaniasWidget), findsOneWidget);
  });
}
```

- [ ] **Step 2: Correr y ver que falla**

Run: `flutter test test/widgets/letanias_widget_test.dart`
Expected: FAIL de compilación — `LineaLetania` y `analizarLetanias` no están definidos.

- [ ] **Step 3: Reescribir el widget**

`lib/widgets/letanias_widget.dart` (reemplazo completo; desaparecen `LetaniasListWidget`, `LetaniaSection` y `LetaniaItem`):

```dart
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../theme/seccion_colores.dart';

/// Una línea de las letanías: la invocación y, si la tiene, la respuesta del pueblo.
@immutable
class LineaLetania {
  const LineaLetania(this.invocacion, [this.respuesta]);

  final String invocacion;
  final String? respuesta;

  @override
  bool operator ==(Object other) =>
      other is LineaLetania && other.invocacion == invocacion && other.respuesta == respuesta;

  @override
  int get hashCode => Object.hash(invocacion, respuesta);

  @override
  String toString() => 'LineaLetania($invocacion, $respuesta)';
}

const _respuestas = ['ruega por nosotros.', 'ten misericordia de nosotros.'];

/// Divide el texto en bloques (separados por una línea en blanco) y separa cada respuesta.
List<List<LineaLetania>> analizarLetanias(String texto) {
  final grupos = <List<LineaLetania>>[];
  for (final bloque in texto.split(RegExp(r'\n\s*\n'))) {
    final lineas = <LineaLetania>[];
    for (final linea in bloque.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty)) {
      final respuesta = _respuestas.where((r) => linea.endsWith(', $r')).firstOrNull;
      if (respuesta == null) {
        lineas.add(LineaLetania(linea));
      } else {
        final invocacion = linea.substring(0, linea.length - respuesta.length - 2);
        lineas.add(LineaLetania('$invocacion,', '${respuesta[0].toUpperCase()}${respuesta.substring(1)}'));
      }
    }
    if (lineas.isNotEmpty) grupos.add(lineas);
  }
  return grupos;
}

/// Letanías con la respuesta resaltada en cada línea.
class LetaniasWidget extends StatelessWidget {
  const LetaniasWidget({super.key, required this.texto, required this.colores});

  final String texto;
  final SeccionColores colores;

  @override
  Widget build(BuildContext context) {
    final estilo = AppTheme.oracion(context);
    final grupos = analizarLetanias(texto);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var g = 0; g < grupos.length; g++) ...[
          if (g > 0) const SizedBox(height: AppTokens.espacioM),
          for (final linea in grupos[g])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppTokens.espacioXS / 2),
              child: linea.respuesta == null
                  ? Text(linea.invocacion, style: estilo.copyWith(fontWeight: FontWeight.w600))
                  : Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: '${linea.invocacion} '),
                          TextSpan(
                            text: linea.respuesta,
                            style: TextStyle(
                              color: colores.acento,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      style: estilo,
                    ),
            ),
        ],
      ],
    );
  }
}
```

- [ ] **Step 4: Usarlo en la pantalla de rezo**

En `lib/screens/rezo_screen.dart`, agregar `import '../widgets/letanias_widget.dart';` y en `_Contenido` reemplazar la última línea de la columna:

```dart
// ANTES
        Text(paso.oracion.text, style: AppTheme.oracion(context)),
// DESPUÉS
        if (paso.oracion.type == 'letanias')
          LetaniasWidget(texto: paso.oracion.text, colores: colores)
        else
          Text(paso.oracion.text, style: AppTheme.oracion(context)),
```

- [ ] **Step 5: Correr y ver que pasa**

Run: `flutter test`
Expected: `All tests passed!`

- [ ] **Step 6: Commit**

Run: `flutter analyze` → sin errores ni advertencias.

```bash
git add lib/widgets/letanias_widget.dart lib/screens/rezo_screen.dart test/widgets/letanias_widget_test.dart
git commit -m "feat: letanías con la respuesta resaltada" -m "Se repara y se usa el widget de letanías que estaba sin uso; una sola variante en lugar de dos." -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 18: Plantillas rápidas en el formulario de recordatorios

**Files:**
- Modify: `lib/widgets/reminder_form.dart`
- Modify: `test/widgets/reminder_form_test.dart` (agregar dos pruebas)

**Interfaces:**
- Consumes: `ReminderTemplates.templates`, `ReminderTemplate` (Task 13); `ReminderForm` (Task 16).
- Produces: al crear (no al editar), el formulario muestra "Plantillas rápidas" con un `ActionChip` por plantilla; tocarlo llena título, descripción, hora, días y tipo.

- [ ] **Step 1: Agregar las pruebas**

Al final de `main()` en `test/widgets/reminder_form_test.dart`:

```dart
  testWidgets('una plantilla llena el formulario', (tester) async {
    final guardados = await mostrar(tester);
    await tester.tap(find.text('Rosario Matutino'));
    await tester.pump();
    await guardar(tester);

    final r = guardados.single;
    expect(r.title, 'Rosario Matutino');
    expect(r.description, 'Momento perfecto para comenzar el día con oración');
    expect(r.time, const TimeOfDay(hour: 7, minute: 0));
    expect(r.daysOfWeek, [1, 2, 3, 4, 5, 6, 7]);
    expect(r.type, ReminderType.notification);
  });

  testWidgets('al editar no se muestran plantillas', (tester) async {
    await mostrar(
      tester,
      recordatorio: RosarioReminder(
        id: 1,
        title: 'Noche',
        description: 'd',
        time: const TimeOfDay(hour: 21, minute: 0),
        daysOfWeek: const [7],
        isActive: true,
        type: ReminderType.alarm,
        createdAt: DateTime(2026, 1, 1),
      ),
    );
    expect(find.text('Plantillas rápidas'), findsNothing);
  });
```

- [ ] **Step 2: Correr y ver que falla**

Run: `flutter test test/widgets/reminder_form_test.dart`
Expected: FAIL — `Found 0 widgets with text "Rosario Matutino"`.

- [ ] **Step 3: Implementar**

En `lib/widgets/reminder_form.dart`, agregar este método a `_ReminderFormState` (debajo de `_elegirHora`):

```dart
  void _aplicar(ReminderTemplate plantilla) {
    HapticFeedback.selectionClick();
    setState(() {
      _titulo.text = plantilla.title;
      _descripcion = plantilla.description;
      _hora = plantilla.time;
      _dias
        ..clear()
        ..addAll(plantilla.daysOfWeek);
      _tipo = plantilla.type;
      _faltanDias = false;
    });
  }
```

Y en `build`, justo después de `const SizedBox(height: AppTokens.espacioL),` que sigue al título del formulario, insertar:

```dart
              if (widget.reminder == null) ...[
                Text('Plantillas rápidas', style: textos.titleSmall),
                const SizedBox(height: AppTokens.espacioS),
                Wrap(
                  spacing: AppTokens.espacioS,
                  runSpacing: AppTokens.espacioS,
                  children: [
                    for (final plantilla in ReminderTemplates.templates)
                      ActionChip(
                        avatar: Icon(plantilla.type.icon, size: 18),
                        label: Text(plantilla.title),
                        onPressed: () => _aplicar(plantilla),
                      ),
                  ],
                ),
                const SizedBox(height: AppTokens.espacioL),
              ],
```

- [ ] **Step 4: Correr y ver que pasa**

Run: `flutter test`
Expected: `All tests passed!`

- [ ] **Step 5: Commit**

Run: `flutter analyze` → sin errores ni advertencias.

```bash
git add lib/widgets/reminder_form.dart test/widgets/reminder_form_test.dart
git commit -m "feat: plantillas rápidas para crear recordatorios" -m "Las plantillas existían en el modelo pero ninguna pantalla las usaba." -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 19: Versión real de la app en el menú y en "Acerca de"

**Files:**
- Modify: `lib/widgets/app_drawer.dart`
- Rewrite: `test/widgets/app_drawer_test.dart`

**Interfaces:**
- Consumes: `AppDrawer`, `mostrarAcercaDe` (Task 15); `package_info_plus`.
- Produces: pie del menú con `"Versión <version>"`; `Future<void> mostrarAcercaDe(BuildContext context)` (ahora asíncrona, lee la versión; muestra `"<version> (<build>)"`).

- [ ] **Step 1: Reescribir las pruebas del menú**

`test/widgets/app_drawer_test.dart`:

```dart
import 'package:app_resar_rosario/data/oraciones.dart';
import 'package:app_resar_rosario/models/prayer_models.dart';
import 'package:app_resar_rosario/widgets/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../support/app_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Santo Rosario',
      packageName: 'com.alejandrovaldez.santorosario',
      version: '1.2.3',
      buildNumber: '4',
      buildSignature: '',
    );
  });

  Future<void> abrirMenu(WidgetTester tester) async {
    final preferencias = await preferenciasDePrueba();
    final clave = GlobalKey<ScaffoldState>();
    await tester.pumpWidget(envolver(
      Scaffold(key: clave, drawer: const AppDrawer(), body: const SizedBox.shrink()),
      preferencias: preferencias,
    ));
    clave.currentState!.openDrawer();
    await tester.pumpAndSettle();
  }

  testWidgets('el menú muestra el misterio de hoy y todas las opciones', (tester) async {
    await abrirMenu(tester);
    expect(find.text('Gozosos · Lunes'), findsOneWidget);
    for (final opcion in ['Misterios del día', 'Agendar Rosario', 'Configuración', 'Acerca de']) {
      expect(find.text(opcion), findsOneWidget);
    }
  });

  testWidgets('abre el diálogo con los 5 misterios y se cierra', (tester) async {
    await abrirMenu(tester);
    await tester.tap(find.text('Misterios del día'));
    await tester.pumpAndSettle();
    for (final misterio in misteriosPorTipo[TipoMisterio.gozosos]!) {
      expect(find.text(misterio), findsOneWidget);
    }
    await tester.tap(find.text('Entendido'));
    await tester.pumpAndSettle();
    expect(find.text('Misterios Gozosos'), findsNothing);
  });

  testWidgets('el menú muestra la versión instalada', (tester) async {
    await abrirMenu(tester);
    expect(find.text('Versión 1.2.3'), findsOneWidget);
  });

  testWidgets('Acerca de muestra versión y compilación', (tester) async {
    await abrirMenu(tester);
    await tester.tap(find.text('Acerca de'));
    await tester.pumpAndSettle();
    expect(find.text('1.2.3 (4)'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Correr y ver que falla**

Run: `flutter test test/widgets/app_drawer_test.dart`
Expected: FAIL — `Found 0 widgets with text "Versión 1.2.3"`.

- [ ] **Step 3: Implementar**

En `lib/widgets/app_drawer.dart`:

1. Agregar `import 'package:package_info_plus/package_info_plus.dart';`.
2. En la `Column` del `Drawer`, después del `Expanded(child: ListView(...))`, agregar `const _Version(),`.
3. Reemplazar el `onTap` de "Acerca de":

```dart
// ANTES
                  onTap: () {
                    Navigator.pop(context);
                    mostrarAcercaDe(context);
                  },
// DESPUÉS
                  onTap: () {
                    final navegador = Navigator.of(context);
                    navegador.pop();
                    // El contexto del menú se cierra; el del navegador sigue vivo.
                    mostrarAcercaDe(navegador.context);
                  },
```

4. Reemplazar la función `mostrarAcercaDe` y agregar el pie con la versión:

```dart
Future<void> mostrarAcercaDe(BuildContext context) async {
  final info = await PackageInfo.fromPlatform();
  if (!context.mounted) return;
  showAboutDialog(
    context: context,
    applicationName: 'Santo Rosario',
    applicationVersion: '${info.version} (${info.buildNumber})',
    applicationIcon: Image.asset('assets/icons/icono-rosario.png', width: 48, height: 48),
    children: const [
      Text('Una aplicación para rezar el Santo Rosario de manera guiada.'),
      SizedBox(height: AppTokens.espacioM),
      Text('Desarrollada con amor y devoción.'),
    ],
  );
}

class _Version extends StatelessWidget {
  const _Version();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, info) {
        final version = info.data?.version;
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.espacioM),
            child: Text(
              version == null ? '' : 'Versión $version',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        );
      },
    );
  }
}
```

- [ ] **Step 4: Correr y ver que pasa**

Run: `flutter test`
Expected: `All tests passed!`

- [ ] **Step 5: Commit**

Run: `flutter analyze` → sin errores ni advertencias.

```bash
git add lib/widgets/app_drawer.dart test/widgets/app_drawer_test.dart
git commit -m "feat: mostrar la versión real de la app" -m "La versión salía escrita a mano en tres lugares; ahora se lee de pubspec con package_info_plus." -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 20: Borrar el código muerto y comprobarlo con Graphify

**Files:**
- Delete: `lib/widgets/rosario_widget.dart`, `lib/widgets/responsive.dart`, `lib/widgets/responsive_builder.dart`, `lib/widgets/responsive_container.dart`, `lib/widgets/orientation_builder_widget.dart`, `lib/utils/responsive_utils.dart`, `test/utils/responsive_utils_test.dart`, `lib/l10n/app_localizations.dart`, `lib/generate_icons.dart`, `lib/constants/app_constants.dart`
- Rewrite: `lib/widgets/rosary_image_widget.dart` (solo el widget base)

**Interfaces:**
- Consumes: todo lo anterior.
- Produces: `RosaryImageWidget({required double width, required double height, required String imagePath, BoxFit fit = BoxFit.contain, BorderRadius borderRadius})` con etiqueta para lector de pantalla. No quedan clases públicas sin uso.

- [ ] **Step 1: Confirmar que nadie usa lo que se va a borrar**

Run:

```bash
grep -rn "rosario_widget.dart\|responsive\|orientation_builder\|app_localizations\|generate_icons\|app_constants\|AppConstants\|ParallaxRosaryImage\|InteractiveRosaryImage" lib test --include=*.dart | grep -v "^lib/widgets/rosario_widget.dart\|^lib/widgets/responsive\|^lib/utils/\|^test/utils/\|^lib/widgets/orientation_builder_widget.dart\|^lib/l10n/\|^lib/generate_icons.dart\|^lib/constants/\|^lib/widgets/rosary_image_widget.dart"
```

Expected: sin coincidencias (solo se mencionan a sí mismos). Si aparece alguna, ese archivo todavía depende de código viejo: reemplazar `AppConstants.spacing*`/`radius*` por `AppTokens.espacio*`/`radio*` antes de seguir.

- [ ] **Step 2: Borrar**

```bash
git rm -q lib/widgets/rosario_widget.dart lib/widgets/responsive.dart lib/widgets/responsive_builder.dart \
  lib/widgets/responsive_container.dart lib/widgets/orientation_builder_widget.dart lib/utils/responsive_utils.dart \
  test/utils/responsive_utils_test.dart lib/l10n/app_localizations.dart lib/generate_icons.dart lib/constants/app_constants.dart
ls lib
```

Expected: `lib` contiene `app.dart`, `data/`, `logic/`, `main.dart`, `models/`, `screens/`, `services/`, `theme/`, `widgets/` (ya no `constants/`, `l10n/`, `utils/`).

- [ ] **Step 3: Dejar solo el widget base de la imagen**

`lib/widgets/rosary_image_widget.dart` (reemplazo completo; la foto tiene fondo blanco, por eso el marco claro se mantiene en todos los temas):

```dart
import 'package:flutter/material.dart';

/// Imagen del rosario de la pantalla de inicio, con aparición suave.
class RosaryImageWidget extends StatelessWidget {
  const RosaryImageWidget({
    super.key,
    required this.width,
    required this.height,
    required this.imagePath,
    this.fit = BoxFit.contain,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
  });

  final double width;
  final double height;
  final String imagePath;
  final BoxFit fit;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), spreadRadius: 2, blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Image.asset(
          imagePath,
          fit: fit,
          semanticLabel: 'Imagen de un rosario',
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded) return child;
            return AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut,
              child: child,
            );
          },
          errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.image_not_supported_outlined, size: 48)),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Buscar clases públicas que nadie más usa**

Run:

```bash
for clase in $(grep -rhoE "^(abstract |final |sealed |base |interface )*class [A-Z][A-Za-z0-9_]*" lib | awk '{print $NF}' | sort -u); do
  usos=$(grep -rlw "$clase" lib | wc -l)
  [ "$usos" -le 1 ] && echo "$clase"
done
```

Expected: solo `LineaLetania` (se usa dentro de su propio archivo y en pruebas). Cualquier otra clase listada es código muerto: borrarla o justificar su uso antes de seguir.

- [ ] **Step 5: Verificar, actualizar el grafo y hacer commit**

Run: `flutter analyze && flutter test && flutter build apk --debug`
Expected: sin errores ni advertencias; `All tests passed!`; APK compila.

```bash
git add -A lib test
git commit -m "chore: borrar código muerto" -m "Se eliminan pintor del rosario, variantes de imagen, widgets responsivos, traducciones sin uso, constantes viejas y el script de íconos dentro de lib/." -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
graphify update .
graphify explain "RosarioSession"
```

Expected de `graphify explain`: lista conexiones con `RezoScreen`, `InicioScreen`, `AppDrawer`, `PrincipalScreen` y `SantoRosarioApp`.

**Cierre de la Fase 3:** no queda código muerto; letanías y plantillas integradas; versión real visible.
