# Constructor de rosarios — Etapas 0 y 1: viabilidad y motor de datos

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Comprobar que el lector de texto compila y funciona en Android e iOS, y convertir el rezo en un motor basado en datos sin cambiar el Rosario tradicional.

**Architecture:** La Etapa 0 solo agrega dependencias y mide. La Etapa 1 fija una referencia de los 93 pasos actuales, crea los modelos, cambia el motor y agrega almacenamiento y `BibliotecaService`.

**Tech Stack:** Flutter 3.47.9, google_mlkit_text_recognition, image_picker, share_plus, path_provider, receive_sharing_intent.

**Spec:** `docs/superpowers/specs/2026-11-18-constructor-rosarios-design.md` · **Índice:** `docs/superpowers/plans/2026-11-18-constructor-rosarios.md`

## Global Constraints

Se aplican todas las del índice, incluida la sección "Reglas aprendidas en este proyecto".

---

### Task 1: Viabilidad en Android (compuerta)

**Files:**
- Modify: `pubspec.yaml`, `pubspec.lock`
- Create: `android/app/proguard-rules.pro`
- Modify: `android/app/build.gradle.kts`
- Create: `docs/superpowers/viabilidad-constructor-2026-11.md`
- Temporary, not committed: `lib/main_prueba_lector.dart`

**Interfaces:**
- Produces: dependencias resueltas y fijadas en `pubspec.lock`.

- [ ] **Step 1: Medir el tamaño actual**

Run: `flutter build appbundle --release`
Anotar el tamaño de `build/app/outputs/bundle/release/app-release.aab`.

- [ ] **Step 2: Agregar las dependencias**

Run: `flutter pub add google_mlkit_text_recognition image_picker share_plus path_provider receive_sharing_intent`
Expected: se resuelven sin conflictos. Si hay conflicto, anotar el mensaje exacto y detenerse (compuerta).

- [ ] **Step 3: Reglas de R8**

Crear `android/app/proguard-rules.pro`:

```proguard
# ML Kit referencia modelos de idiomas opcionales que la app no incluye.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
```

En `android/app/build.gradle.kts`, dentro de `release { ... }`, después de `isShrinkResources = true`:

```kotlin
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
```

- [ ] **Step 4: Compilar**

Run: `flutter build appbundle --release`
Expected: `✓ Built build\app\outputs\bundle\release\app-release.aab`. Anotar el tamaño nuevo.

Si falla por versión de AGP, Kotlin o `compileSdk`, usar **superpowers:systematic-debugging**. Se permite subir `compileSdk` si el error lo pide. Si no se resuelve, detenerse (compuerta).

- [ ] **Step 5: Comprobar páginas de 16 KB**

Run: `flutter build apk --release`

Run en Git Bash:

```bash
python -I - build/app/outputs/flutter-apk/app-release.apk <<'EOF'
import struct, sys, zipfile
malas = []
with zipfile.ZipFile(sys.argv[1]) as apk:
    for nombre in apk.namelist():
        if not (nombre.startswith('lib/arm64-v8a/') or nombre.startswith('lib/x86_64/')) or not nombre.endswith('.so'):
            continue
        d = apk.read(nombre)
        phoff = struct.unpack_from('<Q', d, 32)[0]
        phsize, phnum = struct.unpack_from('<HH', d, 54)
        alin = [struct.unpack_from('<Q', d, phoff + i * phsize + 48)[0]
                for i in range(phnum) if struct.unpack_from('<I', d, phoff + i * phsize)[0] == 1]
        if min(alin) < 0x4000:
            malas.append((nombre, hex(min(alin))))
print('SIN PROBLEMAS' if not malas else malas)
EOF
```

Expected: `SIN PROBLEMAS`. Si aparece una librería mal alineada, buscar una versión más nueva del paquete que la trae; si no existe, detenerse (compuerta), porque Google Play exige 16 KB.

- [ ] **Step 6: Revisar permisos del manifest final**

Run en Git Bash:

```bash
"$LOCALAPPDATA/Android/Sdk/build-tools/36.0.0/aapt2.exe" dump permissions build/app/outputs/flutter-apk/app-release.apk
```

Anotar la lista. Se espera que ML Kit agregue `INTERNET` y `ACCESS_NETWORK_STATE`. **No debe aparecer `CAMERA`**: si aparece, agregar en `android/app/src/main/AndroidManifest.xml` la línea `<uses-permission android:name="android.permission.CAMERA" tools:node="remove" />` con su `xmlns:tools`, y comprobar de nuevo.

- [ ] **Step 7: Probar la lectura real en el teléfono**

Crear `lib/main_prueba_lector.dart` (temporal, **no se sube**):

```dart
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

void main() => runApp(const MaterialApp(home: _Prueba()));

class _Prueba extends StatefulWidget {
  const _Prueba();

  @override
  State<_Prueba> createState() => _PruebaState();
}

class _PruebaState extends State<_Prueba> {
  String _texto = 'Toma una foto de una oración impresa';

  Future<void> _leer() async {
    final foto = await ImagePicker().pickImage(source: ImageSource.camera);
    if (foto == null) return;
    final lector = TextRecognizer(script: TextRecognitionScript.latin);
    final resultado = await lector.processImage(InputImage.fromFilePath(foto.path));
    await lector.close();
    setState(() => _texto = resultado.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(onPressed: _leer, child: const Icon(Icons.camera_alt)),
      body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Text(_texto))),
    );
  }
}
```

Con el teléfono conectado, run: `flutter run --release -t lib/main_prueba_lector.dart`
Expected: la cámara abre, y al fotografiar una oración impresa aparece su texto con acentos y ñ.

Borrar `lib/main_prueba_lector.dart` después de la prueba.

- [ ] **Step 8: Escribir el resultado**

Crear `docs/superpowers/viabilidad-constructor-2026-11.md` con estos datos reales: versiones resueltas de los 5 paquetes, tamaño del AAB antes y después, resultado de 16 KB, permisos del manifest final y resultado de la prueba en el teléfono.

- [ ] **Step 9: Verificar y guardar**

Run: `flutter analyze` y `flutter test`
Expected: `No issues found!` y `All tests passed!`.

```bash
git add pubspec.yaml pubspec.lock android/app/proguard-rules.pro android/app/build.gradle.kts docs/superpowers/viabilidad-constructor-2026-11.md
git commit -m "build: dependencias del lector de texto, compartir y almacenamiento"
```

---

### Task 2: Viabilidad en iOS (compuerta)

**Files:**
- Modify: `ios/Runner.xcodeproj/project.pbxproj`, `ios/Runner/Info.plist`
- Test: `test/plataforma/ios_config_test.dart`
- Modify: `docs/superpowers/viabilidad-constructor-2026-11.md`

**Interfaces:**
- Produces: iOS mínimo 15.5 y textos de permisos de cámara y fotos.

- [ ] **Step 1: Escribir las pruebas**

Agregar en `test/plataforma/ios_config_test.dart`, dentro de `main()`:

```dart
  test('iOS mínimo 15.5, que exige el lector de texto', () {
    final proyecto = File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
    final versiones = RegExp(r'IPHONEOS_DEPLOYMENT_TARGET = ([0-9.]+);').allMatches(proyecto).map((m) => m.group(1)).toSet();
    expect(versiones, {'15.5'});
  });

  test('explica en español para qué usa la cámara y las fotos', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    expect(plist, matches(RegExp(r'<key>NSCameraUsageDescription</key>\s*<string>[^<]*oraci[^<]*</string>')));
    expect(plist, matches(RegExp(r'<key>NSPhotoLibraryUsageDescription</key>\s*<string>[^<]*oraci[^<]*</string>')));
  });
```

- [ ] **Step 2: Ver que fallan**

Run: `flutter test test/plataforma/ios_config_test.dart`
Expected: FAIL en las dos pruebas nuevas.

- [ ] **Step 3: Aplicar la configuración**

En `ios/Runner.xcodeproj/project.pbxproj`, reemplazar todas las apariciones de `IPHONEOS_DEPLOYMENT_TARGET = 15.0;` por `IPHONEOS_DEPLOYMENT_TARGET = 15.5;`.

En `ios/Runner/Info.plist`, antes de `</dict>` final:

```xml
	<key>NSCameraUsageDescription</key>
	<string>Santo Rosario usa la cámara para leer oraciones impresas. La foto no se guarda.</string>
	<key>NSPhotoLibraryUsageDescription</key>
	<string>Santo Rosario abre tus fotos para leer oraciones impresas. La foto no se guarda.</string>
```

- [ ] **Step 4: Ver que pasan y guardar**

Run: `flutter test test/plataforma/ios_config_test.dart`
Expected: `All tests passed!`.

```bash
git add ios/Runner.xcodeproj/project.pbxproj ios/Runner/Info.plist test/plataforma/ios_config_test.dart
git commit -m "build: iOS 15.5 y permisos de cámara y fotos para leer oraciones"
```

- [ ] **Step 5: Compilar iOS en la nube (requiere autorización)**

**Detenerse y pedir autorización al usuario** para subir la rama. Con la autorización:

Run: `git -c http.sslBackend=schannel push -u origin constructor-rosarios`
Run: `gh run list --branch constructor-rosarios --limit 3`, y `gh run watch <id> --exit-status` para los flujos "CI" e "iOS".

Expected: los dos terminan en verde. Si GitHub dice que no consiguió una máquina ("not acquired by Runner"), relanzar con `gh run rerun <id>`: no es un error del código.

- [ ] **Step 6: Si iOS falla por CocoaPods**

El proyecto no tiene `ios/Podfile`. Si el error menciona el mínimo de iOS de los pods, crear `ios/Podfile`:

```ruby
platform :ios, '15.5'
ENV['COCOAPODS_DISABLE_STATS'] = 'true'

project 'Runner', {
  'Debug' => :debug,
  'Profile' => :release,
  'Release' => :release,
}

def flutter_root
  generated_xcode_build_settings_path = File.expand_path(File.join('..', 'Flutter', 'Generated.xcconfig'), __FILE__)
  unless File.exist?(generated_xcode_build_settings_path)
    raise "#{generated_xcode_build_settings_path} must exist. Run flutter pub get first"
  end
  File.foreach(generated_xcode_build_settings_path) do |line|
    matches = line.match(/FLUTTER_ROOT\=(.*)/)
    return matches[1].strip if matches
  end
  raise "FLUTTER_ROOT not found in #{generated_xcode_build_settings_path}"
end

require File.expand_path(File.join('packages', 'flutter_tools', 'bin', 'podhelper'), flutter_root)

flutter_ios_podfile_setup

target 'Runner' do
  use_frameworks!
  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.5'
    end
  end
end
```

Subir el cambio, con la misma autorización, y repetir el Step 5. Si sigue fallando después de 3 intentos, detenerse (compuerta) y presentar opciones al usuario.

- [ ] **Step 7: Anotar y guardar**

Agregar a `docs/superpowers/viabilidad-constructor-2026-11.md` el resultado de iOS y el enlace a la corrida.

```bash
git add docs/superpowers/viabilidad-constructor-2026-11.md
git commit -m "docs: resultado de la viabilidad en iOS"
```

---

### Task 3: Referencia de los 93 pasos del Rosario tradicional

**Files:**
- Create: `test/support/resumen_pasos.dart`, `test/logic/pasos_tradicional_test.dart`, `test/fixtures/pasos_tradicional.json`

**Interfaces:**
- Produces: `List<Map<String, Object?>> resumenPasos(List<PasoRosario> pasos)` y el archivo de referencia que protege al tradicional en todas las tareas siguientes.

- [ ] **Step 1: Escribir el resumen y la prueba**

`test/support/resumen_pasos.dart`:

```dart
import 'package:app_resar_rosario/logic/rosario_session.dart';

/// Lo que define a cada paso del rezo, en un formato que se puede comparar y guardar.
List<Map<String, Object?>> resumenPasos(List<PasoRosario> pasos) => [
      for (final p in pasos)
        {
          'seccion': p.seccion.name,
          'tipo': p.oracion.type,
          'titulo': p.oracion.title,
          'texto': p.oracion.text,
          'veces': p.oracion.count,
          'indice': p.indiceEnSeccion,
          'total': p.totalEnSeccion,
          'misterio': p.misterio,
          'repeticion': p.repeticion,
          'anuncio': p.esAnuncioDeMisterio,
        },
    ];
```

`test/logic/pasos_tradicional_test.dart`:

```dart
import 'dart:convert';
import 'dart:io';

import 'package:app_resar_rosario/logic/rosario_session.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/resumen_pasos.dart';

const _generar = bool.fromEnvironment('GENERAR_REFERENCIA');

void main() {
  final archivo = File('test/fixtures/pasos_tradicional.json');

  test('el Rosario tradicional produce exactamente los 93 pasos de referencia', () {
    final actual = resumenPasos(construirPasos());
    if (_generar) {
      archivo
        ..createSync(recursive: true)
        ..writeAsStringSync(const JsonEncoder.withIndent('  ').convert(actual));
    }
    expect(actual, hasLength(93));
    expect(jsonEncode(actual), jsonEncode(jsonDecode(archivo.readAsStringSync())));
  });
}
```

- [ ] **Step 2: Generar la referencia con el código actual**

Run: `flutter test --dart-define=GENERAR_REFERENCIA=true test/logic/pasos_tradicional_test.dart`
Expected: `All tests passed!` y existe `test/fixtures/pasos_tradicional.json`.

- [ ] **Step 3: Comprobar que la prueba compara de verdad**

Cambiar temporalmente en `lib/data/oraciones.dart` una letra del título `'Gloria'` a `'Gloriax'`.

Run: `flutter test test/logic/pasos_tradicional_test.dart`
Expected: FAIL. Regresar el cambio y correr de nuevo: `All tests passed!`.

- [ ] **Step 4: Guardar**

```bash
git add test/support/resumen_pasos.dart test/logic/pasos_tradicional_test.dart test/fixtures/pasos_tradicional.json
git commit -m "test: referencia de los 93 pasos del Rosario tradicional"
```

---

### Task 4: Modelos de oraciones y rosarios

**Files:**
- Create: `lib/models/oracion.dart`, `lib/models/rosario.dart`
- Test: `test/models/rosario_test.dart`

**Interfaces:**
- Produces:
  - `LimitesBiblioteca` con `tituloOracion`, `textoOracion`, `nombre`, `partes`, `elementos`, `veces`, `vueltas`, `pasos`.
  - `Oracion({id, titulo, texto, origen, formato})`, `esDeLaApp`, `copyWith({titulo, texto})`, `toJson()`, `Oracion.fromJson(map)`.
  - `FuenteMisterios` (sellada) con `vueltas`, `anuncia`, `toJson()`, `FuenteMisterios.fromJson(map)`; variantes `SinMisterios({vueltas = 1})`, `MisteriosDelDia()`, `GrupoMisterios(tipo)`, `MeditacionesPropias(textos)`.
  - `ElementoParte({id, oracionId, veces = 1})` con `copyWith({veces})`.
  - `ParteRosario({id, nombre, elementos, misterios})` con `copyWith({nombre, elementos, misterios})`.
  - `TipoRosario { tradicional, plantilla, propio }`.
  - `Rosario({id, nombre, tipo, partes})` con `esProtegido` y `copyWith({nombre, partes})`.

- [ ] **Step 1: Escribir las pruebas**

`test/models/rosario_test.dart`:

```dart
import 'package:app_resar_rosario/models/oracion.dart';
import 'package:app_resar_rosario/models/prayer_models.dart';
import 'package:app_resar_rosario/models/rosario.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('una oración propia se guarda y se recupera', () {
    const o = Oracion(id: 'a1', titulo: 'Por mi familia', texto: 'Señor, cuida a mi familia.');
    final copia = Oracion.fromJson(o.toJson());
    expect(copia.toJson(), o.toJson());
    expect(copia.esDeLaApp, isFalse);
  });

  test('cada fuente de misterios conserva sus datos y sus vueltas', () {
    final fuentes = <FuenteMisterios, int>{
      const SinMisterios(vueltas: 3): 3,
      const MisteriosDelDia(): 5,
      const GrupoMisterios(TipoMisterio.luminosos): 5,
      const MeditacionesPropias(['Una', 'Dos']): 2,
    };
    fuentes.forEach((fuente, vueltas) {
      final copia = FuenteMisterios.fromJson(fuente.toJson());
      expect(copia.toJson(), fuente.toJson());
      expect(copia.vueltas, vueltas);
    });
  });

  test('solo se anuncia algo cuando hay misterios o meditaciones', () {
    expect(const SinMisterios().anuncia, isFalse);
    expect(const MisteriosDelDia().anuncia, isTrue);
    expect(const MeditacionesPropias(['Una']).anuncia, isTrue);
  });

  test('un rosario completo se guarda y se recupera', () {
    const r = Rosario(id: 'r1', nombre: 'De mi familia', tipo: TipoRosario.propio, partes: [
      ParteRosario(
        id: 'p1',
        nombre: 'Decenas',
        elementos: [ElementoParte(id: 'e1', oracionId: 'app:avemaria', veces: 10)],
        misterios: GrupoMisterios(TipoMisterio.gozosos),
      ),
    ]);
    expect(Rosario.fromJson(r.toJson()).toJson(), r.toJson());
  });

  test('el tradicional y las plantillas están protegidos', () {
    const base = Rosario(id: 'x', nombre: 'x', tipo: TipoRosario.tradicional, partes: []);
    expect(base.esProtegido, isTrue);
    expect(base.copyWith().esProtegido, isTrue);
    expect(const Rosario(id: 'x', nombre: 'x', tipo: TipoRosario.plantilla, partes: []).esProtegido, isTrue);
    expect(const Rosario(id: 'x', nombre: 'x', tipo: TipoRosario.propio, partes: []).esProtegido, isFalse);
  });
}
```

- [ ] **Step 2: Ver que fallan**

Run: `flutter test test/models/rosario_test.dart`
Expected: FAIL porque los archivos no existen.

- [ ] **Step 3: Implementar**

`lib/models/oracion.dart`:

```dart
import 'package:flutter/foundation.dart';

/// Límites de lo que el usuario puede crear.
abstract final class LimitesBiblioteca {
  static const int tituloOracion = 80;
  static const int textoOracion = 10000;
  static const int nombre = 60;
  static const int partes = 30;
  static const int elementos = 50;
  static const int veces = 99;
  static const int vueltas = 20;
  static const int pasos = 1000;
}

enum OrigenOracion { app, propia }

enum FormatoOracion { normal, letanias }

/// Una oración de la biblioteca.
@immutable
class Oracion {
  const Oracion({
    required this.id,
    required this.titulo,
    required this.texto,
    this.origen = OrigenOracion.propia,
    this.formato = FormatoOracion.normal,
  });

  /// En el archivo solo se guardan oraciones propias.
  factory Oracion.fromJson(Map<String, dynamic> json) => Oracion(
        id: json['id'] as String,
        titulo: json['titulo'] as String,
        texto: json['texto'] as String,
        formato: FormatoOracion.values.byName(json['formato'] as String? ?? FormatoOracion.normal.name),
      );

  final String id;
  final String titulo;
  final String texto;
  final OrigenOracion origen;
  final FormatoOracion formato;

  bool get esDeLaApp => origen == OrigenOracion.app;

  Oracion copyWith({String? titulo, String? texto}) => Oracion(
        id: id,
        titulo: titulo ?? this.titulo,
        texto: texto ?? this.texto,
        origen: origen,
        formato: formato,
      );

  Map<String, dynamic> toJson() => {'id': id, 'titulo': titulo, 'texto': texto, 'formato': formato.name};
}
```

`lib/models/rosario.dart`:

```dart
import 'package:flutter/foundation.dart';

import 'prayer_models.dart';

/// Misterios que tiene cada grupo.
const int misteriosPorGrupo = 5;

/// Qué se medita en cada vuelta de una parte.
@immutable
sealed class FuenteMisterios {
  const FuenteMisterios();

  factory FuenteMisterios.fromJson(Map<String, dynamic> json) => switch (json['fuente'] as String) {
        'ninguna' => SinMisterios(vueltas: json['vueltas'] as int),
        'del_dia' => const MisteriosDelDia(),
        'grupo' => GrupoMisterios(TipoMisterio.values.byName(json['grupo'] as String)),
        'propias' => MeditacionesPropias(List<String>.unmodifiable(json['textos'] as List)),
        final otra => throw FormatException('Fuente de misterios desconocida: $otra'),
      };

  int get vueltas;

  /// Si cada vuelta empieza anunciando un misterio o una meditación.
  bool get anuncia => true;

  Map<String, dynamic> toJson();
}

class SinMisterios extends FuenteMisterios {
  const SinMisterios({this.vueltas = 1});

  @override
  final int vueltas;

  @override
  bool get anuncia => false;

  @override
  Map<String, dynamic> toJson() => {'fuente': 'ninguna', 'vueltas': vueltas};
}

class MisteriosDelDia extends FuenteMisterios {
  const MisteriosDelDia();

  @override
  int get vueltas => misteriosPorGrupo;

  @override
  Map<String, dynamic> toJson() => {'fuente': 'del_dia'};
}

class GrupoMisterios extends FuenteMisterios {
  const GrupoMisterios(this.tipo);

  final TipoMisterio tipo;

  @override
  int get vueltas => misteriosPorGrupo;

  @override
  Map<String, dynamic> toJson() => {'fuente': 'grupo', 'grupo': tipo.name};
}

class MeditacionesPropias extends FuenteMisterios {
  const MeditacionesPropias(this.textos);

  final List<String> textos;

  @override
  int get vueltas => textos.length;

  @override
  Map<String, dynamic> toJson() => {'fuente': 'propias', 'textos': textos};
}

/// Una oración dentro de una parte, con las veces seguidas que se reza.
@immutable
class ElementoParte {
  const ElementoParte({required this.id, required this.oracionId, this.veces = 1});

  factory ElementoParte.fromJson(Map<String, dynamic> json) => ElementoParte(
        id: json['id'] as String,
        oracionId: json['oracionId'] as String,
        veces: json['veces'] as int,
      );

  final String id;
  final String oracionId;
  final int veces;

  ElementoParte copyWith({int? veces}) => ElementoParte(id: id, oracionId: oracionId, veces: veces ?? this.veces);

  Map<String, dynamic> toJson() => {'id': id, 'oracionId': oracionId, 'veces': veces};
}

/// Un tramo del rosario.
@immutable
class ParteRosario {
  const ParteRosario({required this.id, required this.nombre, required this.elementos, required this.misterios});

  factory ParteRosario.fromJson(Map<String, dynamic> json) => ParteRosario(
        id: json['id'] as String,
        nombre: json['nombre'] as String,
        elementos: [
          for (final e in json['elementos'] as List) ElementoParte.fromJson(e as Map<String, dynamic>),
        ],
        misterios: FuenteMisterios.fromJson(json['misterios'] as Map<String, dynamic>),
      );

  final String id;
  final String nombre;
  final List<ElementoParte> elementos;
  final FuenteMisterios misterios;

  ParteRosario copyWith({String? nombre, List<ElementoParte>? elementos, FuenteMisterios? misterios}) => ParteRosario(
        id: id,
        nombre: nombre ?? this.nombre,
        elementos: elementos ?? this.elementos,
        misterios: misterios ?? this.misterios,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'elementos': [for (final e in elementos) e.toJson()],
        'misterios': misterios.toJson(),
      };
}

enum TipoRosario { tradicional, plantilla, propio }

/// Un rosario: su nombre y sus partes en orden.
@immutable
class Rosario {
  const Rosario({required this.id, required this.nombre, required this.tipo, required this.partes});

  factory Rosario.fromJson(Map<String, dynamic> json) => Rosario(
        id: json['id'] as String,
        nombre: json['nombre'] as String,
        tipo: TipoRosario.values.byName(json['tipo'] as String),
        partes: [for (final p in json['partes'] as List) ParteRosario.fromJson(p as Map<String, dynamic>)],
      );

  final String id;
  final String nombre;
  final TipoRosario tipo;
  final List<ParteRosario> partes;

  bool get esProtegido => tipo != TipoRosario.propio;

  Rosario copyWith({String? nombre, List<ParteRosario>? partes}) =>
      Rosario(id: id, nombre: nombre ?? this.nombre, tipo: tipo, partes: partes ?? this.partes);

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'tipo': tipo.name,
        'partes': [for (final p in partes) p.toJson()],
      };
}
```

- [ ] **Step 4: Ver que pasan**

Run: `flutter test test/models/rosario_test.dart`
Expected: `All tests passed!`.

- [ ] **Step 5: Guardar**

```bash
git add lib/models/oracion.dart lib/models/rosario.dart test/models/rosario_test.dart
git commit -m "feat: modelos de oraciones, partes y rosarios"
```

---

### Task 5: Motor único de rezo

**Files:**
- Create: `lib/data/rosario_tradicional.dart`
- Modify: `lib/logic/rosario_session.dart`, `lib/widgets/barra_rezo.dart`, `lib/screens/rezo_screen.dart`
- Test: `test/logic/motor_rosario_test.dart`

**Interfaces:**
- Consumes: modelos de la Task 4; `oracionesIniciales`, `oracionesPorMisterio`, `oracionesFinales`, `misteriosPorTipo` de `lib/data/oraciones.dart`.
- Produces:
  - `const String prefijoApp = 'app:'`, `String idDeApp(String tipo)`, `final Map<String, Oracion> oracionesDeLaApp`, `final Rosario rosarioTradicional`.
  - `List<PasoRosario> construirPasos({Rosario? rosario, Map<String, Oracion>? oraciones, TipoMisterio tipoDelDia = TipoMisterio.gozosos})`.
  - `PasoRosario` agrega `nombreParte`, `vuelta`, `totalVueltas`, `meditacion` y `fuente`.
  - `RosarioSession.comenzar({Rosario? rosario, Map<String, Oracion>? oraciones})`.

- [ ] **Step 1: Escribir las pruebas**

`test/logic/motor_rosario_test.dart`:

```dart
import 'package:app_resar_rosario/data/rosario_tradicional.dart';
import 'package:app_resar_rosario/logic/rosario_session.dart';
import 'package:app_resar_rosario/models/oracion.dart';
import 'package:app_resar_rosario/models/prayer_models.dart';
import 'package:app_resar_rosario/models/rosario.dart';
import 'package:app_resar_rosario/screens/rezo_screen.dart';
import 'package:app_resar_rosario/widgets/barra_rezo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const propia = Oracion(id: 'o1', titulo: 'Mi oración', texto: 'Señor, escúchame.');
  final oraciones = {...oracionesDeLaApp, propia.id: propia};

  Rosario conParte(FuenteMisterios fuente, {int veces = 1}) => Rosario(
        id: 'r',
        nombre: 'Prueba',
        tipo: TipoRosario.propio,
        partes: [
          ParteRosario(
            id: 'p',
            nombre: 'Mi parte',
            elementos: [ElementoParte(id: 'e', oracionId: propia.id, veces: veces)],
            misterios: fuente,
          ),
        ],
      );

  test('una parte simple da un paso por oración y usa su nombre', () {
    final pasos = construirPasos(rosario: conParte(const SinMisterios()), oraciones: oraciones);
    expect(pasos, hasLength(1));
    expect(nombreSeccion(pasos.single, TipoMisterio.gozosos), 'Mi parte');
    expect(avanceSeccion(pasos.single), '1 de 1');
  });

  test('las veces repiten la oración y se cuentan', () {
    final pasos = construirPasos(rosario: conParte(const SinMisterios(), veces: 3), oraciones: oraciones);
    expect(pasos.map((p) => p.repeticion), [0, 1, 2]);
    expect(tituloOracion(pasos[1]), 'Mi oración · 2 de 3');
  });

  test('las vueltas sin misterios repiten la parte sin anunciar nada', () {
    final pasos = construirPasos(rosario: conParte(const SinMisterios(vueltas: 2)), oraciones: oraciones);
    expect(pasos, hasLength(2));
    expect(pasos.any((p) => p.esAnuncioDeMisterio), isFalse);
    expect(avanceSeccion(pasos[1]), '2 de 2');
  });

  test('un grupo fijo anuncia sus 5 misterios aunque hoy toque otro', () {
    final pasos = construirPasos(
      rosario: conParte(const GrupoMisterios(TipoMisterio.dolorosos)),
      oraciones: oraciones,
      tipoDelDia: TipoMisterio.gozosos,
    );
    expect(pasos, hasLength(10));
    expect(pasos.first.esAnuncioDeMisterio, isTrue);
    expect(tituloAnuncio(pasos.first, TipoMisterio.gozosos), '1.º Misterio Doloroso');
    expect(nombreSeccion(pasos.first, TipoMisterio.gozosos), 'Misterios Dolorosos');
  });

  test('las meditaciones propias se anuncian una por vuelta', () {
    final pasos = construirPasos(rosario: conParte(const MeditacionesPropias(['Por la paz', 'Por los enfermos'])), oraciones: oraciones);
    expect(pasos.where((p) => p.esAnuncioDeMisterio).map((p) => p.meditacion), ['Por la paz', 'Por los enfermos']);
    expect(tituloAnuncio(pasos.first, TipoMisterio.gozosos), 'Meditación 1');
    expect(nombreSeccion(pasos.first, TipoMisterio.gozosos), 'Mi parte');
  });

  test('una oración que ya no existe se omite sin romper el rezo', () {
    expect(construirPasos(rosario: conParte(const SinMisterios()), oraciones: oracionesDeLaApp), isEmpty);
  });

  test('la sesión reza un rosario propio y lo fija al comenzar', () {
    final sesion = RosarioSession(reloj: () => DateTime(2026, 11, 9, 8))
      ..comenzar(rosario: conParte(const SinMisterios(vueltas: 2)), oraciones: oraciones);
    expect(sesion.pasos, hasLength(2));
    sesion.siguiente();
    expect(sesion.esUltimo, isTrue);
    sesion.siguiente();
    expect(sesion.enInicio, isTrue);
  });

  test('un rosario sin pasos no se puede comenzar', () {
    final sesion = RosarioSession(reloj: () => DateTime(2026, 11, 9, 8))
      ..comenzar(rosario: const Rosario(id: 'v', nombre: 'Vacío', tipo: TipoRosario.propio, partes: []));
    expect(sesion.enInicio, isTrue);
  });
}
```

- [ ] **Step 2: Ver que fallan**

Run: `flutter test test/logic/motor_rosario_test.dart`
Expected: FAIL porque `rosario_tradicional.dart` no existe.

- [ ] **Step 3: Crear el Rosario tradicional como datos**

`lib/data/rosario_tradicional.dart`:

```dart
import '../models/oracion.dart';
import '../models/prayer_models.dart';
import '../models/rosario.dart';
import 'oraciones.dart';

/// Las oraciones de la app se identifican con este prefijo.
const String prefijoApp = 'app:';

String idDeApp(String tipo) => '$prefijoApp$tipo';

Oracion _deLaApp(Prayer p) => Oracion(
      id: idDeApp(p.type),
      titulo: p.title,
      texto: p.text,
      origen: OrigenOracion.app,
      formato: p.type == 'letanias' ? FormatoOracion.letanias : FormatoOracion.normal,
    );

/// Oraciones que rezan los misterios, sin el anuncio, que el motor genera solo.
final List<Prayer> _delMisterio = [
  for (final p in oracionesPorMisterio)
    if (p.type != 'misterio') p,
];

/// Todas las oraciones que trae la app.
final Map<String, Oracion> oracionesDeLaApp = Map.unmodifiable({
  for (final p in [...oracionesIniciales, ..._delMisterio, ...oracionesFinales]) idDeApp(p.type): _deLaApp(p),
});

List<ElementoParte> _elementos(String parte, List<Prayer> oraciones) => [
      for (final p in oraciones)
        ElementoParte(id: 'tradicional:$parte:${p.type}', oracionId: idDeApp(p.type), veces: p.count ?? 1),
    ];

/// El rosario de siempre. Es fijo: nunca se guarda ni se edita.
final Rosario rosarioTradicional = Rosario(
  id: 'app:tradicional',
  nombre: 'Rosario tradicional',
  tipo: TipoRosario.tradicional,
  partes: [
    ParteRosario(
      id: 'tradicional:iniciales',
      nombre: 'Oraciones iniciales',
      elementos: _elementos('iniciales', oracionesIniciales),
      misterios: const SinMisterios(),
    ),
    ParteRosario(
      id: 'tradicional:misterios',
      nombre: 'Misterios del día',
      elementos: _elementos('misterios', _delMisterio),
      misterios: const MisteriosDelDia(),
    ),
    ParteRosario(
      id: 'tradicional:finales',
      nombre: 'Oraciones finales',
      elementos: _elementos('finales', oracionesFinales),
      misterios: const SinMisterios(),
    ),
  ],
);
```

- [ ] **Step 4: Cambiar el motor y la sesión**

En `lib/logic/rosario_session.dart`, reemplazar desde el inicio del archivo hasta el final de `construirPasos` por:

```dart
import 'package:flutter/foundation.dart';

import '../data/oraciones.dart';
import '../data/rosario_tradicional.dart';
import '../models/oracion.dart';
import '../models/prayer_models.dart';
import '../models/rosario.dart';

/// Misterios que se rezan en cada rosario.
const int misteriosPorRosario = misteriosPorGrupo;

/// Un paso del recorrido del rosario.
@immutable
class PasoRosario {
  const PasoRosario({
    required this.seccion,
    required this.oracion,
    required this.indiceEnSeccion,
    required this.totalEnSeccion,
    this.misterio,
    this.repeticion,
    this.nombreParte = '',
    this.vuelta = 0,
    this.totalVueltas = 1,
    this.meditacion,
    this.fuente = const SinMisterios(),
  });

  /// Define el color del paso.
  final SeccionRosario seccion;
  final Prayer oracion;

  /// Posición de la oración en su parte.
  final int indiceEnSeccion;
  final int totalEnSeccion;

  /// Misterio o meditación actual (desde 0). Solo en las partes que anuncian algo.
  final int? misterio;

  /// Repetición actual (desde 0). Solo en las oraciones que se rezan varias veces seguidas.
  final int? repeticion;

  final String nombreParte;

  /// Vuelta actual de la parte (desde 0) y total de vueltas.
  final int vuelta;
  final int totalVueltas;

  /// Lo que se medita en esta vuelta.
  final String? meditacion;
  final FuenteMisterios fuente;

  bool get esAnuncioDeMisterio => oracion.type == 'misterio';
}

const Prayer _anuncio = Prayer(type: 'misterio', title: 'Misterio', text: '');

String _tipoDe(Oracion o) {
  if (o.formato == FormatoOracion.letanias) return 'letanias';
  return o.id.startsWith(prefijoApp) ? o.id.substring(prefijoApp.length) : o.id;
}

String? _meditacion(FuenteMisterios fuente, int vuelta, TipoMisterio tipoDelDia) => switch (fuente) {
      SinMisterios() => null,
      MisteriosDelDia() => misteriosPorTipo[tipoDelDia]![vuelta],
      GrupoMisterios(tipo: final grupo) => misteriosPorTipo[grupo]![vuelta],
      MeditacionesPropias(textos: final textos) => textos[vuelta],
    };

/// Arma la lista completa de pasos de un rosario. Sin argumentos, la del Rosario tradicional.
List<PasoRosario> construirPasos({
  Rosario? rosario,
  Map<String, Oracion>? oraciones,
  TipoMisterio tipoDelDia = TipoMisterio.gozosos,
}) {
  final partes = (rosario ?? rosarioTradicional).partes;
  final mapa = oraciones ?? oracionesDeLaApp;
  final primera = partes.indexWhere((p) => p.misterios.vueltas > 1);
  final ultima = partes.lastIndexWhere((p) => p.misterios.vueltas > 1);

  SeccionRosario seccionDe(int i) {
    if (primera < 0 || i < primera) return SeccionRosario.iniciales;
    return i > ultima ? SeccionRosario.finales : SeccionRosario.misterio;
  }

  final pasos = <PasoRosario>[];
  for (var p = 0; p < partes.length; p++) {
    final parte = partes[p];
    final fuente = parte.misterios;
    final elementos = [
      for (final e in parte.elementos)
        if (mapa[e.oracionId] case final oracion?) (elemento: e, oracion: oracion),
    ];
    if (elementos.isEmpty && !fuente.anuncia) continue;
    final desfase = fuente.anuncia ? 1 : 0;
    for (var vuelta = 0; vuelta < fuente.vueltas; vuelta++) {
      PasoRosario paso(Prayer oracion, int indice, int? repeticion) => PasoRosario(
            seccion: seccionDe(p),
            oracion: oracion,
            indiceEnSeccion: indice,
            totalEnSeccion: elementos.length + desfase,
            misterio: fuente.anuncia ? vuelta : null,
            repeticion: repeticion,
            nombreParte: parte.nombre,
            vuelta: vuelta,
            totalVueltas: fuente.vueltas,
            meditacion: _meditacion(fuente, vuelta, tipoDelDia),
            fuente: fuente,
          );
      if (fuente.anuncia) pasos.add(paso(_anuncio, 0, null));
      for (var i = 0; i < elementos.length; i++) {
        final (:elemento, :oracion) = elementos[i];
        final veces = elemento.veces;
        final prayer = Prayer(type: _tipoDe(oracion), title: oracion.titulo, text: oracion.texto, count: veces > 1 ? veces : null);
        for (var r = 0; r < veces; r++) {
          pasos.add(paso(prayer, i + desfase, veces > 1 ? r : null));
        }
      }
    }
  }
  return List.unmodifiable(pasos);
}
```

En la clase `RosarioSession` del mismo archivo, hacer estos cambios:

```dart
class RosarioSession extends ChangeNotifier {
  RosarioSession({DateTime Function()? reloj}) : _reloj = reloj ?? DateTime.now;

  final DateTime Function() _reloj;
  List<PasoRosario> _pasos = const [];

  /// Los pasos del rosario que se está rezando.
  List<PasoRosario> get pasos => _pasos;

  int _indice = -1;
  TipoMisterio? _tipoFijado;

  DateTime get hoy => _reloj();
  bool get enInicio => _indice < 0;
  int get indice => _indice;
  bool get esUltimo => !enInicio && _indice == _pasos.length - 1;
  double get progreso => enInicio ? 0 : (_indice + 1) / _pasos.length;
```

Reemplazar `pasoActual`, `tituloMisterioActual` y `comenzar`:

```dart
  PasoRosario get pasoActual {
    if (enInicio) throw StateError('El rosario no ha comenzado.');
    return _pasos[_indice];
  }

  String get tituloMisterioActual {
    final meditacion = pasoActual.meditacion;
    if (meditacion == null) throw StateError('El paso actual no es de un misterio.');
    return meditacion;
  }

  /// Empieza un rosario; sin argumentos, el tradicional. Los pasos quedan fijos mientras se reza.
  void comenzar({Rosario? rosario, Map<String, Oracion>? oraciones}) {
    final tipo = misterioDelDia(_reloj());
    final pasos = construirPasos(rosario: rosario, oraciones: oraciones, tipoDelDia: tipo);
    if (pasos.isEmpty) return;
    _pasos = pasos;
    _tipoFijado = tipo;
    _indice = 0;
    notifyListeners();
  }
```

- [ ] **Step 5: Adaptar la barra y la pantalla de rezo**

En `lib/widgets/barra_rezo.dart`, agregar `import '../models/rosario.dart';` y reemplazar `nombreSeccion` y `avanceSeccion`:

```dart
/// Nombre de la parte: "Oraciones iniciales", "Misterios Gozosos" o el que eligió el usuario.
String nombreSeccion(PasoRosario paso, TipoMisterio tipo) => switch (paso.fuente) {
      MisteriosDelDia() => 'Misterios ${tipo.nombre}',
      GrupoMisterios(tipo: final grupo) => 'Misterios ${grupo.nombre}',
      _ => paso.nombreParte,
    };

/// Avance dentro de la parte: la vuelta si se repite; si no, la oración.
/// Los espacios son duros ("1 de 10" nunca se parte con letra grande).
String avanceSeccion(PasoRosario paso) => paso.totalVueltas > 1
    ? '${paso.vuelta + 1} de ${paso.totalVueltas}'
    : '${paso.indiceEnSeccion + 1} de ${paso.totalEnSeccion}';
```

En `lib/screens/rezo_screen.dart`, agregar `import '../models/rosario.dart';` y reemplazar `tituloAnuncio`:

```dart
/// Título del anuncio: "2.º Misterio Luminoso" o "Meditación 2".
String tituloAnuncio(PasoRosario paso, TipoMisterio tipo) {
  final numero = paso.misterio! + 1;
  return switch (paso.fuente) {
    MisteriosDelDia() => '$numero.º Misterio ${tipo.singular}',
    GrupoMisterios(tipo: final grupo) => '$numero.º Misterio ${grupo.singular}',
    _ => 'Meditación $numero',
  };
}
```

En `_Cuerpo.build` de ese archivo:
- reemplazar el texto fijo `'Medita en este misterio.'` por `paso.fuente is MeditacionesPropias ? 'Dedica un momento a meditar.' : 'Medita en este misterio.'`;
- reemplazar `if (paso.seccion == SeccionRosario.misterio) ...[` por `if (paso.meditacion != null) ...[`;
- reemplazar `if (paso.repeticion != null) ...[` (el de las cuentas) por `if (paso.repeticion != null && paso.oracion.count! <= 20) ...[`.

Quitar el import de `prayer_models.dart` solo si el analizador lo marca sin uso.

- [ ] **Step 6: Ver que pasan todas las pruebas**

Run: `flutter test test/logic/ test/screens/rezo_screen_test.dart test/widgets/barra_rezo_test.dart`
Expected: `All tests passed!`, incluida la referencia de los 93 pasos.

Run: `flutter analyze` y `flutter test`
Expected: `No issues found!` y `All tests passed!`.

- [ ] **Step 7: Guardar**

```bash
git add lib/data/rosario_tradicional.dart lib/logic/rosario_session.dart lib/widgets/barra_rezo.dart lib/screens/rezo_screen.dart test/logic/motor_rosario_test.dart
git commit -m "feat: un solo motor de rezo basado en datos, con el tradicional intacto"
```

---

### Task 6: Almacenamiento seguro en un archivo

**Files:**
- Create: `lib/services/almacen_rosarios.dart`
- Create: `test/support/almacen_en_memoria.dart`
- Test: `test/services/almacen_rosarios_test.dart`

**Interfaces:**
- Consumes: `Oracion`, `Rosario`.
- Produces:
  - `DatosUsuario({oraciones = const [], rosarios = const [], recuperado = false})`.
  - `abstract interface class AlmacenRosarios { Future<DatosUsuario> leer(); Future<void> guardar(DatosUsuario datos); }`.
  - `AlmacenArchivo(Directory carpeta)`.
  - En pruebas: `AlmacenEnMemoria({DatosUsuario? inicial})` con `DatosUsuario datos` y `bool fallarAlGuardar`.

- [ ] **Step 1: Escribir las pruebas**

`test/services/almacen_rosarios_test.dart`:

```dart
import 'dart:convert';
import 'dart:io';

import 'package:app_resar_rosario/models/oracion.dart';
import 'package:app_resar_rosario/models/rosario.dart';
import 'package:app_resar_rosario/services/almacen_rosarios.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory carpeta;
  late AlmacenArchivo almacen;
  const oracion = Oracion(id: 'o1', titulo: 'Por la paz', texto: 'Señor, danos tu paz.');
  const rosario = Rosario(id: 'r1', nombre: 'Mío', tipo: TipoRosario.propio, partes: []);
  File archivo(String nombre) => File('${carpeta.path}/$nombre');

  setUp(() {
    carpeta = Directory.systemTemp.createTempSync('almacen_');
    almacen = AlmacenArchivo(carpeta);
  });
  tearDown(() => carpeta.deleteSync(recursive: true));

  test('sin archivo empieza vacío', () async {
    final datos = await almacen.leer();
    expect(datos.oraciones, isEmpty);
    expect(datos.rosarios, isEmpty);
    expect(datos.recuperado, isFalse);
  });

  test('guarda y vuelve a leer', () async {
    await almacen.guardar(const DatosUsuario(oraciones: [oracion], rosarios: [rosario]));
    final datos = await AlmacenArchivo(carpeta).leer();
    expect(datos.oraciones.single.titulo, 'Por la paz');
    expect(datos.rosarios.single.nombre, 'Mío');
    expect(archivo('rosarios_usuario.tmp').existsSync(), isFalse);
  });

  test('si el archivo se daña, recupera el respaldo y lo avisa', () async {
    await almacen.guardar(const DatosUsuario(oraciones: [oracion]));
    await almacen.guardar(const DatosUsuario(oraciones: [oracion], rosarios: [rosario]));
    archivo('rosarios_usuario.json').writeAsStringSync('{dañado');

    final datos = await almacen.leer();
    expect(datos.recuperado, isTrue);
    expect(datos.oraciones.single.id, 'o1');
    expect(archivo('rosarios_usuario.danado').existsSync(), isTrue);
  });

  test('si también se daña el respaldo, empieza vacío sin fallar', () async {
    archivo('rosarios_usuario.json').writeAsStringSync('no es json');
    archivo('rosarios_usuario.bak').writeAsStringSync('tampoco');
    final datos = await almacen.leer();
    expect(datos.oraciones, isEmpty);
    expect(datos.recuperado, isTrue);
  });

  test('el archivo guarda su versión', () async {
    await almacen.guardar(const DatosUsuario());
    final json = jsonDecode(archivo('rosarios_usuario.json').readAsStringSync()) as Map<String, dynamic>;
    expect(json['version'], 1);
  });
}
```

- [ ] **Step 2: Ver que fallan**

Run: `flutter test test/services/almacen_rosarios_test.dart`
Expected: FAIL porque el archivo no existe.

- [ ] **Step 3: Implementar**

`lib/services/almacen_rosarios.dart`:

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/oracion.dart';
import '../models/rosario.dart';

/// Lo que crea el usuario. Lo protegido vive en el código y nunca se guarda.
@immutable
class DatosUsuario {
  const DatosUsuario({this.oraciones = const [], this.rosarios = const [], this.recuperado = false});

  final List<Oracion> oraciones;
  final List<Rosario> rosarios;

  /// El archivo estaba dañado y se usó el respaldo o se empezó de nuevo.
  final bool recuperado;
}

abstract interface class AlmacenRosarios {
  Future<DatosUsuario> leer();
  Future<void> guardar(DatosUsuario datos);
}

/// Guarda en un archivo JSON. Escribe primero en un temporal para no dejar nunca un archivo a medias.
class AlmacenArchivo implements AlmacenRosarios {
  AlmacenArchivo(this.carpeta);

  static const int _version = 1;

  final Directory carpeta;

  File _archivo(String extension) => File('${carpeta.path}/rosarios_usuario.$extension');

  DatosUsuario _interpretar(String contenido) {
    final json = jsonDecode(contenido) as Map<String, dynamic>;
    if (json['version'] != _version) throw const FormatException('Versión desconocida');
    return DatosUsuario(
      oraciones: [for (final o in json['oraciones'] as List) Oracion.fromJson(o as Map<String, dynamic>)],
      rosarios: [for (final r in json['rosarios'] as List) Rosario.fromJson(r as Map<String, dynamic>)],
    );
  }

  @override
  Future<DatosUsuario> leer() async {
    final principal = _archivo('json');
    final respaldo = _archivo('bak');
    if (!principal.existsSync() && !respaldo.existsSync()) return const DatosUsuario();
    try {
      return _interpretar(await principal.readAsString());
    } catch (error) {
      debugPrint('No se pudo leer el archivo de rosarios: $error');
    }
    if (principal.existsSync()) await principal.copy(_archivo('danado').path);
    try {
      final datos = _interpretar(await respaldo.readAsString());
      return DatosUsuario(oraciones: datos.oraciones, rosarios: datos.rosarios, recuperado: true);
    } catch (error) {
      debugPrint('No se pudo leer el respaldo de rosarios: $error');
      return const DatosUsuario(recuperado: true);
    }
  }

  @override
  Future<void> guardar(DatosUsuario datos) async {
    await carpeta.create(recursive: true);
    final temporal = _archivo('tmp');
    await temporal.writeAsString(
      jsonEncode({
        'version': _version,
        'oraciones': [for (final o in datos.oraciones) o.toJson()],
        'rosarios': [for (final r in datos.rosarios) r.toJson()],
      }),
      flush: true,
    );
    final principal = _archivo('json');
    if (principal.existsSync()) await principal.copy(_archivo('bak').path);
    await temporal.rename(principal.path);
  }
}
```

`test/support/almacen_en_memoria.dart`:

```dart
import 'package:app_resar_rosario/services/almacen_rosarios.dart';

/// Doble del almacén: guarda en memoria.
class AlmacenEnMemoria implements AlmacenRosarios {
  AlmacenEnMemoria({DatosUsuario? inicial}) : datos = inicial ?? const DatosUsuario();

  DatosUsuario datos;
  bool fallarAlGuardar = false;

  @override
  Future<DatosUsuario> leer() async => datos;

  @override
  Future<void> guardar(DatosUsuario datos) async {
    if (fallarAlGuardar) throw StateError('Fallo simulado al guardar');
    this.datos = datos;
  }
}
```

- [ ] **Step 4: Ver que pasan**

Run: `flutter test test/services/almacen_rosarios_test.dart`
Expected: `All tests passed!`.

- [ ] **Step 5: Guardar**

```bash
git add lib/services/almacen_rosarios.dart test/support/almacen_en_memoria.dart test/services/almacen_rosarios_test.dart
git commit -m "feat: almacenamiento seguro de oraciones y rosarios propios"
```

---

### Task 7: Biblioteca de oraciones y rosarios

**Files:**
- Create: `lib/services/biblioteca_service.dart`, `lib/data/plantillas_rosario.dart`
- Modify: `lib/app.dart`, `lib/main.dart`, `test/support/app_harness.dart`
- Test: `test/services/biblioteca_service_test.dart`

**Interfaces:**
- Consumes: `AlmacenRosarios`, `DatosUsuario`, `oracionesDeLaApp`, `rosarioTradicional`.
- Produces:
  - `PlantillaRosario({required Rosario rosario, required bool textosValidados})`, `plantillasRosario`, `oracionesDePlantillas`.
  - `BibliotecaService({required AlmacenRosarios almacen, String Function()? nuevoId, bool mostrarSinValidar = kDebugMode})`.
  - Lectura: `datosRecuperados`, `errorAlGuardar`, `oracionesApp`, `oracionesPropias`, `mapaOraciones`, `plantillas`, `rosariosPropios`, `rosarioPorId(id)`, `rosariosQueUsan(oracionId)`.
  - Escritura (todas `Future`): `cargar()`, `guardarOracion({String? id, required String titulo, required String texto})` → `Oracion`, `crearMiVersion(Oracion base)` → `Oracion`, `eliminarOracion(id)`, `crearRosario(nombre, {Rosario? base})` → `Rosario`, `guardarRosario(Rosario)`, `eliminarRosario(id)`, `duplicarRosario(id)` → `Rosario`.
  - `String nuevoId()` público, para que el constructor cree partes y elementos.
  - `SantoRosarioApp` requiere `biblioteca`. En pruebas: `dependenciasDePrueba` devuelve también `biblioteca`, y `envolver` acepta `biblioteca`.

- [ ] **Step 1: Escribir las pruebas**

`test/services/biblioteca_service_test.dart`:

```dart
import 'package:app_resar_rosario/data/rosario_tradicional.dart';
import 'package:app_resar_rosario/models/rosario.dart';
import 'package:app_resar_rosario/services/almacen_rosarios.dart';
import 'package:app_resar_rosario/services/biblioteca_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/almacen_en_memoria.dart';

void main() {
  late AlmacenEnMemoria almacen;
  late BibliotecaService biblioteca;

  setUp(() async {
    almacen = AlmacenEnMemoria();
    var n = 0;
    biblioteca = BibliotecaService(almacen: almacen, nuevoId: () => 'id${n++}');
    await biblioteca.cargar();
  });

  ParteRosario parteCon(String oracionId) => ParteRosario(
        id: 'p',
        nombre: 'Parte',
        elementos: [ElementoParte(id: 'e', oracionId: oracionId)],
        misterios: const SinMisterios(),
      );

  test('las oraciones de la app aparecen una sola vez aunque se recen en varias partes', () {
    final titulos = biblioteca.oracionesApp.map((o) => o.titulo).toList();
    expect(titulos.where((t) => t == 'Ave María'), hasLength(1));
    expect(titulos.where((t) => t == 'Gloria'), hasLength(1));
  });

  test('crear una oración la guarda', () async {
    final o = await biblioteca.guardarOracion(titulo: ' Por la paz ', texto: ' Señor, danos paz. ');
    expect(o.titulo, 'Por la paz');
    expect(o.texto, 'Señor, danos paz.');
    expect(almacen.datos.oraciones.single.id, o.id);
    expect(biblioteca.mapaOraciones[o.id], isNotNull);
  });

  test('editar conserva el id', () async {
    final o = await biblioteca.guardarOracion(titulo: 'Uno', texto: 'Texto');
    await biblioteca.guardarOracion(id: o.id, titulo: 'Dos', texto: 'Texto');
    expect(biblioteca.oracionesPropias.single.titulo, 'Dos');
  });

  test('crear mi versión copia una oración de la app como propia', () async {
    final base = oracionesDeLaApp[idDeApp('avemaria')]!;
    final copia = await biblioteca.crearMiVersion(base);
    expect(copia.esDeLaApp, isFalse);
    expect(copia.titulo, 'Ave María (mi versión)');
    expect(copia.texto, base.texto);
  });

  test('eliminar una oración la quita de los rosarios que la usan', () async {
    final o = await biblioteca.guardarOracion(titulo: 'Uno', texto: 'Texto');
    final r = await biblioteca.crearRosario('Mío');
    await biblioteca.guardarRosario(r.copyWith(partes: [parteCon(o.id)]));
    expect(biblioteca.rosariosQueUsan(o.id).single.id, r.id);

    await biblioteca.eliminarOracion(o.id);
    expect(biblioteca.rosarioPorId(r.id)!.partes.single.elementos, isEmpty);
    expect(biblioteca.oracionesPropias, isEmpty);
  });

  test('crear desde el tradicional hace una copia propia independiente', () async {
    final copia = await biblioteca.crearRosario('Mi versión', base: rosarioTradicional);
    expect(copia.tipo, TipoRosario.propio);
    expect(copia.partes, hasLength(3));
    expect(copia.partes.first.id, isNot(rosarioTradicional.partes.first.id));
  });

  test('un rosario protegido no se puede guardar ni eliminar', () async {
    expect(() => biblioteca.guardarRosario(rosarioTradicional), throwsStateError);
    expect(() => biblioteca.eliminarRosario(rosarioTradicional.id), throwsStateError);
  });

  test('duplicar y eliminar un rosario propio', () async {
    final r = await biblioteca.crearRosario('Mío');
    final d = await biblioteca.duplicarRosario(r.id);
    expect(d.nombre, 'Mío (copia)');
    await biblioteca.eliminarRosario(r.id);
    expect(biblioteca.rosariosPropios.single.id, d.id);
  });

  test('si falla el guardado lo avisa y conserva los datos en memoria', () async {
    almacen.fallarAlGuardar = true;
    await biblioteca.guardarOracion(titulo: 'Uno', texto: 'Texto');
    expect(biblioteca.errorAlGuardar, isTrue);
    expect(biblioteca.oracionesPropias, hasLength(1));
  });

  test('avisa si los datos se recuperaron de un respaldo', () async {
    final b = BibliotecaService(almacen: AlmacenEnMemoria(inicial: const DatosUsuario(recuperado: true)));
    await b.cargar();
    expect(b.datosRecuperados, isTrue);
  });
}
```

- [ ] **Step 2: Ver que fallan**

Run: `flutter test test/services/biblioteca_service_test.dart`
Expected: FAIL porque el servicio no existe.

- [ ] **Step 3: Implementar**

`lib/data/plantillas_rosario.dart` (la Task 15 agrega el contenido):

```dart
import '../models/oracion.dart';
import '../models/rosario.dart';

/// Un rosario incluido en la app. Sin validar sus textos, no aparece en la versión publicada.
class PlantillaRosario {
  const PlantillaRosario({required this.rosario, required this.textosValidados});

  final Rosario rosario;
  final bool textosValidados;
}

/// Oraciones que solo usan las plantillas.
final Map<String, Oracion> oracionesDePlantillas = Map.unmodifiable(<String, Oracion>{});

final List<PlantillaRosario> plantillasRosario = List.unmodifiable(<PlantillaRosario>[]);
```

`lib/services/biblioteca_service.dart`:

```dart
import 'package:flutter/foundation.dart';

import '../data/plantillas_rosario.dart';
import '../data/rosario_tradicional.dart';
import '../models/oracion.dart';
import '../models/rosario.dart';
import 'almacen_rosarios.dart';

/// Oraciones y rosarios del usuario, junto con lo protegido que trae la app.
class BibliotecaService extends ChangeNotifier {
  BibliotecaService({required AlmacenRosarios almacen, String Function()? nuevoId, bool mostrarSinValidar = kDebugMode})
      : _almacen = almacen,
        _generarId = nuevoId,
        _mostrarSinValidar = mostrarSinValidar;

  final AlmacenRosarios _almacen;
  final String Function()? _generarId;
  final bool _mostrarSinValidar;

  List<Oracion> _oraciones = const [];
  List<Rosario> _rosarios = const [];
  bool _datosRecuperados = false;
  bool _errorAlGuardar = false;
  int _contador = 0;
  Future<void> _escritura = Future<void>.value();

  bool get datosRecuperados => _datosRecuperados;
  bool get errorAlGuardar => _errorAlGuardar;
  List<Oracion> get oracionesPropias => List.unmodifiable(_oraciones);
  List<Rosario> get rosariosPropios => List.unmodifiable(_rosarios);

  /// Oraciones de la app sin repetir: varias partes del rosario rezan la misma oración.
  List<Oracion> get oracionesApp {
    final vistas = <String>{};
    return [
      for (final o in [...oracionesDeLaApp.values, ...oracionesDePlantillas.values])
        if (vistas.add('${o.titulo}\n${o.texto}')) o,
    ];
  }

  Map<String, Oracion> get mapaOraciones => {
        ...oracionesDeLaApp,
        ...oracionesDePlantillas,
        for (final o in _oraciones) o.id: o,
      };

  List<Rosario> get plantillas => [
        for (final p in plantillasRosario)
          if (p.textosValidados || _mostrarSinValidar) p.rosario,
      ];

  Rosario? rosarioPorId(String id) {
    for (final r in [rosarioTradicional, ...plantillas, ..._rosarios]) {
      if (r.id == id) return r;
    }
    return null;
  }

  List<Rosario> rosariosQueUsan(String oracionId) => [
        for (final r in _rosarios)
          if (r.partes.any((p) => p.elementos.any((e) => e.oracionId == oracionId))) r,
      ];

  String nuevoId() => _generarId?.call() ?? '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}-${_contador++}';

  /// Nunca lanza: si no se puede leer, la app sigue con lo protegido.
  Future<void> cargar() async {
    try {
      final datos = await _almacen.leer();
      _oraciones = datos.oraciones;
      _rosarios = datos.rosarios;
      _datosRecuperados = datos.recuperado;
    } catch (error) {
      debugPrint('No se pudo cargar la biblioteca: $error');
      _datosRecuperados = true;
    }
    notifyListeners();
  }

  /// Las escrituras van en fila para que un guardado lento no pise a uno más nuevo.
  Future<void> _persistir() {
    notifyListeners();
    final datos = DatosUsuario(oraciones: _oraciones, rosarios: _rosarios);
    return _escritura = _escritura.then((_) async {
      try {
        await _almacen.guardar(datos);
        _errorAlGuardar = false;
      } catch (error) {
        debugPrint('No se pudo guardar la biblioteca: $error');
        _errorAlGuardar = true;
      }
      notifyListeners();
    });
  }

  Future<Oracion> guardarOracion({String? id, required String titulo, required String texto}) async {
    final oracion = Oracion(id: id ?? nuevoId(), titulo: titulo.trim(), texto: texto.trim());
    final existe = _oraciones.any((o) => o.id == oracion.id);
    _oraciones = existe ? [for (final o in _oraciones) o.id == oracion.id ? oracion : o] : [..._oraciones, oracion];
    await _persistir();
    return oracion;
  }

  Future<Oracion> crearMiVersion(Oracion base) {
    const sufijo = ' (mi versión)';
    final limite = LimitesBiblioteca.tituloOracion - sufijo.length;
    final titulo = base.titulo.length > limite ? base.titulo.substring(0, limite) : base.titulo;
    return guardarOracion(titulo: '$titulo$sufijo', texto: base.texto);
  }

  Future<void> eliminarOracion(String id) {
    _oraciones = [
      for (final o in _oraciones)
        if (o.id != id) o,
    ];
    _rosarios = [
      for (final r in _rosarios)
        r.copyWith(partes: [
          for (final p in r.partes)
            p.copyWith(elementos: [
              for (final e in p.elementos)
                if (e.oracionId != id) e,
            ]),
        ]),
    ];
    return _persistir();
  }

  /// Copia las partes con identificadores nuevos.
  List<ParteRosario> _copiarPartes(List<ParteRosario> partes) => [
        for (final p in partes)
          ParteRosario(
            id: nuevoId(),
            nombre: p.nombre,
            misterios: p.misterios,
            elementos: [
              for (final e in p.elementos) ElementoParte(id: nuevoId(), oracionId: e.oracionId, veces: e.veces),
            ],
          ),
      ];

  Future<Rosario> crearRosario(String nombre, {Rosario? base}) async {
    final rosario = Rosario(
      id: nuevoId(),
      nombre: nombre.trim(),
      tipo: TipoRosario.propio,
      partes: base == null ? const [] : _copiarPartes(base.partes),
    );
    _rosarios = [..._rosarios, rosario];
    await _persistir();
    return rosario;
  }

  Future<void> guardarRosario(Rosario rosario) {
    if (rosario.esProtegido) throw StateError('Un rosario protegido no se puede modificar.');
    final existe = _rosarios.any((r) => r.id == rosario.id);
    _rosarios = existe ? [for (final r in _rosarios) r.id == rosario.id ? rosario : r] : [..._rosarios, rosario];
    return _persistir();
  }

  Future<void> eliminarRosario(String id) {
    if (rosarioPorId(id)?.esProtegido ?? false) throw StateError('Un rosario protegido no se puede eliminar.');
    _rosarios = [
      for (final r in _rosarios)
        if (r.id != id) r,
    ];
    return _persistir();
  }

  Future<Rosario> duplicarRosario(String id) {
    final base = rosarioPorId(id);
    if (base == null) throw StateError('El rosario no existe.');
    const sufijo = ' (copia)';
    final limite = LimitesBiblioteca.nombre - sufijo.length;
    final nombre = base.nombre.length > limite ? base.nombre.substring(0, limite) : base.nombre;
    return crearRosario('$nombre$sufijo', base: base);
  }
}
```

- [ ] **Step 4: Conectar con la app**

En `lib/app.dart`:
- agregar `import 'services/biblioteca_service.dart';`;
- agregar el parámetro `required this.biblioteca` y el campo `final BibliotecaService biblioteca;`;
- agregar a `providers`: `ChangeNotifierProvider<BibliotecaService>.value(value: biblioteca),`.

En `lib/main.dart`:
- agregar `import 'package:path_provider/path_provider.dart';`, `import 'services/almacen_rosarios.dart';` e `import 'services/biblioteca_service.dart';`;
- antes de `runApp`:

```dart
  final biblioteca = BibliotecaService(almacen: AlmacenArchivo(await getApplicationSupportDirectory()));
  await biblioteca.cargar(); // nunca lanza: si algo falla, la app sigue con lo protegido
```

- pasar `biblioteca: biblioteca` a `SantoRosarioApp`.

En `test/support/app_harness.dart`:
- agregar imports de `biblioteca_service.dart` y `almacen_en_memoria.dart`;
- cambiar `dependenciasDePrueba` para crear y devolver `biblioteca`:

```dart
Future<({PreferencesService preferencias, NotificationService notificaciones, FakeNotificationsGateway gateway, BibliotecaService biblioteca})>
    dependenciasDePrueba({Map<String, Object> preferencias = const {}, FakeNotificationsGateway? gateway, BibliotecaService? biblioteca}) async {
  final prefs = await preferenciasDePrueba(preferencias);
  final g = gateway ?? FakeNotificationsGateway();
  final b = biblioteca ?? BibliotecaService(almacen: AlmacenEnMemoria());
  await b.cargar();
  return (preferencias: prefs, notificaciones: await notificacionesDePrueba(g), gateway: g, biblioteca: b);
}
```

- cambiar `appDePrueba` para aceptar `BibliotecaService? biblioteca`, pasarlo a `dependenciasDePrueba` y pasar `biblioteca: d.biblioteca` a `SantoRosarioApp`;
- en `envolver`, agregar el parámetro `BibliotecaService? biblioteca` y el proveedor `ChangeNotifierProvider<BibliotecaService>.value(value: biblioteca ?? BibliotecaService(almacen: AlmacenEnMemoria())),`.

Run: `grep -rn "SantoRosarioApp(" test lib`
Agregar `biblioteca:` en cualquier otra llamada que aparezca.

- [ ] **Step 5: Ver que todo pasa**

Run: `flutter test test/services/biblioteca_service_test.dart`
Expected: `All tests passed!`.

Run: `flutter analyze` y `flutter test`
Expected: `No issues found!` y `All tests passed!`.

- [ ] **Step 6: Guardar y cerrar la etapa**

Run: `graphify update .`

```bash
git add lib/services/biblioteca_service.dart lib/data/plantillas_rosario.dart lib/app.dart lib/main.dart test/support/app_harness.dart test/services/biblioteca_service_test.dart
git commit -m "feat: biblioteca de oraciones y rosarios del usuario"
```
