# Mejora integral — Fase 4: Sistema de diseño y accesibilidad

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. **Antes de la Task 21, cargar la skill `frontend-design:frontend-design`** y aplicarla a toda la fase (dirección: "pulir el estilo actual", no rediseñar).

**Goal:** Modo oscuro y alto contraste reales en cada sección (E11, E12), contraste verificado por pruebas, fuente serif para las oraciones, progreso visible del rosario y accesibilidad comprobada (tamaño táctil, etiquetas, texto al 200 %).

**Architecture:** `SeccionesTema` gana tres variantes (oscuro, alto contraste claro, alto contraste oscuro) elegidas por `SeccionesTema.para()` dentro de `AppTheme`. Las pantallas no cambian de forma: ya leen todo del tema desde la Fase 2.

**Tech Stack:** Flutter 3.47.9 (Material 3, `ThemeExtension`, `ColorScheme.fromSeed(contrastLevel:)`), fuente Lora (OFL), guías de accesibilidad de `flutter_test`.

**Spec:** `docs/superpowers/specs/2026-11-09-mejora-integral-design.md` (§4.3, §4.4) · **Índice:** `docs/superpowers/plans/2026-11-09-mejora-integral.md`

## Global Constraints

- Rama `mejora-integral`; cada commit termina con `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; sin `git push` sin autorización.
- Dirección visual: **pulir el estilo actual** (azul inicio/iniciales, morado misterios, verde finales, cuentas doradas). No se cambia la estructura de las pantallas.
- Contraste mínimo: 4.5:1 para texto (7:1 para el texto de acento en alto contraste); 3:1 para bordes de componentes.
- Ningún `Color(0x…)` fuera de `lib/theme/`; sin `withOpacity`.
- Objetivos táctiles ≥ 48 dp; todo botón de solo ícono con `tooltip` o etiqueta.
- Cierre de cada tarea: `flutter analyze` sin errores ni advertencias y `flutter test` en verde.

---

### Task 21: Colores de sección para oscuro y alto contraste, con pruebas de contraste (E11, E12)

**Files:**
- Modify: `lib/theme/seccion_colores.dart` (tres variantes nuevas y `para()`)
- Modify: `lib/theme/app_theme.dart` (usar la variante de cada tema)
- Create: `test/theme/contraste_test.dart`

**Interfaces:**
- Consumes: `SeccionColores`, `SeccionesTema.claro` (Task 9); `AppTheme.claro/oscuro` (Task 9).
- Produces: `SeccionesTema.oscuro`, `SeccionesTema.altoContrasteClaro`, `SeccionesTema.altoContrasteOscuro`; `static SeccionesTema para({required Brightness brillo, required bool altoContraste})`.

- [ ] **Step 1: Escribir las pruebas de contraste**

`test/theme/contraste_test.dart`:

```dart
import 'package:app_resar_rosario/models/prayer_models.dart';
import 'package:app_resar_rosario/theme/app_theme.dart';
import 'package:app_resar_rosario/theme/seccion_colores.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Relación de contraste WCAG 2.1 entre dos colores.
double contraste(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final (claro, oscuro) = la > lb ? (la, lb) : (lb, la);
  return (claro + 0.05) / (oscuro + 0.05);
}

void main() {
  final temas = <String, ThemeData>{
    'claro': AppTheme.claro(),
    'oscuro': AppTheme.oscuro(),
    'alto contraste claro': AppTheme.claro(altoContraste: true),
    'alto contraste oscuro': AppTheme.oscuro(altoContraste: true),
  };

  for (final MapEntry(key: nombre, value: tema) in temas.entries) {
    group(nombre, () {
      final secciones = tema.extension<SeccionesTema>()!;
      final tarjeta = tema.colorScheme.surfaceContainerLow;
      final minimoAcento = nombre.startsWith('alto') ? 7.0 : 4.5;

      for (final seccion in SeccionRosario.values) {
        final c = secciones.de(seccion);
        test('${seccion.name}: texto del botón', () {
          expect(contraste(c.sobreBoton, c.boton), greaterThanOrEqualTo(4.5));
        });
        test('${seccion.name}: acento sobre el recuadro', () {
          expect(contraste(c.acento, c.suave), greaterThanOrEqualTo(minimoAcento));
        });
        test('${seccion.name}: acento sobre la tarjeta', () {
          expect(contraste(c.acento, tarjeta), greaterThanOrEqualTo(4.5));
        });
      }

      test('título del inicio sobre su fondo', () {
        for (final fondo in secciones.fondoInicio) {
          expect(contraste(secciones.tituloInicio, fondo), greaterThanOrEqualTo(4.5));
        }
      });

      test('borde de las cuentas rezadas visible (3:1)', () {
        expect(contraste(secciones.bordeCuenta, tarjeta), greaterThanOrEqualTo(3));
      });
    });
  }

  test('cada tema usa su propia variante', () {
    expect(AppTheme.claro().extension<SeccionesTema>(), same(SeccionesTema.claro));
    expect(AppTheme.oscuro().extension<SeccionesTema>(), same(SeccionesTema.oscuro));
    expect(AppTheme.claro(altoContraste: true).extension<SeccionesTema>(), same(SeccionesTema.altoContrasteClaro));
    expect(AppTheme.oscuro(altoContraste: true).extension<SeccionesTema>(), same(SeccionesTema.altoContrasteOscuro));
  });
}
```

- [ ] **Step 2: Correr y ver que falla**

Run: `flutter test test/theme/contraste_test.dart`
Expected: FAIL de compilación — `Member not found: 'oscuro'` (y las otras variantes).

- [ ] **Step 3: Agregar las variantes**

En `lib/theme/seccion_colores.dart`, dentro de `SeccionesTema`, después de `static const claro = ...;`:

```dart
  static const oscuro = SeccionesTema(
    iniciales: SeccionColores(
      fondo: [Color(0xFF0B1220), Color(0xFF172554)],
      boton: Color(0xFF1E3A8A),
      sobreBoton: Color(0xFFFFFFFF),
      suave: Color(0xFF1E2B4D),
      acento: Color(0xFFBFDBFE),
    ),
    misterio: SeccionColores(
      fondo: [Color(0xFF140821), Color(0xFF3B0764)],
      boton: Color(0xFF581C87),
      sobreBoton: Color(0xFFFFFFFF),
      suave: Color(0xFF2E1A47),
      acento: Color(0xFFE9D5FF),
    ),
    finales: SeccionColores(
      fondo: [Color(0xFF04140A), Color(0xFF052E16)],
      boton: Color(0xFF14532D),
      sobreBoton: Color(0xFFFFFFFF),
      suave: Color(0xFF15301F),
      acento: Color(0xFFBBF7D0),
    ),
    fondoInicio: [Color(0xFF0B1220), Color(0xFF0F1E3D), Color(0xFF172554)],
    tituloInicio: Color(0xFFBFDBFE),
    cuenta: Color(0xFFFBBF24),
    bordeCuenta: Color(0xFFFDE68A),
  );

  /// Fondo blanco liso, texto casi negro y bordes marcados.
  static const altoContrasteClaro = SeccionesTema(
    iniciales: SeccionColores(
      fondo: [Color(0xFFFFFFFF), Color(0xFFFFFFFF)],
      boton: Color(0xFF172554),
      sobreBoton: Color(0xFFFFFFFF),
      suave: Color(0xFFFFFFFF),
      acento: Color(0xFF172554),
      borde: Color(0xFF172554),
    ),
    misterio: SeccionColores(
      fondo: [Color(0xFFFFFFFF), Color(0xFFFFFFFF)],
      boton: Color(0xFF3B0764),
      sobreBoton: Color(0xFFFFFFFF),
      suave: Color(0xFFFFFFFF),
      acento: Color(0xFF3B0764),
      borde: Color(0xFF3B0764),
    ),
    finales: SeccionColores(
      fondo: [Color(0xFFFFFFFF), Color(0xFFFFFFFF)],
      boton: Color(0xFF052E16),
      sobreBoton: Color(0xFFFFFFFF),
      suave: Color(0xFFFFFFFF),
      acento: Color(0xFF052E16),
      borde: Color(0xFF052E16),
    ),
    fondoInicio: [Color(0xFFFFFFFF), Color(0xFFFFFFFF), Color(0xFFFFFFFF)],
    tituloInicio: Color(0xFF172554),
    cuenta: Color(0xFF000000),
    bordeCuenta: Color(0xFF000000),
  );

  /// Fondo negro liso, texto claro y bordes marcados.
  static const altoContrasteOscuro = SeccionesTema(
    iniciales: SeccionColores(
      fondo: [Color(0xFF000000), Color(0xFF000000)],
      boton: Color(0xFFBFDBFE),
      sobreBoton: Color(0xFF000000),
      suave: Color(0xFF000000),
      acento: Color(0xFFBFDBFE),
      borde: Color(0xFFBFDBFE),
    ),
    misterio: SeccionColores(
      fondo: [Color(0xFF000000), Color(0xFF000000)],
      boton: Color(0xFFE9D5FF),
      sobreBoton: Color(0xFF000000),
      suave: Color(0xFF000000),
      acento: Color(0xFFE9D5FF),
      borde: Color(0xFFE9D5FF),
    ),
    finales: SeccionColores(
      fondo: [Color(0xFF000000), Color(0xFF000000)],
      boton: Color(0xFFBBF7D0),
      sobreBoton: Color(0xFF000000),
      suave: Color(0xFF000000),
      acento: Color(0xFFBBF7D0),
      borde: Color(0xFFBBF7D0),
    ),
    fondoInicio: [Color(0xFF000000), Color(0xFF000000), Color(0xFF000000)],
    tituloInicio: Color(0xFFFFFFFF),
    cuenta: Color(0xFFFFFFFF),
    bordeCuenta: Color(0xFFFFFFFF),
  );

  /// Variante que corresponde al tema.
  static SeccionesTema para({required Brightness brillo, required bool altoContraste}) =>
      switch ((brillo, altoContraste)) {
        (Brightness.light, false) => claro,
        (Brightness.dark, false) => oscuro,
        (Brightness.light, true) => altoContrasteClaro,
        (Brightness.dark, true) => altoContrasteOscuro,
      };
```

- [ ] **Step 4: Usar la variante correcta en el tema**

En `lib/theme/app_theme.dart`:

```dart
// ANTES
      extensions: const <ThemeExtension<dynamic>>[SeccionesTema.claro],
// DESPUÉS
      extensions: <ThemeExtension<dynamic>>[SeccionesTema.para(brillo: brillo, altoContraste: altoContraste)],
```

- [ ] **Step 5: Correr y ver que pasa**

Run: `flutter test`
Expected: `All tests passed!` (las 4 × 11 pruebas de contraste pasan).

- [ ] **Step 6: Commit**

Run: `flutter analyze` → sin errores ni advertencias.

```bash
git add lib/theme test/theme/contraste_test.dart
git commit -m "feat: modo oscuro y alto contraste reales en cada sección" -m "Variantes de colores por tema con contraste WCAG verificado por pruebas (E11, E12)." -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 22: Fuente serif Lora para las oraciones

**Files:**
- Create: `assets/fonts/Lora-Variable.ttf`, `assets/fonts/Lora-Italic-Variable.ttf`, `assets/fonts/OFL.txt`
- Modify: `pubspec.yaml` (fuentes y licencia)
- Modify: `lib/theme/app_theme.dart` (`oracion()` usa Lora)
- Modify: `lib/widgets/letanias_widget.dart` (peso semibold de la fuente variable)
- Modify: `lib/main.dart` (registrar la licencia OFL)
- Modify: `test/theme/app_theme_test.dart` (agregar dos pruebas)

**Interfaces:**
- Consumes: `AppTheme.oracion` (Task 9).
- Produces: familia de fuente `'Lora'` disponible; `AppTheme.oracion(context).fontFamily == 'Lora'`; la licencia aparece en "Acerca de → Ver licencias".

- [ ] **Step 1: Descargar la fuente (repositorio oficial de Google Fonts)**

```bash
mkdir -p assets/fonts
curl -sSL --ssl-no-revoke -o assets/fonts/Lora-Variable.ttf "https://raw.githubusercontent.com/google/fonts/main/ofl/lora/Lora%5Bwght%5D.ttf"
curl -sSL --ssl-no-revoke -o assets/fonts/Lora-Italic-Variable.ttf "https://raw.githubusercontent.com/google/fonts/main/ofl/lora/Lora-Italic%5Bwght%5D.ttf"
curl -sSL --ssl-no-revoke -o assets/fonts/OFL.txt "https://raw.githubusercontent.com/google/fonts/main/ofl/lora/OFL.txt"
ls -l assets/fonts
```

Expected: tres archivos de 212196, 221232 y 4423 bytes aproximadamente.

- [ ] **Step 2: Agregar las pruebas**

Al final de `main()` en `test/theme/app_theme_test.dart` (agregar `import 'dart:io';` arriba):

```dart
  testWidgets('las oraciones usan Lora', (tester) async {
    late TextStyle estilo;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.claro(),
      home: Builder(builder: (context) {
        estilo = AppTheme.oracion(context);
        return const SizedBox.shrink();
      }),
    ));
    expect(estilo.fontFamily, 'Lora');
  });

  test('la fuente y su licencia están en el proyecto', () {
    for (final archivo in ['Lora-Variable.ttf', 'Lora-Italic-Variable.ttf', 'OFL.txt']) {
      expect(File('assets/fonts/$archivo').existsSync(), isTrue, reason: archivo);
    }
  });
```

- [ ] **Step 3: Correr y ver que falla**

Run: `flutter test test/theme/app_theme_test.dart`
Expected: FAIL — `Expected: 'Lora' Actual: <null>`.

- [ ] **Step 4: Declarar la fuente y usarla**

En `pubspec.yaml`, reemplazar la sección `flutter:` completa:

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/images/
    - assets/icons/
    - assets/fonts/OFL.txt
  fonts:
    - family: Lora
      fonts:
        - asset: assets/fonts/Lora-Variable.ttf
        - asset: assets/fonts/Lora-Italic-Variable.ttf
          style: italic
```

En `lib/theme/app_theme.dart`:

```dart
// ANTES
  static TextStyle oracion(BuildContext context) =>
      Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 18, height: 1.6);
// DESPUÉS
  static TextStyle oracion(BuildContext context) =>
      Theme.of(context).textTheme.bodyLarge!.copyWith(fontFamily: 'Lora', fontSize: 18, height: 1.6);
```

En `lib/widgets/letanias_widget.dart` (Lora es una fuente variable: el grosor se pide por eje):

```dart
// ANTES
                  ? Text(linea.invocacion, style: estilo.copyWith(fontWeight: FontWeight.w600))
// DESPUÉS
                  ? Text(
                      linea.invocacion,
                      style: estilo.copyWith(
                        fontWeight: FontWeight.w600,
                        fontVariations: const [FontVariation.weight(600)],
                      ),
                    )
```

En `lib/main.dart`, agregar `import 'package:flutter/foundation.dart';` e `import 'package:flutter/services.dart';`, y justo después de `WidgetsFlutterBinding.ensureInitialized();`:

```dart
  LicenseRegistry.addLicense(() async* {
    final licencia = await rootBundle.loadString('assets/fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(const ['Lora'], licencia);
  });
```

- [ ] **Step 5: Correr y ver que pasa**

Run: `flutter pub get && flutter test`
Expected: `All tests passed!`

- [ ] **Step 6: Commit**

Run: `flutter analyze && flutter build apk --debug` → sin errores ni advertencias; APK compila.

```bash
git add assets/fonts pubspec.yaml lib test/theme/app_theme_test.dart
git commit -m "feat: texto de las oraciones en Lora" -m "Fuente serif empaquetada (licencia OFL registrada) para una lectura más pausada; la interfaz sigue con la fuente del sistema." -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 23: Progreso visible del rosario

**Files:**
- Create: `lib/widgets/progreso_rosario.dart`
- Modify: `lib/screens/rezo_screen.dart` (pasar `progreso` y quitar el texto repetido "Ave María n de 10")
- Create: `test/widgets/progreso_rosario_test.dart`
- Modify: `test/screens/rezo_screen_test.dart` (una expectativa)

**Interfaces:**
- Consumes: `PasoRosario`, `misteriosPorRosario`, `construirPasos` (Task 8); `SeccionColores`, `AppTokens` (Task 9); `PasoOracionLayout.progreso` (Task 11).
- Produces: `String etiquetaProgreso(PasoRosario paso)`; `class ProgresoRosario` (`const ProgresoRosario({required PasoRosario paso, required double progreso, required SeccionColores colores})`).

- [ ] **Step 1: Escribir las pruebas**

`test/widgets/progreso_rosario_test.dart`:

```dart
import 'package:app_resar_rosario/logic/rosario_session.dart';
import 'package:app_resar_rosario/theme/app_theme.dart';
import 'package:app_resar_rosario/theme/seccion_colores.dart';
import 'package:app_resar_rosario/widgets/progreso_rosario.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final pasos = construirPasos();

  test('etiquetas de progreso', () {
    expect(etiquetaProgreso(pasos[0]), 'Oraciones iniciales · 1/3');
    expect(etiquetaProgreso(pasos[3]), 'Misterio 1/5');
    expect(etiquetaProgreso(pasos[5]), 'Misterio 1/5 · Ave María 1/10');
    expect(etiquetaProgreso(pasos[14]), 'Misterio 1/5 · Ave María 10/10');
    expect(etiquetaProgreso(pasos[92]), 'Oraciones finales · 10/10');
  });

  testWidgets('muestra la etiqueta y la barra, y la anuncia al lector de pantalla', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.claro(),
      home: Scaffold(
        body: ProgresoRosario(paso: pasos[5], progreso: 6 / 93, colores: SeccionesTema.claro.misterio),
      ),
    ));
    expect(find.text('Misterio 1/5 · Ave María 1/10'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp(r'^Progreso del rosario: Misterio 1/5 · Ave María 1/10, 6 por ciento$')),
      findsOneWidget,
    );
    handle.dispose();
  });
}
```

- [ ] **Step 2: Correr y ver que falla**

Run: `flutter test test/widgets/progreso_rosario_test.dart`
Expected: FAIL de compilación — `Target of URI doesn't exist: 'package:app_resar_rosario/widgets/progreso_rosario.dart'`.

- [ ] **Step 3: Implementar**

`lib/widgets/progreso_rosario.dart`:

```dart
import 'package:flutter/material.dart';

import '../logic/rosario_session.dart';
import '../models/prayer_models.dart';
import '../theme/app_tokens.dart';
import '../theme/seccion_colores.dart';

/// Texto corto que dice en qué parte del rosario se va.
String etiquetaProgreso(PasoRosario paso) => switch (paso.seccion) {
      SeccionRosario.iniciales => 'Oraciones iniciales · ${paso.indiceEnSeccion + 1}/${paso.totalEnSeccion}',
      SeccionRosario.misterio => paso.repeticion == null
          ? 'Misterio ${paso.misterio! + 1}/$misteriosPorRosario'
          : 'Misterio ${paso.misterio! + 1}/$misteriosPorRosario · '
              'Ave María ${paso.repeticion! + 1}/${paso.oracion.count}',
      SeccionRosario.finales => 'Oraciones finales · ${paso.indiceEnSeccion + 1}/${paso.totalEnSeccion}',
    };

/// Etiqueta y barra con el avance del rosario completo.
class ProgresoRosario extends StatelessWidget {
  const ProgresoRosario({super.key, required this.paso, required this.progreso, required this.colores});

  final PasoRosario paso;
  final double progreso;
  final SeccionColores colores;

  @override
  Widget build(BuildContext context) {
    final etiqueta = etiquetaProgreso(paso);
    return Semantics(
      label: 'Progreso del rosario: $etiqueta, ${(progreso * 100).round()} por ciento',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(etiqueta, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: colores.acento)),
          const SizedBox(height: AppTokens.espacioXS),
          LinearProgressIndicator(
            value: progreso,
            minHeight: 6,
            borderRadius: BorderRadius.circular(AppTokens.radioS),
            color: colores.acento,
            backgroundColor: colores.suave,
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Mostrarlo en la pantalla de rezo**

En `lib/screens/rezo_screen.dart`, agregar `import '../widgets/progreso_rosario.dart';` y en `PasoOracionLayout(...)` el parámetro:

```dart
        progreso: ProgresoRosario(paso: paso, progreso: sesion.progreso, colores: colores),
```

En `_Contenido`, borrar el texto que ahora repite la etiqueta de progreso:

```dart
// BORRAR estas líneas dentro de `if (repeticion != null) ...[`
          const SizedBox(height: AppTokens.espacioS),
          Text(
            'Ave María ${repeticion + 1} de ${paso.oracion.count}',
            textAlign: TextAlign.center,
            style: textos.labelLarge?.copyWith(color: colores.acento),
          ),
```

En `test/screens/rezo_screen_test.dart`, en la prueba "Ave María con sus cuentas":

```dart
// ANTES
    expect(find.text('Ave María 1 de 10'), findsOneWidget);
// DESPUÉS
    expect(find.text('Misterio 1/5 · Ave María 1/10'), findsOneWidget);
```

- [ ] **Step 5: Correr y ver que pasa**

Run: `flutter test`
Expected: `All tests passed!`

- [ ] **Step 6: Commit**

Run: `flutter analyze` → sin errores ni advertencias.

```bash
git add lib/widgets/progreso_rosario.dart lib/screens/rezo_screen.dart test
git commit -m "feat: progreso visible del rosario" -m "Etiqueta 'Misterio 2/5 · Ave María 4/10' y barra de avance global, anunciadas al lector de pantalla." -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 24: Cuentas del rosario con el tema y pruebas de accesibilidad

**Files:**
- Rewrite: `lib/widgets/rosary_beads_widget.dart`
- Create: `test/accesibilidad_test.dart`
- Modify: `test/widgets/rosary_beads_widget_test.dart` (agregar una prueba)

**Interfaces:**
- Consumes: `context.secciones` (`cuenta`, `bordeCuenta`) (Tasks 9 y 21); `appDePrueba` (Task 15).
- Produces: `RosaryBeadsWidget` con colores del tema, clave `ValueKey('cuenta-$i')` por cuenta y etiqueta "Ave María n de N" para lector de pantalla.

- [ ] **Step 1: Escribir las pruebas**

Agregar al final de `main()` en `test/widgets/rosary_beads_widget_test.dart`:

```dart
  testWidgets('se anuncia como "Ave María n de 10"', (tester) async {
    final handle = tester.ensureSemantics();
    await mostrar(tester, actual: 3);
    expect(find.bySemanticsLabel('Ave María 4 de 10'), findsOneWidget);
    handle.dispose();
  });
```

`test/accesibilidad_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/app_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> cumpleGuias(WidgetTester tester) async {
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  }

  Future<void> abrirDesdeMenu(WidgetTester tester, String opcion) async {
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text(opcion));
    await tester.pumpAndSettle();
  }

  testWidgets('inicio, rezo, configuración y recordatorios cumplen tamaño táctil y etiquetas', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(await appDePrueba());
    await tester.pumpAndSettle();
    await cumpleGuias(tester);

    await abrirDesdeMenu(tester, 'Configuración');
    await cumpleGuias(tester);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await abrirDesdeMenu(tester, 'Agendar Rosario');
    await cumpleGuias(tester);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Comenzar a Rezar'));
    await tester.pumpAndSettle();
    await cumpleGuias(tester);
    for (var i = 0; i < 5; i++) {
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
    }
    await cumpleGuias(tester); // paso de Ave María con cuentas
    handle.dispose();
  });

  testWidgets('con el texto al 200 % en un teléfono chico se recorre todo el rosario sin cortes', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340); // 360 × 780 dp
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(await appDePrueba(preferencias: {'pref_text_scale': 2.0}));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Comenzar a Rezar'));
    await tester.pumpAndSettle();
    for (var paso = 1; paso < 93; paso++) {
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'paso $paso');
    }
    expect(find.text('Terminar Rosario'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Correr y ver que falla**

Run: `flutter test test/widgets/rosary_beads_widget_test.dart test/accesibilidad_test.dart`
Expected: FAIL — la prueba de las cuentas no encuentra la etiqueta `Ave María 4 de 10`. (Si `accesibilidad_test.dart` también falla, anotar qué guía o qué paso falla: se corrige en el Step 4.)

- [ ] **Step 3: Reescribir las cuentas**

`lib/widgets/rosary_beads_widget.dart`:

```dart
import 'package:flutter/material.dart';

import '../theme/seccion_colores.dart';

/// Diez cuentas: las rezadas se rellenan con el dorado del tema.
class RosaryBeadsWidget extends StatelessWidget {
  const RosaryBeadsWidget({super.key, required this.current, required this.total});

  /// Cuenta actual, empezando en 0.
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final secciones = context.secciones;
    final pendiente = Theme.of(context).colorScheme.outline;
    return Semantics(
      label: 'Ave María ${current + 1} de $total',
      excludeSemantics: true,
      child: Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 6,
          runSpacing: 8,
          children: List.generate(total, (i) {
            final rezada = i <= current;
            return Container(
              key: ValueKey('cuenta-$i'),
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: rezada ? secciones.cuenta : Colors.transparent,
                border: Border.all(color: rezada ? secciones.bordeCuenta : pendiente, width: 2),
              ),
            );
          }),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Correr, corregir lo que falle y volver a correr**

Run: `flutter test`
Expected: `All tests passed!`
Si `accesibilidad_test.dart` falla, el mensaje indica el elemento: un botón de solo ícono sin `tooltip` se arregla agregando `tooltip:`; un objetivo táctil menor a 48 dp se arregla con `minimumSize`/`materialTapTargetSize: MaterialTapTargetSize.padded`; un desborde al 200 % se arregla envolviendo el `Text` en `Flexible`/`Expanded` o permitiendo varias líneas. Cada corrección se repite hasta que pase. No se relajan las pruebas.

- [ ] **Step 5: Commit**

Run: `flutter analyze` → sin errores ni advertencias.

```bash
git add lib test
git commit -m "feat: cuentas del rosario con el tema y pruebas de accesibilidad" -m "Tamaño táctil, etiquetas para lector de pantalla y recorrido completo con texto al 200 % verificados por pruebas." -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 25: Barrido final del diseño y revisión visual con Frontend Design

**Files:**
- Create: `docs/superpowers/revision-visual-2026-11.md` (hallazgos y decisiones)
- Modify: los archivos de `lib/` que salgan en la revisión (cambios pequeños, uno por commit)

**Interfaces:**
- Consumes: toda la app.
- Produces: ningún `Color(0x…)` fuera de `lib/theme/`, ningún `withOpacity`, y el registro de la revisión visual.

- [ ] **Step 1: Barrido automático**

Run:

```bash
grep -rn "Color(0x" lib --include=*.dart | grep -v "^lib/theme/"
grep -rn "withOpacity" lib --include=*.dart
grep -rn "fontSize:.*textScaleFactor" lib --include=*.dart
```

Expected: las tres sin salida (el único uso válido de `textScaleFactor` está en `app.dart` y en el porcentaje de `configuracion_screen.dart`). Cualquier coincidencia se reemplaza por un valor del tema (`colorScheme`, `context.secciones`) o `withValues(alpha: …)`.

- [ ] **Step 2: Revisar en un dispositivo o emulador**

Run: `flutter devices` y luego `flutter run -d <id>` (dispositivo Android real o emulador).
Si no hay ninguno, pedir al usuario que conecte un teléfono con depuración USB o que cree un emulador en Android Studio; esta revisión no se puede hacer solo con pruebas.

Recorrer cada combinación y anotar lo que se vea mal en `docs/superpowers/revision-visual-2026-11.md`, con una tabla `| Pantalla | Tema | Texto | Hallazgo | Decisión |`:

- Pantallas: Inicio, menú lateral, Misterios del día, Rezo (iniciales, anuncio de misterio, Ave María, letanías, último paso), Configuración, Mis recordatorios (vacío y con 2 recordatorios), formulario de recordatorio.
- Temas: claro, oscuro, alto contraste claro, alto contraste oscuro (Configuración → Alto contraste + Tema).
- Texto: 100 % y 200 %; botones normales y grandes.
- Qué buscar (criterios de Frontend Design aplicados a "pulir"): una sola acción principal por pantalla; jerarquía clara (título › encabezado › oración); radios y espacios consistentes (12/16/24 y 8/16/24); degradados del modo oscuro sin verse "lodosos"; texto nunca cortado; los colores de cada sección se reconocen en los cuatro temas; la imagen del inicio no se ve como un recuadro blanco fuera de lugar en oscuro (si se ve mal, decidir con el usuario entre mantener el marco claro o usar `colorScheme.surfaceContainerHighest`).

- [ ] **Step 3: Corregir cada hallazgo**

Por cada hallazgo marcado como "corregir": un cambio pequeño en `lib/theme/` o en el widget afectado, `flutter test` en verde y un commit:

```bash
git add <archivos del cambio>
git commit -m "style: <qué se ajustó y en qué pantalla>" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

Los hallazgos que requieran una decisión de gusto se le presentan al usuario antes de cambiar nada.

- [ ] **Step 4: Cierre de fase**

Run: `flutter analyze && flutter test && flutter build apk --debug`
Expected: sin errores ni advertencias; `All tests passed!`; APK compila.

```bash
git add docs/superpowers/revision-visual-2026-11.md
git commit -m "docs: registro de la revisión visual" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
graphify update .
```

**Cierre de la Fase 4:** cada pantalla revisada en los 4 temas y al 200 % de texto; contraste y accesibilidad verificados por pruebas.
