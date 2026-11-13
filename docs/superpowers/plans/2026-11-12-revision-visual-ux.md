# Revisión visual y de experiencia de uso — Plan de implementación

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Las tareas se ejecutan **en orden numérico**: cada una deja la app compilando y con las pruebas en verde. Para el trabajo visual aplicar también **frontend-design:frontend-design** (la dirección es pulir el estilo actual, sin cambiar la paleta).

**Goal:** Que todo texto se lea en las 4 variantes de tema, que cada pantalla muestre cada dato una sola vez, que nada se corte en ningún teléfono, con letra grande ni en horizontal, y que crear un recordatorio sea simple.

**Architecture:** El orden es: corregir la causa raíz en el tema; reorganizar el rezo en tres zonas (barra de contexto fija, cuerpo desplazable y botones fijos); pasar el formulario de recordatorio a pantalla completa; ajustar el inicio, el menú y la lista. Al final, dos pruebas transversales recorren toda la app con un mismo conjunto de recorridos (`test/support/recorridos_app.dart`): la auditoría de contraste (4 temas) y la matriz responsiva (4 tamaños × 3 escalas de texto).

**Tech Stack:** Flutter 3.47.9 / Dart 3.13.7, provider, flutter_test (guías de accesibilidad, `tester.view`), adb para las capturas en el teléfono.

**Spec:** `docs/superpowers/specs/2026-11-12-revision-visual-ux-design.md`

## Global Constraints

- **Rama:** `mejora-integral` (PR #1 abierto). Cada commit termina con `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. `git push` solo con autorización del usuario.
- **SDK:** Flutter 3.47.9, Dart 3.13.7. **Sin dependencias nuevas.**
- **Colores:** solo en `lib/theme/` (se permite `Colors.transparent`). Contraste mínimo 4.5:1 en texto normal y 3:1 en texto grande (≥ 24 px, o ≥ 18.66 px en negrita), según WCAG.
- **Texto:** el escalado se aplica una sola vez, en `MaterialApp.builder`. Prohibido multiplicar `fontSize` por un factor de escala. Interfaz en español (es-MX).
- **Nombres:** pantallas, widgets, tema y lógica en español; modelos y servicios en inglés.
- **Toques:** 48 dp como mínimo. Ningún botón parte una palabra.
- **Fuera de alcance:** la lógica de recordatorios (IDs, zona horaria, permisos, canales) y los textos de las oraciones.
- **Cierre de cada tarea:** `flutter analyze` termina con `No issues found!` y `flutter test` pasa completo. No se relaja ninguna prueba para que pase y no se usa `// ignore:`.

## Ajustes respecto al spec (decididos al escribir el plan)

1. **La barra del rezo es fija, salvo en tarjetas de menos de 400 dp de alto** (horizontal con letra grande). En ese caso entra al área desplazable, para que el pie con los botones nunca se corte. Se implementa con un `LayoutBuilder` en `PasoOracionLayout`.
2. **Barra superior del formulario.** El título y la etiqueta de "Guardar" usan `FittedBox(fit: BoxFit.scaleDown)`. Así no se parten con letra al 300 % en un teléfono de 360 dp.
3. **`progreso_rosario.dart` desaparece.** Su papel lo toma `lib/widgets/barra_rezo.dart`.
4. **Pruebas que se borran por duplicadas.** `test/rezo_texto_grande_test.dart` y `test/accesibilidad_test.dart` quedan cubiertas por la matriz responsiva de la Task 7, así que se borran en esa tarea.

## Archivos

| Archivo | Responsabilidad |
|---|---|
| `lib/theme/app_theme.dart` | Tema: tamaños M3 con color (Task 1) |
| `lib/widgets/barra_rezo.dart` (nuevo) | `nombreSeccion`, `avanceSeccion`, `BarraRezo`, `confirmarSalida` (Task 2) |
| `lib/widgets/paso_oracion_layout.dart` | Tres zonas: barra, cuerpo desplazable y botones fijos (Task 3) |
| `lib/screens/rezo_screen.dart` | Cuerpo de cada paso sin repeticiones: `tituloAnuncio`, `tituloOracion` (Task 3) |
| `lib/widgets/rosary_beads_widget.dart` | Las cuentas no se anuncian al lector de pantalla (Task 3) |
| `lib/screens/recordatorio_form_screen.dart` (nuevo) | Formulario a pantalla completa (Task 4) |
| `lib/screens/agendar_rosario_screen.dart` | Abre el formulario nuevo; la tarjeta se toca para editar (Tasks 4 y 5) |
| `lib/screens/inicio_screen.dart`, `lib/widgets/app_drawer.dart` | Tarjeta del día que se toca, menú sin duplicado e imagen adaptable (Task 5) |
| `test/support/contraste.dart` (nuevo) | Función `contraste` compartida (Task 1) |
| `test/support/recorridos_app.dart` (nuevo) | Recorridos por toda la app (Task 6) |
| `test/support/auditor_contraste.dart` (nuevo) | `fallasDeContraste` (Task 6) |
| `test/accesibilidad/auditoria_contraste_test.dart` (nuevo) | Auditoría en 4 temas (Task 6) |
| `test/responsivo_test.dart` (nuevo) | Matriz de tamaños y escalas (Task 7) |

---

### Task 1: Los textos del tema vuelven a tener color (H1)

**Files:**
- Modify: `lib/theme/app_theme.dart:32-33`
- Create: `test/support/contraste.dart`
- Modify: `test/theme/contraste_test.dart:7-13` (usa la función compartida)
- Test: `test/theme/app_theme_test.dart`

**Interfaces:**
- Produces: `double contraste(Color a, Color b)` en `test/support/contraste.dart`, que usan las Tasks 6 y 7.

- [ ] **Step 1: Mover la función de contraste a un archivo compartido**

Crear `test/support/contraste.dart`:

```dart
import 'dart:ui';

/// Relación de contraste WCAG 2.1 entre dos colores.
double contraste(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final (claro, oscuro) = la > lb ? (la, lb) : (lb, la);
  return (claro + 0.05) / (oscuro + 0.05);
}
```

En `test/theme/contraste_test.dart`, borrar la función `contraste` local (líneas 7-13) y agregar `import '../support/contraste.dart';`.

- [ ] **Step 2: Escribir la prueba que falla**

Agregar al final de `main()` en `test/theme/app_theme_test.dart`, junto con `import '../support/contraste.dart';`:

```dart
  group('cada estilo de texto del tema tiene color legible (H1)', () {
    final temas = <String, ThemeData>{
      'claro': AppTheme.claro(),
      'oscuro': AppTheme.oscuro(),
      'claro alto contraste': AppTheme.claro(altoContraste: true),
      'oscuro alto contraste': AppTheme.oscuro(altoContraste: true),
    };
    for (final MapEntry(key: nombre, value: tema) in temas.entries) {
      testWidgets(nombre, (tester) async {
        late TextTheme textos;
        await tester.pumpWidget(MaterialApp(
          theme: tema,
          home: Builder(builder: (context) {
            textos = Theme.of(context).textTheme;
            return const SizedBox();
          }),
        ));
        final estilos = <String, TextStyle?>{
          'displayLarge': textos.displayLarge,
          'displayMedium': textos.displayMedium,
          'displaySmall': textos.displaySmall,
          'headlineLarge': textos.headlineLarge,
          'headlineMedium': textos.headlineMedium,
          'headlineSmall': textos.headlineSmall,
          'titleLarge': textos.titleLarge,
          'titleMedium': textos.titleMedium,
          'titleSmall': textos.titleSmall,
          'bodyLarge': textos.bodyLarge,
          'bodyMedium': textos.bodyMedium,
          'bodySmall': textos.bodySmall,
          'labelLarge': textos.labelLarge,
          'labelMedium': textos.labelMedium,
          'labelSmall': textos.labelSmall,
        };
        for (final MapEntry(key: n, value: estilo) in estilos.entries) {
          expect(estilo?.color, isNotNull, reason: '$nombre: $n sin color');
          expect(estilo!.fontSize, isNotNull, reason: '$nombre: $n sin tamaño');
          expect(contraste(estilo.color!, tema.colorScheme.surface), greaterThanOrEqualTo(4.5),
              reason: '$nombre: $n');
        }
      });
    }
  });
```

- [ ] **Step 3: Correr la prueba y ver que falla**

Run: `flutter test test/theme/app_theme_test.dart`
Expected: FAIL con `claro: displayLarge sin color` (y lo mismo en las otras variantes).

- [ ] **Step 4: Corregir el tema**

En `lib/theme/app_theme.dart`, reemplazar:

```dart
      // ThemeData no trae tamaños de letra: se toman de la escala M3 (bodyLarge = 16).
      textTheme: base.textTheme.merge(Typography.englishLike2021),
```

por:

```dart
      // Tamaños de la escala M3 con los colores del tema, en el mismo orden que ThemeData.localize.
      // Al revés (base.merge(englishLike)) se pierde el color: esos estilos tienen inherit: false.
      textTheme: Typography.englishLike2021.merge(base.textTheme),
```

- [ ] **Step 5: Correr las pruebas del tema y la suite completa**

Run: `flutter test test/theme/ && flutter test`
Expected: `All tests passed!`, incluida la prueba existente "el tema no escala el texto" (`bodyLarge.fontSize == 16`).

- [ ] **Step 6: Commit**

```bash
git add lib/theme/app_theme.dart test/support/contraste.dart test/theme/contraste_test.dart test/theme/app_theme_test.dart
git commit -m "fix: los textos del tema vuelven a tener color" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Barra de contexto del rezo

**Files:**
- Create: `lib/widgets/barra_rezo.dart`
- Test: `test/widgets/barra_rezo_test.dart`

**Interfaces:**
- Consumes: `PasoRosario`, `construirPasos()` y `misteriosPorRosario` (de `lib/logic/rosario_session.dart`); `TipoMisterio` (de `lib/models/prayer_models.dart`, con `nombre` y `singular`); `SeccionColores` (con `acento` y `suave`).
- Produces:
  - `String nombreSeccion(PasoRosario paso, TipoMisterio tipo)`
  - `String avanceSeccion(PasoRosario paso)`
  - `BarraRezo({required PasoRosario paso, required TipoMisterio tipo, required double progreso, required SeccionColores colores, required VoidCallback onSalir})`
  - `Future<void> confirmarSalida(BuildContext context, VoidCallback onSalir)`
  - En pantalla, la barra muestra un solo texto `'$seccion · $avance'` (p. ej. `Misterios Gozosos · 1 de 5`).

- [ ] **Step 1: Escribir las pruebas**

`test/widgets/barra_rezo_test.dart`:

```dart
import 'package:app_resar_rosario/logic/rosario_session.dart';
import 'package:app_resar_rosario/models/prayer_models.dart';
import 'package:app_resar_rosario/theme/app_theme.dart';
import 'package:app_resar_rosario/theme/seccion_colores.dart';
import 'package:app_resar_rosario/widgets/barra_rezo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final pasos = construirPasos();

  test('nombre y avance de cada sección', () {
    expect(nombreSeccion(pasos[0], TipoMisterio.gozosos), 'Oraciones iniciales');
    expect(avanceSeccion(pasos[0]), '1 de 3');
    expect(nombreSeccion(pasos[3], TipoMisterio.luminosos), 'Misterios Luminosos');
    expect(avanceSeccion(pasos[3]), '1 de 5');
    expect(avanceSeccion(pasos[14]), '1 de 5');
    expect(avanceSeccion(pasos[19]), '2 de 5');
    expect(avanceSeccion(pasos[67]), '5 de 5');
    expect(nombreSeccion(pasos[83], TipoMisterio.gozosos), 'Oraciones finales');
    expect(avanceSeccion(pasos[83]), '1 de 10');
    expect(avanceSeccion(pasos[92]), '10 de 10');
  });

  Future<List<int>> mostrar(WidgetTester tester) async {
    final salidas = <int>[];
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.claro(),
      home: Scaffold(
        body: BarraRezo(
          paso: pasos[3],
          tipo: TipoMisterio.gozosos,
          progreso: 0.25,
          colores: SeccionesTema.claro.misterio,
          onSalir: () => salidas.add(1),
        ),
      ),
    ));
    return salidas;
  }

  testWidgets('muestra la sección y su avance en un solo texto', (tester) async {
    await mostrar(tester);
    expect(find.text('Misterios Gozosos · 1 de 5'), findsOneWidget);
  });

  testWidgets('anuncia el avance total al lector de pantalla', (tester) async {
    final handle = tester.ensureSemantics();
    await mostrar(tester);
    expect(find.bySemanticsLabel('Progreso del rosario: 25 por ciento'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('el botón de inicio pregunta antes de salir', (tester) async {
    final salidas = await mostrar(tester);

    await tester.tap(find.byTooltip('Volver al inicio'));
    await tester.pumpAndSettle();
    expect(find.text('¿Salir del rosario?'), findsOneWidget);
    expect(find.text('Se perderá el avance de este rosario.'), findsOneWidget);
    await tester.tap(find.text('Seguir rezando'));
    await tester.pumpAndSettle();
    expect(salidas, isEmpty);

    await tester.tap(find.byTooltip('Volver al inicio'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salir'));
    await tester.pumpAndSettle();
    expect(salidas, [1]);
  });
}
```

- [ ] **Step 2: Correr y ver que falla**

Run: `flutter test test/widgets/barra_rezo_test.dart`
Expected: FAIL. No compila porque `barra_rezo.dart` no existe.

- [ ] **Step 3: Implementar**

`lib/widgets/barra_rezo.dart`:

```dart
import 'package:flutter/material.dart';

import '../logic/rosario_session.dart';
import '../models/prayer_models.dart';
import '../theme/app_tokens.dart';
import '../theme/seccion_colores.dart';

/// Nombre de la sección del paso: "Oraciones iniciales", "Misterios Gozosos" u "Oraciones finales".
String nombreSeccion(PasoRosario paso, TipoMisterio tipo) => switch (paso.seccion) {
      SeccionRosario.iniciales => 'Oraciones iniciales',
      SeccionRosario.misterio => 'Misterios ${tipo.nombre}',
      SeccionRosario.finales => 'Oraciones finales',
    };

/// Avance dentro de la sección: la oración en iniciales y finales, el misterio en los misterios.
String avanceSeccion(PasoRosario paso) => switch (paso.seccion) {
      SeccionRosario.misterio => '${paso.misterio! + 1} de $misteriosPorRosario',
      SeccionRosario.iniciales || SeccionRosario.finales => '${paso.indiceEnSeccion + 1} de ${paso.totalEnSeccion}',
    };

/// Contexto del rezo, dicho una sola vez: inicio, sección con su avance y avance del rosario completo.
class BarraRezo extends StatelessWidget {
  const BarraRezo({
    super.key,
    required this.paso,
    required this.tipo,
    required this.progreso,
    required this.colores,
    required this.onSalir,
  });

  final PasoRosario paso;
  final TipoMisterio tipo;

  /// Avance del rosario completo, de 0 a 1.
  final double progreso;
  final SeccionColores colores;

  /// Se llama solo si la persona confirma que quiere salir.
  final VoidCallback onSalir;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => confirmarSalida(context, onSalir),
              icon: const Icon(Icons.home_outlined),
              tooltip: 'Volver al inicio',
              color: colores.acento,
            ),
            const SizedBox(width: AppTokens.espacioXS),
            Expanded(
              child: Text(
                '${nombreSeccion(paso, tipo)} · ${avanceSeccion(paso)}',
                style: textos.titleSmall?.copyWith(color: colores.acento, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.espacioS),
        Semantics(
          label: 'Progreso del rosario: ${(progreso * 100).round()} por ciento',
          excludeSemantics: true,
          child: LinearProgressIndicator(
            value: progreso,
            minHeight: 6,
            borderRadius: BorderRadius.circular(AppTokens.radioS),
            color: colores.acento,
            backgroundColor: colores.suave,
          ),
        ),
      ],
    );
  }
}

/// Pregunta antes de salir del rosario; si se confirma, llama a [onSalir].
Future<void> confirmarSalida(BuildContext context, VoidCallback onSalir) async {
  final salir = await showDialog<bool>(
    context: context,
    builder: (dialogo) => AlertDialog(
      scrollable: true,
      title: const Text('¿Salir del rosario?'),
      content: const Text('Se perderá el avance de este rosario.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogo, false), child: const Text('Seguir rezando')),
        FilledButton(onPressed: () => Navigator.pop(dialogo, true), child: const Text('Salir')),
      ],
    ),
  );
  if (salir ?? false) onSalir();
}
```

- [ ] **Step 4: Correr y ver que pasa**

Run: `flutter test test/widgets/barra_rezo_test.dart && flutter analyze`
Expected: `All tests passed!` y `No issues found!`.

- [ ] **Step 5: Commit**

```bash
git add lib/widgets/barra_rezo.dart test/widgets/barra_rezo_test.dart
git commit -m "feat: barra de contexto del rezo con confirmación al salir" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: Pantalla de rezo sin repeticiones y con botones fijos (H3, H4, H5)

**Files:**
- Modify (reescribir): `lib/widgets/paso_oracion_layout.dart`
- Modify: `lib/screens/rezo_screen.dart` (reemplaza `tituloDelPaso`, `_Encabezado` y `_Contenido`)
- Modify: `lib/widgets/rosary_beads_widget.dart` (semántica)
- Delete: `lib/widgets/progreso_rosario.dart`, `test/widgets/progreso_rosario_test.dart`
- Test:
  - `test/screens/rezo_screen_test.dart` (reescribir);
  - `test/recorrido_completo_test.dart` (hitos nuevos);
  - `test/screens/principal_screen_test.dart` (confirmación al salir);
  - `test/widgets/rosary_beads_widget_test.dart` (semántica).

**Interfaces:**
- Consumes (Task 2): `BarraRezo`, `nombreSeccion` y `avanceSeccion`.
- Produces:
  - `PasoOracionLayout({required SeccionColores colores, required Widget barra, required Widget cuerpo, required VoidCallback onSiguiente, VoidCallback? onAnterior, String textoSiguiente = 'Continuar', Key? claveCuerpo})`, con la constante `PasoOracionLayout.altoMinimoBarraFija = 400`.
  - `String tituloAnuncio(PasoRosario paso, TipoMisterio tipo)`, que da `'2.º Misterio Luminoso'`.
  - `String tituloOracion(PasoRosario paso)`, que da `'Ave María · 3 de 10'`.
  - El botón para retroceder es un `IconButton.outlined` con tooltip `'Paso anterior'`.

- [ ] **Step 1: Reescribir las pruebas de la pantalla de rezo**

`test/screens/rezo_screen_test.dart`. Se conserva el ayudante `mostrarEnPaso` y se reemplazan las pruebas:

```dart
import 'package:app_resar_rosario/logic/rosario_session.dart';
import 'package:app_resar_rosario/models/prayer_models.dart';
import 'package:app_resar_rosario/screens/rezo_screen.dart';
import 'package:app_resar_rosario/widgets/barra_rezo.dart';
import 'package:app_resar_rosario/widgets/rosary_beads_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<RosarioSession> mostrarEnPaso(WidgetTester tester, int indice) async {
    final sesion = RosarioSession(reloj: () => lunes)..comenzar();
    for (var i = 0; i < indice; i++) {
      sesion.siguiente();
    }
    await tester.pumpWidget(envolver(const RezoScreen(), preferencias: await preferenciasDePrueba(), sesion: sesion));
    await tester.pumpAndSettle();
    return sesion;
  }

  test('títulos del anuncio y de la oración', () {
    final pasos = construirPasos();
    expect(tituloAnuncio(pasos[19], TipoMisterio.luminosos), '2.º Misterio Luminoso');
    expect(tituloOracion(pasos[0]), 'Señal de la Cruz');
    expect(tituloOracion(pasos[7]), 'Ave María · 3 de 10');
  });

  testWidgets('primer paso: oraciones iniciales, sin botón para retroceder', (tester) async {
    await mostrarEnPaso(tester, 0);
    expect(find.text('Oraciones iniciales · 1 de 3'), findsOneWidget);
    expect(find.text('Señal de la Cruz'), findsOneWidget);
    expect(find.byTooltip('Paso anterior'), findsNothing);
  });

  testWidgets('Continuar avanza y aparece el botón para retroceder', (tester) async {
    await mostrarEnPaso(tester, 0);
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('Acto de contrición'), findsOneWidget);
    await tester.tap(find.byTooltip('Paso anterior'));
    await tester.pumpAndSettle();
    expect(find.text('Señal de la Cruz'), findsOneWidget);
  });

  testWidgets('anuncio del primer misterio: cada dato una vez', (tester) async {
    await mostrarEnPaso(tester, 3);
    expect(find.text('Misterios Gozosos · 1 de 5'), findsOneWidget);
    expect(find.text('1.º Misterio Gozoso'), findsOneWidget);
    expect(find.text('Medita en este misterio.'), findsOneWidget);
    expect(find.text('La Encarnación del Hijo de Dios'), findsOneWidget);
  });

  testWidgets('Ave María: título con su número, cuentas y el misterio como recordatorio', (tester) async {
    await mostrarEnPaso(tester, 5);
    expect(find.text('Ave María · 1 de 10'), findsOneWidget);
    expect(find.text('La Encarnación del Hijo de Dios'), findsOneWidget);
    expect(find.byType(RosaryBeadsWidget), findsOneWidget);
  });

  testWidgets('cada paso muestra cada dato una sola vez (los 93)', (tester) async {
    final sesion = await mostrarEnPaso(tester, 0);
    for (var i = 0; i < 93; i++) {
      final paso = sesion.pasoActual;
      expect(find.textContaining(nombreSeccion(paso, sesion.tipoMisterio)), findsOneWidget, reason: 'paso $i: sección');
      expect(find.textContaining(avanceSeccion(paso)), findsOneWidget, reason: 'paso $i: avance');
      if (paso.seccion == SeccionRosario.misterio) {
        expect(find.textContaining(sesion.tituloMisterioActual), findsOneWidget, reason: 'paso $i: misterio');
      }
      if (paso.repeticion != null) {
        expect(find.textContaining('${paso.repeticion! + 1} de 10'), findsOneWidget, reason: 'paso $i: Ave María');
      }
      if (i < 92) {
        sesion.siguiente();
        await tester.pumpAndSettle();
      }
    }
  });

  testWidgets('el último paso dice Terminar Rosario y regresa al inicio', (tester) async {
    final sesion = await mostrarEnPaso(tester, 92);
    expect(find.text('Dulce Madre'), findsOneWidget);
    await tester.tap(find.text('Terminar Rosario'));
    await tester.pumpAndSettle();
    expect(sesion.enInicio, isTrue);
  });

  testWidgets('volver al inicio pide confirmación', (tester) async {
    final sesion = await mostrarEnPaso(tester, 10);
    await tester.tap(find.byTooltip('Volver al inicio'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Seguir rezando'));
    await tester.pumpAndSettle();
    expect(sesion.indice, 10);

    await tester.tap(find.byTooltip('Volver al inicio'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salir'));
    await tester.pumpAndSettle();
    expect(sesion.enInicio, isTrue);
  });

  testWidgets('al avanzar, el texto vuelve arriba', (tester) async {
    final sesion = await mostrarEnPaso(tester, 83); // letanías: texto largo
    final desplazable = find.byType(Scrollable).first;
    await tester.drag(desplazable, const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(tester.state<ScrollableState>(desplazable).position.pixels, greaterThan(0));
    sesion.siguiente();
    await tester.pumpAndSettle();
    expect(tester.state<ScrollableState>(find.byType(Scrollable).first).position.pixels, 0);
  });

  testWidgets('el botón Atrás del sistema retrocede un paso', (tester) async {
    final sesion = await mostrarEnPaso(tester, 2);
    await tester.state<NavigatorState>(find.byType(Navigator)).maybePop();
    await tester.pumpAndSettle();
    expect(sesion.indice, 1);
  });
}
```

En `test/recorrido_completo_test.dart`, reemplazar el mapa `hitos` y su comprobación:

```dart
    // Momentos clave del recorrido: índice del paso → textos que deben verse una vez.
    const hitos = <int, List<String>>{
      0: ['Oraciones iniciales · 1 de 3', 'Señal de la Cruz'],
      3: ['Misterios Gozosos · 1 de 5', '1.º Misterio Gozoso'],
      5: ['Misterios Gozosos · 1 de 5', 'Ave María · 1 de 10'],
      14: ['Misterios Gozosos · 1 de 5', 'Ave María · 10 de 10'],
      19: ['Misterios Gozosos · 2 de 5', '2.º Misterio Gozoso'],
      67: ['Misterios Gozosos · 5 de 5', '5.º Misterio Gozoso'],
      83: ['Oraciones finales · 1 de 10', 'Letanías de la Santísima Virgen'],
      92: ['Oraciones finales · 10 de 10', 'Dulce Madre'],
    };

    for (var paso = 0; paso < 93; paso++) {
      for (final esperado in hitos[paso] ?? const <String>[]) {
        expect(find.text(esperado), findsOneWidget, reason: 'paso $paso: $esperado');
      }
      await tester.tap(find.text(paso == 92 ? 'Terminar Rosario' : 'Continuar'));
      await tester.pumpAndSettle();
    }
```

En `test/screens/principal_screen_test.dart`:
- reemplazar `expect(find.text('Oraciones Iniciales'), findsOneWidget);` por `expect(find.text('Oraciones iniciales · 1 de 3'), findsOneWidget);`;
- después del toque en `'Volver al inicio'`, agregar la confirmación:

```dart
    await tester.tap(find.byTooltip('Volver al inicio'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salir'));
    await tester.pumpAndSettle();
    expect(find.text('Comenzar a Rezar'), findsOneWidget);
```

En `test/widgets/rosary_beads_widget_test.dart`, reemplazar la prueba `se anuncia como "Ave María n de 10"` por:

```dart
  testWidgets('las cuentas no se anuncian: el número ya está en el título de la oración', (tester) async {
    final handle = tester.ensureSemantics();
    await mostrar(tester, actual: 3); // ayudante que ya existe en el archivo
    expect(find.bySemanticsLabel(RegExp('Ave María')), findsNothing);
    handle.dispose();
  });
```

Borrar `test/widgets/progreso_rosario_test.dart`.

- [ ] **Step 2: Correr y ver que fallan**

Run: `flutter test test/screens/rezo_screen_test.dart test/recorrido_completo_test.dart test/screens/principal_screen_test.dart test/widgets/rosary_beads_widget_test.dart`
Expected: FAIL. No compilan `tituloAnuncio` ni `tituloOracion`, y faltan textos como `'Oraciones iniciales · 1 de 3'`.

- [ ] **Step 3: Reescribir `PasoOracionLayout`**

`lib/widgets/paso_oracion_layout.dart` completo:

```dart
import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../theme/seccion_colores.dart';

/// Estructura de cada paso del rezo: el fondo de la sección y una tarjeta con la [barra] arriba,
/// el [cuerpo] que se desplaza y los botones fijos abajo.
class PasoOracionLayout extends StatelessWidget {
  const PasoOracionLayout({
    super.key,
    required this.colores,
    required this.barra,
    required this.cuerpo,
    required this.onSiguiente,
    this.onAnterior,
    this.textoSiguiente = 'Continuar',
    this.claveCuerpo,
  });

  /// Con menos alto que esto (horizontal con letra grande), la barra se desplaza junto con el cuerpo
  /// para que los botones nunca se corten.
  static const double altoMinimoBarraFija = 400;

  final SeccionColores colores;
  final Widget barra;

  /// Contenido del paso. No debe tener su propio desplazamiento: el layout ya lo da.
  final Widget cuerpo;
  final VoidCallback onSiguiente;

  /// Si es `null`, no se muestra el botón para retroceder.
  final VoidCallback? onAnterior;
  final String textoSiguiente;

  /// Cambia en cada paso para que el cuerpo empiece arriba.
  final Key? claveCuerpo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: colores.fondo),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppTokens.anchoMaximo),
              child: Padding(
                padding: const EdgeInsets.all(AppTokens.espacioM),
                child: Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(AppTokens.espacioL),
                    child: LayoutBuilder(
                      builder: (context, limites) {
                        final barraFija = limites.maxHeight >= altoMinimoBarraFija;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (barraFija) ...[barra, const SizedBox(height: AppTokens.espacioM)],
                            Expanded(
                              child: SingleChildScrollView(
                                key: claveCuerpo,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    if (!barraFija) ...[barra, const SizedBox(height: AppTokens.espacioM)],
                                    cuerpo,
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: AppTokens.espacioM),
                            _Botones(
                              colores: colores,
                              onAnterior: onAnterior,
                              onSiguiente: onSiguiente,
                              texto: textoSiguiente,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Botón cuadrado para retroceder y botón principal que ocupa el resto. Las etiquetas no se parten:
/// si no caben, se reducen.
class _Botones extends StatelessWidget {
  const _Botones({required this.colores, required this.onAnterior, required this.onSiguiente, required this.texto});

  final SeccionColores colores;
  final VoidCallback? onAnterior;
  final VoidCallback onSiguiente;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final alto =
        Theme.of(context).filledButtonTheme.style?.minimumSize?.resolve(const <WidgetState>{})?.height ??
            AppTokens.botonNormal;
    return Row(
      children: [
        if (onAnterior != null) ...[
          IconButton.outlined(
            onPressed: onAnterior,
            tooltip: 'Paso anterior',
            icon: const Icon(Icons.chevron_left),
            style: IconButton.styleFrom(
              minimumSize: Size.square(alto),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radioM)),
            ),
          ),
          const SizedBox(width: AppTokens.espacioM),
        ],
        Expanded(
          child: FilledButton(
            onPressed: onSiguiente,
            style: FilledButton.styleFrom(backgroundColor: colores.boton, foregroundColor: colores.sobreBoton),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(texto, maxLines: 1),
                  const SizedBox(width: AppTokens.espacioS),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: Reescribir la pantalla de rezo**

`lib/screens/rezo_screen.dart` completo:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../logic/rosario_session.dart';
import '../models/prayer_models.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../theme/seccion_colores.dart';
import '../widgets/barra_rezo.dart';
import '../widgets/letanias_widget.dart';
import '../widgets/paso_oracion_layout.dart';
import '../widgets/rosary_beads_widget.dart';

/// Pantalla única para todo el recorrido del rosario.
class RezoScreen extends StatelessWidget {
  const RezoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sesion = context.watch<RosarioSession>();
    // Durante la transición de salida la sesión ya volvió al inicio.
    if (sesion.enInicio) return const Scaffold();

    final paso = sesion.pasoActual;
    final colores = context.coloresDe(paso.seccion);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) sesion.anterior();
      },
      child: PasoOracionLayout(
        colores: colores,
        barra: BarraRezo(
          paso: paso,
          tipo: sesion.tipoMisterio,
          progreso: sesion.progreso,
          colores: colores,
          onSalir: sesion.reiniciar,
        ),
        cuerpo: _Cuerpo(paso: paso, sesion: sesion, colores: colores),
        claveCuerpo: ValueKey(sesion.indice),
        onAnterior: sesion.indice > 0 ? sesion.anterior : null,
        onSiguiente: () {
          HapticFeedback.selectionClick();
          sesion.siguiente();
        },
        textoSiguiente: sesion.esUltimo ? 'Terminar Rosario' : 'Continuar',
      ),
    );
  }
}

/// Título del anuncio de un misterio: "2.º Misterio Luminoso".
String tituloAnuncio(PasoRosario paso, TipoMisterio tipo) => '${paso.misterio! + 1}.º Misterio ${tipo.singular}';

/// Título de la oración del paso; durante la decena lleva el número: "Ave María · 3 de 10".
String tituloOracion(PasoRosario paso) => paso.repeticion == null
    ? paso.oracion.title
    : '${paso.oracion.title} · ${paso.repeticion! + 1} de ${paso.oracion.count}';

class _Cuerpo extends StatelessWidget {
  const _Cuerpo({required this.paso, required this.sesion, required this.colores});

  final PasoRosario paso;
  final RosarioSession sesion;
  final SeccionColores colores;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final titulo = textos.titleLarge?.copyWith(fontWeight: FontWeight.w600);

    if (paso.esAnuncioDeMisterio) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppTokens.espacioS),
          Icon(Icons.auto_awesome, size: 32, color: colores.acento),
          const SizedBox(height: AppTokens.espacioM),
          Text(
            tituloAnuncio(paso, sesion.tipoMisterio),
            textAlign: TextAlign.center,
            style: titulo?.copyWith(color: colores.acento),
          ),
          const SizedBox(height: AppTokens.espacioL),
          Text(
            sesion.tituloMisterioActual,
            textAlign: TextAlign.center,
            style: AppTheme.oracion(context).copyWith(fontSize: 22),
          ),
          const SizedBox(height: AppTokens.espacioL),
          Text(
            'Medita en este misterio.',
            textAlign: TextAlign.center,
            style: textos.bodyLarge?.copyWith(
              fontStyle: FontStyle.italic,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (paso.seccion == SeccionRosario.misterio) ...[
          _RecordatorioMisterio(nombre: sesion.tituloMisterioActual, colores: colores),
          const SizedBox(height: AppTokens.espacioM),
        ],
        Text(tituloOracion(paso), style: titulo),
        if (paso.repeticion != null) ...[
          const SizedBox(height: AppTokens.espacioM),
          RosaryBeadsWidget(current: paso.repeticion!, total: paso.oracion.count!),
        ],
        const SizedBox(height: AppTokens.espacioM),
        if (paso.oracion.type == 'letanias')
          LetaniasWidget(texto: paso.oracion.text, colores: colores)
        else
          Text(paso.oracion.text, style: AppTheme.oracion(context)),
      ],
    );
  }
}

/// Línea pequeña con el misterio que se está meditando.
class _RecordatorioMisterio extends StatelessWidget {
  const _RecordatorioMisterio({required this.nombre, required this.colores});

  final String nombre;
  final SeccionColores colores;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.auto_awesome, size: 18, color: colores.acento),
        const SizedBox(width: AppTokens.espacioS),
        Expanded(
          child: Text(nombre, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colores.acento)),
        ),
      ],
    );
  }
}
```

- [ ] **Step 5: Las cuentas dejan de anunciarse**

En `lib/widgets/rosary_beads_widget.dart`, reemplazar el `Semantics(label: ..., excludeSemantics: true, child: ...)` por `ExcludeSemantics(child: ...)` y actualizar el comentario de la clase:

```dart
/// Diez cuentas: las rezadas se rellenan con el dorado del tema. Son decorativas para el lector
/// de pantalla: el número ya se anuncia en el título de la oración.
```

- [ ] **Step 6: Borrar el progreso viejo**

Borrar `lib/widgets/progreso_rosario.dart`. Run: `grep -rn "progreso_rosario\|ProgresoRosario\|etiquetaProgreso\|tituloDelPaso" lib test`
Expected: sin coincidencias.

- [ ] **Step 7: Correr las pruebas**

Run: `flutter test test/screens/ test/widgets/ test/recorrido_completo_test.dart test/rezo_texto_grande_test.dart test/accesibilidad_test.dart && flutter analyze`
Expected: `All tests passed!` y `No issues found!`. `rezo_texto_grande_test.dart` sigue buscando el `FilledButton` dentro de la primera `Card` y debe pasar sin cambios.

- [ ] **Step 8: Suite completa y commit**

Run: `flutter test`
Expected: `All tests passed!`.

```bash
git add -A lib/widgets lib/screens/rezo_screen.dart test
git commit -m "feat: rezo con cada dato una sola vez y botones fijos sin cortes" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: Formulario de recordatorio a pantalla completa (H6)

**Files:**
- Create: `lib/screens/recordatorio_form_screen.dart`
- Delete: `lib/widgets/reminder_form.dart`, `test/widgets/reminder_form_test.dart`
- Modify: `lib/screens/agendar_rosario_screen.dart` (`_abrirFormulario`)
- Test: `test/screens/recordatorio_form_screen_test.dart` (nuevo) y `test/screens/agendar_rosario_screen_test.dart` (sin cambios de lógica; debe seguir pasando)

**Interfaces:**
- Consumes:
  - `RosarioReminder` (con `id`, `title`, `description`, `time`, `daysOfWeek`, `isActive`, `type` y `createdAt`);
  - `ReminderType` (con `displayName`, `description` e `icon`);
  - `ReminderTemplates.templates` y `ReminderTemplate` (con `title`, `description`, `time`, `daysOfWeek` y `type`).
- Produces:
  - `RecordatorioFormScreen({RosarioReminder? recordatorio})`.
  - `static Future<RosarioReminder?> RecordatorioFormScreen.abrir(BuildContext context, {RosarioReminder? recordatorio})`.
  - Textos fijos que buscan las pruebas: `'Nuevo recordatorio'`, `'Editar recordatorio'`, `'Guardar'`, el tooltip `'Cerrar'`, `'Plantillas'`, `'Hora'`, `'Toca para cambiarla'`, `'Repetir'`, `'Diario'`, `'Entre semana'`, `'Fin de semana'`, `'Tipo'`, `'Título'`, `'Elige al menos un día'`, `'Escribe un título'`, `'¿Descartar los cambios?'`, `'Seguir editando'` y `'Descartar'`.
  - Días: botones con las letras `L M X J V S D` y el nombre completo como tooltip.

- [ ] **Step 1: Escribir las pruebas**

`test/screens/recordatorio_form_screen_test.dart`:

```dart
import 'package:app_resar_rosario/models/reminder_model.dart';
import 'package:app_resar_rosario/screens/recordatorio_form_screen.dart';
import 'package:app_resar_rosario/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// Abre el formulario desde una pantalla vacía y guarda lo que devuelve al cerrarse.
  Future<List<RosarioReminder?>> abrir(WidgetTester tester, {RosarioReminder? recordatorio}) async {
    final resultados = <RosarioReminder?>[];
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.claro(),
      locale: const Locale('es', 'MX'),
      supportedLocales: const [Locale('es', 'MX')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () async =>
                  resultados.add(await RecordatorioFormScreen.abrir(context, recordatorio: recordatorio)),
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    return resultados;
  }

  Future<void> tocar(WidgetTester tester, Finder objetivo) async {
    await tester.ensureVisible(objetivo);
    await tester.pumpAndSettle();
    await tester.tap(objetivo);
    await tester.pumpAndSettle();
  }

  final existente = RosarioReminder(
    id: 5,
    title: 'Mañana',
    description: 'd',
    time: const TimeOfDay(hour: 6, minute: 15),
    daysOfWeek: const [2],
    isActive: false,
    type: ReminderType.notification,
    createdAt: DateTime(2026, 1, 1),
  );

  testWidgets('sin días no guarda y lo indica', (tester) async {
    final resultados = await abrir(tester);
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('Elige al menos un día'), findsOneWidget);
    expect(resultados, isEmpty);
  });

  testWidgets('sin título no guarda y lo indica', (tester) async {
    final resultados = await abrir(tester);
    await tocar(tester, find.text('L'));
    await tester.enterText(find.byType(TextFormField), '   ');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('Escribe un título'), findsOneWidget);
    expect(resultados, isEmpty);
  });

  testWidgets('guarda con los días y el tipo elegidos', (tester) async {
    final resultados = await abrir(tester);
    await tocar(tester, find.text('L'));
    await tocar(tester, find.text('X'));
    await tocar(tester, find.text('Alarma'));
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    final r = resultados.single!;
    expect(r.title, 'Rezar el Santo Rosario');
    expect(r.daysOfWeek, [1, 3]);
    expect(r.type, ReminderType.alarm);
    expect(r.time, const TimeOfDay(hour: 19, minute: 0));
    expect(r.isActive, isTrue);
  });

  testWidgets('el atajo Entre semana marca de lunes a viernes', (tester) async {
    final resultados = await abrir(tester);
    await tocar(tester, find.text('Entre semana'));
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(resultados.single!.daysOfWeek, [1, 2, 3, 4, 5]);
  });

  testWidgets('una plantilla llena el formulario', (tester) async {
    final resultados = await abrir(tester);
    await tocar(tester, find.text('Rosario Matutino'));
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    final r = resultados.single!;
    expect(r.title, 'Rosario Matutino');
    expect(r.description, 'Momento perfecto para comenzar el día con oración');
    expect(r.time, const TimeOfDay(hour: 7, minute: 0));
    expect(r.daysOfWeek, [1, 2, 3, 4, 5, 6, 7]);
    expect(r.type, ReminderType.notification);
  });

  testWidgets('al editar conserva el ID y los datos, y no muestra plantillas', (tester) async {
    final resultados = await abrir(tester, recordatorio: existente);
    expect(find.text('Editar recordatorio'), findsOneWidget);
    expect(find.text('Plantillas'), findsNothing);
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    final r = resultados.single!;
    expect([r.id, r.title, r.daysOfWeek, r.isActive], [5, 'Mañana', [2], false]);
  });

  testWidgets('cerrar sin cambios no pregunta', (tester) async {
    final resultados = await abrir(tester);
    await tester.tap(find.byTooltip('Cerrar'));
    await tester.pumpAndSettle();
    expect(find.text('¿Descartar los cambios?'), findsNothing);
    expect(find.text('Abrir'), findsOneWidget);
    expect(resultados, [null]);
  });

  testWidgets('cerrar con cambios pregunta antes de descartar', (tester) async {
    final resultados = await abrir(tester);
    await tocar(tester, find.text('L'));
    await tester.tap(find.byTooltip('Cerrar'));
    await tester.pumpAndSettle();
    expect(find.text('¿Descartar los cambios?'), findsOneWidget);

    await tester.tap(find.text('Seguir editando'));
    await tester.pumpAndSettle();
    expect(find.text('Nuevo recordatorio'), findsOneWidget);

    await tester.tap(find.byTooltip('Cerrar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Descartar'));
    await tester.pumpAndSettle();
    expect(find.text('Abrir'), findsOneWidget);
    expect(resultados, [null]);
  });

  testWidgets('la hora se anuncia y se puede tocar para cambiarla', (tester) async {
    final handle = tester.ensureSemantics();
    await abrir(tester);
    expect(find.bySemanticsLabel(RegExp(r'^Hora: .+\. Toca para cambiarla$')), findsOneWidget);
    await tocar(tester, find.text('Toca para cambiarla'));
    expect(find.byType(TimePickerDialog), findsOneWidget);
    handle.dispose();
  });
}
```

- [ ] **Step 2: Correr y ver que falla**

Run: `flutter test test/screens/recordatorio_form_screen_test.dart`
Expected: FAIL. No compila porque `recordatorio_form_screen.dart` no existe.

- [ ] **Step 3: Implementar la pantalla**

`lib/screens/recordatorio_form_screen.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/reminder_model.dart';
import '../theme/app_tokens.dart';

const _diasSemana = [
  (1, 'L', 'Lunes'),
  (2, 'M', 'Martes'),
  (3, 'X', 'Miércoles'),
  (4, 'J', 'Jueves'),
  (5, 'V', 'Viernes'),
  (6, 'S', 'Sábado'),
  (7, 'D', 'Domingo'),
];

const _atajos = <(String, Set<int>)>[
  ('Diario', {1, 2, 3, 4, 5, 6, 7}),
  ('Entre semana', {1, 2, 3, 4, 5}),
  ('Fin de semana', {6, 7}),
];

/// Crear o editar un recordatorio a pantalla completa. Devuelve el recordatorio guardado, o `null` si se cierra.
class RecordatorioFormScreen extends StatefulWidget {
  const RecordatorioFormScreen({super.key, this.recordatorio});

  final RosarioReminder? recordatorio;

  static Future<RosarioReminder?> abrir(BuildContext context, {RosarioReminder? recordatorio}) {
    return Navigator.of(context).push<RosarioReminder>(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => RecordatorioFormScreen(recordatorio: recordatorio),
    ));
  }

  @override
  State<RecordatorioFormScreen> createState() => _RecordatorioFormScreenState();
}

/// Lo que se puede editar, para saber si hubo cambios.
@immutable
class _Valores {
  const _Valores(this.titulo, this.hora, this.dias, this.tipo, this.descripcion);

  final String titulo;
  final TimeOfDay hora;
  final Set<int> dias;
  final ReminderType tipo;
  final String descripcion;

  @override
  bool operator ==(Object other) =>
      other is _Valores &&
      other.titulo == titulo &&
      other.hora == hora &&
      setEquals(other.dias, dias) &&
      other.tipo == tipo &&
      other.descripcion == descripcion;

  @override
  int get hashCode => Object.hash(titulo, hora, Object.hashAllUnordered(dias), tipo, descripcion);
}

class _RecordatorioFormScreenState extends State<RecordatorioFormScreen> {
  final _formulario = GlobalKey<FormState>();
  final _claveDias = GlobalKey();
  final _claveTitulo = GlobalKey();
  late final TextEditingController _titulo =
      TextEditingController(text: widget.recordatorio?.title ?? 'Rezar el Santo Rosario');
  late TimeOfDay _hora = widget.recordatorio?.time ?? const TimeOfDay(hour: 19, minute: 0);
  late final Set<int> _dias = {...?widget.recordatorio?.daysOfWeek};
  late ReminderType _tipo = widget.recordatorio?.type ?? ReminderType.notification;
  late String _descripcion = widget.recordatorio?.description ?? 'Es hora de tu oración. El Señor está contigo.';
  late final _Valores _inicial;
  bool _faltanDias = false;

  /// Ya se guardó o se confirmó el descarte: se puede cerrar sin preguntar.
  bool _cerrando = false;

  @override
  void initState() {
    super.initState();
    _inicial = _valores();
    _titulo.addListener(_redibujar);
  }

  @override
  void dispose() {
    _titulo
      ..removeListener(_redibujar)
      ..dispose();
    super.dispose();
  }

  void _redibujar() => setState(() {});

  _Valores _valores() => _Valores(_titulo.text, _hora, {..._dias}, _tipo, _descripcion);

  bool get _hayCambios => _valores() != _inicial;

  Future<void> _elegirHora() async {
    final hora = await showTimePicker(context: context, initialTime: _hora);
    if (hora != null) setState(() => _hora = hora);
  }

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

  void _cambiarDias(Set<int> dias) => setState(() {
        _dias
          ..clear()
          ..addAll(dias);
        _faltanDias = false;
      });

  void _guardar() {
    final tituloValido = _formulario.currentState!.validate();
    setState(() => _faltanDias = _dias.isEmpty);
    if (_dias.isEmpty || !tituloValido) {
      HapticFeedback.heavyImpact();
      final clave = _dias.isEmpty ? _claveDias : _claveTitulo;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final destino = clave.currentContext;
        if (destino != null) Scrollable.ensureVisible(destino, duration: const Duration(milliseconds: 300));
      });
      return;
    }
    _cerrando = true;
    Navigator.of(context).pop(RosarioReminder(
      id: widget.recordatorio?.id ?? 0,
      title: _titulo.text.trim(),
      description: _descripcion,
      time: _hora,
      daysOfWeek: _dias.toList()..sort(),
      isActive: widget.recordatorio?.isActive ?? true,
      type: _tipo,
      createdAt: widget.recordatorio?.createdAt ?? DateTime.now(),
    ));
  }

  Future<bool> _confirmarDescarte() async {
    final descartar = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        scrollable: true,
        title: const Text('¿Descartar los cambios?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogo, false), child: const Text('Seguir editando')),
          FilledButton(onPressed: () => Navigator.pop(dialogo, true), child: const Text('Descartar')),
        ],
      ),
    );
    return descartar ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final esquema = Theme.of(context).colorScheme;
    final nuevo = widget.recordatorio == null;

    return PopScope<RosarioReminder>(
      canPop: _cerrando || !_hayCambios,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navegador = Navigator.of(context);
        if (await _confirmarDescarte()) {
          _cerrando = true;
          navegador.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Cerrar',
            onPressed: () => Navigator.maybePop(context),
          ),
          title: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(nuevo ? 'Nuevo recordatorio' : 'Editar recordatorio'),
          ),
          actions: [
            Padding(
              padding: const EdgeInsetsDirectional.only(end: AppTokens.espacioS),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 160),
                child: FilledButton(
                  onPressed: _guardar,
                  child: const FittedBox(fit: BoxFit.scaleDown, child: Text('Guardar', maxLines: 1)),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: Form(
            key: _formulario,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTokens.espacioM),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: AppTokens.anchoMaximo),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (nuevo) ...[
                        const _Titulo('Plantillas'),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final plantilla in ReminderTemplates.templates)
                                Padding(
                                  padding: const EdgeInsetsDirectional.only(end: AppTokens.espacioS),
                                  child: ActionChip(
                                    avatar: Icon(plantilla.type.icon, size: 18),
                                    label: Text(plantilla.title),
                                    onPressed: () => _aplicar(plantilla),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppTokens.espacioL),
                      ],
                      _SelectorHora(hora: _hora, onTap: _elegirHora),
                      const SizedBox(height: AppTokens.espacioL),
                      _Titulo('Repetir', key: _claveDias),
                      _SelectorDias(
                        dias: _dias,
                        onCambio: (dia, marcado) => _cambiarDias(marcado ? {..._dias, dia} : ({..._dias}..remove(dia))),
                      ),
                      const SizedBox(height: AppTokens.espacioS),
                      Wrap(
                        spacing: AppTokens.espacioS,
                        runSpacing: AppTokens.espacioS,
                        children: [
                          for (final (nombre, conjunto) in _atajos)
                            ChoiceChip(
                              label: Text(nombre),
                              selected: setEquals(_dias, conjunto),
                              onSelected: (_) => _cambiarDias(conjunto),
                            ),
                        ],
                      ),
                      if (_faltanDias) ...[
                        const SizedBox(height: AppTokens.espacioS),
                        Text('Elige al menos un día', style: textos.bodyMedium?.copyWith(color: esquema.error)),
                      ],
                      const SizedBox(height: AppTokens.espacioL),
                      const _Titulo('Tipo'),
                      SegmentedButton<ReminderType>(
                        segments: [
                          for (final tipo in ReminderType.values)
                            ButtonSegment(
                              value: tipo,
                              icon: Icon(tipo.icon),
                              label: FittedBox(fit: BoxFit.scaleDown, child: Text(tipo.displayName, maxLines: 1)),
                            ),
                        ],
                        selected: {_tipo},
                        onSelectionChanged: (seleccion) => setState(() => _tipo = seleccion.first),
                      ),
                      const SizedBox(height: AppTokens.espacioS),
                      Text(_tipo.description, style: textos.bodyMedium?.copyWith(color: esquema.onSurfaceVariant)),
                      const SizedBox(height: AppTokens.espacioL),
                      TextFormField(
                        key: _claveTitulo,
                        controller: _titulo,
                        maxLength: 50,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Título',
                          prefixIcon: Icon(Icons.edit_outlined),
                          border: OutlineInputBorder(),
                          counterText: '',
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Escribe un título' : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Titulo extends StatelessWidget {
  const _Titulo(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.espacioS),
      child: Text(
        texto,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}

/// La hora en grande; toda la tarjeta abre el selector.
class _SelectorHora extends StatelessWidget {
  const _SelectorHora({required this.hora, required this.onTap});

  final TimeOfDay hora;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final esquema = Theme.of(context).colorScheme;
    final texto = hora.format(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Semantics(
        button: true,
        label: 'Hora: $texto. Toca para cambiarla',
        excludeSemantics: true,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.espacioM),
            child: Column(
              children: [
                Text('Hora', style: textos.titleSmall?.copyWith(color: esquema.primary)),
                const SizedBox(height: AppTokens.espacioXS),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(texto, maxLines: 1, style: textos.displayMedium?.copyWith(color: esquema.onSurface)),
                ),
                Text('Toca para cambiarla', style: textos.bodySmall?.copyWith(color: esquema.onSurfaceVariant)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Siete botones circulares iguales; si no caben a 48 dp en una fila, se reparten en dos.
class _SelectorDias extends StatelessWidget {
  const _SelectorDias({required this.dias, required this.onCambio});

  final Set<int> dias;
  final void Function(int dia, bool marcado) onCambio;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, limites) {
        final porFila = limites.maxWidth / 7 >= 48 ? 7 : 4;
        final ancho = limites.maxWidth / porFila;
        return Wrap(
          runSpacing: AppTokens.espacioS,
          children: [
            for (final (dia, letra, nombre) in _diasSemana)
              SizedBox(
                width: ancho,
                child: Center(
                  child: _BotonDia(
                    letra: letra,
                    nombre: nombre,
                    marcado: dias.contains(dia),
                    onTap: () => onCambio(dia, !dias.contains(dia)),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _BotonDia extends StatelessWidget {
  const _BotonDia({required this.letra, required this.nombre, required this.marcado, required this.onTap});

  final String letra;
  final String nombre;
  final bool marcado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;
    return Tooltip(
      message: nombre,
      excludeFromSemantics: true,
      child: Semantics(
        button: true,
        selected: marcado,
        label: nombre,
        excludeSemantics: true,
        child: SizedBox.square(
          dimension: 48,
          child: Material(
            color: marcado ? esquema.primary : Colors.transparent,
            shape: CircleBorder(side: BorderSide(color: marcado ? esquema.primary : esquema.outline)),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppTokens.espacioXS),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      letra,
                      style: textos.titleMedium?.copyWith(color: marcado ? esquema.onPrimary : esquema.onSurface),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Abrir la pantalla nueva desde "Mis recordatorios"**

En `lib/screens/agendar_rosario_screen.dart`:
- cambiar el import `../widgets/reminder_form.dart` por `recordatorio_form_screen.dart`;
- reemplazar `_abrirFormulario` por:

```dart
  Future<void> _abrirFormulario({RosarioReminder? recordatorio}) async {
    HapticFeedback.lightImpact();
    final servicio = context.read<NotificationService>();
    final guardado = await RecordatorioFormScreen.abrir(context, recordatorio: recordatorio);
    if (guardado == null || !mounted) return;
    await _avisar(recordatorio == null ? servicio.addReminder(guardado) : servicio.updateReminder(guardado));
  }
```

Los `onPressed`/`onEditar` que hoy llaman a `_abrirFormulario` siguen igual.

Borrar `lib/widgets/reminder_form.dart` y `test/widgets/reminder_form_test.dart`.

- [ ] **Step 5: Correr las pruebas**

Run: `flutter test test/screens/recordatorio_form_screen_test.dart test/screens/agendar_rosario_screen_test.dart test/accesibilidad_test.dart && flutter analyze`
Expected: `All tests passed!` y `No issues found!`.

Si `Navigator.pop` no cierra la ruta porque `PopScope.canPop` es `false`, poner `setState(() => _cerrando = true)` antes del `pop` y hacer el `pop` en `WidgetsBinding.instance.addPostFrameCallback`. La prueba `cerrar con cambios pregunta antes de descartar` lo cubre.

- [ ] **Step 6: Suite completa y commit**

Run: `flutter test`
Expected: `All tests passed!`.

```bash
git add -A lib/screens lib/widgets test
git commit -m "feat: formulario de recordatorio a pantalla completa, con la hora en grande y los días en una fila" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5: Inicio, menú y lista de recordatorios (H7)

**Files:**
- Modify: `lib/screens/inicio_screen.dart` (tarjeta que se toca e imagen adaptable)
- Modify: `lib/widgets/app_drawer.dart` (sin "Misterios del día")
- Modify: `lib/screens/agendar_rosario_screen.dart` (tarjeta que se toca y espacio para el botón "Nuevo")
- Test: `test/screens/principal_screen_test.dart`, `test/widgets/app_drawer_test.dart` y `test/screens/agendar_rosario_screen_test.dart`

**Interfaces:**
- Consumes:
  - `MisteriosDelDiaDialog({required TipoMisterio tipo, required String dia})`;
  - `nombreDelDia(DateTime)` y `misteriosPorTipo` (de `lib/data/oraciones.dart`);
  - `RecordatorioFormScreen` (Task 4).
- Produces:
  - La tarjeta de inicio con el texto `'Ver los 5 misterios'`, que abre el diálogo.
  - El menú solo con `'Agendar Rosario'`, `'Configuración'` y `'Acerca de'`.
  - Tocar el título de una tarjeta de recordatorio abre `'Editar recordatorio'`.

- [ ] **Step 1: Escribir las pruebas**

En `test/screens/principal_screen_test.dart`, agregar (con `import 'package:app_resar_rosario/data/oraciones.dart';`, `import 'package:app_resar_rosario/models/prayer_models.dart';` y `import 'package:flutter/material.dart';`):

```dart
  testWidgets('la tarjeta del día abre los 5 misterios', (tester) async {
    await tester.pumpWidget(envolver(const PrincipalScreen(), preferencias: await preferenciasDePrueba()));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Ver los 5 misterios'));
    await tester.tap(find.text('Ver los 5 misterios'));
    await tester.pumpAndSettle();
    for (final misterio in misteriosPorTipo[TipoMisterio.gozosos]!) {
      expect(find.text(misterio), findsOneWidget);
    }
    await tester.tap(find.text('Entendido'));
    await tester.pumpAndSettle();
    expect(find.text('La Encarnación del Hijo de Dios'), findsNothing);
  });

  for (final escala in [1.0, 1.5]) {
    testWidgets('en 360×640 con texto al ${(escala * 100).round()} % "Comenzar a Rezar" se ve sin desplazar',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 3.0;
      tester.view.padding = const FakeViewPadding(top: 72, bottom: 144); // barras de estado y de navegación
      addTearDown(tester.view.reset);

      await tester.pumpWidget(await appDePrueba(preferencias: {'pref_text_scale': escala}));
      await tester.pumpAndSettle();
      final boton = tester.getRect(find.ancestor(of: find.text('Comenzar a Rezar'), matching: find.byType(FilledButton)));
      expect(boton.bottom, lessThanOrEqualTo(640 - 48), reason: 'el botón termina en ${boton.bottom}');
    });
  }
```

En `test/widgets/app_drawer_test.dart`:
- reemplazar la primera prueba por:

```dart
  testWidgets('el menú muestra las opciones, sin repetir el misterio del día', (tester) async {
    await abrirMenu(tester);
    expect(find.text('Misterios del día'), findsNothing);
    for (final opcion in ['Agendar Rosario', 'Configuración', 'Acerca de']) {
      expect(find.text(opcion), findsOneWidget);
    }
  });
```

- borrar la prueba `abre el diálogo con los 5 misterios y se cierra`, que ahora cubre la tarjeta de inicio, y los imports que queden sin uso.

En `test/screens/agendar_rosario_screen_test.dart`, agregar:

```dart
  testWidgets('tocar la tarjeta abre la edición', (tester) async {
    await mostrar(tester);
    await crearRecordatorioDelLunes(tester);
    await tester.tap(find.text('Rezar el Santo Rosario'));
    await tester.pumpAndSettle();
    expect(find.text('Editar recordatorio'), findsOneWidget);
  });
```

- [ ] **Step 2: Correr y ver que fallan**

Run: `flutter test test/screens/principal_screen_test.dart test/widgets/app_drawer_test.dart test/screens/agendar_rosario_screen_test.dart`
Expected: FAIL. No existe `'Ver los 5 misterios'`, el menú todavía tiene "Misterios del día" y la tarjeta no abre la edición.

- [ ] **Step 3: La tarjeta de inicio se puede tocar**

En `lib/screens/inicio_screen.dart`, agregar el import `../widgets/misterios_del_dia_modal.dart` y reemplazar `_MisterioDelDia.build` por:

```dart
  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Semantics(
        button: true,
        label: '$dia: Misterios ${tipo.nombre}. Ver los 5 misterios',
        excludeSemantics: true,
        child: InkWell(
          onTap: () => showDialog<void>(context: context, builder: (_) => MisteriosDelDiaDialog(tipo: tipo, dia: dia)),
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.espacioL),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 20, color: colores.acento),
                    const SizedBox(width: AppTokens.espacioS),
                    Flexible(
                      child: Text(dia, textAlign: TextAlign.center, style: textos.titleMedium?.copyWith(color: colores.acento)),
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.espacioM),
                DecoratedBox(
                  decoration: BoxDecoration(color: colores.boton, borderRadius: BorderRadius.circular(999)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppTokens.espacioL, vertical: AppTokens.espacioS),
                    child: Text(
                      'Misterios ${tipo.nombre}',
                      textAlign: TextAlign.center,
                      style: textos.titleLarge?.copyWith(color: colores.sobreBoton, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: AppTokens.espacioM),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        'Ver los 5 misterios',
                        textAlign: TextAlign.center,
                        style: textos.labelLarge?.copyWith(color: colores.acento),
                      ),
                    ),
                    Icon(Icons.chevron_right, color: colores.acento),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
```

- [ ] **Step 4: La imagen se adapta a la letra y a la orientación**

En `_InicioScreenState.build`, reemplazar `final altoImagen = MediaQuery.sizeOf(context).height * 0.32;` por:

```dart
    // Con letra grande o en horizontal la imagen se achica para que "Comenzar a Rezar" se vea pronto.
    final tamano = MediaQuery.sizeOf(context);
    final escala = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0);
    final horizontal = tamano.width > tamano.height;
    final altoImagen = (tamano.height * (horizontal ? 0.4 : 0.26) / escala).clamp(96.0, 320.0);
```

Si la prueba de 150 % no pasa, bajar el factor vertical (0.26) sin bajar del mínimo de 96 dp, y anotar el valor final en el reporte.

- [ ] **Step 5: Quitar el duplicado del menú**

En `lib/widgets/app_drawer.dart`:
- borrar el `ListTile` de "Misterios del día";
- borrar las variables que solo usaba ese elemento (`sesion` y `dia`) y los imports que queden sin uso (`misterios_del_dia_modal.dart`, `rosario_session.dart` y `provider` si ya no se usa).

El encabezado del menú y las demás opciones quedan igual.

- [ ] **Step 6: La tarjeta de recordatorio se toca para editar**

En `lib/screens/agendar_rosario_screen.dart`:
- en `_TarjetaRecordatorio.build`, envolver el `Padding` del `Card` con:

```dart
      child: Semantics(
        onTapHint: 'Editar ${recordatorio.title}',
        child: InkWell(
          onTap: onEditar,
          child: Padding(/* el contenido actual de la tarjeta, sin cambios */),
        ),
      ),
```

  y en la misma tarjeta, envolver la hora (`Text(recordatorio.time.format(context), ...)`) con `FittedBox(fit: BoxFit.scaleDown, alignment: AlignmentDirectional.centerStart, child: ...)` y agregar `maxLines: 1`, para que con letra grande la hora no se parta;
- en el `ListView` de la pantalla, reemplazar el `padding` fijo por uno que deje libre el botón "Nuevo" aunque la letra esté grande:

```dart
        padding: EdgeInsets.fromLTRB(
          AppTokens.espacioM,
          AppTokens.espacioS,
          AppTokens.espacioM,
          MediaQuery.textScalerOf(context).scale(56) + AppTokens.espacioXL + AppTokens.espacioM,
        ),
```

- [ ] **Step 7: Correr las pruebas**

Run: `flutter test test/screens/ test/widgets/ && flutter analyze`
Expected: `All tests passed!` y `No issues found!`.

- [ ] **Step 8: Suite completa y commit**

Run: `flutter test`
Expected: `All tests passed!`.

```bash
git add lib/screens/inicio_screen.dart lib/widgets/app_drawer.dart lib/screens/agendar_rosario_screen.dart test
git commit -m "feat: la tarjeta del día abre los misterios, menú sin duplicados y tarjetas que se tocan para editar" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 6: Auditoría de contraste en toda la app (H1, H2)

**Files:**
- Modify: `test/support/app_harness.dart` (para que `appDePrueba` y `dependenciasDePrueba` acepten un `gateway`)
- Create: `test/support/recorridos_app.dart`, `test/support/auditor_contraste.dart`
- Test: `test/accesibilidad/auditor_contraste_test.dart` (prueba del auditor) y `test/accesibilidad/auditoria_contraste_test.dart` (la auditoría)
- Modify: los archivos de `lib/` que la auditoría marque. Los colores solo se cambian en `lib/theme/`.

**Interfaces:**
- Consumes: `contraste` (Task 1); los textos de las Tasks 2 a 5 (`'Ver los 5 misterios'`, `'Volver al inicio'`, `'Seguir rezando'`, `'Nuevo'`, `'Guardar'`, `'L'`, `'Toca para cambiarla'`, el tooltip `'Cerrar'` y `'Rezar el Santo Rosario'`).
- Produces (los usa la Task 7):
  - `typedef Revisar = Future<void> Function(String pantalla);`
  - `class Recorrido { const Recorrido(String nombre, Future<void> Function(WidgetTester, Revisar) recorrer, {FakeNotificationsGateway Function()? gateway}); }`
  - `final List<Recorrido> recorridos;`
  - `Future<void> tocar(WidgetTester tester, Finder objetivo)`
  - `const Map<String, Map<String, Object>> variantesDeTema;`
  - `List<String> fallasDeContraste(WidgetTester tester, String pantalla)`
  - `Future<Widget> appDePrueba({Map<String, Object> preferencias = const {}, FakeNotificationsGateway? gateway})`

- [ ] **Step 1: El arnés acepta un doble del sistema de notificaciones**

En `test/support/app_harness.dart`, cambiar `dependenciasDePrueba` y `appDePrueba`:

```dart
/// Todo lo que necesita la app completa, con dobles.
Future<({PreferencesService preferencias, NotificationService notificaciones, FakeNotificationsGateway gateway})>
    dependenciasDePrueba({Map<String, Object> preferencias = const {}, FakeNotificationsGateway? gateway}) async {
  final prefs = await preferenciasDePrueba(preferencias);
  final g = gateway ?? FakeNotificationsGateway();
  return (preferencias: prefs, notificaciones: await notificacionesDePrueba(g), gateway: g);
}

/// La app completa, lista para `pumpWidget`.
Future<Widget> appDePrueba({Map<String, Object> preferencias = const {}, FakeNotificationsGateway? gateway}) async {
  final d = await dependenciasDePrueba(preferencias: preferencias, gateway: gateway);
  return SantoRosarioApp(preferencias: d.preferencias, notificaciones: d.notificaciones, reloj: () => lunes);
}
```

- [ ] **Step 2: Escribir el auditor y su prueba**

`test/accesibilidad/auditor_contraste_test.dart` comprueba que el auditor detecta los problemas que busca:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/auditor_contraste.dart';

void main() {
  Future<List<String>> auditar(WidgetTester tester, Widget contenido) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Center(child: contenido))));
    return fallasDeContraste(tester, 'prueba');
  }

  testWidgets('detecta un texto sin color', (tester) async {
    final fallas = await auditar(tester, const Text('x', style: TextStyle(inherit: false, fontSize: 14)));
    expect(fallas.single, contains('no tiene color'));
  });

  testWidgets('detecta poco contraste contra el fondo real', (tester) async {
    final fallas = await auditar(
      tester,
      const ColoredBox(color: Color(0xFFFFFFFF), child: Text('x', style: TextStyle(color: Color(0xFFBBBBBB)))),
    );
    expect(fallas.single, contains(':1'));
  });

  testWidgets('en un degradado cuenta el color con peor contraste', (tester) async {
    final fallas = await auditar(
      tester,
      const DecoratedBox(
        decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF000000), Color(0xFFFFFFFF)])),
        child: Text('x', style: TextStyle(color: Color(0xFF000000))),
      ),
    );
    expect(fallas, isNotEmpty);
  });

  testWidgets('acepta texto oscuro sobre fondo claro', (tester) async {
    final fallas = await auditar(
      tester,
      const ColoredBox(color: Color(0xFFFFFFFF), child: Text('x', style: TextStyle(color: Color(0xFF222222)))),
    );
    expect(fallas, isEmpty);
  });
}
```

`test/support/auditor_contraste.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'contraste.dart';

/// Revisa cada texto dibujado: debe tener color y contraste WCAG suficiente contra su fondo real
/// (4.5:1, o 3:1 en texto grande). Devuelve una línea por cada falla.
List<String> fallasDeContraste(WidgetTester tester, String pantalla) {
  final fallas = <String>[];
  for (final elemento in find.byType(RichText).evaluate()) {
    final parrafo = elemento.renderObject;
    if (parrafo is! RenderParagraph || !parrafo.hasSize || parrafo.size.isEmpty) continue;
    // Los íconos se dibujan como texto, pero son gráficos y no entran en esta regla.
    if (elemento.findAncestorWidgetOfExactType<Icon>() != null) continue;
    if (_enControlDeshabilitado(elemento)) continue;
    final fondos = _fondosDe(elemento);

    void visitar(InlineSpan span, TextStyle? heredado) {
      if (span is! TextSpan) return;
      final estilo = heredado == null ? span.style : heredado.merge(span.style);
      final texto = span.text ?? '';
      if (texto.trim().isNotEmpty) {
        final color = estilo?.color ?? estilo?.foreground?.color;
        if (color == null) {
          fallas.add('$pantalla: "$texto" no tiene color');
        } else {
          final tamano = parrafo.textScaler.scale(estilo?.fontSize ?? 14);
          final negrita = (estilo?.fontWeight ?? FontWeight.normal).value >= FontWeight.bold.value;
          final minimo = tamano >= 24 || (negrita && tamano >= 18.66) ? 3.0 : 4.5;
          for (final fondo in fondos) {
            final relacion = contraste(Color.alphaBlend(color, fondo), fondo);
            if (relacion < minimo) {
              fallas.add('$pantalla: "$texto" ${relacion.toStringAsFixed(2)}:1 (mínimo $minimo) — $color sobre $fondo');
              break;
            }
          }
        }
      }
      for (final hijo in span.children ?? const <InlineSpan>[]) {
        visitar(hijo, estilo);
      }
    }

    visitar((elemento.widget as RichText).text, null);
  }
  return fallas;
}

bool _enControlDeshabilitado(Element elemento) {
  var deshabilitado = false;
  elemento.visitAncestorElements((ancestro) {
    final widget = ancestro.widget;
    if (widget is ButtonStyleButton) {
      deshabilitado = !widget.enabled;
      return false;
    }
    return true;
  });
  return deshabilitado;
}

/// Colores posibles del fondo real. Si el fondo es un degradado, devuelve todos sus colores.
List<Color> _fondosDe(Element elemento) {
  final capas = <Color>[]; // de la más cercana a la más lejana
  List<Color>? degradado;
  elemento.visitAncestorElements((ancestro) {
    if (ancestro is! RenderObjectElement) return true;
    final render = ancestro.renderObject;
    Color? relleno;
    List<Color>? colores;
    if (render is RenderPhysicalShape) {
      relleno = render.color;
    } else if (render is RenderPhysicalModel) {
      relleno = render.color;
    } else if (render is RenderDecoratedBox && render.position == DecorationPosition.background) {
      final decoracion = render.decoration;
      if (decoracion is BoxDecoration) {
        relleno = decoracion.color;
        colores = decoracion.gradient?.colors;
      } else if (decoracion is ShapeDecoration) {
        relleno = decoracion.color;
        colores = decoracion.gradient?.colors;
      }
    } else if (ancestro.widget is ColoredBox) {
      relleno = (ancestro.widget as ColoredBox).color;
    }
    if (colores != null && colores.isNotEmpty) {
      degradado = colores;
      return false;
    }
    if (relleno != null && relleno.a > 0) {
      capas.add(relleno);
      return relleno.a < 1; // si es translúcido, sigue hacia el fondo de abajo
    }
    return true;
  });
  final opaca = capas.isNotEmpty && capas.last.a >= 1 ? capas.removeLast() : null;
  final bases = degradado ?? [opaca ?? Theme.of(elemento).colorScheme.surface];
  return [
    for (final base in bases) capas.reversed.fold(base, (fondo, capa) => Color.alphaBlend(capa, fondo)),
  ];
}
```

Run: `flutter test test/accesibilidad/auditor_contraste_test.dart`
Expected: `All tests passed!`.

- [ ] **Step 3: Los recorridos por la app**

`test/support/recorridos_app.dart`:

```dart
import 'package:app_resar_rosario/services/notifications_gateway.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_notifications_gateway.dart';

/// Se llama en cada pantalla que hay que revisar, con un nombre que la identifica.
typedef Revisar = Future<void> Function(String pantalla);

/// Un camino por la app, desde el inicio recién abierto, que pasa por varias pantallas.
class Recorrido {
  const Recorrido(this.nombre, this.recorrer, {this.gateway});

  final String nombre;
  final Future<void> Function(WidgetTester tester, Revisar revisar) recorrer;

  /// Doble del sistema de notificaciones para este recorrido (p. ej. sin permisos).
  final FakeNotificationsGateway Function()? gateway;
}

/// Las 4 variantes de tema como preferencias guardadas (ThemeMode: 1 claro, 2 oscuro).
const variantesDeTema = <String, Map<String, Object>>{
  'claro': {'pref_theme_mode': 1},
  'oscuro': {'pref_theme_mode': 2},
  'claro alto contraste': {'pref_theme_mode': 1, 'pref_high_contrast': true},
  'oscuro alto contraste': {'pref_theme_mode': 2, 'pref_high_contrast': true},
};

/// Desplaza hasta [objetivo], lo toca y espera a que todo se asiente.
Future<void> tocar(WidgetTester tester, Finder objetivo) async {
  await tester.ensureVisible(objetivo);
  await tester.pumpAndSettle();
  await tester.tap(objetivo);
  await tester.pumpAndSettle();
}

Future<void> _abrirDesdeMenu(WidgetTester tester, String opcion) async {
  await tester.tap(find.byIcon(Icons.menu));
  await tester.pumpAndSettle();
  await tocar(tester, find.text(opcion));
}

Future<void> _soloAgendar(WidgetTester tester, Revisar revisar, String pantalla) async {
  await _abrirDesdeMenu(tester, 'Agendar Rosario');
  await revisar(pantalla);
}

final recorridos = <Recorrido>[
  Recorrido('inicio, menú y misterios del día', (tester, revisar) async {
    await revisar('inicio');
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await revisar('menú');
    Navigator.of(tester.element(find.text('Agendar Rosario'))).pop();
    await tester.pumpAndSettle();
    await tocar(tester, find.text('Ver los 5 misterios'));
    await revisar('misterios del día');
    await tocar(tester, find.text('Entendido'));
  }),
  Recorrido('rezo completo', (tester, revisar) async {
    await tocar(tester, find.text('Comenzar a Rezar'));
    for (var paso = 0; paso < 93; paso++) {
      await revisar('paso $paso');
      if (paso == 4) {
        await tocar(tester, find.byTooltip('Volver al inicio'));
        await revisar('¿Salir del rosario?');
        await tocar(tester, find.text('Seguir rezando'));
      }
      await tocar(tester, find.text(paso == 92 ? 'Terminar Rosario' : 'Continuar'));
    }
  }),
  Recorrido('recordatorios', (tester, revisar) async {
    await _abrirDesdeMenu(tester, 'Agendar Rosario');
    await revisar('lista vacía');
    await tocar(tester, find.text('Nuevo'));
    await revisar('formulario nuevo');
    await tocar(tester, find.text('Guardar'));
    await revisar('formulario con error de días');
    await tocar(tester, find.text('L'));
    await tocar(tester, find.text('Toca para cambiarla'));
    await revisar('selector de hora');
    Navigator.of(tester.element(find.byType(TimePickerDialog))).pop();
    await tester.pumpAndSettle();
    await tocar(tester, find.text('Guardar'));
    await revisar('lista con un recordatorio');
    await tocar(tester, find.byType(Switch));
    await revisar('recordatorio desactivado');
    await tocar(tester, find.text('Rezar el Santo Rosario'));
    await revisar('formulario de edición');
    await tocar(tester, find.byTooltip('Cerrar'));
  }),
  Recorrido(
    'aviso sin notificaciones',
    (tester, revisar) => _soloAgendar(tester, revisar, 'aviso sin notificaciones'),
    gateway: () => FakeNotificationsGateway()
      ..permissions = NotificationPermissions.none
      ..permissionsAfterRequest = NotificationPermissions.none,
  ),
  Recorrido(
    'aviso sin alarmas exactas',
    (tester, revisar) => _soloAgendar(tester, revisar, 'aviso sin alarmas exactas'),
    gateway: () =>
        FakeNotificationsGateway()..permissions = const NotificationPermissions(notifications: true, exactAlarms: false),
  ),
  Recorrido(
    'aviso sin servicio de notificaciones',
    (tester, revisar) => _soloAgendar(tester, revisar, 'aviso sin servicio'),
    gateway: () => FakeNotificationsGateway()..failInitialize = true,
  ),
  Recorrido('configuración y acerca de', (tester, revisar) async {
    await _abrirDesdeMenu(tester, 'Configuración');
    await revisar('configuración');
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await _abrirDesdeMenu(tester, 'Acerca de');
    await revisar('acerca de');
  }),
];
```

- [ ] **Step 4: La auditoría**

`test/accesibilidad/auditoria_contraste_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../support/app_harness.dart';
import '../support/auditor_contraste.dart';
import '../support/recorridos_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Santo Rosario',
      packageName: 'com.alejandrovaldez.santorosario',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  for (final MapEntry(key: tema, value: preferencias) in variantesDeTema.entries) {
    for (final recorrido in recorridos) {
      testWidgets('$tema · ${recorrido.nombre}: todo texto se lee', (tester) async {
        await tester.pumpWidget(await appDePrueba(preferencias: preferencias, gateway: recorrido.gateway?.call()));
        await tester.pumpAndSettle();
        final fallas = <String>[];
        await recorrido.recorrer(tester, (pantalla) async => fallas.addAll(fallasDeContraste(tester, pantalla)));
        expect(fallas, isEmpty, reason: fallas.join('\n'));
      });
    }
  }
}
```

- [ ] **Step 5: Correr la auditoría**

Run: `flutter test test/accesibilidad/`
Expected: es posible que haya fallas, porque la prueba es nueva. Cada una dice la pantalla, el texto, la relación de contraste y los colores.

- [ ] **Step 6: Corregir cada falla en su origen**

Se corrige la causa, nunca la prueba:
- **Si el widget usa un rol de color que no contrasta con su fondo**, cambiar el rol en el widget (por ejemplo, de `onSurfaceVariant` a `onSurface`) o usar el par correcto del `ColorScheme` (`onX` sobre `X`).
- **Si un color de sección no contrasta en alguna variante**, ajustar su tono en `lib/theme/seccion_colores.dart`. `test/theme/contraste_test.dart` tiene que seguir pasando.
- **Si el auditor no reconoce un fondo que sí existe** (por ejemplo, un `Ink`), la prueba toma el fondo del `Material` que está debajo. Si eso produce una falla falsa, explicarla en el reporte con los dos colores y la relación real calculada a mano. No se ajusta el auditor para callarla sin esa evidencia.

Repetir el Step 5 hasta que pase.

- [ ] **Step 7: Suite completa y commit**

Run: `flutter test && flutter analyze`
Expected: `All tests passed!` y `No issues found!`.

```bash
git add test lib
git commit -m "test: auditoría de contraste de toda la app en los cuatro temas" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 7: Matriz responsiva: tamaños, escalas y orientación (spec §3.6)

**Files:**
- Create: `test/responsivo_test.dart`
- Delete: `test/rezo_texto_grande_test.dart`, `test/accesibilidad_test.dart` (quedan cubiertas por la matriz)
- Modify: los archivos de `lib/` que la matriz marque

**Interfaces:**
- Consumes (Task 6): `recorridos`, `Recorrido`, `appDePrueba({preferencias, gateway})`.

- [ ] **Step 1: Escribir la matriz**

`test/responsivo_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'support/app_harness.dart';
import 'support/recorridos_app.dart';

const _tamanos = <String, Size>{
  'teléfono 360×640': Size(360, 640),
  'teléfono 411×914': Size(411, 914),
  'horizontal 640×360': Size(640, 360),
  'tableta 800×1280': Size(800, 1280),
};

/// Escala de la app × escala del sistema. 300 % es el máximo que permite la app.
const _escalas = <String, (double, double)>{
  'texto 100 %': (1.0, 1.0),
  'texto 200 %': (2.0, 1.0),
  'texto 300 %': (2.0, 1.5),
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Santo Rosario',
      packageName: 'com.alejandrovaldez.santorosario',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  for (final MapEntry(key: nombreTamano, value: tamano) in _tamanos.entries) {
    for (final MapEntry(key: nombreEscala, value: (escalaApp, escalaSistema)) in _escalas.entries) {
      for (final recorrido in recorridos) {
        testWidgets('$nombreTamano · $nombreEscala · ${recorrido.nombre}', (tester) async {
          tester.view.physicalSize = tamano * 3;
          tester.view.devicePixelRatio = 3.0;
          tester.view.padding = const FakeViewPadding(top: 72, bottom: 144); // barra de estado 24 dp, navegación 48 dp
          tester.platformDispatcher.textScaleFactorTestValue = escalaSistema;
          addTearDown(() {
            tester.view.reset();
            tester.platformDispatcher.clearTextScaleFactorTestValue();
          });
          final revisarGuias = escalaApp == 1.0 && escalaSistema == 1.0;
          final semantica = revisarGuias ? tester.ensureSemantics() : null;

          await tester.pumpWidget(
            await appDePrueba(preferencias: {'pref_text_scale': escalaApp}, gateway: recorrido.gateway?.call()),
          );
          await tester.pumpAndSettle();
          final areaUtil = Rect.fromLTRB(0, 24, tamano.width, tamano.height - 48);

          await recorrido.recorrer(tester, (pantalla) async {
            expect(tester.takeException(), isNull, reason: pantalla);
            for (final texto in ['Continuar', 'Terminar Rosario', 'Guardar']) {
              final boton = find.ancestor(of: find.text(texto), matching: find.byWidgetPredicate((w) => w is ButtonStyleButton));
              if (boton.evaluate().isEmpty) continue;
              final rect = tester.getRect(boton.first);
              expect(areaUtil.contains(rect.topLeft) && areaUtil.contains(rect.bottomRight), isTrue,
                  reason: '$pantalla: "$texto" $rect se sale de $areaUtil');
            }
            if (revisarGuias) {
              await expectLater(tester, meetsGuideline(androidTapTargetGuideline), reason: pantalla);
              await expectLater(tester, meetsGuideline(labeledTapTargetGuideline), reason: pantalla);
            }
          });
          expect(tester.takeException(), isNull);
          semantica?.dispose();
        });
      }
    }
  }
}
```

- [ ] **Step 2: Correr la matriz**

Run: `flutter test test/responsivo_test.dart`
Expected: es posible que haya fallas. Cada una indica tamaño, escala, recorrido y pantalla.

- [ ] **Step 3: Corregir cada falla en el código**

Nunca se corrige la prueba. Patrones para los casos más probables:
- **`RenderFlex overflowed` en una `Row`:** envolver el texto con `Expanded` o `Flexible`. Si el elemento es un botón o una etiqueta corta que no debe partirse, usar `FittedBox(fit: BoxFit.scaleDown)` con `maxLines: 1`.
- **Diálogo que se desborda en horizontal con letra grande:** `AlertDialog(scrollable: true, ...)`. Aplicarlo en `MisteriosDelDiaDialog`, en el diálogo de eliminar de `agendar_rosario_screen.dart` y en el de restablecer de `configuracion_screen.dart`.
- **`SegmentedButton` de Configuración (Sistema, Claro, Oscuro) con letra al 300 %:** las etiquetas van con `FittedBox(fit: BoxFit.scaleDown, child: Text(..., maxLines: 1))`, como en el formulario.
- **Selector de hora de Flutter que se desborda con letra muy grande:** pasar `builder: (context, child) => MediaQuery.withClampedTextScaling(maxScaleFactor: 1.5, child: child!)` a `showTimePicker` en `recordatorio_form_screen.dart`, y anotarlo en el reporte. Es un widget de Flutter, no de la app.
- **Un botón clave fuera del área útil:** revisar que la pantalla use `SafeArea`, y que el contenido variable esté dentro de un `SingleChildScrollView` o `Expanded`.

Repetir el Step 2 hasta que pase.

- [ ] **Step 4: Borrar las pruebas duplicadas**

Borrar `test/rezo_texto_grande_test.dart` y `test/accesibilidad_test.dart`. La matriz cubre lo mismo:
- 640×360 y 360×640 con letra al 200 % y al 300 %;
- tamaño táctil y etiquetas en todas las pantallas al 100 %.

- [ ] **Step 5: Suite completa y commit**

Run: `flutter test && flutter analyze`
Expected: `All tests passed!` y `No issues found!`.

```bash
git add -A test lib
git commit -m "test: matriz responsiva de tamaños, escalas y orientación para toda la app" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 8: Validación en el teléfono del usuario y cierre (spec §3.7)

La hace el controlador con el usuario; no la hace un subagente.

**Files:**
- Modify: `docs/superpowers/revision-visual-2026-11.md` (sección "Revisión en el teléfono")

- [ ] **Step 1: Compilar e instalar**

Run: `flutter build apk --release` y luego `adb install -r build/app/outputs/flutter-apk/app-release.apk`
Expected: `Success`. La depuración USB tiene que estar activa en el teléfono.

- [ ] **Step 2: Capturas**

**Antes de cambiar cualquier ajuste del teléfono** (tema oscuro, tamaño de letra), pedir permiso al usuario y anotar los valores originales:

```bash
adb shell settings get system font_scale
adb shell cmd uimode night
```

Recorrer las pantallas de la sección 3.6 del spec en claro, en oscuro y con la letra del sistema al máximo. Para navegar, usar `adb shell uiautomator dump` (da las coordenadas de cada elemento) y `adb shell input tap X Y`. Para capturar:

```bash
adb exec-out screencap -p > <scratchpad>/captura-<pantalla>-<variante>.png
```

Al terminar, restaurar los ajustes originales. Las capturas no se suben al repositorio.

- [ ] **Step 3: Revisión con Frontend Design**

Aplicar **frontend-design:frontend-design** a las capturas: jerarquía, espaciado, legibilidad, consistencia y que ningún dato se repita.
- Los problemas se corrigen con su prueba, en un commit `fix: ...` cada uno.
- Los ajustes de gusto se le presentan al usuario y se aplican solo los que apruebe.
- Todo queda anotado en `docs/superpowers/revision-visual-2026-11.md`, sección "Revisión en el teléfono".

- [ ] **Step 4: Verificación final**

Run: `flutter analyze && flutter test && flutter build appbundle --release`
Expected: `No issues found!`, `All tests passed!` y el `.aab` compila firmado.

Run: `graphify update .`

- [ ] **Step 5: Commit y entrega**

```bash
git add docs/superpowers/revision-visual-2026-11.md
git commit -m "docs: revisión visual en el teléfono" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

Copiar el APK nuevo al Escritorio como `SantoRosario-1.0.0-prueba.apk`. Hacer `git push` de la rama (actualiza el PR #1) solo con la autorización del usuario.
