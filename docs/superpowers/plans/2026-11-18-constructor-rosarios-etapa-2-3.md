# Constructor de rosarios — Etapas 2 y 3: Mis oraciones y Mis rosarios

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Para las pantallas de las Tasks 9, 11, 12 y 13 aplicar también **frontend-design:frontend-design**: pulir el estilo actual, sin paleta nueva.

**Goal:** Que el usuario administre sus oraciones y construya, edite y rece sus propios rosarios en un camino de cuentas.

**Architecture:** Las pantallas leen y escriben a través de `BibliotecaService`. La edición de un rosario son funciones puras en `lib/logic/edicion_rosario.dart`; la pantalla solo las aplica y guarda. Compartir, copiar y pegar pasan por `CompartirTexto`.

**Tech Stack:** Flutter 3.47.9, provider, share_plus.

**Spec:** `docs/superpowers/specs/2026-11-18-constructor-rosarios-design.md` · **Índice:** `docs/superpowers/plans/2026-11-18-constructor-rosarios.md`

## Global Constraints

Se aplican todas las del índice, incluida la sección "Reglas aprendidas en este proyecto".

---

### Task 8: Compartir texto y formulario de oración

**Files:**
- Create: `lib/services/compartir_texto.dart`, `lib/services/servicios_dispositivo.dart`, `lib/screens/oracion_form_screen.dart`
- Create: `test/support/servicios_falsos.dart`
- Modify: `lib/app.dart`, `test/support/app_harness.dart`
- Test: `test/screens/oracion_form_screen_test.dart`

**Interfaces:**
- Consumes: `BibliotecaService.guardarOracion`, `rosariosQueUsan`; `LimitesBiblioteca`; `EtiquetaBoton`.
- Produces:
  - `abstract interface class CompartirTexto { Future<void> compartir({required String titulo, required String texto}); Future<void> copiar({required String titulo, required String texto}); Future<String?> pegar(); }`.
  - `ServiciosDispositivo({required CompartirTexto compartir})` y `ServiciosDispositivo.reales()`.
  - `OracionFormScreen.abrir(BuildContext, {Oracion? oracion, String tituloInicial = '', String textoInicial = ''})` → `Future<Oracion?>`.
  - En pruebas: `CompartirFalso` con `compartidos`, `copiados`, `portapapeles`; `serviciosDePrueba({CompartirFalso? compartir})`.

- [ ] **Step 1: Crear los servicios y sus dobles**

`lib/services/compartir_texto.dart`:

```dart
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

/// Enviar una oración a otras apps, copiarla y pegar texto.
abstract interface class CompartirTexto {
  Future<void> compartir({required String titulo, required String texto});
  Future<void> copiar({required String titulo, required String texto});
  Future<String?> pegar();
}

String textoParaCompartir(String titulo, String texto) => '$titulo\n\n$texto';

class CompartirTextoSistema implements CompartirTexto {
  @override
  Future<void> compartir({required String titulo, required String texto}) async {
    await SharePlus.instance.share(ShareParams(text: textoParaCompartir(titulo, texto), subject: titulo));
  }

  @override
  Future<void> copiar({required String titulo, required String texto}) =>
      Clipboard.setData(ClipboardData(text: textoParaCompartir(titulo, texto)));

  @override
  Future<String?> pegar() async => (await Clipboard.getData(Clipboard.kTextPlain))?.text;
}
```

`lib/services/servicios_dispositivo.dart`:

```dart
import 'compartir_texto.dart';

/// Lo que la app le pide al teléfono. En pruebas se reemplaza por dobles.
class ServiciosDispositivo {
  const ServiciosDispositivo({required this.compartir});

  factory ServiciosDispositivo.reales() => ServiciosDispositivo(compartir: CompartirTextoSistema());

  final CompartirTexto compartir;
}
```

`test/support/servicios_falsos.dart`:

```dart
import 'package:app_resar_rosario/services/compartir_texto.dart';
import 'package:app_resar_rosario/services/servicios_dispositivo.dart';

class CompartirFalso implements CompartirTexto {
  final List<String> compartidos = [];
  final List<String> copiados = [];
  String? portapapeles;

  @override
  Future<void> compartir({required String titulo, required String texto}) async => compartidos.add(titulo);

  @override
  Future<void> copiar({required String titulo, required String texto}) async => copiados.add(titulo);

  @override
  Future<String?> pegar() async => portapapeles;
}

ServiciosDispositivo serviciosDePrueba({CompartirFalso? compartir}) =>
    ServiciosDispositivo(compartir: compartir ?? CompartirFalso());
```

En `lib/app.dart`: agregar el parámetro opcional `this.servicios`, el campo `final ServiciosDispositivo? servicios;` y el proveedor `Provider<ServiciosDispositivo>.value(value: servicios ?? ServiciosDispositivo.reales()),`.

En `test/support/app_harness.dart`:
- `appDePrueba` acepta `ServiciosDispositivo? servicios` y pasa `servicios: servicios ?? serviciosDePrueba()` a `SantoRosarioApp`;
- `envolver` acepta `ServiciosDispositivo? servicios` y agrega `Provider<ServiciosDispositivo>.value(value: servicios ?? serviciosDePrueba()),`.

- [ ] **Step 2: Escribir las pruebas del formulario**

`test/screens/oracion_form_screen_test.dart`:

```dart
import 'package:app_resar_rosario/models/oracion.dart';
import 'package:app_resar_rosario/models/rosario.dart';
import 'package:app_resar_rosario/screens/oracion_form_screen.dart';
import 'package:app_resar_rosario/services/biblioteca_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/almacen_en_memoria.dart';
import '../support/app_harness.dart';
import '../support/servicios_falsos.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late BibliotecaService biblioteca;
  late CompartirFalso compartir;
  late List<Oracion?> resultados;

  setUp(() {
    biblioteca = BibliotecaService(almacen: AlmacenEnMemoria());
    compartir = CompartirFalso();
    resultados = [];
  });

  Future<void> abrir(WidgetTester tester, {Oracion? oracion, String textoInicial = ''}) async {
    await tester.pumpWidget(envolver(
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async =>
                resultados.add(await OracionFormScreen.abrir(context, oracion: oracion, textoInicial: textoInicial)),
            child: const Text('Abrir'),
          ),
        ),
      ),
      preferencias: await preferenciasDePrueba(),
      biblioteca: biblioteca,
      servicios: serviciosDePrueba(compartir: compartir),
    ));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('sin título ni texto no guarda y lo indica', (tester) async {
    await abrir(tester);
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('Escribe un título'), findsOneWidget);
    expect(find.text('Escribe el texto de la oración'), findsOneWidget);
    expect(biblioteca.oracionesPropias, isEmpty);
  });

  testWidgets('guarda una oración nueva', (tester) async {
    await abrir(tester);
    await tester.enterText(find.byType(TextFormField).at(0), 'Por la paz');
    await tester.enterText(find.byType(TextFormField).at(1), 'Señor, danos tu paz.');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(resultados.single!.titulo, 'Por la paz');
    expect(biblioteca.oracionesPropias.single.texto, 'Señor, danos tu paz.');
  });

  testWidgets('Pegar agrega el texto del portapapeles', (tester) async {
    compartir.portapapeles = 'Texto copiado';
    await abrir(tester);
    await tester.tap(find.text('Pegar'));
    await tester.pumpAndSettle();
    expect(find.text('Texto copiado'), findsOneWidget);
  });

  testWidgets('Pegar sin texto lo avisa', (tester) async {
    await abrir(tester);
    await tester.tap(find.text('Pegar'));
    await tester.pumpAndSettle();
    expect(find.text('No hay texto para pegar'), findsOneWidget);
  });

  testWidgets('avisa cuántos rosarios se actualizarán al editar', (tester) async {
    final o = await biblioteca.guardarOracion(titulo: 'Uno', texto: 'Texto');
    final r = await biblioteca.crearRosario('Mío');
    await biblioteca.guardarRosario(r.copyWith(partes: [
      ParteRosario(id: 'p', nombre: 'P', elementos: [ElementoParte(id: 'e', oracionId: o.id)], misterios: const SinMisterios()),
    ]));
    await abrir(tester, oracion: o);
    expect(find.text('Editar oración'), findsOneWidget);
    expect(find.text('Se actualizará en 1 rosario.'), findsOneWidget);
  });

  testWidgets('cerrar con cambios pregunta; sin cambios no', (tester) async {
    await abrir(tester);
    await tester.tap(find.byTooltip('Cerrar'));
    await tester.pumpAndSettle();
    expect(find.text('¿Descartar los cambios?'), findsNothing);
    expect(resultados, [null]);

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Algo');
    await tester.tap(find.byTooltip('Cerrar'));
    await tester.pumpAndSettle();
    expect(find.text('¿Descartar los cambios?'), findsOneWidget);
    await tester.tap(find.text('Descartar'));
    await tester.pumpAndSettle();
    expect(find.text('Abrir'), findsOneWidget);
  });

  testWidgets('un texto recibido cuenta como cambio y queda cargado', (tester) async {
    await abrir(tester, textoInicial: 'Texto recibido');
    expect(find.text('Texto recibido'), findsOneWidget);
    await tester.tap(find.byTooltip('Cerrar'));
    await tester.pumpAndSettle();
    expect(find.text('¿Descartar los cambios?'), findsOneWidget);
  });
}
```

- [ ] **Step 3: Ver que fallan**

Run: `flutter test test/screens/oracion_form_screen_test.dart`
Expected: FAIL porque la pantalla no existe.

- [ ] **Step 4: Implementar el formulario**

`lib/screens/oracion_form_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/oracion.dart';
import '../services/biblioteca_service.dart';
import '../services/servicios_dispositivo.dart';
import '../theme/app_tokens.dart';
import '../widgets/etiqueta_boton.dart';

/// Crear o editar una oración propia a pantalla completa. Devuelve la oración guardada o `null`.
class OracionFormScreen extends StatefulWidget {
  const OracionFormScreen({super.key, this.oracion, this.tituloInicial = '', this.textoInicial = ''});

  final Oracion? oracion;
  final String tituloInicial;
  final String textoInicial;

  static Future<Oracion?> abrir(
    BuildContext context, {
    Oracion? oracion,
    String tituloInicial = '',
    String textoInicial = '',
  }) {
    return Navigator.of(context).push<Oracion>(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => OracionFormScreen(oracion: oracion, tituloInicial: tituloInicial, textoInicial: textoInicial),
    ));
  }

  @override
  State<OracionFormScreen> createState() => _OracionFormScreenState();
}

class _OracionFormScreenState extends State<OracionFormScreen> {
  final _formulario = GlobalKey<FormState>();
  late final TextEditingController _titulo = TextEditingController(text: widget.oracion?.titulo ?? widget.tituloInicial);
  late final TextEditingController _texto = TextEditingController(text: widget.oracion?.texto ?? widget.textoInicial);
  bool _cerrando = false;

  @override
  void initState() {
    super.initState();
    _titulo.addListener(_redibujar);
    _texto.addListener(_redibujar);
  }

  @override
  void dispose() {
    _titulo.dispose();
    _texto.dispose();
    super.dispose();
  }

  void _redibujar() => setState(() {});

  bool get _hayCambios => _titulo.text != (widget.oracion?.titulo ?? '') || _texto.text != (widget.oracion?.texto ?? '');

  Future<void> _pegar() async {
    final mensajero = ScaffoldMessenger.of(context);
    final pegado = (await context.read<ServiciosDispositivo>().compartir.pegar())?.trim() ?? '';
    if (pegado.isEmpty) {
      mensajero.showSnackBar(const SnackBar(content: Text('No hay texto para pegar')));
      return;
    }
    final actual = _texto.text.trim();
    final unido = actual.isEmpty ? pegado : '$actual\n\n$pegado';
    _texto.text = unido.length > LimitesBiblioteca.textoOracion ? unido.substring(0, LimitesBiblioteca.textoOracion) : unido;
  }

  Future<void> _guardar() async {
    if (!_formulario.currentState!.validate()) return;
    final navegador = Navigator.of(context);
    final guardada = await context
        .read<BibliotecaService>()
        .guardarOracion(id: widget.oracion?.id, titulo: _titulo.text, texto: _texto.text);
    _cerrando = true;
    navegador.pop(guardada);
  }

  Future<bool> _confirmarDescarte() async {
    final descartar = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        scrollable: true,
        title: const Text('¿Descartar los cambios?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogo, false), child: const EtiquetaBoton('Seguir editando')),
          FilledButton(onPressed: () => Navigator.pop(dialogo, true), child: const EtiquetaBoton('Descartar')),
        ],
      ),
    );
    return descartar ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;
    final oracion = widget.oracion;
    final enUso = oracion == null ? 0 : context.watch<BibliotecaService>().rosariosQueUsan(oracion.id).length;

    return PopScope<Oracion>(
      canPop: _cerrando || !_hayCambios,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navegador = Navigator.of(context);
        final descartar = await _confirmarDescarte();
        if (!mounted || !descartar) return;
        _cerrando = true;
        navegador.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Cerrar',
            onPressed: () => Navigator.maybePop(context),
          ),
          title: MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.3,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(oracion == null ? 'Nueva oración' : 'Editar oración'),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsetsDirectional.only(end: AppTokens.espacioS),
              child: MediaQuery.withClampedTextScaling(
                maxScaleFactor: 1.3,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 160),
                  child: FilledButton(onPressed: _guardar, child: const EtiquetaBoton('Guardar')),
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
                      if (enUso > 0) ...[
                        Text(
                          enUso == 1 ? 'Se actualizará en 1 rosario.' : 'Se actualizará en $enUso rosarios.',
                          style: textos.bodyMedium?.copyWith(color: esquema.onSurfaceVariant),
                        ),
                        const SizedBox(height: AppTokens.espacioM),
                      ],
                      TextFormField(
                        controller: _titulo,
                        maxLength: LimitesBiblioteca.tituloOracion,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(labelText: 'Título', border: OutlineInputBorder(), counterText: ''),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Escribe un título' : null,
                      ),
                      const SizedBox(height: AppTokens.espacioM),
                      TextFormField(
                        controller: _texto,
                        minLines: 8,
                        maxLines: null,
                        maxLength: LimitesBiblioteca.textoOracion,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Texto de la oración',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(),
                          counterText: '',
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Escribe el texto de la oración' : null,
                      ),
                      const SizedBox(height: AppTokens.espacioS),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: TextButton.icon(
                          onPressed: _pegar,
                          icon: const Icon(Icons.content_paste),
                          label: const EtiquetaBoton('Pegar'),
                        ),
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
```

- [ ] **Step 5: Ver que pasan**

Run: `flutter test test/screens/oracion_form_screen_test.dart`
Expected: `All tests passed!`.

Run: `flutter analyze` y `flutter test`
Expected: `No issues found!` y `All tests passed!`.

- [ ] **Step 6: Guardar**

```bash
git add lib/services/compartir_texto.dart lib/services/servicios_dispositivo.dart lib/screens/oracion_form_screen.dart lib/app.dart test/support/servicios_falsos.dart test/support/app_harness.dart test/screens/oracion_form_screen_test.dart
git commit -m "feat: formulario de oración con pegar y servicio para compartir"
```

---

### Task 9: Pantalla "Mis oraciones"

**Files:**
- Create: `lib/screens/mis_oraciones_screen.dart`
- Modify: `lib/widgets/app_drawer.dart`
- Test: `test/screens/mis_oraciones_screen_test.dart`

**Interfaces:**
- Consumes: `BibliotecaService`, `OracionFormScreen.abrir`, `ServiciosDispositivo.compartir`, `LetaniasWidget`.
- Produces: `MisOracionesScreen({bool elegir = false})`, `MisOracionesScreen.elegirOracion(BuildContext)` → `Future<Oracion?>`, `OracionDetalleScreen(oracionId)`. La Task 17 agrega "Con la cámara" a `_nuevaOracion`.

- [ ] **Step 1: Escribir las pruebas**

`test/screens/mis_oraciones_screen_test.dart`:

```dart
import 'package:app_resar_rosario/models/rosario.dart';
import 'package:app_resar_rosario/screens/mis_oraciones_screen.dart';
import 'package:app_resar_rosario/services/biblioteca_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/almacen_en_memoria.dart';
import '../support/app_harness.dart';
import '../support/servicios_falsos.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late BibliotecaService biblioteca;
  late CompartirFalso compartir;

  setUp(() {
    biblioteca = BibliotecaService(almacen: AlmacenEnMemoria());
    compartir = CompartirFalso();
  });

  Future<void> mostrar(WidgetTester tester) async {
    await tester.pumpWidget(envolver(
      const MisOracionesScreen(),
      preferencias: await preferenciasDePrueba(),
      biblioteca: biblioteca,
      servicios: serviciosDePrueba(compartir: compartir),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('busca sin importar acentos ni mayúsculas', (tester) async {
    await mostrar(tester);
    await tester.enterText(find.byType(TextField), 'AVE MARIA');
    await tester.pumpAndSettle();
    expect(find.text('Ave María'), findsOneWidget);
    expect(find.text('Padre Nuestro'), findsNothing);
  });

  testWidgets('el filtro Mías muestra solo las propias', (tester) async {
    await biblioteca.guardarOracion(titulo: 'Por la paz', texto: 'Señor, danos paz.');
    await mostrar(tester);
    await tester.tap(find.text('Mías'));
    await tester.pumpAndSettle();
    expect(find.text('Por la paz'), findsOneWidget);
    expect(find.text('Ave María'), findsNothing);
  });

  testWidgets('sin oraciones propias invita a crear una', (tester) async {
    await mostrar(tester);
    await tester.tap(find.text('Mías'));
    await tester.pumpAndSettle();
    expect(find.text('Todavía no tienes oraciones propias.'), findsOneWidget);
  });

  testWidgets('una oración de la app se comparte y se copia, y no se edita', (tester) async {
    await mostrar(tester);
    await tester.enterText(find.byType(TextField), 'ave maria');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ave María'));
    await tester.pumpAndSettle();
    expect(find.text('Editar'), findsNothing);
    expect(find.text('Crear mi versión'), findsOneWidget);

    await tester.tap(find.text('Compartir'));
    await tester.pump();
    expect(compartir.compartidos, ['Ave María']);
    await tester.tap(find.text('Copiar'));
    await tester.pumpAndSettle();
    expect(compartir.copiados, ['Ave María']);
    expect(find.text('Oración copiada'), findsOneWidget);
  });

  testWidgets('crear mi versión deja una oración propia', (tester) async {
    await mostrar(tester);
    await tester.enterText(find.byType(TextField), 'ave maria');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ave María'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Crear mi versión'));
    await tester.pumpAndSettle();
    expect(biblioteca.oracionesPropias.single.titulo, 'Ave María (mi versión)');
    expect(find.text('Editar'), findsOneWidget);
  });

  testWidgets('eliminar una oración en uso pide confirmación y nombra los rosarios', (tester) async {
    final o = await biblioteca.guardarOracion(titulo: 'Por la paz', texto: 'Texto');
    await biblioteca.crearRosario('De mi familia').then((r) => biblioteca.guardarRosario(r.copyWith(partes: [
          ParteRosario(id: 'p', nombre: 'P', elementos: [ElementoParte(id: 'e', oracionId: o.id)], misterios: const SinMisterios()),
        ])));
    await mostrar(tester);
    await tester.tap(find.text('Mías'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Por la paz'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('De mi familia'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
    await tester.pumpAndSettle();
    expect(biblioteca.oracionesPropias, isEmpty);
  });

  testWidgets('Nueva ofrece escribir y pegar', (tester) async {
    await mostrar(tester);
    await tester.tap(find.text('Nueva'));
    await tester.pumpAndSettle();
    expect(find.text('Escribir'), findsOneWidget);
    expect(find.text('Pegar'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Ver que fallan**

Run: `flutter test test/screens/mis_oraciones_screen_test.dart`
Expected: FAIL porque la pantalla no existe.

- [ ] **Step 3: Implementar la pantalla**

`lib/screens/mis_oraciones_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/oracion.dart';
import '../services/biblioteca_service.dart';
import '../services/servicios_dispositivo.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../theme/seccion_colores.dart';
import '../widgets/etiqueta_boton.dart';
import '../widgets/letanias_widget.dart';
import 'oracion_form_screen.dart';

enum _Filtro { todas, app, mias }

/// Para buscar sin importar acentos ni mayúsculas.
String _normalizar(String texto) {
  const conAcento = 'áéíóúüñ';
  const sinAcento = 'aeiouun';
  final minusculas = texto.toLowerCase();
  return String.fromCharCodes(minusculas.runes.map((c) {
    final i = conAcento.runes.toList().indexOf(c);
    return i < 0 ? c : sinAcento.runes.elementAt(i);
  }));
}

/// La biblioteca de oraciones. Con [elegir], tocar una oración la devuelve.
class MisOracionesScreen extends StatefulWidget {
  const MisOracionesScreen({super.key, this.elegir = false});

  final bool elegir;

  static Future<Oracion?> elegirOracion(BuildContext context) => Navigator.of(context)
      .push<Oracion>(MaterialPageRoute(builder: (_) => const MisOracionesScreen(elegir: true)));

  @override
  State<MisOracionesScreen> createState() => _MisOracionesScreenState();
}

class _MisOracionesScreenState extends State<MisOracionesScreen> {
  String _busqueda = '';
  _Filtro _filtro = _Filtro.todas;

  Future<void> _nuevaOracion() async {
    final servicios = context.read<ServiciosDispositivo>();
    final navegador = Navigator.of(context);
    final opcion = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (hoja) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Escribir'),
                onTap: () => Navigator.pop(hoja, 'escribir'),
              ),
              ListTile(
                leading: const Icon(Icons.content_paste),
                title: const Text('Pegar'),
                onTap: () => Navigator.pop(hoja, 'pegar'),
              ),
            ],
          ),
        ),
      ),
    );
    if (opcion == null || !mounted) return;
    final texto = opcion == 'pegar' ? (await servicios.compartir.pegar())?.trim() ?? '' : '';
    if (!mounted) return;
    final guardada = await OracionFormScreen.abrir(context, textoInicial: texto);
    if (guardada != null && widget.elegir) navegador.pop(guardada);
  }

  @override
  Widget build(BuildContext context) {
    final biblioteca = context.watch<BibliotecaService>();
    final textos = Theme.of(context).textTheme;
    final esquema = Theme.of(context).colorScheme;
    final margen = AppTokens.margenLateral(MediaQuery.sizeOf(context).width);
    final consulta = _normalizar(_busqueda.trim());
    final oraciones = [
      if (_filtro != _Filtro.app) ...biblioteca.oracionesPropias,
      if (_filtro != _Filtro.mias) ...biblioteca.oracionesApp,
    ].where((o) => consulta.isEmpty || _normalizar('${o.titulo} ${o.texto}').contains(consulta)).toList();

    return Scaffold(
      appBar: AppBar(title: Text(widget.elegir ? 'Elegir oración' : 'Mis oraciones')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _nuevaOracion,
        icon: const Icon(Icons.add),
        label: const Text('Nueva'),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppTokens.espacioM + margen,
          AppTokens.espacioS,
          AppTokens.espacioM + margen,
          MediaQuery.textScalerOf(context).scale(56) + AppTokens.espacioXL + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          TextField(
            onChanged: (valor) => setState(() => _busqueda = valor),
            decoration: const InputDecoration(
              labelText: 'Buscar oración',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppTokens.espacioM),
          SegmentedButton<_Filtro>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: _Filtro.todas, label: EtiquetaBoton('Todas')),
              ButtonSegment(value: _Filtro.app, label: EtiquetaBoton('De la app')),
              ButtonSegment(value: _Filtro.mias, label: EtiquetaBoton('Mías')),
            ],
            selected: {_filtro},
            onSelectionChanged: (seleccion) => setState(() => _filtro = seleccion.first),
          ),
          const SizedBox(height: AppTokens.espacioM),
          if (oraciones.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppTokens.espacioXL),
              child: Text(
                _filtro == _Filtro.mias && consulta.isEmpty
                    ? 'Todavía no tienes oraciones propias.'
                    : 'No se encontraron oraciones.',
                textAlign: TextAlign.center,
                style: textos.bodyLarge?.copyWith(color: esquema.onSurfaceVariant),
              ),
            ),
          for (final o in oraciones)
            Card(
              margin: const EdgeInsets.only(bottom: AppTokens.espacioS),
              child: ListTile(
                leading: Icon(o.esDeLaApp ? Icons.lock_outline : Icons.person_outline),
                title: Text(o.titulo),
                subtitle: Text(o.texto, maxLines: 2, overflow: TextOverflow.ellipsis),
                onTap: () {
                  if (widget.elegir) {
                    Navigator.pop(context, o);
                  } else {
                    Navigator.push(context, MaterialPageRoute<void>(builder: (_) => OracionDetalleScreen(oracionId: o.id)));
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// Una oración con sus acciones.
class OracionDetalleScreen extends StatefulWidget {
  const OracionDetalleScreen({super.key, required this.oracionId});

  final String oracionId;

  @override
  State<OracionDetalleScreen> createState() => _OracionDetalleScreenState();
}

class _OracionDetalleScreenState extends State<OracionDetalleScreen> {
  late String _id = widget.oracionId;

  Future<void> _copiar(Oracion o) async {
    final mensajero = ScaffoldMessenger.of(context);
    await context.read<ServiciosDispositivo>().compartir.copiar(titulo: o.titulo, texto: o.texto);
    mensajero.showSnackBar(const SnackBar(content: Text('Oración copiada')));
  }

  Future<void> _crearMiVersion(Oracion o) async {
    final copia = await context.read<BibliotecaService>().crearMiVersion(o);
    if (mounted) setState(() => _id = copia.id);
  }

  Future<void> _eliminar(Oracion o) async {
    final biblioteca = context.read<BibliotecaService>();
    final navegador = Navigator.of(context);
    final enUso = biblioteca.rosariosQueUsan(o.id).map((r) => r.nombre).toList();
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        scrollable: true,
        title: const Text('Eliminar oración'),
        content: Text(enUso.isEmpty
            ? '¿Quieres eliminar "${o.titulo}"?'
            : 'También se quitará de estos rosarios: ${enUso.join(', ')}.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogo, false), child: const EtiquetaBoton('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(dialogo, true), child: const EtiquetaBoton('Eliminar')),
        ],
      ),
    );
    if (confirmado ?? false) {
      await biblioteca.eliminarOracion(o.id);
      navegador.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final oracion = context.watch<BibliotecaService>().mapaOraciones[_id];
    if (oracion == null) return const Scaffold();
    final compartir = context.read<ServiciosDispositivo>().compartir;
    final margen = AppTokens.margenLateral(MediaQuery.sizeOf(context).width);

    return Scaffold(
      appBar: AppBar(title: Text(oracion.titulo)),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppTokens.espacioL + margen,
          AppTokens.espacioM,
          AppTokens.espacioL + margen,
          AppTokens.espacioL + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          if (oracion.formato == FormatoOracion.letanias)
            LetaniasWidget(texto: oracion.texto, colores: context.secciones.iniciales)
          else
            Text(oracion.texto, style: AppTheme.oracion(context)),
          const SizedBox(height: AppTokens.espacioL),
          Wrap(
            spacing: AppTokens.espacioS,
            runSpacing: AppTokens.espacioS,
            children: [
              FilledButton.icon(
                onPressed: () => compartir.compartir(titulo: oracion.titulo, texto: oracion.texto),
                icon: const Icon(Icons.share_outlined),
                label: const EtiquetaBoton('Compartir'),
              ),
              OutlinedButton.icon(
                onPressed: () => _copiar(oracion),
                icon: const Icon(Icons.copy_outlined),
                label: const EtiquetaBoton('Copiar'),
              ),
              if (oracion.esDeLaApp)
                OutlinedButton.icon(
                  onPressed: () => _crearMiVersion(oracion),
                  icon: const Icon(Icons.edit_note),
                  label: const EtiquetaBoton('Crear mi versión'),
                )
              else ...[
                OutlinedButton.icon(
                  onPressed: () => OracionFormScreen.abrir(context, oracion: oracion),
                  icon: const Icon(Icons.edit_outlined),
                  label: const EtiquetaBoton('Editar'),
                ),
                TextButton.icon(
                  onPressed: () => _eliminar(oracion),
                  icon: const Icon(Icons.delete_outline),
                  label: const EtiquetaBoton('Eliminar'),
                  style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Agregar la opción al menú**

En `lib/widgets/app_drawer.dart`, agregar `import '../screens/mis_oraciones_screen.dart';` y, antes del `ListTile` de "Agendar Rosario":

```dart
            ListTile(
              leading: const Icon(Icons.menu_book_outlined),
              title: const Text('Mis oraciones'),
              subtitle: const Text('Crear, copiar y compartir'),
              onTap: () => abrirDesdeMenu(context, (_) => const MisOracionesScreen()),
            ),
```

- [ ] **Step 5: Ver que pasan**

Run: `flutter test test/screens/mis_oraciones_screen_test.dart test/widgets/app_drawer_test.dart`
Expected: `All tests passed!`.

Run: `flutter analyze` y `flutter test`
Expected: `No issues found!` y `All tests passed!`.

- [ ] **Step 6: Guardar y cerrar la etapa**

Run: `graphify update .`

```bash
git add lib/screens/mis_oraciones_screen.dart lib/widgets/app_drawer.dart test/screens/mis_oraciones_screen_test.dart
git commit -m "feat: pantalla Mis oraciones con búsqueda, copiar y compartir"
```

---

### Task 10: Operaciones de edición de un rosario

**Files:**
- Create: `lib/logic/edicion_rosario.dart`
- Test: `test/logic/edicion_rosario_test.dart`

**Interfaces:**
- Consumes: modelos de `lib/models/rosario.dart`, `construirPasos`.
- Produces: `moverParte(Rosario, int desde, int hasta)`, `agregarParte(Rosario, ParteRosario)`, `reemplazarParte(Rosario, ParteRosario)`, `quitarParte(Rosario, String id)`, `moverElemento(ParteRosario, int desde, int hasta)`, `agregarElemento(ParteRosario, ElementoParte)`, `quitarElemento(ParteRosario, String id)`, `cambiarVeces(ParteRosario, String id, int veces)`, `String? motivoParaNoRezar(Rosario, Map<String, Oracion>)`.

- [ ] **Step 1: Escribir las pruebas**

`test/logic/edicion_rosario_test.dart`:

```dart
import 'package:app_resar_rosario/data/rosario_tradicional.dart';
import 'package:app_resar_rosario/logic/edicion_rosario.dart';
import 'package:app_resar_rosario/models/rosario.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ParteRosario parte(String id, [List<String> elementos = const []]) => ParteRosario(
        id: id,
        nombre: id,
        elementos: [for (final e in elementos) ElementoParte(id: e, oracionId: idDeApp('gloria'))],
        misterios: const SinMisterios(),
      );
  Rosario rosario(List<ParteRosario> partes) => Rosario(id: 'r', nombre: 'R', tipo: TipoRosario.propio, partes: partes);

  test('mover una parte a otra posición', () {
    final r = moverParte(rosario([parte('a'), parte('b'), parte('c')]), 0, 2);
    expect(r.partes.map((p) => p.id), ['b', 'c', 'a']);
  });

  test('mover fuera de los límites la deja en el extremo', () {
    final r = moverParte(rosario([parte('a'), parte('b')]), 1, -1);
    expect(r.partes.map((p) => p.id), ['b', 'a']);
  });

  test('agregar, reemplazar y quitar partes', () {
    var r = agregarParte(rosario([parte('a')]), parte('b'));
    r = reemplazarParte(r, parte('a').copyWith(nombre: 'Nuevo'));
    expect(r.partes.first.nombre, 'Nuevo');
    expect(quitarParte(r, 'a').partes.map((p) => p.id), ['b']);
  });

  test('mover, agregar y quitar oraciones de una parte', () {
    var p = moverElemento(parte('a', ['1', '2', '3']), 2, 0);
    expect(p.elementos.map((e) => e.id), ['3', '1', '2']);
    p = agregarElemento(p, ElementoParte(id: '4', oracionId: idDeApp('gloria')));
    expect(p.elementos.last.id, '4');
    expect(quitarElemento(p, '1').elementos.map((e) => e.id), ['3', '2', '4']);
  });

  test('las veces se mantienen entre 1 y 99', () {
    expect(cambiarVeces(parte('a', ['1']), '1', 150).elementos.single.veces, 99);
    expect(cambiarVeces(parte('a', ['1']), '1', 0).elementos.single.veces, 1);
  });

  test('explica por qué no se puede rezar', () {
    expect(motivoParaNoRezar(rosario([]), oracionesDeLaApp), 'Agrega al menos una oración para poder rezar.');
    expect(motivoParaNoRezar(rosario([parte('a', ['1'])]), oracionesDeLaApp), isNull);
    final largo = rosario([
      parte('a').copyWith(
        elementos: [ElementoParte(id: '1', oracionId: idDeApp('gloria'), veces: 99)],
        misterios: const SinMisterios(vueltas: 20),
      ),
    ]);
    expect(motivoParaNoRezar(largo, oracionesDeLaApp), 'Este rosario es muy largo: el máximo es de 1000 pasos.');
  });
}
```

- [ ] **Step 2: Ver que fallan**

Run: `flutter test test/logic/edicion_rosario_test.dart`
Expected: FAIL porque el archivo no existe.

- [ ] **Step 3: Implementar**

`lib/logic/edicion_rosario.dart`:

```dart
import '../models/oracion.dart';
import '../models/rosario.dart';
import 'rosario_session.dart';

List<T> _mover<T>(List<T> lista, int desde, int hasta) {
  final copia = [...lista];
  final elemento = copia.removeAt(desde);
  copia.insert(hasta.clamp(0, copia.length), elemento);
  return copia;
}

Rosario moverParte(Rosario r, int desde, int hasta) => r.copyWith(partes: _mover(r.partes, desde, hasta));

Rosario agregarParte(Rosario r, ParteRosario parte) => r.copyWith(partes: [...r.partes, parte]);

Rosario reemplazarParte(Rosario r, ParteRosario parte) =>
    r.copyWith(partes: [for (final p in r.partes) p.id == parte.id ? parte : p]);

Rosario quitarParte(Rosario r, String id) => r.copyWith(partes: [
      for (final p in r.partes)
        if (p.id != id) p,
    ]);

ParteRosario moverElemento(ParteRosario p, int desde, int hasta) => p.copyWith(elementos: _mover(p.elementos, desde, hasta));

ParteRosario agregarElemento(ParteRosario p, ElementoParte e) => p.copyWith(elementos: [...p.elementos, e]);

ParteRosario quitarElemento(ParteRosario p, String id) => p.copyWith(elementos: [
      for (final e in p.elementos)
        if (e.id != id) e,
    ]);

ParteRosario cambiarVeces(ParteRosario p, String id, int veces) => p.copyWith(elementos: [
      for (final e in p.elementos) e.id == id ? e.copyWith(veces: veces.clamp(1, LimitesBiblioteca.veces)) : e,
    ]);

/// Por qué no se puede rezar este rosario, o `null` si está listo.
String? motivoParaNoRezar(Rosario r, Map<String, Oracion> oraciones) {
  final pasos = construirPasos(rosario: r, oraciones: oraciones).length;
  if (pasos == 0) return 'Agrega al menos una oración para poder rezar.';
  if (pasos > LimitesBiblioteca.pasos) return 'Este rosario es muy largo: el máximo es de ${LimitesBiblioteca.pasos} pasos.';
  return null;
}
```

- [ ] **Step 4: Ver que pasan y guardar**

Run: `flutter test test/logic/edicion_rosario_test.dart`
Expected: `All tests passed!`.

```bash
git add lib/logic/edicion_rosario.dart test/logic/edicion_rosario_test.dart
git commit -m "feat: operaciones para editar las partes de un rosario"
```

---

### Task 11: Camino de cuentas y constructor del rosario

**Files:**
- Create: `lib/widgets/camino_cuentas.dart`, `lib/widgets/selector_numero.dart`, `lib/widgets/pedir_nombre.dart`, `lib/screens/constructor_rosario_screen.dart`
- Test: `test/screens/constructor_rosario_screen_test.dart`

**Interfaces:**
- Consumes: operaciones de la Task 10; `BibliotecaService`; `MisOracionesScreen.elegirOracion`; `RosarioSession.comenzar`.
- Produces:
  - `TramoCamino({required Widget child, bool primero, bool ultimo, bool repite, bool hueco})`.
  - `SelectorNumero({required int valor, required int minimo, required int maximo, required String etiqueta, required ValueChanged<int> onCambio})`.
  - `Future<String?> pedirNombre(BuildContext, {required String titulo, String inicial = '', String accion = 'Guardar'})`.
  - `ConstructorRosarioScreen({required String rosarioId})`.
  - `void rezarRosario(BuildContext, Rosario)`.
  - Textos de la pantalla: `'Agregar parte'`, `'Agregar oración'`, `'Rezar'`, `'Crear mi versión'`, `'Duplicar parte'`, `'Eliminar parte'`, `'Mover arriba'`, `'Mover abajo'`, `'Cambiar veces'`, `'Quitar'`, tooltips `'Abrir {parte}'`, `'Cerrar {parte}'`, `'Opciones de {oración}'`, `'Cambiar nombre'`.

- [ ] **Step 1: Escribir las pruebas**

`test/screens/constructor_rosario_screen_test.dart`:

```dart
import 'package:app_resar_rosario/data/rosario_tradicional.dart';
import 'package:app_resar_rosario/logic/rosario_session.dart';
import 'package:app_resar_rosario/models/rosario.dart';
import 'package:app_resar_rosario/screens/constructor_rosario_screen.dart';
import 'package:app_resar_rosario/services/biblioteca_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/almacen_en_memoria.dart';
import '../support/app_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late BibliotecaService biblioteca;
  late RosarioSession sesion;

  setUp(() {
    biblioteca = BibliotecaService(almacen: AlmacenEnMemoria());
    sesion = RosarioSession(reloj: () => lunes);
  });

  Future<void> mostrar(WidgetTester tester, String id) async {
    await tester.pumpWidget(envolver(
      ConstructorRosarioScreen(rosarioId: id),
      preferencias: await preferenciasDePrueba(),
      biblioteca: biblioteca,
      sesion: sesion,
    ));
    await tester.pumpAndSettle();
  }

  Future<Rosario> conUnaParte() async {
    final r = await biblioteca.crearRosario('De mi familia');
    final con = r.copyWith(partes: [
      ParteRosario(
        id: 'p1',
        nombre: 'Inicio',
        elementos: [
          ElementoParte(id: 'e1', oracionId: idDeApp('gloria')),
          ElementoParte(id: 'e2', oracionId: idDeApp('avemaria'), veces: 10),
        ],
        misterios: const SinMisterios(),
      ),
    ]);
    await biblioteca.guardarRosario(con);
    return con;
  }

  testWidgets('un rosario vacío explica qué falta y no deja rezar', (tester) async {
    final r = await biblioteca.crearRosario('Nuevo');
    await mostrar(tester, r.id);
    expect(find.text('Agrega al menos una oración para poder rezar.'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Rezar')).onPressed, isNull);
  });

  testWidgets('agregar una parte la guarda y la deja abierta', (tester) async {
    final r = await biblioteca.crearRosario('Nuevo');
    await mostrar(tester, r.id);
    await tester.tap(find.text('Agregar parte'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Oraciones de la mañana');
    await tester.tap(find.text('Agregar'));
    await tester.pumpAndSettle();
    expect(biblioteca.rosarioPorId(r.id)!.partes.single.nombre, 'Oraciones de la mañana');
    expect(find.text('Agregar oración'), findsOneWidget);
  });

  testWidgets('abrir una parte muestra sus oraciones y sus veces', (tester) async {
    final r = await conUnaParte();
    await mostrar(tester, r.id);
    expect(find.text('Ave María'), findsNothing);
    await tester.tap(find.byTooltip('Abrir Inicio'));
    await tester.pumpAndSettle();
    expect(find.text('Ave María'), findsOneWidget);
    expect(find.text('10 veces'), findsOneWidget);
  });

  testWidgets('mover una oración con el menú cambia el orden', (tester) async {
    final r = await conUnaParte();
    await mostrar(tester, r.id);
    await tester.tap(find.byTooltip('Abrir Inicio'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Opciones de Ave María'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mover arriba'));
    await tester.pumpAndSettle();
    expect(biblioteca.rosarioPorId(r.id)!.partes.single.elementos.first.id, 'e2');
  });

  testWidgets('cambiar las veces de una oración', (tester) async {
    final r = await conUnaParte();
    await mostrar(tester, r.id);
    await tester.tap(find.byTooltip('Abrir Inicio'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Opciones de Gloria'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cambiar veces'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Más'));
    await tester.pump();
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(biblioteca.rosarioPorId(r.id)!.partes.single.elementos.first.veces, 2);
  });

  testWidgets('quitar una oración se puede deshacer', (tester) async {
    final r = await conUnaParte();
    await mostrar(tester, r.id);
    await tester.tap(find.byTooltip('Abrir Inicio'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Opciones de Gloria'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quitar'));
    await tester.pumpAndSettle();
    expect(biblioteca.rosarioPorId(r.id)!.partes.single.elementos, hasLength(1));
    await tester.tap(find.text('Deshacer'));
    await tester.pumpAndSettle();
    expect(biblioteca.rosarioPorId(r.id)!.partes.single.elementos, hasLength(2));
  });

  testWidgets('el Rosario tradicional es de solo lectura', (tester) async {
    await mostrar(tester, rosarioTradicional.id);
    expect(find.text('Agregar parte'), findsNothing);
    expect(find.byTooltip('Cambiar nombre'), findsNothing);
    expect(find.text('Crear mi versión'), findsOneWidget);
    await tester.tap(find.byTooltip('Abrir Oraciones iniciales'));
    await tester.pumpAndSettle();
    expect(find.text('Señal de la Cruz'), findsOneWidget);
    expect(find.text('Agregar oración'), findsNothing);
    expect(find.byTooltip('Opciones de Señal de la Cruz'), findsNothing);
  });

  testWidgets('Rezar comienza ese rosario', (tester) async {
    final r = await conUnaParte();
    await mostrar(tester, r.id);
    await tester.tap(find.text('Rezar'));
    await tester.pumpAndSettle();
    expect(sesion.enInicio, isFalse);
    expect(sesion.pasos, hasLength(11));
  });
}
```

- [ ] **Step 2: Ver que fallan**

Run: `flutter test test/screens/constructor_rosario_screen_test.dart`
Expected: FAIL porque la pantalla no existe.

- [ ] **Step 3: Crear los widgets de apoyo**

`lib/widgets/camino_cuentas.dart`:

```dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../theme/seccion_colores.dart';

/// Un tramo del camino: una cuenta unida por un hilo a la anterior y a la siguiente.
/// El dibujo es decorativo; el contenido [child] es lo que anuncia el lector de pantalla.
class TramoCamino extends StatelessWidget {
  const TramoCamino({
    super.key,
    required this.child,
    this.primero = false,
    this.ultimo = false,
    this.repite = false,
    this.hueco = false,
  });

  final Widget child;
  final bool primero;
  final bool ultimo;

  /// Las partes que se repiten llevan una cuenta en forma de rombo.
  final bool repite;

  /// Cuenta vacía, para la acción de agregar.
  final bool hueco;

  @override
  Widget build(BuildContext context) {
    final secciones = context.secciones;
    return CustomPaint(
      painter: _PintorCamino(
        hilo: Theme.of(context).colorScheme.outline,
        relleno: hueco ? Colors.transparent : secciones.cuenta,
        borde: hueco ? Theme.of(context).colorScheme.outline : secciones.bordeCuenta,
        primero: primero,
        ultimo: ultimo,
        repite: repite,
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: AppTokens.espacioXL + AppTokens.espacioXS, bottom: AppTokens.espacioS),
        child: child,
      ),
    );
  }
}

class _PintorCamino extends CustomPainter {
  const _PintorCamino({
    required this.hilo,
    required this.relleno,
    required this.borde,
    required this.primero,
    required this.ultimo,
    required this.repite,
  });

  static const double _x = 14;
  static const double _y = 34;
  static const double _radio = 9;

  final Color hilo;
  final Color relleno;
  final Color borde;
  final bool primero;
  final bool ultimo;
  final bool repite;

  @override
  void paint(Canvas canvas, Size size) {
    final linea = Paint()
      ..color = hilo
      ..strokeWidth = 2;
    canvas.drawLine(Offset(_x, primero ? _y : 0), Offset(_x, ultimo ? _y : size.height), linea);

    final fondo = Paint()..color = relleno;
    final contorno = Paint()
      ..color = borde
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.save();
    canvas.translate(_x, _y);
    if (repite) {
      canvas.rotate(math.pi / 4);
      final rombo = Rect.fromCircle(center: Offset.zero, radius: _radio - 1);
      canvas.drawRect(rombo, fondo);
      canvas.drawRect(rombo, contorno);
    } else {
      canvas.drawCircle(Offset.zero, _radio, fondo);
      canvas.drawCircle(Offset.zero, _radio, contorno);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PintorCamino old) =>
      old.hilo != hilo ||
      old.relleno != relleno ||
      old.borde != borde ||
      old.primero != primero ||
      old.ultimo != ultimo ||
      old.repite != repite;
}
```

`lib/widgets/selector_numero.dart`:

```dart
import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Elegir un número con botones de menos y más.
class SelectorNumero extends StatelessWidget {
  const SelectorNumero({
    super.key,
    required this.valor,
    required this.minimo,
    required this.maximo,
    required this.etiqueta,
    required this.onCambio,
  });

  final int valor;
  final int minimo;
  final int maximo;
  final String etiqueta;
  final ValueChanged<int> onCambio;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton.outlined(
          onPressed: valor > minimo ? () => onCambio(valor - 1) : null,
          icon: const Icon(Icons.remove),
          tooltip: 'Menos',
        ),
        Expanded(
          child: Semantics(
            liveRegion: true,
            label: '$etiqueta: $valor',
            excludeSemantics: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTokens.espacioS),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('$valor', style: Theme.of(context).textTheme.headlineMedium),
              ),
            ),
          ),
        ),
        IconButton.outlined(
          onPressed: valor < maximo ? () => onCambio(valor + 1) : null,
          icon: const Icon(Icons.add),
          tooltip: 'Más',
        ),
      ],
    );
  }
}
```

`lib/widgets/pedir_nombre.dart`:

```dart
import 'package:flutter/material.dart';

import '../models/oracion.dart';
import 'etiqueta_boton.dart';

/// Pide un nombre en un diálogo. Devuelve el nombre sin espacios sobrantes, o `null` si se cancela.
Future<String?> pedirNombre(BuildContext context, {required String titulo, String inicial = '', String accion = 'Guardar'}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _DialogoNombre(titulo: titulo, inicial: inicial, accion: accion),
  );
}

class _DialogoNombre extends StatefulWidget {
  const _DialogoNombre({required this.titulo, required this.inicial, required this.accion});

  final String titulo;
  final String inicial;
  final String accion;

  @override
  State<_DialogoNombre> createState() => _DialogoNombreState();
}

class _DialogoNombreState extends State<_DialogoNombre> {
  late final TextEditingController _nombre = TextEditingController(text: widget.inicial);
  bool _faltaNombre = false;

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  void _aceptar() {
    final nombre = _nombre.text.trim();
    if (nombre.isEmpty) {
      setState(() => _faltaNombre = true);
      return;
    }
    Navigator.pop(context, nombre);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Text(widget.titulo),
      content: TextField(
        controller: _nombre,
        autofocus: true,
        maxLength: LimitesBiblioteca.nombre,
        textCapitalization: TextCapitalization.sentences,
        onSubmitted: (_) => _aceptar(),
        decoration: InputDecoration(
          labelText: 'Nombre',
          border: const OutlineInputBorder(),
          counterText: '',
          errorText: _faltaNombre ? 'Escribe un nombre' : null,
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const EtiquetaBoton('Cancelar')),
        FilledButton(onPressed: _aceptar, child: EtiquetaBoton(widget.accion)),
      ],
    );
  }
}
```

- [ ] **Step 4: Implementar el constructor**

`lib/screens/constructor_rosario_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/edicion_rosario.dart';
import '../logic/rosario_session.dart';
import '../models/oracion.dart';
import '../models/rosario.dart';
import '../services/biblioteca_service.dart';
import '../theme/app_tokens.dart';
import '../widgets/camino_cuentas.dart';
import '../widgets/etiqueta_boton.dart';
import '../widgets/pedir_nombre.dart';
import '../widgets/selector_numero.dart';
import 'mis_oraciones_screen.dart';

/// Empieza a rezar [rosario] y regresa a la pantalla principal, que muestra el rezo.
void rezarRosario(BuildContext context, Rosario rosario) {
  final oraciones = context.read<BibliotecaService>().mapaOraciones;
  context.read<RosarioSession>().comenzar(rosario: rosario, oraciones: oraciones);
  Navigator.of(context).popUntil((ruta) => ruta.isFirst);
}

/// Un rosario como camino de cuentas. Los protegidos se ven sin poder editarse.
class ConstructorRosarioScreen extends StatefulWidget {
  const ConstructorRosarioScreen({super.key, required this.rosarioId});

  final String rosarioId;

  @override
  State<ConstructorRosarioScreen> createState() => _ConstructorRosarioScreenState();
}

class _ConstructorRosarioScreenState extends State<ConstructorRosarioScreen> {
  final Set<String> _abiertas = {};

  /// Guarda el cambio. Con [aviso], ofrece deshacerlo.
  Future<void> _aplicar(Rosario anterior, Rosario nuevo, {String? aviso}) async {
    final biblioteca = context.read<BibliotecaService>();
    final mensajero = ScaffoldMessenger.of(context);
    await biblioteca.guardarRosario(nuevo);
    if (aviso == null) return;
    mensajero
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(aviso),
        action: SnackBarAction(label: 'Deshacer', onPressed: () => biblioteca.guardarRosario(anterior)),
      ));
  }

  Future<void> _renombrar(Rosario r) async {
    final nombre = await pedirNombre(context, titulo: 'Nombre del rosario', inicial: r.nombre);
    if (nombre != null) await _aplicar(r, r.copyWith(nombre: nombre));
  }

  Future<void> _agregarParte(Rosario r) async {
    final biblioteca = context.read<BibliotecaService>();
    final nombre = await pedirNombre(context, titulo: 'Nueva parte', accion: 'Agregar');
    if (nombre == null) return;
    final parte = ParteRosario(id: biblioteca.nuevoId(), nombre: nombre, elementos: const [], misterios: const SinMisterios());
    setState(() => _abiertas.add(parte.id));
    await _aplicar(r, agregarParte(r, parte));
  }

  Future<void> _agregarOracion(Rosario r, ParteRosario parte) async {
    final biblioteca = context.read<BibliotecaService>();
    final oracion = await MisOracionesScreen.elegirOracion(context);
    if (oracion == null) return;
    final elemento = ElementoParte(id: biblioteca.nuevoId(), oracionId: oracion.id);
    await _aplicar(r, reemplazarParte(r, agregarElemento(parte, elemento)));
  }

  Future<void> _duplicarParte(Rosario r, ParteRosario parte) async {
    final biblioteca = context.read<BibliotecaService>();
    final copia = ParteRosario(
      id: biblioteca.nuevoId(),
      nombre: parte.nombre,
      misterios: parte.misterios,
      elementos: [
        for (final e in parte.elementos) ElementoParte(id: biblioteca.nuevoId(), oracionId: e.oracionId, veces: e.veces),
      ],
    );
    final indice = r.partes.indexWhere((p) => p.id == parte.id);
    await _aplicar(r, moverParte(agregarParte(r, copia), r.partes.length, indice + 1));
  }

  Future<void> _cambiarVeces(Rosario r, ParteRosario parte, ElementoParte elemento, String titulo) async {
    var veces = elemento.veces;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogo) => StatefulBuilder(
        builder: (dialogo, actualizar) => AlertDialog(
          scrollable: true,
          title: Text(titulo),
          content: SelectorNumero(
            valor: veces,
            minimo: 1,
            maximo: LimitesBiblioteca.veces,
            etiqueta: 'Veces seguidas',
            onCambio: (valor) => actualizar(() => veces = valor),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogo, false), child: const EtiquetaBoton('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(dialogo, true), child: const EtiquetaBoton('Guardar')),
          ],
        ),
      ),
    );
    if (confirmado ?? false) await _aplicar(r, reemplazarParte(r, cambiarVeces(parte, elemento.id, veces)));
  }

  Future<void> _crearMiVersion(Rosario r) async {
    final biblioteca = context.read<BibliotecaService>();
    final navegador = Navigator.of(context);
    final nombre = await pedirNombre(context, titulo: 'Nombre de tu rosario', inicial: r.nombre, accion: 'Crear');
    if (nombre == null) return;
    final copia = await biblioteca.crearRosario(nombre, base: r);
    navegador.pushReplacement(MaterialPageRoute<void>(builder: (_) => ConstructorRosarioScreen(rosarioId: copia.id)));
  }

  @override
  Widget build(BuildContext context) {
    final biblioteca = context.watch<BibliotecaService>();
    final rosario = biblioteca.rosarioPorId(widget.rosarioId);
    if (rosario == null) return const Scaffold();
    final editable = !rosario.esProtegido;
    final oraciones = biblioteca.mapaOraciones;
    final motivo = motivoParaNoRezar(rosario, oraciones);
    final margen = AppTokens.margenLateral(MediaQuery.sizeOf(context).width);
    final partes = rosario.partes;

    return Scaffold(
      appBar: AppBar(
        title: Text(rosario.nombre),
        actions: [
          if (editable)
            IconButton(onPressed: () => _renombrar(rosario), icon: const Icon(Icons.edit_outlined), tooltip: 'Cambiar nombre'),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(AppTokens.espacioM + margen, AppTokens.espacioS, AppTokens.espacioM + margen, AppTokens.espacioS),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (motivo != null) ...[
                Text(motivo, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: AppTokens.espacioS),
              ],
              if (!editable) ...[
                OutlinedButton(onPressed: () => _crearMiVersion(rosario), child: const EtiquetaBoton('Crear mi versión')),
                const SizedBox(height: AppTokens.espacioS),
              ],
              FilledButton(
                onPressed: motivo == null ? () => rezarRosario(context, rosario) : null,
                child: const EtiquetaBoton('Rezar'),
              ),
            ],
          ),
        ),
      ),
      body: ReorderableListView.builder(
        buildDefaultDragHandles: false,
        padding: EdgeInsets.fromLTRB(AppTokens.espacioM + margen, AppTokens.espacioM, AppTokens.espacioM + margen, AppTokens.espacioM),
        itemCount: partes.length,
        onReorder: (desde, hasta) {
          if (editable) _aplicar(rosario, moverParte(rosario, desde, hasta > desde ? hasta - 1 : hasta));
        },
        footer: editable && partes.length < LimitesBiblioteca.partes
            ? TramoCamino(
                primero: partes.isEmpty,
                ultimo: true,
                hueco: true,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppTokens.espacioM),
                    child: OutlinedButton.icon(
                      onPressed: () => _agregarParte(rosario),
                      icon: const Icon(Icons.add),
                      label: const EtiquetaBoton('Agregar parte'),
                    ),
                  ),
                ),
              )
            : null,
        itemBuilder: (context, i) {
          final parte = partes[i];
          return TramoCamino(
            key: ValueKey(parte.id),
            primero: i == 0,
            ultimo: !editable && i == partes.length - 1,
            repite: parte.misterios.vueltas > 1,
            child: _TarjetaParte(
              parte: parte,
              indice: i,
              total: partes.length,
              editable: editable,
              abierta: _abiertas.contains(parte.id),
              oraciones: oraciones,
              onAlternar: () => setState(() => _abiertas.contains(parte.id) ? _abiertas.remove(parte.id) : _abiertas.add(parte.id)),
              onCambiarParte: (nueva, {aviso}) => _aplicar(rosario, reemplazarParte(rosario, nueva), aviso: aviso),
              onMover: (destino) => _aplicar(rosario, moverParte(rosario, i, destino)),
              onDuplicar: () => _duplicarParte(rosario, parte),
              onEliminar: () => _aplicar(rosario, quitarParte(rosario, parte.id), aviso: 'Se eliminó "${parte.nombre}"'),
              onAgregarOracion: () => _agregarOracion(rosario, parte),
              onCambiarVeces: (elemento, titulo) => _cambiarVeces(rosario, parte, elemento, titulo),
            ),
          );
        },
      ),
    );
  }
}

enum _AccionElemento { subir, bajar, veces, quitar }

class _TarjetaParte extends StatelessWidget {
  const _TarjetaParte({
    required this.parte,
    required this.indice,
    required this.total,
    required this.editable,
    required this.abierta,
    required this.oraciones,
    required this.onAlternar,
    required this.onCambiarParte,
    required this.onMover,
    required this.onDuplicar,
    required this.onEliminar,
    required this.onAgregarOracion,
    required this.onCambiarVeces,
  });

  final ParteRosario parte;
  final int indice;
  final int total;
  final bool editable;
  final bool abierta;
  final Map<String, Oracion> oraciones;
  final VoidCallback onAlternar;
  final void Function(ParteRosario nueva, {String? aviso}) onCambiarParte;
  final ValueChanged<int> onMover;
  final VoidCallback onDuplicar;
  final VoidCallback onEliminar;
  final VoidCallback onAgregarOracion;
  final void Function(ElementoParte elemento, String titulo) onCambiarVeces;

  String get _resumen {
    final n = parte.elementos.length;
    final oracionesTexto = n == 1 ? '1 oración' : '$n oraciones';
    final vueltas = parte.misterios.vueltas;
    return vueltas > 1 ? '$oracionesTexto, $vueltas vueltas' : oracionesTexto;
  }

  @override
  Widget build(BuildContext context) {
    final elementos = parte.elementos;
    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            leading: editable
                ? ReorderableDragStartListener(
                    index: indice,
                    child: const ExcludeSemantics(child: SizedBox.square(dimension: 40, child: Icon(Icons.drag_handle))),
                  )
                : null,
            title: Text(parte.nombre),
            subtitle: Text(_resumen),
            trailing: IconButton(
              onPressed: onAlternar,
              icon: Icon(abierta ? Icons.expand_less : Icons.expand_more),
              tooltip: '${abierta ? 'Cerrar' : 'Abrir'} ${parte.nombre}',
            ),
          ),
          if (abierta) ...[
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: elementos.length,
              onReorder: (desde, hasta) {
                if (editable) onCambiarParte(moverElemento(parte, desde, hasta > desde ? hasta - 1 : hasta));
              },
              itemBuilder: (context, i) {
                final elemento = elementos[i];
                final titulo = oraciones[elemento.oracionId]?.titulo ?? 'Oración no disponible';
                return ListTile(
                  key: ValueKey(elemento.id),
                  leading: editable
                      ? ReorderableDragStartListener(
                          index: i,
                          child: const ExcludeSemantics(child: SizedBox.square(dimension: 40, child: Icon(Icons.drag_handle))),
                        )
                      : null,
                  title: Text(titulo),
                  subtitle: Text(elemento.veces == 1 ? '1 vez' : '${elemento.veces} veces'),
                  trailing: editable
                      ? PopupMenuButton<_AccionElemento>(
                          tooltip: 'Opciones de $titulo',
                          onSelected: (accion) {
                            switch (accion) {
                              case _AccionElemento.subir:
                                onCambiarParte(moverElemento(parte, i, i - 1));
                              case _AccionElemento.bajar:
                                onCambiarParte(moverElemento(parte, i, i + 1));
                              case _AccionElemento.veces:
                                onCambiarVeces(elemento, titulo);
                              case _AccionElemento.quitar:
                                onCambiarParte(quitarElemento(parte, elemento.id), aviso: 'Se quitó "$titulo"');
                            }
                          },
                          itemBuilder: (_) => [
                            if (i > 0) const PopupMenuItem(value: _AccionElemento.subir, child: Text('Mover arriba')),
                            if (i < elementos.length - 1) const PopupMenuItem(value: _AccionElemento.bajar, child: Text('Mover abajo')),
                            const PopupMenuItem(value: _AccionElemento.veces, child: Text('Cambiar veces')),
                            const PopupMenuItem(value: _AccionElemento.quitar, child: Text('Quitar')),
                          ],
                        )
                      : null,
                );
              },
            ),
            if (editable)
              Padding(
                padding: const EdgeInsets.all(AppTokens.espacioS),
                child: Wrap(
                  spacing: AppTokens.espacioXS,
                  runSpacing: AppTokens.espacioXS,
                  children: [
                    if (elementos.length < LimitesBiblioteca.elementos)
                      FilledButton.tonalIcon(
                        onPressed: onAgregarOracion,
                        icon: const Icon(Icons.add),
                        label: const EtiquetaBoton('Agregar oración'),
                      ),
                    if (indice > 0) TextButton(onPressed: () => onMover(indice - 1), child: const EtiquetaBoton('Mover arriba')),
                    if (indice < total - 1) TextButton(onPressed: () => onMover(indice + 1), child: const EtiquetaBoton('Mover abajo')),
                    if (total < LimitesBiblioteca.partes) TextButton(onPressed: onDuplicar, child: const EtiquetaBoton('Duplicar parte')),
                    TextButton(
                      onPressed: onEliminar,
                      style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                      child: const EtiquetaBoton('Eliminar parte'),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
```

Si `flutter analyze` marca `onReorder` como obsoleto, cambiar en los dos `ReorderableListView` a `onReorderItem: (desde, hasta) { ... }`, sin el ajuste `hasta > desde ? hasta - 1 : hasta`, porque esa API ya entrega el índice final.

- [ ] **Step 5: Ver que pasan**

Run: `flutter test test/screens/constructor_rosario_screen_test.dart`
Expected: `All tests passed!`.

Run: `flutter analyze` y `flutter test`
Expected: `No issues found!` y `All tests passed!`.

- [ ] **Step 6: Guardar**

```bash
git add lib/widgets/camino_cuentas.dart lib/widgets/selector_numero.dart lib/widgets/pedir_nombre.dart lib/screens/constructor_rosario_screen.dart test/screens/constructor_rosario_screen_test.dart
git commit -m "feat: constructor del rosario con camino de cuentas"
```

---

### Task 12: Editor de una parte: vueltas y misterios

**Files:**
- Create: `lib/screens/editor_parte_screen.dart`
- Modify: `lib/screens/constructor_rosario_screen.dart`
- Test: `test/screens/editor_parte_screen_test.dart`

**Interfaces:**
- Consumes: `ParteRosario`, `FuenteMisterios` y sus variantes, `SelectorNumero`, `LimitesBiblioteca`.
- Produces: `EditorParteScreen.abrir(BuildContext, ParteRosario)` → `Future<ParteRosario?>`. Textos: `'Editar parte'`, `'Meditar en cada vuelta'`, `'Ninguno'`, `'Misterios del día'`, `'Un grupo fijo'`, `'Mis meditaciones'`, `'Vueltas'`, `'Escribe una meditación por renglón'`.

- [ ] **Step 1: Escribir las pruebas**

`test/screens/editor_parte_screen_test.dart`:

```dart
import 'package:app_resar_rosario/models/prayer_models.dart';
import 'package:app_resar_rosario/models/rosario.dart';
import 'package:app_resar_rosario/screens/editor_parte_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<ParteRosario?> resultados;
  const base = ParteRosario(id: 'p', nombre: 'Decenas', elementos: [], misterios: SinMisterios());

  setUp(() => resultados = []);

  Future<void> abrir(WidgetTester tester, {ParteRosario parte = base}) async {
    await tester.pumpWidget(envolver(
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async => resultados.add(await EditorParteScreen.abrir(context, parte)),
            child: const Text('Abrir'),
          ),
        ),
      ),
      preferencias: await preferenciasDePrueba(),
    ));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
  }

  Future<void> guardar(WidgetTester tester) async {
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
  }

  testWidgets('sin misterios se eligen las vueltas', (tester) async {
    await abrir(tester);
    await tester.tap(find.byTooltip('Más'));
    await tester.pump();
    await guardar(tester);
    expect(resultados.single!.misterios.vueltas, 2);
    expect(resultados.single!.misterios, isA<SinMisterios>());
  });

  testWidgets('misterios del día deja 5 vueltas fijas', (tester) async {
    await abrir(tester);
    await tester.tap(find.text('Misterios del día'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Más'), findsNothing);
    expect(find.text('5 vueltas, una por cada misterio.'), findsOneWidget);
    await guardar(tester);
    expect(resultados.single!.misterios, isA<MisteriosDelDia>());
  });

  testWidgets('un grupo fijo se puede elegir', (tester) async {
    await abrir(tester, parte: base.copyWith(misterios: const GrupoMisterios(TipoMisterio.dolorosos)));
    expect(find.text('Dolorosos'), findsOneWidget);
    await guardar(tester);
    expect((resultados.single!.misterios as GrupoMisterios).tipo, TipoMisterio.dolorosos);
  });

  testWidgets('mis meditaciones usa un renglón por vuelta', (tester) async {
    await abrir(tester);
    await tester.tap(find.text('Mis meditaciones'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(1), 'Por la paz\n\nPor los enfermos\n');
    await guardar(tester);
    expect((resultados.single!.misterios as MeditacionesPropias).textos, ['Por la paz', 'Por los enfermos']);
  });

  testWidgets('mis meditaciones vacías no se guardan', (tester) async {
    await abrir(tester);
    await tester.tap(find.text('Mis meditaciones'));
    await tester.pumpAndSettle();
    await guardar(tester);
    expect(find.text('Escribe al menos una meditación'), findsOneWidget);
    expect(resultados, isEmpty);
  });

  testWidgets('más de 20 meditaciones no se guardan', (tester) async {
    await abrir(tester);
    await tester.tap(find.text('Mis meditaciones'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(1), List.generate(21, (i) => 'Meditación $i').join('\n'));
    await guardar(tester);
    expect(find.text('El máximo es de 20 meditaciones'), findsOneWidget);
  });

  testWidgets('la parte necesita un nombre', (tester) async {
    await abrir(tester);
    await tester.enterText(find.byType(TextFormField).first, '  ');
    await guardar(tester);
    expect(find.text('Escribe un nombre'), findsOneWidget);
  });

  testWidgets('cerrar con cambios pregunta antes de descartar', (tester) async {
    await abrir(tester);
    await tester.tap(find.text('Misterios del día'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Cerrar'));
    await tester.pumpAndSettle();
    expect(find.text('¿Descartar los cambios?'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Ver que fallan**

Run: `flutter test test/screens/editor_parte_screen_test.dart`
Expected: FAIL porque la pantalla no existe.

- [ ] **Step 3: Implementar el editor**

`lib/screens/editor_parte_screen.dart`:

```dart
import 'package:flutter/material.dart';

import '../models/oracion.dart';
import '../models/prayer_models.dart';
import '../models/rosario.dart';
import '../theme/app_tokens.dart';
import '../widgets/etiqueta_boton.dart';
import '../widgets/selector_numero.dart';

enum _Opcion { ninguno, delDia, grupo, propias }

/// Nombre, vueltas y misterios de una parte. Devuelve la parte editada o `null`.
class EditorParteScreen extends StatefulWidget {
  const EditorParteScreen({super.key, required this.parte});

  final ParteRosario parte;

  static Future<ParteRosario?> abrir(BuildContext context, ParteRosario parte) {
    return Navigator.of(context).push<ParteRosario>(
      MaterialPageRoute(fullscreenDialog: true, builder: (_) => EditorParteScreen(parte: parte)),
    );
  }

  @override
  State<EditorParteScreen> createState() => _EditorParteScreenState();
}

class _EditorParteScreenState extends State<EditorParteScreen> {
  final _formulario = GlobalKey<FormState>();
  late final TextEditingController _nombre = TextEditingController(text: widget.parte.nombre);
  late final TextEditingController _meditaciones = TextEditingController(
    text: switch (widget.parte.misterios) {
      MeditacionesPropias(textos: final textos) => textos.join('\n'),
      _ => '',
    },
  );
  late _Opcion _opcion = switch (widget.parte.misterios) {
    SinMisterios() => _Opcion.ninguno,
    MisteriosDelDia() => _Opcion.delDia,
    GrupoMisterios() => _Opcion.grupo,
    MeditacionesPropias() => _Opcion.propias,
  };
  late int _vueltas = widget.parte.misterios is SinMisterios ? widget.parte.misterios.vueltas : 1;
  late TipoMisterio _grupo = switch (widget.parte.misterios) {
    GrupoMisterios(tipo: final tipo) => tipo,
    _ => TipoMisterio.gozosos,
  };
  bool _hayCambios = false;
  bool _cerrando = false;

  @override
  void dispose() {
    _nombre.dispose();
    _meditaciones.dispose();
    super.dispose();
  }

  void _cambiar(VoidCallback cambio) => setState(() {
        cambio();
        _hayCambios = true;
      });

  List<String> get _lineas => [
        for (final linea in _meditaciones.text.split('\n'))
          if (linea.trim().isNotEmpty) linea.trim(),
      ];

  void _guardar() {
    if (!_formulario.currentState!.validate()) return;
    final FuenteMisterios fuente = switch (_opcion) {
      _Opcion.ninguno => SinMisterios(vueltas: _vueltas),
      _Opcion.delDia => const MisteriosDelDia(),
      _Opcion.grupo => GrupoMisterios(_grupo),
      _Opcion.propias => MeditacionesPropias(_lineas),
    };
    _cerrando = true;
    Navigator.of(context).pop(widget.parte.copyWith(nombre: _nombre.text.trim(), misterios: fuente));
  }

  Future<bool> _confirmarDescarte() async {
    final descartar = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        scrollable: true,
        title: const Text('¿Descartar los cambios?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogo, false), child: const EtiquetaBoton('Seguir editando')),
          FilledButton(onPressed: () => Navigator.pop(dialogo, true), child: const EtiquetaBoton('Descartar')),
        ],
      ),
    );
    return descartar ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final esquema = Theme.of(context).colorScheme;

    return PopScope<ParteRosario>(
      canPop: _cerrando || !_hayCambios,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navegador = Navigator.of(context);
        final descartar = await _confirmarDescarte();
        if (!mounted || !descartar) return;
        _cerrando = true;
        navegador.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(icon: const Icon(Icons.close), tooltip: 'Cerrar', onPressed: () => Navigator.maybePop(context)),
          title: MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.3,
            child: const FittedBox(fit: BoxFit.scaleDown, alignment: AlignmentDirectional.centerStart, child: Text('Editar parte')),
          ),
          actions: [
            Padding(
              padding: const EdgeInsetsDirectional.only(end: AppTokens.espacioS),
              child: MediaQuery.withClampedTextScaling(
                maxScaleFactor: 1.3,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 160),
                  child: FilledButton(onPressed: _guardar, child: const EtiquetaBoton('Guardar')),
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
                      TextFormField(
                        controller: _nombre,
                        maxLength: LimitesBiblioteca.nombre,
                        textCapitalization: TextCapitalization.sentences,
                        onChanged: (_) => _cambiar(() {}),
                        decoration: const InputDecoration(labelText: 'Nombre de la parte', border: OutlineInputBorder(), counterText: ''),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Escribe un nombre' : null,
                      ),
                      const SizedBox(height: AppTokens.espacioL),
                      Text('Meditar en cada vuelta', style: textos.titleSmall?.copyWith(color: esquema.primary)),
                      RadioGroup<_Opcion>(
                        groupValue: _opcion,
                        onChanged: (valor) => _cambiar(() => _opcion = valor!),
                        child: const Column(
                          children: [
                            RadioListTile(value: _Opcion.ninguno, title: Text('Ninguno')),
                            RadioListTile(value: _Opcion.delDia, title: Text('Misterios del día')),
                            RadioListTile(value: _Opcion.grupo, title: Text('Un grupo fijo')),
                            RadioListTile(value: _Opcion.propias, title: Text('Mis meditaciones')),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTokens.espacioM),
                      ..._detalle(textos, esquema),
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

  List<Widget> _detalle(TextTheme textos, ColorScheme esquema) => switch (_opcion) {
        _Opcion.ninguno => [
            Text('Vueltas', style: textos.titleSmall?.copyWith(color: esquema.primary)),
            const SizedBox(height: AppTokens.espacioS),
            SelectorNumero(
              valor: _vueltas,
              minimo: 1,
              maximo: LimitesBiblioteca.vueltas,
              etiqueta: 'Vueltas',
              onCambio: (valor) => _cambiar(() => _vueltas = valor),
            ),
          ],
        _Opcion.delDia => [Text('5 vueltas, una por cada misterio.', style: textos.bodyMedium)],
        _Opcion.grupo => [
            DropdownButtonFormField<TipoMisterio>(
              initialValue: _grupo,
              decoration: const InputDecoration(labelText: 'Misterios', border: OutlineInputBorder()),
              items: [
                for (final tipo in TipoMisterio.values) DropdownMenuItem(value: tipo, child: Text(tipo.nombre)),
              ],
              onChanged: (valor) => _cambiar(() => _grupo = valor!),
            ),
            const SizedBox(height: AppTokens.espacioS),
            Text('5 vueltas, una por cada misterio.', style: textos.bodyMedium),
          ],
        _Opcion.propias => [
            TextFormField(
              controller: _meditaciones,
              minLines: 5,
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => _cambiar(() {}),
              decoration: const InputDecoration(
                labelText: 'Escribe una meditación por renglón',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              validator: (_) {
                if (_lineas.isEmpty) return 'Escribe al menos una meditación';
                if (_lineas.length > LimitesBiblioteca.vueltas) return 'El máximo es de ${LimitesBiblioteca.vueltas} meditaciones';
                return null;
              },
            ),
            const SizedBox(height: AppTokens.espacioS),
            Text('Cada meditación es una vuelta.', style: textos.bodyMedium),
          ],
      };
}
```

- [ ] **Step 4: Abrir el editor desde el constructor**

En `lib/screens/constructor_rosario_screen.dart`:
- agregar `import 'editor_parte_screen.dart';`;
- agregar a `_TarjetaParte` el parámetro `required this.onEditar` y el campo `final VoidCallback onEditar;`;
- al crear `_TarjetaParte` en `itemBuilder`, pasar:

```dart
              onEditar: () async {
                final editada = await EditorParteScreen.abrir(context, parte);
                if (editada != null) await _aplicar(rosario, reemplazarParte(rosario, editada));
              },
```

- dentro del `Wrap` de acciones de `_TarjetaParte`, después del botón "Agregar oración":

```dart
                    TextButton(onPressed: onEditar, child: const EtiquetaBoton('Editar parte')),
```

Agregar en `test/screens/constructor_rosario_screen_test.dart`:

```dart
  testWidgets('Editar parte guarda las vueltas', (tester) async {
    final r = await conUnaParte();
    await mostrar(tester, r.id);
    await tester.tap(find.byTooltip('Abrir Inicio'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Editar parte'));
    await tester.tap(find.text('Editar parte'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Más'));
    await tester.pump();
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(biblioteca.rosarioPorId(r.id)!.partes.single.misterios.vueltas, 2);
  });
```

- [ ] **Step 5: Ver que pasan**

Run: `flutter test test/screens/editor_parte_screen_test.dart test/screens/constructor_rosario_screen_test.dart`
Expected: `All tests passed!`.

Run: `flutter analyze` y `flutter test`
Expected: `No issues found!` y `All tests passed!`.

- [ ] **Step 6: Guardar**

```bash
git add lib/screens/editor_parte_screen.dart lib/screens/constructor_rosario_screen.dart test/screens/editor_parte_screen_test.dart test/screens/constructor_rosario_screen_test.dart
git commit -m "feat: editor de partes con vueltas, misterios y meditaciones propias"
```

---

### Task 13: Pantalla "Mis rosarios" y entrada desde inicio

**Files:**
- Create: `lib/screens/mis_rosarios_screen.dart`
- Modify: `lib/screens/inicio_screen.dart`, `lib/widgets/app_drawer.dart`
- Test: `test/screens/mis_rosarios_screen_test.dart`

**Interfaces:**
- Consumes: `BibliotecaService`, `ConstructorRosarioScreen`, `rezarRosario`, `pedirNombre`, `construirPasos`, `rosarioTradicional`.
- Produces: `MisRosariosScreen()`. Textos: `'Crear rosario'`, `'Empezar en blanco'`, `'Partir de otro rosario'`, `'Plantillas'`, `'Mis rosarios'`, `'Rezar'`, `'Duplicar'`, `'Eliminar'`.

- [ ] **Step 1: Escribir las pruebas**

`test/screens/mis_rosarios_screen_test.dart`:

```dart
import 'package:app_resar_rosario/logic/rosario_session.dart';
import 'package:app_resar_rosario/screens/mis_rosarios_screen.dart';
import 'package:app_resar_rosario/services/almacen_rosarios.dart';
import 'package:app_resar_rosario/services/biblioteca_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/almacen_en_memoria.dart';
import '../support/app_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late BibliotecaService biblioteca;
  late RosarioSession sesion;

  setUp(() {
    biblioteca = BibliotecaService(almacen: AlmacenEnMemoria());
    sesion = RosarioSession(reloj: () => lunes);
  });

  Future<void> mostrar(WidgetTester tester) async {
    await tester.pumpWidget(envolver(
      const MisRosariosScreen(),
      preferencias: await preferenciasDePrueba(),
      biblioteca: biblioteca,
      sesion: sesion,
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('el Rosario tradicional siempre está y se puede rezar', (tester) async {
    await mostrar(tester);
    expect(find.text('Rosario tradicional'), findsOneWidget);
    expect(find.text('3 partes, 93 pasos'), findsOneWidget);
    expect(find.text('Eliminar'), findsNothing);
    await tester.tap(find.text('Rezar').first);
    await tester.pumpAndSettle();
    expect(sesion.pasos, hasLength(93));
  });

  testWidgets('crear un rosario en blanco abre el constructor', (tester) async {
    await mostrar(tester);
    await tester.tap(find.text('Crear rosario'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Empezar en blanco'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'De mi familia');
    await tester.tap(find.text('Crear'));
    await tester.pumpAndSettle();
    expect(biblioteca.rosariosPropios.single.nombre, 'De mi familia');
    expect(find.text('Agregar parte'), findsOneWidget);
  });

  testWidgets('crear desde el tradicional hace una copia editable', (tester) async {
    await mostrar(tester);
    await tester.tap(find.text('Crear rosario'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Partir de otro rosario'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rosario tradicional').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Mi versión');
    await tester.tap(find.text('Crear'));
    await tester.pumpAndSettle();
    expect(biblioteca.rosariosPropios.single.partes, hasLength(3));
  });

  testWidgets('duplicar y eliminar un rosario propio', (tester) async {
    await biblioteca.crearRosario('Mío');
    await mostrar(tester);
    await tester.ensureVisible(find.text('Duplicar'));
    await tester.tap(find.text('Duplicar'));
    await tester.pumpAndSettle();
    expect(biblioteca.rosariosPropios, hasLength(2));

    await tester.ensureVisible(find.text('Eliminar').first);
    await tester.tap(find.text('Eliminar').first);
    await tester.pumpAndSettle();
    expect(find.text('Eliminar rosario'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
    await tester.pumpAndSettle();
    expect(biblioteca.rosariosPropios, hasLength(1));
  });

  testWidgets('avisa si los datos se recuperaron de un respaldo', (tester) async {
    biblioteca = BibliotecaService(almacen: AlmacenEnMemoria(inicial: const DatosUsuario(recuperado: true)));
    await biblioteca.cargar();
    await mostrar(tester);
    expect(find.textContaining('respaldo'), findsOneWidget);
  });

  testWidgets('avisa si no se pudo guardar', (tester) async {
    final almacen = AlmacenEnMemoria()..fallarAlGuardar = true;
    biblioteca = BibliotecaService(almacen: almacen);
    await biblioteca.crearRosario('Mío');
    await mostrar(tester);
    expect(find.textContaining('No se pudieron guardar'), findsOneWidget);
  });
}
```

Agregar en `test/screens/principal_screen_test.dart`:

```dart
  testWidgets('inicio ofrece Mis rosarios', (tester) async {
    await tester.pumpWidget(await appDePrueba());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mis rosarios'));
    await tester.pumpAndSettle();
    expect(find.text('Rosario tradicional'), findsOneWidget);
  });
```

- [ ] **Step 2: Ver que fallan**

Run: `flutter test test/screens/mis_rosarios_screen_test.dart`
Expected: FAIL porque la pantalla no existe.

- [ ] **Step 3: Implementar la pantalla**

`lib/screens/mis_rosarios_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/rosario_tradicional.dart';
import '../logic/rosario_session.dart';
import '../models/rosario.dart';
import '../services/biblioteca_service.dart';
import '../theme/app_tokens.dart';
import '../widgets/etiqueta_boton.dart';
import '../widgets/pedir_nombre.dart';
import 'constructor_rosario_screen.dart';

/// El tradicional, las plantillas y los rosarios propios.
class MisRosariosScreen extends StatelessWidget {
  const MisRosariosScreen({super.key});

  Future<void> _crear(BuildContext context) async {
    final biblioteca = context.read<BibliotecaService>();
    final navegador = Navigator.of(context);
    final desdeOtro = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (hoja) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('Empezar en blanco'),
                onTap: () => Navigator.pop(hoja, false),
              ),
              ListTile(
                leading: const Icon(Icons.copy_all_outlined),
                title: const Text('Partir de otro rosario'),
                onTap: () => Navigator.pop(hoja, true),
              ),
            ],
          ),
        ),
      ),
    );
    if (desdeOtro == null || !context.mounted) return;

    Rosario? base;
    if (desdeOtro) {
      base = await showDialog<Rosario>(
        context: context,
        builder: (dialogo) => SimpleDialog(
          title: const Text('Partir de'),
          children: [
            for (final r in [rosarioTradicional, ...biblioteca.plantillas, ...biblioteca.rosariosPropios])
              SimpleDialogOption(
                onPressed: () => Navigator.pop(dialogo, r),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppTokens.espacioS),
                  child: Text(r.nombre),
                ),
              ),
          ],
        ),
      );
      if (base == null || !context.mounted) return;
    }

    final nombre = await pedirNombre(context, titulo: 'Nombre de tu rosario', inicial: base?.nombre ?? '', accion: 'Crear');
    if (nombre == null) return;
    final creado = await biblioteca.crearRosario(nombre, base: base);
    navegador.push(MaterialPageRoute<void>(builder: (_) => ConstructorRosarioScreen(rosarioId: creado.id)));
  }

  @override
  Widget build(BuildContext context) {
    final biblioteca = context.watch<BibliotecaService>();
    final textos = Theme.of(context).textTheme;
    final esquema = Theme.of(context).colorScheme;
    final margen = AppTokens.margenLateral(MediaQuery.sizeOf(context).width);
    final plantillas = biblioteca.plantillas;
    final propios = biblioteca.rosariosPropios;

    Widget titulo(String texto) => Padding(
          padding: const EdgeInsets.only(top: AppTokens.espacioL, bottom: AppTokens.espacioS),
          child: Text(texto, style: textos.titleSmall?.copyWith(color: esquema.primary)),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Mis rosarios')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _crear(context),
        icon: const Icon(Icons.add),
        label: const Text('Crear rosario'),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppTokens.espacioM + margen,
          AppTokens.espacioS,
          AppTokens.espacioM + margen,
          MediaQuery.textScalerOf(context).scale(56) + AppTokens.espacioXL + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          if (biblioteca.datosRecuperados)
            const _Aviso('Tus datos estaban dañados y se recuperó el último respaldo disponible.'),
          if (biblioteca.errorAlGuardar)
            const _Aviso('No se pudieron guardar tus últimos cambios. Revisa el espacio libre de tu teléfono.'),
          _TarjetaRosario(rosario: rosarioTradicional),
          if (plantillas.isNotEmpty) ...[
            titulo('Plantillas'),
            for (final r in plantillas) _TarjetaRosario(rosario: r),
          ],
          titulo('Mis rosarios'),
          if (propios.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppTokens.espacioM),
              child: Text(
                'Toca «Crear rosario» para armar el tuyo.',
                style: textos.bodyMedium?.copyWith(color: esquema.onSurfaceVariant),
              ),
            ),
          for (final r in propios) _TarjetaRosario(rosario: r),
        ],
      ),
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Card(
      color: esquema.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.espacioM),
        child: Text(texto, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: esquema.onSecondaryContainer)),
      ),
    );
  }
}

class _TarjetaRosario extends StatelessWidget {
  const _TarjetaRosario({required this.rosario});

  final Rosario rosario;

  Future<void> _eliminar(BuildContext context) async {
    final biblioteca = context.read<BibliotecaService>();
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        scrollable: true,
        title: const Text('Eliminar rosario'),
        content: Text('¿Quieres eliminar "${rosario.nombre}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogo, false), child: const EtiquetaBoton('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(dialogo, true), child: const EtiquetaBoton('Eliminar')),
        ],
      ),
    );
    if (confirmado ?? false) await biblioteca.eliminarRosario(rosario.id);
  }

  @override
  Widget build(BuildContext context) {
    final biblioteca = context.read<BibliotecaService>();
    final textos = Theme.of(context).textTheme;
    final esquema = Theme.of(context).colorScheme;
    final pasos = construirPasos(rosario: rosario, oraciones: context.watch<BibliotecaService>().mapaOraciones).length;
    final partes = rosario.partes.length;
    final resumen = '${partes == 1 ? '1 parte' : '$partes partes'}, ${pasos == 1 ? '1 paso' : '$pasos pasos'}';

    return Card(
      margin: const EdgeInsets.only(bottom: AppTokens.espacioS),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => ConstructorRosarioScreen(rosarioId: rosario.id)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.espacioM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(rosario.esProtegido ? Icons.lock_outline : Icons.favorite_border, color: esquema.primary),
                  const SizedBox(width: AppTokens.espacioS),
                  Expanded(child: Text(rosario.nombre, style: textos.titleMedium)),
                ],
              ),
              const SizedBox(height: AppTokens.espacioXS),
              Text(resumen, style: textos.bodyMedium?.copyWith(color: esquema.onSurfaceVariant)),
              const SizedBox(height: AppTokens.espacioS),
              Wrap(
                spacing: AppTokens.espacioXS,
                runSpacing: AppTokens.espacioXS,
                children: [
                  FilledButton(
                    onPressed: pasos == 0 ? null : () => rezarRosario(context, rosario),
                    child: const EtiquetaBoton('Rezar'),
                  ),
                  if (!rosario.esProtegido) ...[
                    TextButton(onPressed: () => biblioteca.duplicarRosario(rosario.id), child: const EtiquetaBoton('Duplicar')),
                    TextButton(
                      onPressed: () => _eliminar(context),
                      style: TextButton.styleFrom(foregroundColor: esquema.error),
                      child: const EtiquetaBoton('Eliminar'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Agregar las entradas**

En `lib/widgets/app_drawer.dart`, agregar `import '../screens/mis_rosarios_screen.dart';` y, antes de "Mis oraciones":

```dart
            ListTile(
              leading: const Icon(Icons.auto_awesome_motion_outlined),
              title: const Text('Mis rosarios'),
              subtitle: const Text('Crear y personalizar'),
              onTap: () => abrirDesdeMenu(context, (_) => const MisRosariosScreen()),
            ),
```

En `lib/screens/inicio_screen.dart`, agregar los imports de `mis_rosarios_screen.dart` y `etiqueta_boton.dart`, y reemplazar el `Padding` que contiene el botón fijo por:

```dart
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppTokens.espacioL, AppTokens.espacioS, AppTokens.espacioL, AppTokens.espacioS),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FilledButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            sesion.comenzar();
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: colores.boton,
                            foregroundColor: colores.sobreBoton,
                          ),
                          // La etiqueta no se parte: si no cabe con letra grande, se reduce.
                          child: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.favorite_rounded),
                                SizedBox(width: AppTokens.espacioS),
                                Text('Comenzar a Rezar', maxLines: 1),
                              ],
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const MisRosariosScreen())),
                          style: TextButton.styleFrom(foregroundColor: secciones.tituloInicio),
                          child: const EtiquetaBoton('Mis rosarios'),
                        ),
                      ],
                    ),
                  ),
```

Si la prueba existente de "espacio para desplazar" de `test/screens/principal_screen_test.dart` falla a 360×640, no relajarla: mover el `TextButton` "Mis rosarios" al contenido desplazable, justo debajo de la tarjeta `_MisterioDelDia`.

- [ ] **Step 5: Ver que pasan**

Run: `flutter test test/screens/mis_rosarios_screen_test.dart test/screens/principal_screen_test.dart test/widgets/app_drawer_test.dart`
Expected: `All tests passed!`.

Run: `flutter analyze` y `flutter test`
Expected: `No issues found!` y `All tests passed!`.

- [ ] **Step 6: Guardar**

```bash
git add lib/screens/mis_rosarios_screen.dart lib/screens/inicio_screen.dart lib/widgets/app_drawer.dart test/screens/mis_rosarios_screen_test.dart test/screens/principal_screen_test.dart
git commit -m "feat: pantalla Mis rosarios y entrada desde el inicio y el menú"
```

---

### Task 14: Auditoría, matriz y recorrido completo de lo nuevo

**Files:**
- Modify: `test/support/recorridos_app.dart`
- Create: `test/constructor_completo_test.dart`
- Modify: los archivos de `lib/` que marquen la auditoría o la matriz

**Interfaces:**
- Consumes: `recorridos`, `tocar`, `appDePrueba({biblioteca})`, `AlmacenEnMemoria`.

- [ ] **Step 1: Agregar los recorridos**

En `test/support/recorridos_app.dart`, cambiar en `_abrirDesdeMenu` la última línea por `await tocar(tester, find.text(opcion).last);`: el inicio también muestra "Mis rosarios", y la opción del menú es la última en el árbol.

Agregar este ayudante antes de la lista `recorridos`, porque una lista larga no construye lo que queda fuera de la pantalla:

```dart
/// Busca una oración en la biblioteca y la toca.
Future<void> _tocarOracion(WidgetTester tester, String busqueda, String titulo) async {
  await tester.enterText(find.byType(TextField).first, busqueda);
  await tester.pumpAndSettle();
  await tocar(tester, find.text(titulo));
}
```

Agregar al final de la lista `recorridos`:

```dart
  Recorrido('mis oraciones', (tester, revisar) async {
    await _abrirDesdeMenu(tester, 'Mis oraciones');
    await revisar('mis oraciones');
    await tocar(tester, find.text('Nueva'));
    await revisar('opciones de oración nueva');
    await tocar(tester, find.text('Escribir'));
    await revisar('formulario de oración');
    await tocar(tester, find.text('Guardar'));
    await revisar('formulario de oración con errores');
    await tester.enterText(find.byType(TextFormField).at(0), 'Por la paz');
    await tester.enterText(find.byType(TextFormField).at(1), 'Señor, danos tu paz.');
    await tester.pumpAndSettle();
    await tocar(tester, find.byTooltip('Cerrar'));
    await revisar('descartar oración');
    await tocar(tester, find.text('Seguir editando'));
    await tocar(tester, find.text('Guardar'));
    await tocar(tester, find.text('Mías'));
    await revisar('oraciones propias');
    await tocar(tester, find.text('Por la paz'));
    await revisar('detalle de oración propia');
    await tocar(tester, find.text('Eliminar'));
    await revisar('eliminar oración');
    await tocar(tester, find.text('Cancelar'));
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tocar(tester, find.text('De la app'));
    await _tocarOracion(tester, 'ave maria', 'Ave María');
    await revisar('detalle de oración de la app');
  }),
  Recorrido('mis rosarios y constructor', (tester, revisar) async {
    await _abrirDesdeMenu(tester, 'Mis rosarios');
    await revisar('mis rosarios');
    await tocar(tester, find.text('Rosario tradicional'));
    await revisar('tradicional de solo lectura');
    await tocar(tester, find.byTooltip('Abrir Misterios del día'));
    await revisar('parte abierta de solo lectura');
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tocar(tester, find.text('Crear rosario'));
    await revisar('opciones de rosario nuevo');
    await tocar(tester, find.text('Empezar en blanco'));
    await revisar('nombre del rosario');
    await tester.enterText(find.byType(TextField), 'De mi familia');
    await tester.pumpAndSettle();
    await tocar(tester, find.text('Crear'));
    await revisar('constructor vacío');
    await tocar(tester, find.text('Agregar parte'));
    await tester.enterText(find.byType(TextField), 'Inicio');
    await tester.pumpAndSettle();
    await tocar(tester, find.text('Agregar'));
    await revisar('parte vacía');
    await tocar(tester, find.text('Agregar oración'));
    await revisar('elegir oración');
    await _tocarOracion(tester, 'ave maria', 'Ave María');
    await revisar('parte con una oración');
    await tocar(tester, find.byTooltip('Opciones de Ave María'));
    await revisar('menú de la oración');
    await tocar(tester, find.text('Cambiar veces'));
    await revisar('cambiar veces');
    await tocar(tester, find.text('Cancelar'));
    await tocar(tester, find.text('Editar parte'));
    await revisar('editar parte');
    await tocar(tester, find.text('Mis meditaciones'));
    await revisar('editar parte con meditaciones');
    await tocar(tester, find.text('Un grupo fijo'));
    await revisar('editar parte con grupo');
    await tocar(tester, find.text('Guardar'));
    await revisar('constructor con misterios');
    await tocar(tester, find.text('Rezar'));
    await revisar('rezo del rosario propio');
  }),
```

- [ ] **Step 2: Escribir el recorrido de punta a punta**

`test/constructor_completo_test.dart`:

```dart
import 'package:app_resar_rosario/logic/rosario_session.dart';
import 'package:app_resar_rosario/services/biblioteca_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'support/almacen_en_memoria.dart';
import 'support/app_harness.dart';
import 'support/recorridos_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('crear un rosario, rezarlo completo y encontrarlo igual al reabrir la app', (tester) async {
    final almacen = AlmacenEnMemoria();
    await tester.pumpWidget(await appDePrueba(biblioteca: BibliotecaService(almacen: almacen)));
    await tester.pumpAndSettle();

    await tocar(tester, find.text('Mis rosarios'));
    await tocar(tester, find.text('Crear rosario'));
    await tocar(tester, find.text('Empezar en blanco'));
    await tester.enterText(find.byType(TextField), 'De mi familia');
    await tester.pumpAndSettle();
    await tocar(tester, find.text('Crear'));
    await tocar(tester, find.text('Agregar parte'));
    await tester.enterText(find.byType(TextField), 'Inicio');
    await tester.pumpAndSettle();
    await tocar(tester, find.text('Agregar'));
    await tocar(tester, find.text('Agregar oración'));
    await tester.enterText(find.byType(TextField), 'gloria');
    await tester.pumpAndSettle();
    await tocar(tester, find.text('Gloria'));
    await tocar(tester, find.text('Rezar'));

    expect(find.text('Inicio · 1 de 1'), findsOneWidget);
    expect(find.text('Gloria'), findsOneWidget);
    await tocar(tester, find.text('Terminar Rosario'));
    expect(find.text('Comenzar a Rezar'), findsOneWidget);

    // La app se vuelve a abrir con los mismos datos guardados.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(await appDePrueba(biblioteca: BibliotecaService(almacen: almacen)));
    await tester.pumpAndSettle();
    await tocar(tester, find.text('Mis rosarios'));
    expect(find.text('De mi familia'), findsOneWidget);
    expect(find.text('1 parte, 1 paso'), findsOneWidget);
  });

  testWidgets('Comenzar a Rezar sigue iniciando el tradicional con sus 93 pasos', (tester) async {
    await tester.pumpWidget(await appDePrueba());
    await tester.pumpAndSettle();
    await tocar(tester, find.text('Comenzar a Rezar'));
    final contexto = tester.element(find.text('Continuar'));
    expect(Provider.of<RosarioSession>(contexto, listen: false).pasos, hasLength(93));
  });
}
```

- [ ] **Step 3: Correr auditoría, matriz y recorrido**

Run: `flutter test test/constructor_completo_test.dart`
Run: `flutter test test/accesibilidad/`
Run: `flutter test test/responsivo_test.dart`
Expected: es posible que haya fallas, porque cubren pantallas nuevas.

- [ ] **Step 4: Corregir cada falla en el código**

Se corrige la causa, nunca la prueba. Patrones frecuentes:
- **Contraste:** usar el par correcto del `ColorScheme` (`onX` sobre `X`) o `onSurfaceVariant` → `onSurface`.
- **Desborde en una `Row`:** envolver el texto en `Expanded` o `Flexible`.
- **`bottomNavigationBar` del constructor demasiado alto en horizontal con letra grande:** dejar la barra de botones en una sola fila con `Expanded`, y mover el texto de `motivo` al inicio de la lista desplazable.
- **Etiqueta en dos líneas:** usar `EtiquetaBoton`.
- **Tooltip o etiqueta faltante:** agregarla.

Si un recorrido asume algo falso sobre la app, corregir el recorrido y explicarlo en el reporte. Recordar la regla 8 del índice sobre la fuente de pruebas.

- [ ] **Step 5: Suite completa y guardar**

Run: `flutter analyze` y `flutter test`
Expected: `No issues found!` y `All tests passed!`.

Run: `graphify update .`

```bash
git add test/support/recorridos_app.dart test/constructor_completo_test.dart
git add lib/screens lib/widgets
git commit -m "test: auditoría, matriz y recorrido completo del constructor de rosarios"
```
