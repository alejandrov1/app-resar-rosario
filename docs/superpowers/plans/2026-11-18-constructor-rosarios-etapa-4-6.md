# Constructor de rosarios — Etapas 4, 5 y 6: plantillas, cámara y recibir texto

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Para la pantalla de la Task 17 aplicar también **frontend-design:frontend-design**.

**Goal:** Incluir tres plantillas de rosario, leer oraciones impresas con la cámara y recibir texto compartido desde otras apps en Android.

**Architecture:** Las plantillas son datos protegidos que solo se publican con los textos validados. La cámara y el lector están detrás de `SelectorImagen` y `LectorTexto`; la limpieza del texto es una función pura. La recepción de texto pasa por `TextoRecibido` y abre el formulario de oración, sin guardar nada por su cuenta.

**Tech Stack:** google_mlkit_text_recognition, image_picker, receive_sharing_intent.

**Spec:** `docs/superpowers/specs/2026-11-18-constructor-rosarios-design.md` · **Índice:** `docs/superpowers/plans/2026-11-18-constructor-rosarios.md`

## Global Constraints

Se aplican todas las del índice, incluida la sección "Reglas aprendidas en este proyecto".

---

### Task 15: Plantillas con validación de textos

**Files:**
- Modify: `lib/data/plantillas_rosario.dart`, `lib/services/biblioteca_service.dart`
- Create: `docs/plantillas-para-validar.md`
- Test: `test/data/plantillas_rosario_test.dart`

**Interfaces:**
- Consumes: `PlantillaRosario`, `idDeApp`, `BibliotecaService.plantillas`.
- Produces: tres plantillas en `plantillasRosario`, con ids `plantilla:divina_misericordia`, `plantilla:siete_dolores` y `plantilla:difuntos`.

- [ ] **Step 1: Escribir las pruebas**

`test/data/plantillas_rosario_test.dart`:

```dart
import 'package:app_resar_rosario/data/plantillas_rosario.dart';
import 'package:app_resar_rosario/data/rosario_tradicional.dart';
import 'package:app_resar_rosario/logic/rosario_session.dart';
import 'package:app_resar_rosario/models/rosario.dart';
import 'package:app_resar_rosario/services/biblioteca_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/almacen_en_memoria.dart';

void main() {
  final oraciones = {...oracionesDeLaApp, ...oracionesDePlantillas};

  Rosario plantilla(String id) => plantillasRosario.firstWhere((p) => p.rosario.id == id).rosario;
  int pasos(String id) => construirPasos(rosario: plantilla(id), oraciones: oraciones).length;

  test('son las tres plantillas acordadas y están protegidas', () {
    expect(plantillasRosario.map((p) => p.rosario.nombre), ['Divina Misericordia', 'Siete Dolores de María', 'Por los difuntos']);
    expect(plantillasRosario.every((p) => p.rosario.tipo == TipoRosario.plantilla), isTrue);
  });

  test('todas sus oraciones existen', () {
    for (final p in plantillasRosario) {
      for (final parte in p.rosario.partes) {
        for (final e in parte.elementos) {
          expect(oraciones[e.oracionId], isNotNull, reason: '${p.rosario.nombre}: ${e.oracionId}');
        }
      }
    }
  });

  test('cada plantilla tiene la estructura esperada', () {
    expect(pasos('plantilla:divina_misericordia'), 62); // 4 + 5 × (1 + 10) + 3
    expect(pasos('plantilla:siete_dolores'), 66); // 2 + 7 × (anuncio + 1 + 7) + 1
    expect(pasos('plantilla:difuntos'), 63); // 2 + 5 × (1 + 10 + 1) + 1
  });

  test('las plantillas sin validar no aparecen en la versión publicada', () async {
    final publicada = BibliotecaService(almacen: AlmacenEnMemoria(), mostrarSinValidar: false);
    final validadas = plantillasRosario.where((p) => p.textosValidados).length;
    expect(publicada.plantillas, hasLength(validadas));
    if (validadas == 0) {
      expect(publicada.oracionesApp.any((o) => o.titulo == 'Credo'), isFalse);
    }
  });

  test('en depuración se pueden revisar todas', () {
    final depuracion = BibliotecaService(almacen: AlmacenEnMemoria(), mostrarSinValidar: true);
    expect(depuracion.plantillas, hasLength(3));
    expect(depuracion.oracionesApp.any((o) => o.titulo == 'Credo'), isTrue);
  });
}
```

- [ ] **Step 2: Ver que fallan**

Run: `flutter test test/data/plantillas_rosario_test.dart`
Expected: FAIL porque la lista de plantillas está vacía.

- [ ] **Step 3: Agregar el contenido**

Reemplazar `lib/data/plantillas_rosario.dart` completo:

```dart
import '../models/oracion.dart';
import '../models/rosario.dart';
import 'rosario_tradicional.dart';

/// Un rosario incluido en la app. Sin validar sus textos, no aparece en la versión publicada.
class PlantillaRosario {
  const PlantillaRosario({required this.rosario, required this.textosValidados});

  final Rosario rosario;
  final bool textosValidados;
}

Oracion _oracion(String tipo, String titulo, String texto) =>
    Oracion(id: idDeApp(tipo), titulo: titulo, texto: texto, origen: OrigenOracion.app);

/// Oraciones que solo usan las plantillas.
final Map<String, Oracion> oracionesDePlantillas = Map.unmodifiable({
  for (final o in [
    _oracion(
      'credo',
      'Credo',
      'Creo en Dios, Padre todopoderoso, Creador del cielo y de la tierra. Creo en Jesucristo, su único Hijo, '
          'nuestro Señor, que fue concebido por obra y gracia del Espíritu Santo, nació de santa María Virgen, '
          'padeció bajo el poder de Poncio Pilato, fue crucificado, muerto y sepultado, descendió a los infiernos, '
          'al tercer día resucitó de entre los muertos, subió a los cielos y está sentado a la derecha de Dios, '
          'Padre todopoderoso. Desde allí ha de venir a juzgar a vivos y muertos. Creo en el Espíritu Santo, la '
          'santa Iglesia católica, la comunión de los santos, el perdón de los pecados, la resurrección de la '
          'carne y la vida eterna. Amén.',
    ),
    _oracion(
      'padre_eterno',
      'Padre Eterno',
      'Padre Eterno, te ofrezco el Cuerpo y la Sangre, el Alma y la Divinidad de tu amadísimo Hijo, nuestro '
          'Señor Jesucristo, como propiciación de nuestros pecados y los del mundo entero.',
    ),
    _oracion(
      'dolorosa_pasion',
      'Por su dolorosa Pasión',
      'Por su dolorosa Pasión, ten misericordia de nosotros y del mundo entero.',
    ),
    _oracion(
      'santo_dios',
      'Santo Dios',
      'Santo Dios, Santo Fuerte, Santo Inmortal, ten piedad de nosotros y del mundo entero.',
    ),
    _oracion(
      'virgen_dolorosa',
      'Virgen dolorosísima',
      'Ruega por nosotros, Virgen dolorosísima.\nPara que seamos dignos de alcanzar las promesas de Jesucristo.',
    ),
    _oracion(
      'descanso_eterno',
      'Dales, Señor, el descanso eterno',
      'Dales, Señor, el descanso eterno.\nY brille para ellos la luz perpetua.',
    ),
    _oracion(
      'descansen_en_paz',
      'Descansen en paz',
      'Que las almas de los fieles difuntos, por la misericordia de Dios, descansen en paz. Amén.',
    ),
  ])
    o.id: o,
});

ElementoParte _e(String parte, String tipo, [int veces = 1]) =>
    ElementoParte(id: 'plantilla:$parte:$tipo', oracionId: idDeApp(tipo), veces: veces);

ParteRosario _parte(String id, String nombre, List<ElementoParte> elementos, [FuenteMisterios misterios = const SinMisterios()]) =>
    ParteRosario(id: 'plantilla:$id', nombre: nombre, elementos: elementos, misterios: misterios);

/// Cambiar `textosValidados` a `true` solo cuando el usuario apruebe `docs/plantillas-para-validar.md`.
final List<PlantillaRosario> plantillasRosario = List.unmodifiable([
  PlantillaRosario(
    textosValidados: false,
    rosario: Rosario(
      id: 'plantilla:divina_misericordia',
      nombre: 'Divina Misericordia',
      tipo: TipoRosario.plantilla,
      partes: [
        _parte('dm_inicio', 'Oraciones iniciales', [
          _e('dm_inicio', 'inicio'),
          _e('dm_inicio', 'padrenuestro'),
          _e('dm_inicio', 'avemaria'),
          _e('dm_inicio', 'credo'),
        ]),
        _parte(
          'dm_decenas',
          'Decenas',
          [_e('dm_decenas', 'padre_eterno'), _e('dm_decenas', 'dolorosa_pasion', 10)],
          const SinMisterios(vueltas: 5),
        ),
        _parte('dm_final', 'Oración final', [_e('dm_final', 'santo_dios', 3)]),
      ],
    ),
  ),
  PlantillaRosario(
    textosValidados: false,
    rosario: Rosario(
      id: 'plantilla:siete_dolores',
      nombre: 'Siete Dolores de María',
      tipo: TipoRosario.plantilla,
      partes: [
        _parte('sd_inicio', 'Oraciones iniciales', [_e('sd_inicio', 'inicio'), _e('sd_inicio', 'contricion')]),
        _parte(
          'sd_dolores',
          'Los siete dolores',
          [_e('sd_dolores', 'padrenuestro'), _e('sd_dolores', 'avemaria', 7)],
          const MeditacionesPropias([
            'La profecía de Simeón',
            'La huida a Egipto',
            'El Niño perdido en el templo',
            'María encuentra a Jesús camino del Calvario',
            'La crucifixión y muerte de Jesús',
            'María recibe en sus brazos el cuerpo de Jesús',
            'La sepultura de Jesús',
          ]),
        ),
        _parte('sd_final', 'Oración final', [_e('sd_final', 'virgen_dolorosa')]),
      ],
    ),
  ),
  PlantillaRosario(
    textosValidados: false,
    rosario: Rosario(
      id: 'plantilla:difuntos',
      nombre: 'Por los difuntos',
      tipo: TipoRosario.plantilla,
      partes: [
        _parte('df_inicio', 'Oraciones iniciales', [_e('df_inicio', 'inicio'), _e('df_inicio', 'contricion')]),
        _parte(
          'df_decenas',
          'Decenas',
          [_e('df_decenas', 'padrenuestro'), _e('df_decenas', 'descanso_eterno', 10), _e('df_decenas', 'descansen_en_paz')],
          const SinMisterios(vueltas: 5),
        ),
        _parte('df_final', 'Oración final', [_e('df_final', 'salve')]),
      ],
    ),
  ),
]);
```

En `lib/services/biblioteca_service.dart`, reemplazar `oracionesApp` por:

```dart
  /// Oraciones de las plantillas que el usuario puede ver.
  Iterable<Oracion> get _oracionesDePlantillasVisibles {
    final ids = {
      for (final r in plantillas)
        for (final p in r.partes)
          for (final e in p.elementos) e.oracionId,
    };
    return oracionesDePlantillas.values.where((o) => ids.contains(o.id));
  }

  /// Oraciones de la app sin repetir: varias partes del rosario rezan la misma oración.
  List<Oracion> get oracionesApp {
    final vistas = <String>{};
    return [
      for (final o in [...oracionesDeLaApp.values, ..._oracionesDePlantillasVisibles])
        if (vistas.add('${o.titulo}\n${o.texto}')) o,
    ];
  }
```

- [ ] **Step 4: Ver que pasan**

Run: `flutter test test/data/plantillas_rosario_test.dart`
Expected: `All tests passed!`.

Run: `flutter analyze` y `flutter test`
Expected: `No issues found!` y `All tests passed!`. Si una prueba existente encuentra varios botones "Rezar", ajustarla a la tarjeta que corresponde: en depuración ahora se muestran las plantillas.

- [ ] **Step 5: Escribir el documento de validación**

Crear `docs/plantillas-para-validar.md` con este encabezado y, debajo, una sección por plantilla que copie **textualmente** de `lib/data/plantillas_rosario.dart` sus partes, número de vueltas, veces de cada oración y el texto completo de cada oración nueva:

```markdown
# Plantillas para validar

Estas plantillas solo aparecen en la versión publicada cuando sus textos estén aprobados.
Revisa cada oración contra tu devocionario o la fuente que uses en tu comunidad. Marca cada casilla al aprobarla
y anota aquí cualquier corrección.

- [ ] Divina Misericordia
- [ ] Siete Dolores de María
- [ ] Por los difuntos
```

- [ ] **Step 6: Guardar**

```bash
git add lib/data/plantillas_rosario.dart lib/services/biblioteca_service.dart docs/plantillas-para-validar.md test/data/plantillas_rosario_test.dart
git commit -m "feat: plantillas de rosario, ocultas hasta validar sus textos"
```

- [ ] **Step 7: Pedir la validación al usuario**

Mostrar al usuario `docs/plantillas-para-validar.md`. Por cada plantilla que apruebe, aplicar sus correcciones y cambiar su `textosValidados` a `true`. Las que no apruebe se quedan en `false`; esto **no detiene** las tareas siguientes.

```bash
git add lib/data/plantillas_rosario.dart docs/plantillas-para-validar.md
git commit -m "feat: plantillas validadas por el usuario"
```

Cerrar la etapa con `graphify update .`.

---

### Task 16: Limpieza del texto, lector y selector de imagen

**Files:**
- Create: `lib/logic/limpieza_texto.dart`, `lib/services/lector_texto.dart`, `lib/services/selector_imagen.dart`
- Modify: `lib/services/servicios_dispositivo.dart`, `test/support/servicios_falsos.dart`
- Test: `test/logic/limpieza_texto_test.dart`

**Interfaces:**
- Produces:
  - `String limpiarTextoLeido(List<List<String>> bloques)` y `String tituloSugerido(String texto)`.
  - `abstract interface class LectorTexto { Future<List<List<String>>> leer(String rutaImagen); }` y `LectorTextoMlKit`.
  - `enum OrigenFoto { camara, galeria }`; `abstract interface class SelectorImagen { Future<String?> elegir(OrigenFoto origen); Future<String?> recuperarPerdida(); Future<void> descartar(String ruta); }` y `SelectorImagenSistema`.
  - `ServiciosDispositivo` agrega `lector` y `selectorImagen`.
  - En pruebas: `LectorFalso` con `bloques` y `fallar`; `SelectorFalso` con `ruta`, `perdida` y `descartadas`; `serviciosDePrueba({compartir, lector, selector})`.

- [ ] **Step 1: Escribir las pruebas**

`test/logic/limpieza_texto_test.dart`:

```dart
import 'package:app_resar_rosario/logic/limpieza_texto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('une los renglones de un párrafo', () {
    expect(
      limpiarTextoLeido([
        ['Dios te salve, María,', 'llena eres de gracia;'],
      ]),
      'Dios te salve, María, llena eres de gracia;',
    );
  });

  test('une las palabras cortadas con guion al final del renglón', () {
    expect(
      limpiarTextoLeido([
        ['bendita Tú eres en-', 'tre todas las mujeres'],
      ]),
      'bendita Tú eres entre todas las mujeres',
    );
  });

  test('conserva el guion si el renglón siguiente empieza con mayúscula', () {
    expect(
      limpiarTextoLeido([
        ['Oración -', 'Amén'],
      ]),
      'Oración - Amén',
    );
  });

  test('separa los bloques en párrafos', () {
    expect(
      limpiarTextoLeido([
        ['Primer párrafo'],
        ['Segundo párrafo'],
      ]),
      'Primer párrafo\n\nSegundo párrafo',
    );
  });

  test('limpia espacios de más y descarta bloques vacíos', () {
    expect(
      limpiarTextoLeido([
        ['  Señor   mío  ', '   '],
        ['   '],
      ]),
      'Señor mío',
    );
  });

  test('sin texto devuelve vacío', () {
    expect(limpiarTextoLeido(const []), '');
  });

  test('sugiere como título el primer renglón', () {
    expect(tituloSugerido('Oración a San José\n\nGlorioso patriarca'), 'Oración a San José');
  });

  test('un título largo se corta en una palabra completa', () {
    final titulo = tituloSugerido('Señor mío Jesucristo, Dios y hombre verdadero, Creador, Padre y Redentor mío, por ser Tú quien eres');
    expect(titulo.length, lessThanOrEqualTo(60));
    expect(titulo, 'Señor mío Jesucristo, Dios y hombre verdadero, Creador,');
  });
}
```

- [ ] **Step 2: Ver que fallan**

Run: `flutter test test/logic/limpieza_texto_test.dart`
Expected: FAIL porque el archivo no existe.

- [ ] **Step 3: Implementar la limpieza**

`lib/logic/limpieza_texto.dart`:

```dart
const int _largoTitulo = 60;

final RegExp _espacios = RegExp(r'\s+');
final RegExp _empiezaMinuscula = RegExp(r'^\p{Ll}', unicode: true);

String _unirRenglones(List<String> renglones) {
  var parrafo = '';
  for (final crudo in renglones) {
    final renglon = crudo.trim().replaceAll(_espacios, ' ');
    if (renglon.isEmpty) continue;
    if (parrafo.isEmpty) {
      parrafo = renglon;
    } else if (parrafo.endsWith('-') && !parrafo.endsWith(' -') && _empiezaMinuscula.hasMatch(renglon)) {
      parrafo = parrafo.substring(0, parrafo.length - 1) + renglon;
    } else {
      parrafo = '$parrafo $renglon';
    }
  }
  return parrafo;
}

/// Convierte los bloques que entrega el lector en párrafos limpios.
String limpiarTextoLeido(List<List<String>> bloques) =>
    bloques.map(_unirRenglones).where((p) => p.isNotEmpty).join('\n\n');

/// El primer renglón como título, cortado en una palabra completa si es muy largo.
String tituloSugerido(String texto) {
  final primero = texto.trim().split('\n').first.trim();
  if (primero.length <= _largoTitulo) return primero;
  final corte = primero.lastIndexOf(' ', _largoTitulo);
  return primero.substring(0, corte < 0 ? _largoTitulo : corte).trim();
}
```

- [ ] **Step 4: Implementar los servicios**

`lib/services/lector_texto.dart`:

```dart
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Lee el texto de una foto dentro del teléfono. Devuelve los renglones de cada bloque.
abstract interface class LectorTexto {
  Future<List<List<String>>> leer(String rutaImagen);
}

class LectorTextoMlKit implements LectorTexto {
  @override
  Future<List<List<String>>> leer(String rutaImagen) async {
    final lector = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final resultado = await lector.processImage(InputImage.fromFilePath(rutaImagen));
      return [
        for (final bloque in resultado.blocks) [for (final renglon in bloque.lines) renglon.text],
      ];
    } finally {
      await lector.close();
    }
  }
}
```

`lib/services/selector_imagen.dart`:

```dart
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

enum OrigenFoto { camara, galeria }

/// Toma una foto o la elige de la galería. La foto es temporal: se descarta después de leerla.
abstract interface class SelectorImagen {
  Future<String?> elegir(OrigenFoto origen);

  /// En Android, el sistema puede cerrar la app mientras la cámara está abierta; aquí se recupera esa foto.
  Future<String?> recuperarPerdida();
  Future<void> descartar(String ruta);
}

class SelectorImagenSistema implements SelectorImagen {
  final ImagePicker _selector = ImagePicker();

  @override
  Future<String?> elegir(OrigenFoto origen) async {
    final foto = await _selector.pickImage(
      source: origen == OrigenFoto.camara ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 2400,
      maxHeight: 2400,
      imageQuality: 90,
    );
    return foto?.path;
  }

  @override
  Future<String?> recuperarPerdida() async {
    if (defaultTargetPlatform != TargetPlatform.android) return null;
    final perdida = await _selector.retrieveLostData();
    return perdida.isEmpty ? null : perdida.file?.path;
  }

  @override
  Future<void> descartar(String ruta) async {
    try {
      final archivo = File(ruta);
      if (archivo.existsSync()) await archivo.delete();
    } catch (error) {
      debugPrint('No se pudo borrar la foto temporal: $error');
    }
  }
}
```

Reemplazar `lib/services/servicios_dispositivo.dart`:

```dart
import 'compartir_texto.dart';
import 'lector_texto.dart';
import 'selector_imagen.dart';

/// Lo que la app le pide al teléfono. En pruebas se reemplaza por dobles.
class ServiciosDispositivo {
  const ServiciosDispositivo({required this.compartir, required this.lector, required this.selectorImagen});

  factory ServiciosDispositivo.reales() => ServiciosDispositivo(
        compartir: CompartirTextoSistema(),
        lector: LectorTextoMlKit(),
        selectorImagen: SelectorImagenSistema(),
      );

  final CompartirTexto compartir;
  final LectorTexto lector;
  final SelectorImagen selectorImagen;
}
```

En `test/support/servicios_falsos.dart`, agregar los imports de `lector_texto.dart` y `selector_imagen.dart`, estos dobles, y reemplazar `serviciosDePrueba`:

```dart
class LectorFalso implements LectorTexto {
  List<List<String>> bloques = [
    ['Oración de prueba'],
    ['Señor, escúchame.'],
  ];
  bool fallar = false;

  @override
  Future<List<List<String>>> leer(String rutaImagen) async {
    if (fallar) throw StateError('Fallo simulado al leer');
    return bloques;
  }
}

class SelectorFalso implements SelectorImagen {
  String? ruta = 'foto.jpg';
  String? perdida;
  final List<String> descartadas = [];

  @override
  Future<String?> elegir(OrigenFoto origen) async => ruta;

  @override
  Future<String?> recuperarPerdida() async => perdida;

  @override
  Future<void> descartar(String ruta) async => descartadas.add(ruta);
}

ServiciosDispositivo serviciosDePrueba({CompartirFalso? compartir, LectorFalso? lector, SelectorFalso? selector}) =>
    ServiciosDispositivo(
      compartir: compartir ?? CompartirFalso(),
      lector: lector ?? LectorFalso(),
      selectorImagen: selector ?? SelectorFalso(),
    );
```

- [ ] **Step 5: Ver que pasan**

Run: `flutter test test/logic/limpieza_texto_test.dart`
Expected: `All tests passed!`.

Run: `flutter analyze` y `flutter test`
Expected: `No issues found!` y `All tests passed!`.

- [ ] **Step 6: Guardar**

```bash
git add lib/logic/limpieza_texto.dart lib/services/lector_texto.dart lib/services/selector_imagen.dart lib/services/servicios_dispositivo.dart test/logic/limpieza_texto_test.dart test/support/servicios_falsos.dart
git commit -m "feat: lector de texto, selector de imagen y limpieza del texto leído"
```

---

### Task 17: Pantalla para leer oraciones con la cámara

**Files:**
- Create: `lib/screens/leer_oracion_screen.dart`
- Modify: `lib/screens/mis_oraciones_screen.dart`, `test/support/recorridos_app.dart`
- Test: `test/screens/leer_oracion_screen_test.dart`

**Interfaces:**
- Consumes: `ServiciosDispositivo.lector`, `ServiciosDispositivo.selectorImagen`, `limpiarTextoLeido`, `tituloSugerido`, `BibliotecaService.guardarOracion`.
- Produces: `LeerOracionScreen.abrir(BuildContext)` → `Future<Oracion?>`. Textos: `'Leer oración'`, `'Tomar foto'`, `'Elegir de la galería'`, `'Agregar otra foto'`, `'Volver a tomar'`, `'Guardar'`, `'Con la cámara'`.

- [ ] **Step 1: Escribir las pruebas**

`test/screens/leer_oracion_screen_test.dart`:

```dart
import 'package:app_resar_rosario/models/oracion.dart';
import 'package:app_resar_rosario/screens/leer_oracion_screen.dart';
import 'package:app_resar_rosario/services/biblioteca_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/almacen_en_memoria.dart';
import '../support/app_harness.dart';
import '../support/servicios_falsos.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late BibliotecaService biblioteca;
  late LectorFalso lector;
  late SelectorFalso selector;
  late List<Oracion?> resultados;

  setUp(() {
    biblioteca = BibliotecaService(almacen: AlmacenEnMemoria());
    lector = LectorFalso();
    selector = SelectorFalso();
    resultados = [];
  });

  Future<void> abrir(WidgetTester tester) async {
    await tester.pumpWidget(envolver(
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async => resultados.add(await LeerOracionScreen.abrir(context)),
            child: const Text('Abrir'),
          ),
        ),
      ),
      preferencias: await preferenciasDePrueba(),
      biblioteca: biblioteca,
      servicios: serviciosDePrueba(lector: lector, selector: selector),
    ));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('explica cómo tomar la foto y que la letra impresa se lee mejor', (tester) async {
    await abrir(tester);
    expect(find.textContaining('buena luz'), findsOneWidget);
    expect(find.textContaining('impreso'), findsOneWidget);
  });

  testWidgets('lee, deja revisar y guarda solo al confirmar', (tester) async {
    await abrir(tester);
    await tester.tap(find.text('Tomar foto'));
    await tester.pumpAndSettle();
    expect(find.text('Oración de prueba'), findsOneWidget); // título sugerido
    expect(biblioteca.oracionesPropias, isEmpty);

    await tester.enterText(find.byType(TextFormField).at(1), 'Texto corregido');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(biblioteca.oracionesPropias.single.titulo, 'Oración de prueba');
    expect(biblioteca.oracionesPropias.single.texto, 'Texto corregido');
    expect(resultados.single, isNotNull);
  });

  testWidgets('la foto temporal se borra después de leerla', (tester) async {
    await abrir(tester);
    await tester.tap(find.text('Tomar foto'));
    await tester.pumpAndSettle();
    expect(selector.descartadas, ['foto.jpg']);
  });

  testWidgets('la foto se borra aunque la lectura falle', (tester) async {
    lector.fallar = true;
    await abrir(tester);
    await tester.tap(find.text('Tomar foto'));
    await tester.pumpAndSettle();
    expect(selector.descartadas, ['foto.jpg']);
    expect(find.textContaining('No se pudo leer'), findsOneWidget);
  });

  testWidgets('agregar otra foto suma el texto al anterior', (tester) async {
    await abrir(tester);
    await tester.tap(find.text('Tomar foto'));
    await tester.pumpAndSettle();
    lector.bloques = [
      ['Segunda página'],
    ];
    await tester.ensureVisible(find.text('Agregar otra foto'));
    await tester.tap(find.text('Agregar otra foto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tomar foto'));
    await tester.pumpAndSettle();
    final texto = tester.widget<TextFormField>(find.byType(TextFormField).at(1)).controller!.text;
    expect(texto, contains('Señor, escúchame.'));
    expect(texto, endsWith('Segunda página'));
  });

  testWidgets('sin texto en la foto explica qué hacer', (tester) async {
    lector.bloques = const [];
    await abrir(tester);
    await tester.tap(find.text('Tomar foto'));
    await tester.pumpAndSettle();
    expect(find.textContaining('No se encontró texto'), findsOneWidget);
    expect(find.text('Tomar foto'), findsOneWidget);
  });

  testWidgets('cancelar la cámara deja todo como estaba', (tester) async {
    selector.ruta = null;
    await abrir(tester);
    await tester.tap(find.text('Tomar foto'));
    await tester.pumpAndSettle();
    expect(find.text('Tomar foto'), findsOneWidget);
    expect(selector.descartadas, isEmpty);
  });

  testWidgets('recupera una foto si Android cerró la app con la cámara abierta', (tester) async {
    selector.perdida = 'perdida.jpg';
    await abrir(tester);
    expect(find.text('Oración de prueba'), findsOneWidget);
    expect(selector.descartadas, ['perdida.jpg']);
  });

  testWidgets('cerrar con texto leído pregunta antes de descartar', (tester) async {
    await abrir(tester);
    await tester.tap(find.text('Tomar foto'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Cerrar'));
    await tester.pumpAndSettle();
    expect(find.text('¿Descartar los cambios?'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Ver que fallan**

Run: `flutter test test/screens/leer_oracion_screen_test.dart`
Expected: FAIL porque la pantalla no existe.

- [ ] **Step 3: Implementar la pantalla**

`lib/screens/leer_oracion_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/limpieza_texto.dart';
import '../models/oracion.dart';
import '../services/biblioteca_service.dart';
import '../services/selector_imagen.dart';
import '../services/servicios_dispositivo.dart';
import '../theme/app_tokens.dart';
import '../widgets/etiqueta_boton.dart';

enum _Estado { eligiendo, leyendo, revisando }

/// Lee una oración impresa con la cámara. Nada se guarda hasta que el usuario lo confirma.
class LeerOracionScreen extends StatefulWidget {
  const LeerOracionScreen({super.key});

  static Future<Oracion?> abrir(BuildContext context) {
    return Navigator.of(context).push<Oracion>(
      MaterialPageRoute(fullscreenDialog: true, builder: (_) => const LeerOracionScreen()),
    );
  }

  @override
  State<LeerOracionScreen> createState() => _LeerOracionScreenState();
}

class _LeerOracionScreenState extends State<LeerOracionScreen> {
  final _formulario = GlobalKey<FormState>();
  final TextEditingController _titulo = TextEditingController();
  final TextEditingController _texto = TextEditingController();
  _Estado _estado = _Estado.eligiendo;
  String? _mensaje;
  bool _cerrando = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _recuperar());
  }

  @override
  void dispose() {
    _titulo.dispose();
    _texto.dispose();
    super.dispose();
  }

  bool get _hayCambios => _texto.text.trim().isNotEmpty || _titulo.text.trim().isNotEmpty;

  Future<void> _recuperar() async {
    final ruta = await context.read<ServiciosDispositivo>().selectorImagen.recuperarPerdida();
    if (ruta != null && mounted) await _leer(ruta);
  }

  Future<void> _capturar(OrigenFoto origen) async {
    final ruta = await context.read<ServiciosDispositivo>().selectorImagen.elegir(origen);
    if (ruta != null && mounted) await _leer(ruta);
  }

  Future<void> _leer(String ruta) async {
    final servicios = context.read<ServiciosDispositivo>();
    final anterior = _texto.text.trim();
    setState(() {
      _estado = _Estado.leyendo;
      _mensaje = null;
    });
    var leido = '';
    String? mensaje;
    try {
      leido = limpiarTextoLeido(await servicios.lector.leer(ruta));
      if (leido.isEmpty) mensaje = 'No se encontró texto. Prueba con más luz y con la hoja bien derecha.';
    } catch (error) {
      debugPrint('No se pudo leer la foto: $error');
      mensaje = 'No se pudo leer la foto. Inténtalo de nuevo.';
    } finally {
      await servicios.selectorImagen.descartar(ruta);
    }
    if (!mounted) return;
    setState(() {
      _mensaje = mensaje;
      if (leido.isNotEmpty) {
        final unido = anterior.isEmpty ? leido : '$anterior\n\n$leido';
        _texto.text = unido.length > LimitesBiblioteca.textoOracion ? unido.substring(0, LimitesBiblioteca.textoOracion) : unido;
        if (_titulo.text.trim().isEmpty) _titulo.text = tituloSugerido(leido);
      }
      _estado = _texto.text.trim().isEmpty ? _Estado.eligiendo : _Estado.revisando;
    });
  }

  void _volverATomar() => setState(() {
        _titulo.clear();
        _texto.clear();
        _mensaje = null;
        _estado = _Estado.eligiendo;
      });

  Future<void> _guardar() async {
    if (!_formulario.currentState!.validate()) return;
    final navegador = Navigator.of(context);
    final guardada = await context.read<BibliotecaService>().guardarOracion(titulo: _titulo.text, texto: _texto.text);
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
    final revisando = _estado == _Estado.revisando;
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
          leading: IconButton(icon: const Icon(Icons.close), tooltip: 'Cerrar', onPressed: () => Navigator.maybePop(context)),
          title: MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.3,
            child: const FittedBox(fit: BoxFit.scaleDown, alignment: AlignmentDirectional.centerStart, child: Text('Leer oración')),
          ),
          actions: [
            if (revisando)
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTokens.espacioM),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: AppTokens.anchoMaximo),
                child: switch (_estado) {
                  _Estado.eligiendo => _elegir(context),
                  _Estado.leyendo => const _Leyendo(),
                  _Estado.revisando => _revisar(context),
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _elegir(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final esquema = Theme.of(context).colorScheme;
    final agregando = _texto.text.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.document_scanner_outlined, size: 64, color: esquema.primary),
        const SizedBox(height: AppTokens.espacioM),
        Text('Usa buena luz y mantén la hoja derecha.', textAlign: TextAlign.center, style: textos.titleMedium),
        const SizedBox(height: AppTokens.espacioS),
        Text(
          'El texto impreso se lee mejor que la letra a mano. Podrás corregirlo antes de guardar.',
          textAlign: TextAlign.center,
          style: textos.bodyMedium?.copyWith(color: esquema.onSurfaceVariant),
        ),
        if (_mensaje != null) ...[
          const SizedBox(height: AppTokens.espacioM),
          Text(_mensaje!, textAlign: TextAlign.center, style: textos.bodyLarge?.copyWith(color: esquema.error)),
        ],
        const SizedBox(height: AppTokens.espacioL),
        FilledButton.icon(
          onPressed: () => _capturar(OrigenFoto.camara),
          icon: const Icon(Icons.photo_camera_outlined),
          label: const EtiquetaBoton('Tomar foto'),
        ),
        const SizedBox(height: AppTokens.espacioS),
        OutlinedButton.icon(
          onPressed: () => _capturar(OrigenFoto.galeria),
          icon: const Icon(Icons.photo_library_outlined),
          label: const EtiquetaBoton('Elegir de la galería'),
        ),
        if (agregando) ...[
          const SizedBox(height: AppTokens.espacioS),
          TextButton(
            onPressed: () => setState(() => _estado = _Estado.revisando),
            child: const EtiquetaBoton('Volver al texto'),
          ),
        ],
      ],
    );
  }

  Widget _revisar(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Form(
      key: _formulario,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Revisa el texto y corrige lo que haga falta.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: esquema.onSurfaceVariant),
          ),
          const SizedBox(height: AppTokens.espacioM),
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
          Wrap(
            spacing: AppTokens.espacioS,
            runSpacing: AppTokens.espacioS,
            children: [
              OutlinedButton.icon(
                onPressed: () => setState(() => _estado = _Estado.eligiendo),
                icon: const Icon(Icons.add_a_photo_outlined),
                label: const EtiquetaBoton('Agregar otra foto'),
              ),
              TextButton(onPressed: _volverATomar, child: const EtiquetaBoton('Volver a tomar')),
            ],
          ),
        ],
      ),
    );
  }
}

class _Leyendo extends StatelessWidget {
  const _Leyendo();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.espacioXL),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: AppTokens.espacioM),
          Text('Leyendo la oración…', style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Agregar la opción en "Mis oraciones"**

En `lib/screens/mis_oraciones_screen.dart`:
- agregar `import 'leer_oracion_screen.dart';`;
- en la hoja de `_nuevaOracion`, después de "Pegar":

```dart
              ListTile(
                leading: const Icon(Icons.document_scanner_outlined),
                title: const Text('Con la cámara'),
                onTap: () => Navigator.pop(hoja, 'camara'),
              ),
```

- después de `if (opcion == null || !mounted) return;`:

```dart
    if (opcion == 'camara') {
      final leida = await LeerOracionScreen.abrir(context);
      if (leida != null && widget.elegir) navegador.pop(leida);
      return;
    }
```

En `test/support/recorridos_app.dart`, agregar a la lista `recorridos`:

```dart
  Recorrido('leer con la cámara', (tester, revisar) async {
    await _abrirDesdeMenu(tester, 'Mis oraciones');
    await tocar(tester, find.text('Nueva'));
    await tocar(tester, find.text('Con la cámara'));
    await revisar('elegir foto');
    await tocar(tester, find.text('Tomar foto'));
    await revisar('revisar texto leído');
    await tocar(tester, find.text('Agregar otra foto'));
    await revisar('agregar otra foto');
    await tocar(tester, find.text('Volver al texto'));
    await tocar(tester, find.byTooltip('Cerrar'));
    await revisar('descartar lectura');
    await tocar(tester, find.text('Descartar'));
  }),
```

- [ ] **Step 5: Ver que pasan**

Run: `flutter test test/screens/leer_oracion_screen_test.dart test/screens/mis_oraciones_screen_test.dart`
Expected: `All tests passed!`.

Run: `flutter test test/accesibilidad/` y `flutter test test/responsivo_test.dart`
Expected: pasan. Corregir en el código cualquier falla.

Run: `flutter analyze` y `flutter test`
Expected: `No issues found!` y `All tests passed!`.

- [ ] **Step 6: Probar en el teléfono**

Con el teléfono conectado, run: `flutter run --release`
Probar con una oración impresa real: tomar foto, elegir de la galería, corregir y guardar. Confirmar que acentos y ñ se leen bien. Anotar el resultado en el reporte.

- [ ] **Step 7: Guardar y cerrar la etapa**

Run: `graphify update .`

```bash
git add lib/screens/leer_oracion_screen.dart lib/screens/mis_oraciones_screen.dart test/screens/leer_oracion_screen_test.dart test/support/recorridos_app.dart
git commit -m "feat: leer oraciones impresas con la cámara y revisarlas antes de guardar"
```

---

### Task 18: Recibir texto desde otras apps en Android

**Files:**
- Create: `lib/services/texto_recibido.dart`
- Modify: `lib/services/servicios_dispositivo.dart`, `lib/screens/principal_screen.dart`, `android/app/src/main/AndroidManifest.xml`, `test/support/servicios_falsos.dart`
- Test: `test/screens/principal_screen_test.dart`, `test/plataforma/android_config_test.dart`

**Interfaces:**
- Consumes: `OracionFormScreen.abrir`, `tituloSugerido`, `LimitesBiblioteca`.
- Produces: `abstract interface class TextoRecibido { Future<String?> inicial(); Stream<String> get nuevos; Future<void> limpiar(); }`, `TextoRecibidoSistema`, y en pruebas `TextoRecibidoFalso` con `textoInicial`, `controlador` y `limpiezas`.

- [ ] **Step 1: Escribir las pruebas**

En `test/plataforma/android_config_test.dart`, dentro de `main()`:

```dart
  test('recibe texto compartido desde otras apps', () {
    expect(manifest, contains('android.intent.action.SEND'));
    expect(manifest, contains('android:mimeType="text/plain"'));
    expect(manifest, contains('android:launchMode="singleTask"'));
  });
```

En `test/support/servicios_falsos.dart`, agregar `import 'dart:async';`, el import de `texto_recibido.dart`, este doble y el parámetro `TextoRecibidoFalso? textoRecibido` en `serviciosDePrueba`, que pasa `textoRecibido: textoRecibido ?? TextoRecibidoFalso()`:

```dart
class TextoRecibidoFalso implements TextoRecibido {
  String? textoInicial;
  final StreamController<String> controlador = StreamController<String>.broadcast();
  int limpiezas = 0;

  @override
  Future<String?> inicial() async => textoInicial;

  @override
  Stream<String> get nuevos => controlador.stream;

  @override
  Future<void> limpiar() async => limpiezas++;
}
```

En `test/screens/principal_screen_test.dart`, agregar `import '../support/servicios_falsos.dart';` y:

```dart
  testWidgets('un texto recibido con la app cerrada abre Nueva oración sin guardar nada', (tester) async {
    final recibido = TextoRecibidoFalso()..textoInicial = 'Oración a San José\n\nGlorioso patriarca';
    final biblioteca = BibliotecaService(almacen: AlmacenEnMemoria());
    await tester.pumpWidget(await appDePrueba(biblioteca: biblioteca, servicios: serviciosDePrueba(textoRecibido: recibido)));
    await tester.pumpAndSettle();
    expect(find.text('Nueva oración'), findsOneWidget);
    expect(find.text('Oración a San José'), findsOneWidget);
    expect(biblioteca.oracionesPropias, isEmpty);
    expect(recibido.limpiezas, 1);
  });

  testWidgets('un texto recibido con la app abierta también abre Nueva oración', (tester) async {
    final recibido = TextoRecibidoFalso();
    await tester.pumpWidget(await appDePrueba(servicios: serviciosDePrueba(textoRecibido: recibido)));
    await tester.pumpAndSettle();
    recibido.controlador.add('Señor, escúchame');
    await tester.pumpAndSettle();
    expect(find.text('Nueva oración'), findsOneWidget);
    expect(find.text('Señor, escúchame'), findsNWidgets(2)); // título sugerido y texto
  });

  testWidgets('un texto muy largo se recorta al límite', (tester) async {
    final recibido = TextoRecibidoFalso()..textoInicial = 'a' * (LimitesBiblioteca.textoOracion + 50);
    await tester.pumpWidget(await appDePrueba(servicios: serviciosDePrueba(textoRecibido: recibido)));
    await tester.pumpAndSettle();
    final texto = tester.widget<TextFormField>(find.byType(TextFormField).at(1)).controller!.text;
    expect(texto.length, LimitesBiblioteca.textoOracion);
  });
```

Agregar a ese archivo los imports de `models/oracion.dart`, `services/biblioteca_service.dart`, `package:flutter/material.dart` y `../support/almacen_en_memoria.dart`.

- [ ] **Step 2: Ver que fallan**

Run: `flutter test test/plataforma/android_config_test.dart`
Expected: FAIL en la prueba nueva.

- [ ] **Step 3: Implementar el servicio**

`lib/services/texto_recibido.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

/// Texto que otra app comparte hacia Santo Rosario.
abstract interface class TextoRecibido {
  /// El texto con el que se abrió la app, si lo hay.
  Future<String?> inicial();

  /// Los textos que llegan con la app abierta.
  Stream<String> get nuevos;

  /// Olvida el texto ya atendido, para no abrirlo otra vez.
  Future<void> limpiar();
}

/// Solo funciona en Android. En iPhone requiere una extensión aparte (Task 21).
class TextoRecibidoSistema implements TextoRecibido {
  bool get _disponible => defaultTargetPlatform == TargetPlatform.android;

  String? _texto(List<SharedMediaFile> archivos) {
    for (final archivo in archivos) {
      if (archivo.type == SharedMediaType.text || archivo.type == SharedMediaType.url) return archivo.path;
    }
    return null;
  }

  @override
  Future<String?> inicial() async {
    if (!_disponible) return null;
    return _texto(await ReceiveSharingIntent.instance.getInitialMedia());
  }

  @override
  Stream<String> get nuevos {
    if (!_disponible) return const Stream.empty();
    return ReceiveSharingIntent.instance.getMediaStream().map(_texto).where((t) => t != null).cast<String>();
  }

  @override
  Future<void> limpiar() async {
    if (_disponible) await ReceiveSharingIntent.instance.reset();
  }
}
```

Si la versión fijada en la Task 1 usa otros nombres, ajustar solo este archivo según su documentación.

En `lib/services/servicios_dispositivo.dart`: agregar `import 'texto_recibido.dart';`, el parámetro `required this.textoRecibido`, el campo `final TextoRecibido textoRecibido;` y `textoRecibido: TextoRecibidoSistema(),` en `ServiciosDispositivo.reales()`.

- [ ] **Step 4: Abrir el formulario al recibir texto**

Reemplazar `lib/screens/principal_screen.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/limpieza_texto.dart';
import '../logic/rosario_session.dart';
import '../models/oracion.dart';
import '../services/servicios_dispositivo.dart';
import 'inicio_screen.dart';
import 'oracion_form_screen.dart';
import 'rezo_screen.dart';

/// Muestra el inicio o el rezo según la sesión, y atiende el texto que comparten otras apps.
class PrincipalScreen extends StatefulWidget {
  const PrincipalScreen({super.key});

  @override
  State<PrincipalScreen> createState() => _PrincipalScreenState();
}

class _PrincipalScreenState extends State<PrincipalScreen> {
  StreamSubscription<String>? _suscripcion;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _escuchar());
  }

  @override
  void dispose() {
    _suscripcion?.cancel();
    super.dispose();
  }

  Future<void> _escuchar() async {
    final recibido = context.read<ServiciosDispositivo>().textoRecibido;
    _suscripcion = recibido.nuevos.listen(_abrir);
    final inicial = await recibido.inicial();
    if (inicial != null) await _abrir(inicial);
  }

  /// Abre "Nueva oración" con el texto cargado; el usuario decide si la guarda.
  Future<void> _abrir(String texto) async {
    if (!mounted) return;
    final recibido = context.read<ServiciosDispositivo>().textoRecibido;
    final limpio = texto.trim();
    await recibido.limpiar();
    if (limpio.isEmpty || !mounted) return;
    final recortado = limpio.length > LimitesBiblioteca.textoOracion ? limpio.substring(0, LimitesBiblioteca.textoOracion) : limpio;
    await OracionFormScreen.abrir(context, tituloInicial: tituloSugerido(recortado), textoInicial: recortado);
  }

  @override
  Widget build(BuildContext context) {
    final enInicio = context.select<RosarioSession, bool>((s) => s.enInicio);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: enInicio ? const InicioScreen(key: ValueKey('inicio')) : const RezoScreen(key: ValueKey('rezo')),
    );
  }
}
```

- [ ] **Step 5: Configurar Android**

En `android/app/src/main/AndroidManifest.xml`, dentro de la `<activity>` de `MainActivity`:
- cambiar `android:launchMode` a `"singleTask"`;
- agregar:

```xml
            <intent-filter>
                <action android:name="android.intent.action.SEND" />
                <category android:name="android.intent.category.DEFAULT" />
                <data android:mimeType="text/plain" />
            </intent-filter>
```

- [ ] **Step 6: Ver que pasan**

Run: `flutter test test/plataforma/android_config_test.dart test/screens/principal_screen_test.dart`
Expected: `All tests passed!`.

Run: `flutter analyze` y `flutter test`
Expected: `No issues found!` y `All tests passed!`.

- [ ] **Step 7: Probar en el teléfono**

Run: `flutter run --release`

Probar los tres casos y anotar el resultado:
1. Con la app cerrada, compartir un texto desde WhatsApp o el navegador hacia "Santo Rosario".
2. Con la app abierta en segundo plano, repetir.
3. Después de compartir, cerrar el formulario y regresar: no debe abrirse otra vez.

Comprobar también que un recordatorio de alarma sigue abriendo la app correctamente con `singleTask`.

- [ ] **Step 8: Guardar y cerrar la etapa**

Run: `graphify update .`

```bash
git add lib/services/texto_recibido.dart lib/services/servicios_dispositivo.dart lib/screens/principal_screen.dart android/app/src/main/AndroidManifest.xml test/support/servicios_falsos.dart test/screens/principal_screen_test.dart test/plataforma/android_config_test.dart
git commit -m "feat: recibir en Android oraciones compartidas desde otras apps"
```
