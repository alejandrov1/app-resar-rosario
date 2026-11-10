# Mejora integral — Fase 2A: Preferencias y recorrido del rosario

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Preferencias que se guardan (E3), oraciones escritas una sola vez, el recorrido del rosario como lista fija de 93 pasos con pruebas, un tema base sin escalado doble (E4) y una sola pantalla de rezo en lugar de tres.

**Architecture:** `RosarioSession` (ChangeNotifier puro, sin widgets) guarda el índice del paso actual. `PrincipalScreen` muestra `InicioScreen` o `RezoScreen` según la sesión. Todos los colores nuevos vienen de `lib/theme/` (`SeccionesTema`, una `ThemeExtension`). Las pantallas viejas se mantienen compilando con una fachada temporal `PrayerData` que se borra en la Task 11.

**Tech Stack:** Flutter 3.47.9, provider, shared_preferences, flutter_test.

**Spec:** `docs/superpowers/specs/2026-11-09-mejora-integral-design.md` (§4.1, §4.3, §4.4) · **Índice:** `docs/superpowers/plans/2026-11-09-mejora-integral.md`

## Global Constraints

- Rama `mejora-integral`; cada commit termina con `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; sin `git push` sin autorización.
- Nombres: pantallas, widgets, tema y lógica en español; modelos y servicios en inglés (patrón existente del repo).
- Colores nuevos solo en `lib/theme/`. Las pantallas nuevas leen `Theme.of(context)` y `context.secciones` / `context.coloresDe(...)`.
- **Prohibido** multiplicar tamaños de letra por `textScaleFactor`; el escalado se aplica una sola vez en `MaterialApp.builder`.
- Interfaz en español; los textos visibles son exactamente los de cada tarea.
- Cierre de cada tarea: `flutter analyze` sin errores ni advertencias y `flutter test` en verde.

---

### Task 6: Preferencias que se guardan en el teléfono (E3)

**Files:**
- Rewrite: `lib/services/preferences_service.dart`
- Create: `test/support/app_harness.dart`
- Rewrite: `test/services/preferences_service_test.dart`
- Rewrite: `lib/main.dart`
- Modify: `test/widget_test.dart`

**Interfaces:**
- Consumes: —
- Produces:
  - `class PreferencesService extends ChangeNotifier` con constructor `PreferencesService(SharedPreferences prefs)`; getters `double textScaleFactor`, `bool useHighContrast`, `bool useLargeButtons`, `ThemeMode themeMode`; métodos `void updateTextScaleFactor(double)`, `void toggleHighContrast()`, `void toggleLargeButtons()`, `void updateThemeMode(ThemeMode)`, `void resetToDefaults()`; constantes `static const double minTextScale = 0.8`, `maxTextScale = 2.0`.
  - Claves guardadas: `pref_text_scale` (double), `pref_high_contrast` (bool), `pref_large_buttons` (bool), `pref_theme_mode` (int = `ThemeMode.index`).
  - `test/support/app_harness.dart`: `Future<PreferencesService> preferenciasDePrueba([Map<String, Object> valores = const {}])`.

- [ ] **Step 1: Crear el soporte de pruebas**

`test/support/app_harness.dart`:

```dart
import 'package:app_resar_rosario/services/preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferencias de prueba, vacías o con [valores] ya guardados.
Future<PreferencesService> preferenciasDePrueba([Map<String, Object> valores = const {}]) async {
  SharedPreferences.setMockInitialValues(valores);
  return PreferencesService(await SharedPreferences.getInstance());
}
```

- [ ] **Step 2: Escribir las pruebas**

`test/services/preferences_service_test.dart`:

```dart
import 'package:app_resar_rosario/services/preferences_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/app_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('valores por defecto', () async {
    final p = await preferenciasDePrueba();
    expect(p.textScaleFactor, 1.0);
    expect(p.useHighContrast, isFalse);
    expect(p.useLargeButtons, isFalse);
    expect(p.themeMode, ThemeMode.system);
  });

  test('los cambios se guardan y se recuperan al volver a abrir la app', () async {
    final p = await preferenciasDePrueba();
    p
      ..updateTextScaleFactor(1.5)
      ..toggleHighContrast()
      ..toggleLargeButtons()
      ..updateThemeMode(ThemeMode.dark);

    final reabierta = PreferencesService(await SharedPreferences.getInstance());
    expect(reabierta.textScaleFactor, 1.5);
    expect(reabierta.useHighContrast, isTrue);
    expect(reabierta.useLargeButtons, isTrue);
    expect(reabierta.themeMode, ThemeMode.dark);
  });

  test('ignora tamaños de texto fuera de rango', () async {
    final p = await preferenciasDePrueba();
    p.updateTextScaleFactor(1.4);
    p.updateTextScaleFactor(0.5);
    p.updateTextScaleFactor(3.0);
    expect(p.textScaleFactor, 1.4);
  });

  test('si lo guardado está dañado usa los valores por defecto', () async {
    final p = await preferenciasDePrueba({'pref_text_scale': 9.0, 'pref_theme_mode': 7});
    expect(p.textScaleFactor, 1.0);
    expect(p.themeMode, ThemeMode.system);
  });

  test('restablecer borra lo guardado', () async {
    final p = await preferenciasDePrueba({'pref_large_buttons': true, 'pref_text_scale': 1.8});
    p.resetToDefaults();
    final reabierta = PreferencesService(await SharedPreferences.getInstance());
    expect(reabierta.useLargeButtons, isFalse);
    expect(reabierta.textScaleFactor, 1.0);
  });

  test('avisa a quien escucha en cada cambio', () async {
    final p = await preferenciasDePrueba();
    var avisos = 0;
    p.addListener(() => avisos++);
    p
      ..toggleHighContrast()
      ..updateThemeMode(ThemeMode.light);
    expect(avisos, 2);
  });
}
```

- [ ] **Step 3: Correr y ver que falla**

Run: `flutter test test/services/preferences_service_test.dart`
Expected: FAIL de compilación — `Too many positional arguments: 0 expected, but 1 found` (el constructor actual no recibe `SharedPreferences`).

- [ ] **Step 4: Implementar**

`lib/services/preferences_service.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferencias de accesibilidad y apariencia, guardadas en el teléfono.
class PreferencesService extends ChangeNotifier {
  PreferencesService(this._prefs)
      : _textScaleFactor = _leerEscala(_prefs),
        _useHighContrast = _prefs.getBool(_kContraste) ?? false,
        _useLargeButtons = _prefs.getBool(_kBotones) ?? false,
        _themeMode = _leerTema(_prefs);

  static const double minTextScale = 0.8;
  static const double maxTextScale = 2.0;

  static const String _kEscala = 'pref_text_scale';
  static const String _kContraste = 'pref_high_contrast';
  static const String _kBotones = 'pref_large_buttons';
  static const String _kTema = 'pref_theme_mode';

  final SharedPreferences _prefs;
  double _textScaleFactor;
  bool _useHighContrast;
  bool _useLargeButtons;
  ThemeMode _themeMode;

  double get textScaleFactor => _textScaleFactor;
  bool get useHighContrast => _useHighContrast;
  bool get useLargeButtons => _useLargeButtons;
  ThemeMode get themeMode => _themeMode;

  void updateTextScaleFactor(double factor) {
    if (factor < minTextScale || factor > maxTextScale) return;
    _textScaleFactor = factor;
    unawaited(_prefs.setDouble(_kEscala, factor));
    notifyListeners();
  }

  void toggleHighContrast() {
    _useHighContrast = !_useHighContrast;
    unawaited(_prefs.setBool(_kContraste, _useHighContrast));
    notifyListeners();
  }

  void toggleLargeButtons() {
    _useLargeButtons = !_useLargeButtons;
    unawaited(_prefs.setBool(_kBotones, _useLargeButtons));
    notifyListeners();
  }

  void updateThemeMode(ThemeMode mode) {
    _themeMode = mode;
    unawaited(_prefs.setInt(_kTema, mode.index));
    notifyListeners();
  }

  void resetToDefaults() {
    _textScaleFactor = 1.0;
    _useHighContrast = false;
    _useLargeButtons = false;
    _themeMode = ThemeMode.system;
    for (final clave in [_kEscala, _kContraste, _kBotones, _kTema]) {
      unawaited(_prefs.remove(clave));
    }
    notifyListeners();
  }

  static double _leerEscala(SharedPreferences prefs) {
    final valor = prefs.getDouble(_kEscala) ?? 1.0;
    return valor < minTextScale || valor > maxTextScale ? 1.0 : valor;
  }

  static ThemeMode _leerTema(SharedPreferences prefs) {
    final indice = prefs.getInt(_kTema);
    if (indice == null || indice < 0 || indice >= ThemeMode.values.length) {
      return ThemeMode.system;
    }
    return ThemeMode.values[indice];
  }
}
```

- [ ] **Step 5: Correr y ver que pasa**

Run: `flutter test test/services/preferences_service_test.dart`
Expected: `All tests passed!`

- [ ] **Step 6: Crear las preferencias al arrancar la app**

`lib/main.dart` (reemplazo completo; la estructura antigua se conserva hasta la Task 15):

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'constants/app_theme.dart';
import 'resar_rosario_app.dart';
import 'services/notification_service.dart';
import 'services/preferences_service.dart';
import 'widgets/settings_drawer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final preferencias = PreferencesService(await SharedPreferences.getInstance());
  final notificaciones = NotificationService();
  try {
    await notificaciones.initialize();
    if (notificaciones.isInitialized) {
      await notificaciones.cleanInvalidReminders();
    }
  } catch (e) {
    debugPrint('Error al inicializar las notificaciones: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: preferencias),
        ChangeNotifierProvider.value(value: notificaciones),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final preferencias = context.watch<PreferencesService>();
    return MaterialApp(
      title: 'Santo Rosario',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(preferencias.textScaleFactor),
      darkTheme: AppTheme.darkTheme(preferencias.textScaleFactor),
      themeMode: preferencias.themeMode,
      home: MainScreen(preferences: preferencias),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(preferencias.textScaleFactor),
          highContrast: preferencias.useHighContrast,
        ),
        child: child!,
      ),
    );
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({super.key, required this.preferences});

  final PreferencesService preferences;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: SettingsDrawer(preferences: preferences),
      body: RosarioApp(preferences: preferences),
    );
  }
}
```

- [ ] **Step 7: Ajustar la prueba de arranque**

En `test/widget_test.dart`, reemplazar el cuerpo de la prueba:

```dart
import 'package:app_resar_rosario/main.dart';
import 'package:app_resar_rosario/services/notification_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'support/app_harness.dart';

void main() {
  testWidgets('la app arranca en la pantalla de inicio', (tester) async {
    final preferencias = await preferenciasDePrueba();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: preferencias),
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

- [ ] **Step 8: Verificar y hacer commit**

Run: `flutter analyze && flutter test`
Expected: sin errores ni advertencias; `All tests passed!`

```bash
git add lib/services/preferences_service.dart lib/main.dart test
git commit -m "fix: guardar las preferencias en el teléfono" -m "Tamaño de texto, alto contraste, botones grandes y tema se pierden al cerrar la app (E3). Ahora se guardan con shared_preferences y se cargan antes de runApp." -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 7: Oraciones escritas una sola vez y modelos del rosario

**Files:**
- Create: `lib/data/oraciones.dart`
- Rewrite: `lib/models/prayer_models.dart`
- Create: `test/data/oraciones_test.dart`
- Delete: `test/models/prayer_models_test.dart`

**Interfaces:**
- Consumes: —
- Produces:
  - `lib/models/prayer_models.dart`: `class Prayer { const Prayer({required String type, required String title, required String text, int? count}); }`; `enum SeccionRosario { iniciales, misterio, finales }`; `enum TipoMisterio { gozosos, dolorosos, gloriosos, luminosos }` con `String nombre` ("Gozosos") y `String singular` ("Gozoso"); fachada temporal `PrayerData` (se borra en la Task 11).
  - `lib/data/oraciones.dart`: `const Map<TipoMisterio, List<String>> misteriosPorTipo`; `const Map<int, TipoMisterio> misterioPorDia` (clave = `DateTime.weekday`); `const List<String> nombresDias` (índice = `weekday - 1`); `const List<Prayer> oracionesIniciales` (3), `oracionesPorMisterio` (7, el Ave María con `count: 10`), `oracionesFinales` (10).

- [ ] **Step 1: Escribir las pruebas**

`test/data/oraciones_test.dart`:

```dart
import 'package:app_resar_rosario/data/oraciones.dart';
import 'package:app_resar_rosario/models/prayer_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cada tipo de misterio tiene 5 misterios', () {
    for (final tipo in TipoMisterio.values) {
      expect(misteriosPorTipo[tipo], hasLength(5), reason: tipo.nombre);
    }
  });

  test('a cada día le toca su misterio', () {
    expect(misterioPorDia, {
      DateTime.monday: TipoMisterio.gozosos,
      DateTime.tuesday: TipoMisterio.dolorosos,
      DateTime.wednesday: TipoMisterio.gloriosos,
      DateTime.thursday: TipoMisterio.luminosos,
      DateTime.friday: TipoMisterio.dolorosos,
      DateTime.saturday: TipoMisterio.gozosos,
      DateTime.sunday: TipoMisterio.gloriosos,
    });
    expect(nombresDias, ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo']);
  });

  test('oraciones iniciales en orden', () {
    expect(oracionesIniciales.map((o) => o.type), ['inicio', 'contricion', 'invocacion']);
  });

  test('oraciones de cada misterio en orden, con 10 Ave Marías', () {
    expect(oracionesPorMisterio.map((o) => o.type), [
      'misterio',
      'padrenuestro',
      'avemaria',
      'gloria',
      'maria_madre',
      'sagrado_corazon',
      'oh_jesus',
    ]);
    expect(oracionesPorMisterio[2].count, 10);
  });

  test('oraciones finales en orden', () {
    expect(oracionesFinales.map((o) => o.type), [
      'letanias',
      'cordero',
      'oracion_final',
      'intenciones_papa',
      'avemaria_final',
      'gloria_final',
      'salve',
      'jaculatoria',
      'senal_final',
      'dulce_madre',
    ]);
  });

  test('las oraciones repetidas usan el mismo texto', () {
    expect(oracionesFinales[3].text, oracionesPorMisterio[1].text); // Padre Nuestro
    expect(oracionesFinales[4].text, oracionesPorMisterio[2].text); // Ave María
    expect(oracionesFinales[5].text, oracionesPorMisterio[3].text); // Gloria
    expect(oracionesFinales[8].text, oracionesIniciales[0].text); // Señal de la Cruz
    expect(oracionesIniciales[2].text, endsWith(oracionesPorMisterio[3].text)); // termina con el Gloria
  });

  test('erratas corregidas', () {
    final todo = [...oracionesIniciales, ...oracionesPorMisterio, ...oracionesFinales]
        .map((o) => '${o.title}\n${o.text}')
        .join('\n');
    expect(todo, contains('Sagrado Corazón de Jesús,\nen vos confío.'));
    expect(todo, contains('ampáranos, gran Señora'));
    expect(todo, contains('Por ser Tú quien eres'));
    expect(todo, isNot(contains('Santo.Amén')));
    expect(todo, isNot(contains('corazon')));
  });
}
```

- [ ] **Step 2: Correr y ver que falla**

Run: `flutter test test/data/oraciones_test.dart`
Expected: FAIL de compilación — `Target of URI doesn't exist: 'package:app_resar_rosario/data/oraciones.dart'`.

- [ ] **Step 3: Crear los datos**

`lib/data/oraciones.dart`:

```dart
import '../models/prayer_models.dart';

// Textos que se rezan en varias partes del rosario: se escriben una sola vez.
const String _senalDeLaCruz =
    'Por la señal de la Santa Cruz, de nuestros enemigos líbranos Señor Dios Nuestro. '
    'En el nombre del Padre, del Hijo y del Espíritu Santo. Amén.';

const String _padreNuestro =
    'Padre nuestro, que estás en el cielo, santificado sea tu Nombre; venga a nosotros tu reino; '
    'hágase tu voluntad en la tierra como en el cielo.\n'
    'Danos hoy nuestro pan de cada día; perdona nuestras ofensas como también nosotros perdonamos '
    'a los que nos ofenden; no nos dejes caer en la tentación y líbranos del mal. Amén.';

const String _aveMaria =
    'Dios te salve, María, llena eres de gracia; el Señor es contigo, bendita Tú eres entre todas '
    'las mujeres y bendito es el fruto de tu vientre, Jesús.\n'
    'Santa María, Madre de Dios, ruega por nosotros, pecadores, ahora y en la hora de nuestra muerte. Amén.';

const String _gloria =
    'Gloria al Padre y al Hijo y al Espíritu Santo.\n'
    'Como era en el principio, ahora y siempre, por los siglos de los siglos. Amén.';

const String _ruegaPorNosotros =
    'Ruega por nosotros, Santa Madre de Dios.\n'
    'Para que seamos dignos de alcanzar las promesas de Nuestro Señor Jesucristo. Amén.';

const String _letanias = 'Señor, ten piedad\n'
    'Cristo, ten piedad\n'
    'Señor, ten piedad\n'
    '\n'
    'Cristo, óyenos\n'
    'Cristo, escúchanos\n'
    '\n'
    'Dios, Padre celestial, ten misericordia de nosotros.\n'
    'Dios, Hijo, Redentor del mundo, ten misericordia de nosotros.\n'
    'Dios, Espíritu Santo, ten misericordia de nosotros.\n'
    'Santísima Trinidad, un solo Dios, ten misericordia de nosotros.\n'
    '\n'
    'Santa María, ruega por nosotros.\n'
    'Santa Madre de Dios, ruega por nosotros.\n'
    'Santa Virgen de las vírgenes, ruega por nosotros.\n'
    'Madre de Cristo, ruega por nosotros.\n'
    'Madre de la Iglesia, ruega por nosotros.\n'
    'Madre de la misericordia, ruega por nosotros.\n'
    'Madre de la divina gracia, ruega por nosotros.\n'
    'Madre de la esperanza, ruega por nosotros.\n'
    'Madre purísima, ruega por nosotros.\n'
    'Madre castísima, ruega por nosotros.\n'
    'Madre siempre virgen, ruega por nosotros.\n'
    'Madre inmaculada, ruega por nosotros.\n'
    'Madre amable, ruega por nosotros.\n'
    'Madre admirable, ruega por nosotros.\n'
    'Madre del buen consejo, ruega por nosotros.\n'
    'Madre del Creador, ruega por nosotros.\n'
    'Madre del Salvador, ruega por nosotros.\n'
    'Virgen prudentísima, ruega por nosotros.\n'
    'Virgen digna de veneración, ruega por nosotros.\n'
    'Virgen digna de alabanza, ruega por nosotros.\n'
    'Virgen poderosa, ruega por nosotros.\n'
    'Virgen clemente, ruega por nosotros.\n'
    'Virgen fiel, ruega por nosotros.\n'
    'Espejo de justicia, ruega por nosotros.\n'
    'Trono de la sabiduría, ruega por nosotros.\n'
    'Causa de nuestra alegría, ruega por nosotros.\n'
    'Vaso espiritual, ruega por nosotros.\n'
    'Vaso digno de honor, ruega por nosotros.\n'
    'Vaso de insigne devoción, ruega por nosotros.\n'
    'Rosa mística, ruega por nosotros.\n'
    'Torre de David, ruega por nosotros.\n'
    'Torre de marfil, ruega por nosotros.\n'
    'Casa de oro, ruega por nosotros.\n'
    'Arca de la Alianza, ruega por nosotros.\n'
    'Puerta del cielo, ruega por nosotros.\n'
    'Estrella de la mañana, ruega por nosotros.\n'
    'Salud de los enfermos, ruega por nosotros.\n'
    'Refugio de los pecadores, ruega por nosotros.\n'
    'Consuelo de los migrantes, ruega por nosotros.\n'
    'Consoladora de los afligidos, ruega por nosotros.\n'
    'Auxilio de los cristianos, ruega por nosotros.\n'
    'Reina de los Ángeles, ruega por nosotros.\n'
    'Reina de los Patriarcas, ruega por nosotros.\n'
    'Reina de los Profetas, ruega por nosotros.\n'
    'Reina de los Apóstoles, ruega por nosotros.\n'
    'Reina de los Mártires, ruega por nosotros.\n'
    'Reina de los Confesores, ruega por nosotros.\n'
    'Reina de las Vírgenes, ruega por nosotros.\n'
    'Reina de todos los Santos, ruega por nosotros.\n'
    'Reina concebida sin pecado original, ruega por nosotros.\n'
    'Reina asunta a los Cielos, ruega por nosotros.\n'
    'Reina del Santísimo Rosario, ruega por nosotros.\n'
    'Reina de la familia, ruega por nosotros.\n'
    'Reina de la paz, ruega por nosotros.';

/// Los cinco misterios de cada tipo, en orden.
const Map<TipoMisterio, List<String>> misteriosPorTipo = {
  TipoMisterio.gozosos: [
    'La Encarnación del Hijo de Dios',
    'La Visitación de Nuestra Señora a su prima santa Isabel',
    'El Nacimiento del Hijo de Dios',
    'La Presentación de Jesús en el templo',
    'El Niño Jesús perdido y hallado en el templo',
  ],
  TipoMisterio.dolorosos: [
    'La Oración de Jesús en el huerto',
    'La Flagelación del Señor',
    'La Coronación de espinas',
    'Jesús con la Cruz a cuestas, camino del Calvario',
    'La Crucifixión y Muerte de nuestro Señor',
  ],
  TipoMisterio.gloriosos: [
    'La Resurrección del Hijo de Dios',
    'La Ascensión del Señor a los Cielos',
    'La Venida del Espíritu Santo sobre los Apóstoles',
    'La Asunción de nuestra Señora a los Cielos',
    'La Coronación de la Santísima Virgen como Reina de Cielos y Tierra',
  ],
  TipoMisterio.luminosos: [
    'El Bautismo de Jesús en el Jordán',
    'La autorrevelación de Jesús en las bodas de Caná',
    'El anuncio del Reino de Dios invitando a la conversión',
    'La Transfiguración',
    'La Institución de la Eucaristía',
  ],
};

/// Misterio que se reza cada día. La clave es `DateTime.weekday` (1 = lunes … 7 = domingo).
const Map<int, TipoMisterio> misterioPorDia = {
  DateTime.monday: TipoMisterio.gozosos,
  DateTime.tuesday: TipoMisterio.dolorosos,
  DateTime.wednesday: TipoMisterio.gloriosos,
  DateTime.thursday: TipoMisterio.luminosos,
  DateTime.friday: TipoMisterio.dolorosos,
  DateTime.saturday: TipoMisterio.gozosos,
  DateTime.sunday: TipoMisterio.gloriosos,
};

/// Nombre de cada día. El índice es `DateTime.weekday - 1`.
const List<String> nombresDias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];

const List<Prayer> oracionesIniciales = [
  Prayer(type: 'inicio', title: 'Señal de la Cruz', text: _senalDeLaCruz),
  Prayer(
    type: 'contricion',
    title: 'Acto de contrición',
    text: 'Señor mío Jesucristo, Dios y hombre verdadero, Creador, Padre y Redentor mío. Por ser Tú quien '
        'eres, Bondad infinita, y porque te amo sobre todas las cosas, me pesa de todo corazón haberte '
        'ofendido. También me pesa que puedes castigarme con las penas del infierno. Ayudado de tu divina '
        'gracia propongo firmemente nunca más pecar, confesarme y cumplir la penitencia que me fuere '
        'impuesta. Amén.',
  ),
  Prayer(
    type: 'invocacion',
    title: 'Invocaciones',
    text: 'Señor, ábreme los labios.\nY mi boca proclamará tu alabanza.\n\n'
        'Dios mío, ven en mi auxilio.\nSeñor, date prisa en socorrerme.\n\n$_gloria',
  ),
];

/// Oraciones de cada misterio. La primera es el anuncio; el Ave María se reza 10 veces.
const List<Prayer> oracionesPorMisterio = [
  Prayer(type: 'misterio', title: 'Misterio', text: ''),
  Prayer(type: 'padrenuestro', title: 'Padre Nuestro', text: _padreNuestro),
  Prayer(type: 'avemaria', title: 'Ave María', text: _aveMaria, count: 10),
  Prayer(type: 'gloria', title: 'Gloria', text: _gloria),
  Prayer(
    type: 'maria_madre',
    title: 'María, Madre de gracia',
    text: 'María, Madre de gracia, Madre de misericordia.\nEn la vida y en la muerte ampáranos, gran Señora.',
  ),
  Prayer(type: 'sagrado_corazon', title: 'Sagrado Corazón', text: 'Sagrado Corazón de Jesús,\nen vos confío.'),
  Prayer(
    type: 'oh_jesus',
    title: 'Oh, Jesús mío',
    text: 'Oh Jesús mío, perdónanos. Líbranos del fuego del infierno, lleva a todas las almas al cielo, '
        'especialmente a las más necesitadas.',
  ),
];

const List<Prayer> oracionesFinales = [
  Prayer(type: 'letanias', title: 'Letanías de la Santísima Virgen', text: _letanias),
  Prayer(
    type: 'cordero',
    title: 'Cordero de Dios',
    text: 'Cordero de Dios, que quitas el pecado del mundo.\nPerdónanos, Señor.\n'
        'Cordero de Dios, que quitas el pecado del mundo.\nEscúchanos, Señor.\n'
        'Cordero de Dios, que quitas el pecado del mundo.\nTen piedad de nosotros.\n\n$_ruegaPorNosotros',
  ),
  Prayer(
    type: 'oracion_final',
    title: 'Oración',
    text: 'Te pedimos, Señor, nos concedas a nosotros tus siervos, gozar de perpetua salud de alma y '
        'cuerpo, y por la gloriosa intercesión de la bienaventurada siempre Virgen María, seamos librados '
        'de las tristezas presentes y gocemos de la eterna alegría. Por Jesucristo, nuestro Señor. Amén.',
  ),
  Prayer(type: 'intenciones_papa', title: 'Por las intenciones del Santo Padre', text: _padreNuestro),
  Prayer(type: 'avemaria_final', title: 'Ave María', text: _aveMaria),
  Prayer(type: 'gloria_final', title: 'Gloria', text: _gloria),
  Prayer(
    type: 'salve',
    title: 'Una Salve a la Virgen',
    text: 'Dios te salve, Reina y Madre de misericordia, vida, dulzura y esperanza nuestra; Dios te salve. '
        'A Ti llamamos los desterrados hijos de Eva; a Ti suspiramos, gimiendo y llorando, en este valle de '
        'lágrimas. Ea, pues, Señora, abogada nuestra, vuelve a nosotros esos tus ojos misericordiosos; y '
        'después de este destierro muéstranos a Jesús, fruto bendito de tu vientre. ¡Oh clementísima, oh '
        'piadosa, oh dulce Virgen María!\n\n$_ruegaPorNosotros',
  ),
  Prayer(type: 'jaculatoria', title: 'Jaculatoria final', text: 'Ave María Purísima.\nSin pecado concebida.'),
  Prayer(type: 'senal_final', title: 'Señal de la Cruz', text: _senalDeLaCruz),
  Prayer(
    type: 'dulce_madre',
    title: 'Dulce Madre',
    text: 'Dulce Madre, no te alejes, tu vista de mí no apartes, ven conmigo a todas partes y solo/a nunca '
        'me dejes. Ya que proteges tanto como verdadera madre, haz que me bendiga.\n'
        'El Padre, el Hijo y el Espíritu Santo. Amén.',
  ),
];
```

- [ ] **Step 4: Reescribir los modelos (con fachada temporal para las pantallas viejas)**

`lib/models/prayer_models.dart`:

```dart
import '../data/oraciones.dart';

/// Una oración del rosario.
class Prayer {
  const Prayer({required this.type, required this.title, required this.text, this.count});

  final String type;
  final String title;
  final String text;

  /// Veces seguidas que se reza (solo el Ave María de cada misterio: 10).
  final int? count;
}

/// Las tres partes del rosario.
enum SeccionRosario { iniciales, misterio, finales }

/// Tipos de misterios.
enum TipoMisterio {
  gozosos('Gozosos', 'Gozoso'),
  dolorosos('Dolorosos', 'Doloroso'),
  gloriosos('Gloriosos', 'Glorioso'),
  luminosos('Luminosos', 'Luminoso');

  const TipoMisterio(this.nombre, this.singular);

  final String nombre;
  final String singular;
}

/// Compatibilidad temporal con las pantallas antiguas. Se elimina en la Task 11.
class PrayerData {
  static final Map<String, String> mysteries = {
    for (var dia = DateTime.monday; dia <= DateTime.sunday; dia++) nombresDias[dia - 1]: misterioPorDia[dia]!.nombre,
  };
  static final Map<String, List<String>> mysteryData = {
    for (final tipo in TipoMisterio.values) tipo.nombre: misteriosPorTipo[tipo]!,
  };
  static const List<Prayer> initialPrayers = oracionesIniciales;
  static const List<Prayer> mysteryPrayers = oracionesPorMisterio;
  static const List<Prayer> finalPrayers = oracionesFinales;
}
```

- [ ] **Step 5: Borrar la prueba vieja y correr todo**

Run: `git rm -q test/models/prayer_models_test.dart && flutter test`
Expected: `All tests passed!` (incluye `oraciones_test.dart`; la app vieja sigue funcionando gracias a `PrayerData`).

- [ ] **Step 6: Commit**

Run: `flutter analyze` → sin errores ni advertencias.

```bash
git add lib/data lib/models/prayer_models.dart test
git commit -m "refactor: oraciones escritas una sola vez" -m "Padre Nuestro, Ave María, Gloria, Señal de la Cruz y 'Ruega por nosotros' dejan de repetirse. Corrige erratas (Sagrado Corazón, ampáranos, 'quien eres'). Agrega SeccionRosario y TipoMisterio." -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 8: El recorrido del rosario como lista de 93 pasos (`RosarioSession`)

**Files:**
- Create: `lib/logic/rosario_session.dart`
- Create: `test/logic/rosario_session_test.dart`

**Interfaces:**
- Consumes: `Prayer`, `SeccionRosario`, `TipoMisterio` (Task 7); `oracionesIniciales`, `oracionesPorMisterio`, `oracionesFinales`, `misteriosPorTipo`, `misterioPorDia`, `nombresDias` (Task 7).
- Produces:
  - `const int misteriosPorRosario = 5;`
  - `class PasoRosario` (inmutable): `SeccionRosario seccion`, `Prayer oracion`, `int indiceEnSeccion`, `int totalEnSeccion`, `int? misterio` (0–4), `int? repeticion` (0–9, solo Ave María), `bool get esAnuncioDeMisterio`.
  - `List<PasoRosario> construirPasos({List<Prayer> iniciales, List<Prayer> porMisterio, List<Prayer> finales, int misterios})`.
  - `TipoMisterio misterioDelDia(DateTime fecha)`, `String nombreDelDia(DateTime fecha)`.
  - `class RosarioSession extends ChangeNotifier`: constructor `RosarioSession({DateTime Function()? reloj, List<PasoRosario>? pasos})`; getters `List<PasoRosario> pasos`, `DateTime hoy`, `bool enInicio`, `int indice` (-1 en inicio), `bool esUltimo`, `double progreso`, `TipoMisterio tipoMisterio`, `PasoRosario pasoActual` (lanza `StateError` en inicio), `String tituloMisterioActual`; métodos `comenzar()`, `siguiente()`, `anterior()`, `reiniciar()`.

- [ ] **Step 1: Escribir las pruebas**

`test/logic/rosario_session_test.dart`:

```dart
import 'package:app_resar_rosario/logic/rosario_session.dart';
import 'package:app_resar_rosario/models/prayer_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('construirPasos', () {
    final pasos = construirPasos();

    test('el rosario completo tiene 93 pasos', () {
      expect(pasos, hasLength(93));
    });

    test('empieza con las 3 oraciones iniciales', () {
      expect(pasos.take(3).map((p) => p.seccion), everyElement(SeccionRosario.iniciales));
      expect(pasos.first.oracion.type, 'inicio');
      expect(pasos[2].indiceEnSeccion, 2);
      expect(pasos[2].totalEnSeccion, 3);
    });

    test('cada misterio tiene 16 pasos: anuncio, Padre Nuestro, 10 Ave Marías y 4 oraciones', () {
      for (var m = 0; m < misteriosPorRosario; m++) {
        final delMisterio = pasos.where((p) => p.misterio == m).toList();
        expect(delMisterio, hasLength(16), reason: 'misterio $m');
        expect(delMisterio.first.esAnuncioDeMisterio, isTrue);
        final aves = delMisterio.where((p) => p.oracion.type == 'avemaria');
        expect(aves.map((p) => p.repeticion), [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]);
      }
    });

    test('termina con las 10 oraciones finales', () {
      final finales = pasos.skip(83).toList();
      expect(finales, hasLength(10));
      expect(finales.map((p) => p.seccion), everyElement(SeccionRosario.finales));
      expect(finales.last.oracion.type, 'dulce_madre');
    });
  });

  test('misterio y nombre de cada día', () {
    expect(misterioDelDia(DateTime(2026, 11, 9)), TipoMisterio.gozosos); // lunes
    expect(misterioDelDia(DateTime(2026, 11, 10)), TipoMisterio.dolorosos);
    expect(misterioDelDia(DateTime(2026, 11, 11)), TipoMisterio.gloriosos);
    expect(misterioDelDia(DateTime(2026, 11, 12)), TipoMisterio.luminosos);
    expect(misterioDelDia(DateTime(2026, 11, 13)), TipoMisterio.dolorosos);
    expect(misterioDelDia(DateTime(2026, 11, 14)), TipoMisterio.gozosos);
    expect(misterioDelDia(DateTime(2026, 11, 15)), TipoMisterio.gloriosos);
    expect(nombreDelDia(DateTime(2026, 11, 9)), 'Lunes');
    expect(nombreDelDia(DateTime(2026, 11, 15)), 'Domingo');
  });

  group('RosarioSession', () {
    late DateTime ahora;
    RosarioSession nueva() => RosarioSession(reloj: () => ahora);

    setUp(() => ahora = DateTime(2026, 11, 9, 8)); // lunes

    test('empieza en la pantalla de inicio', () {
      final s = nueva();
      expect(s.enInicio, isTrue);
      expect(s.indice, -1);
      expect(s.progreso, 0);
      expect(() => s.pasoActual, throwsStateError);
    });

    test('comenzar lleva al primer paso', () {
      final s = nueva()..comenzar();
      expect(s.enInicio, isFalse);
      expect(s.pasoActual.oracion.type, 'inicio');
    });

    test('siguiente avanza y anterior retrocede', () {
      final s = nueva()..comenzar();
      s.siguiente();
      expect(s.pasoActual.oracion.type, 'contricion');
      s.anterior();
      expect(s.pasoActual.oracion.type, 'inicio');
    });

    test('anterior desde el primer paso vuelve al inicio', () {
      final s = nueva()..comenzar();
      s.anterior();
      expect(s.enInicio, isTrue);
    });

    test('desde el Gloria, anterior vuelve a la décima Ave María', () {
      final s = nueva()..comenzar();
      while (s.pasoActual.oracion.type != 'gloria') {
        s.siguiente();
      }
      s.anterior();
      expect(s.pasoActual.oracion.type, 'avemaria');
      expect(s.pasoActual.repeticion, 9);
    });

    test('el último paso marca 100 % y al seguir vuelve al inicio', () {
      final s = nueva()..comenzar();
      for (var i = 0; i < 92; i++) {
        s.siguiente();
      }
      expect(s.esUltimo, isTrue);
      expect(s.progreso, 1.0);
      s.siguiente();
      expect(s.enInicio, isTrue);
    });

    test('el misterio se fija al comenzar aunque cambie el día', () {
      final s = nueva()..comenzar();
      ahora = DateTime(2026, 11, 10, 0, 1); // ya es martes
      expect(s.tipoMisterio, TipoMisterio.gozosos);
      s.reiniciar();
      expect(s.tipoMisterio, TipoMisterio.dolorosos);
    });

    test('título del misterio actual', () {
      final s = nueva()..comenzar();
      for (var i = 0; i < 3; i++) {
        s.siguiente();
      }
      expect(s.pasoActual.esAnuncioDeMisterio, isTrue);
      expect(s.tituloMisterioActual, 'La Encarnación del Hijo de Dios');
    });

    test('avisa a quien escucha', () {
      final s = nueva();
      var avisos = 0;
      s.addListener(() => avisos++);
      s
        ..comenzar()
        ..siguiente()
        ..anterior()
        ..reiniciar();
      expect(avisos, 4);
    });
  });
}
```

- [ ] **Step 2: Correr y ver que falla**

Run: `flutter test test/logic/rosario_session_test.dart`
Expected: FAIL de compilación — `Target of URI doesn't exist: 'package:app_resar_rosario/logic/rosario_session.dart'`.

- [ ] **Step 3: Implementar**

`lib/logic/rosario_session.dart`:

```dart
import 'package:flutter/foundation.dart';

import '../data/oraciones.dart';
import '../models/prayer_models.dart';

/// Misterios que se rezan en cada rosario.
const int misteriosPorRosario = 5;

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
  });

  final SeccionRosario seccion;
  final Prayer oracion;

  /// Posición de la oración en su lista (iniciales, finales o las de cada misterio).
  final int indiceEnSeccion;
  final int totalEnSeccion;

  /// Misterio actual (0 a 4). Solo en la sección de misterios.
  final int? misterio;

  /// Repetición actual (0 a 9). Solo durante las diez Ave Marías.
  final int? repeticion;

  bool get esAnuncioDeMisterio => oracion.type == 'misterio';
}

/// Arma la lista completa de pasos del rosario.
List<PasoRosario> construirPasos({
  List<Prayer> iniciales = oracionesIniciales,
  List<Prayer> porMisterio = oracionesPorMisterio,
  List<Prayer> finales = oracionesFinales,
  int misterios = misteriosPorRosario,
}) {
  final pasos = <PasoRosario>[
    for (var i = 0; i < iniciales.length; i++)
      PasoRosario(
        seccion: SeccionRosario.iniciales,
        oracion: iniciales[i],
        indiceEnSeccion: i,
        totalEnSeccion: iniciales.length,
      ),
  ];
  for (var m = 0; m < misterios; m++) {
    for (var i = 0; i < porMisterio.length; i++) {
      final oracion = porMisterio[i];
      final veces = oracion.count ?? 1;
      for (var r = 0; r < veces; r++) {
        pasos.add(PasoRosario(
          seccion: SeccionRosario.misterio,
          oracion: oracion,
          indiceEnSeccion: i,
          totalEnSeccion: porMisterio.length,
          misterio: m,
          repeticion: oracion.count == null ? null : r,
        ));
      }
    }
  }
  pasos.addAll([
    for (var i = 0; i < finales.length; i++)
      PasoRosario(
        seccion: SeccionRosario.finales,
        oracion: finales[i],
        indiceEnSeccion: i,
        totalEnSeccion: finales.length,
      ),
  ]);
  return List.unmodifiable(pasos);
}

TipoMisterio misterioDelDia(DateTime fecha) => misterioPorDia[fecha.weekday]!;

String nombreDelDia(DateTime fecha) => nombresDias[fecha.weekday - 1];

/// Estado del rezo: en qué paso va la persona.
class RosarioSession extends ChangeNotifier {
  RosarioSession({DateTime Function()? reloj, List<PasoRosario>? pasos})
      : _reloj = reloj ?? DateTime.now,
        pasos = pasos ?? construirPasos();

  final DateTime Function() _reloj;
  final List<PasoRosario> pasos;

  int _indice = -1;
  TipoMisterio? _tipoFijado;

  DateTime get hoy => _reloj();
  bool get enInicio => _indice < 0;
  int get indice => _indice;
  bool get esUltimo => _indice == pasos.length - 1;
  double get progreso => enInicio ? 0 : (_indice + 1) / pasos.length;

  /// El misterio de hoy. Mientras se reza no cambia, aunque pase la medianoche.
  TipoMisterio get tipoMisterio => _tipoFijado ?? misterioDelDia(_reloj());

  PasoRosario get pasoActual {
    if (enInicio) throw StateError('El rosario no ha comenzado.');
    return pasos[_indice];
  }

  String get tituloMisterioActual {
    final misterio = pasoActual.misterio;
    if (misterio == null) throw StateError('El paso actual no es de un misterio.');
    return misteriosPorTipo[tipoMisterio]![misterio];
  }

  void comenzar() {
    _tipoFijado = misterioDelDia(_reloj());
    _indice = 0;
    notifyListeners();
  }

  void siguiente() {
    if (enInicio) {
      comenzar();
      return;
    }
    if (esUltimo) {
      reiniciar();
      return;
    }
    _indice++;
    notifyListeners();
  }

  void anterior() {
    if (enInicio) return;
    if (_indice == 0) {
      reiniciar();
      return;
    }
    _indice--;
    notifyListeners();
  }

  void reiniciar() {
    _indice = -1;
    _tipoFijado = null;
    notifyListeners();
  }
}
```

- [ ] **Step 4: Correr y ver que pasa**

Run: `flutter test test/logic/rosario_session_test.dart`
Expected: `All tests passed!`

- [ ] **Step 5: Commit**

Run: `flutter analyze` → sin errores ni advertencias.

```bash
git add lib/logic test/logic
git commit -m "feat: recorrido del rosario como lista fija de pasos" -m "RosarioSession reemplaza los switch con textos de resar_rosario_app.dart. El misterio del día queda fijo mientras se reza." -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 9: Tema base sin escalado doble y con botones grandes desde el tema (E4)

**Files:**
- Create: `lib/theme/app_tokens.dart`
- Create: `lib/theme/seccion_colores.dart`
- Create: `lib/theme/app_theme.dart`
- Delete: `lib/constants/app_theme.dart`
- Modify: `lib/main.dart` (temas y `builder`)
- Create: `test/theme/app_theme_test.dart`

**Interfaces:**
- Consumes: `SeccionRosario` (Task 7).
- Produces:
  - `abstract final class AppTokens` con `espacioXS=4, espacioS=8, espacioM=16, espacioL=24, espacioXL=32`, `radioS=12, radioM=16, radioL=24`, `botonNormal=48, botonGrande=64`, `anchoMaximo=600`.
  - `class SeccionColores` con `List<Color> fondo`, `Color boton`, `Color sobreBoton`, `Color suave`, `Color acento`, `Color? borde`; `static SeccionColores lerp(a, b, t)`.
  - `class SeccionesTema extends ThemeExtension<SeccionesTema>` con `iniciales`, `misterio`, `finales` (`SeccionColores`), `List<Color> fondoInicio`, `Color tituloInicio`, `Color cuenta`, `Color bordeCuenta`; `static const SeccionesTema claro`; `SeccionColores de(SeccionRosario)`.
  - `extension SeccionesDelContexto on BuildContext { SeccionesTema get secciones; SeccionColores coloresDe(SeccionRosario) }`.
  - `abstract final class AppTheme { static ThemeData claro({bool altoContraste = false, bool botonesGrandes = false}); static ThemeData oscuro({...}); static TextStyle oracion(BuildContext) }`.
  - Regla de color: **`acento`** es el color del texto de acento sobre la tarjeta y sobre `suave`; **`sobreBoton`** sobre `boton`.

- [ ] **Step 1: Escribir las pruebas**

`test/theme/app_theme_test.dart`:

```dart
import 'package:app_resar_rosario/models/prayer_models.dart';
import 'package:app_resar_rosario/theme/app_theme.dart';
import 'package:app_resar_rosario/theme/seccion_colores.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double altoMinimo(ButtonStyle? estilo) => estilo!.minimumSize!.resolve(<WidgetState>{})!.height;

void main() {
  test('botones de 48 de alto por defecto', () {
    final tema = AppTheme.claro();
    expect(altoMinimo(tema.filledButtonTheme.style), 48);
    expect(altoMinimo(tema.outlinedButtonTheme.style), 48);
  });

  test('botones grandes de 64 de alto', () {
    final tema = AppTheme.oscuro(botonesGrandes: true);
    expect(altoMinimo(tema.filledButtonTheme.style), 64);
    expect(altoMinimo(tema.outlinedButtonTheme.style), 64);
  });

  test('claro y oscuro', () {
    expect(AppTheme.claro().brightness, Brightness.light);
    expect(AppTheme.oscuro().brightness, Brightness.dark);
  });

  test('alto contraste cambia los colores del esquema', () {
    expect(AppTheme.claro(altoContraste: true).colorScheme.primary, isNot(AppTheme.claro().colorScheme.primary));
  });

  test('el tema no escala el texto: el tamaño se aplica una sola vez en la app (E4)', () {
    expect(AppTheme.claro().textTheme.bodyLarge!.fontSize, 16);
  });

  test('incluye los colores de cada sección', () {
    final secciones = AppTheme.claro().extension<SeccionesTema>()!;
    expect(secciones.de(SeccionRosario.misterio), same(secciones.misterio));
  });
}
```

- [ ] **Step 2: Correr y ver que falla**

Run: `flutter test test/theme/app_theme_test.dart`
Expected: FAIL de compilación — `Target of URI doesn't exist: 'package:app_resar_rosario/theme/app_theme.dart'`.

- [ ] **Step 3: Crear las medidas**

`lib/theme/app_tokens.dart`:

```dart
/// Medidas compartidas de la interfaz. Los colores viven en `app_theme.dart` y `seccion_colores.dart`.
abstract final class AppTokens {
  static const double espacioXS = 4;
  static const double espacioS = 8;
  static const double espacioM = 16;
  static const double espacioL = 24;
  static const double espacioXL = 32;

  static const double radioS = 12;
  static const double radioM = 16;
  static const double radioL = 24;

  /// Altura mínima de los botones.
  static const double botonNormal = 48;
  static const double botonGrande = 64;

  /// Ancho máximo del contenido (tabletas).
  static const double anchoMaximo = 600;
}
```

- [ ] **Step 4: Crear los colores de sección**

`lib/theme/seccion_colores.dart`:

```dart
import 'package:flutter/material.dart';

import '../models/prayer_models.dart';

/// Colores de una sección del rosario.
@immutable
class SeccionColores {
  const SeccionColores({
    required this.fondo,
    required this.boton,
    required this.sobreBoton,
    required this.suave,
    required this.acento,
    this.borde,
  });

  /// Degradado detrás de la tarjeta de la oración.
  final List<Color> fondo;

  /// Fondo del botón principal.
  final Color boton;

  /// Texto e íconos sobre [boton].
  final Color sobreBoton;

  /// Fondo de los recuadros de encabezado.
  final Color suave;

  /// Texto de acento sobre la tarjeta o sobre [suave].
  final Color acento;

  /// Borde de los recuadros (solo en alto contraste).
  final Color? borde;

  static SeccionColores lerp(SeccionColores a, SeccionColores b, double t) => SeccionColores(
        fondo: [for (var i = 0; i < a.fondo.length; i++) Color.lerp(a.fondo[i], b.fondo[i], t)!],
        boton: Color.lerp(a.boton, b.boton, t)!,
        sobreBoton: Color.lerp(a.sobreBoton, b.sobreBoton, t)!,
        suave: Color.lerp(a.suave, b.suave, t)!,
        acento: Color.lerp(a.acento, b.acento, t)!,
        borde: Color.lerp(a.borde, b.borde, t),
      );
}

/// Colores propios de la app que cambian con el tema.
@immutable
class SeccionesTema extends ThemeExtension<SeccionesTema> {
  const SeccionesTema({
    required this.iniciales,
    required this.misterio,
    required this.finales,
    required this.fondoInicio,
    required this.tituloInicio,
    required this.cuenta,
    required this.bordeCuenta,
  });

  final SeccionColores iniciales;
  final SeccionColores misterio;
  final SeccionColores finales;

  /// Degradado de la pantalla de inicio.
  final List<Color> fondoInicio;

  /// Título y textos sobre [fondoInicio].
  final Color tituloInicio;

  /// Relleno y borde de las cuentas del rosario ya rezadas.
  final Color cuenta;
  final Color bordeCuenta;

  /// Estilo actual de la app: azul (iniciales), morado (misterios), verde (finales).
  static const claro = SeccionesTema(
    iniciales: SeccionColores(
      fondo: [Color(0xFF1E40AF), Color(0xFF2563EB)],
      boton: Color(0xFF2563EB),
      sobreBoton: Color(0xFFFFFFFF),
      suave: Color(0xFFE3F2FD),
      acento: Color(0xFF1E40AF),
    ),
    misterio: SeccionColores(
      fondo: [Color(0xFF6B21A8), Color(0xFF9333EA)],
      boton: Color(0xFF9333EA),
      sobreBoton: Color(0xFFFFFFFF),
      suave: Color(0xFFF3E5F5),
      acento: Color(0xFF6B21A8),
    ),
    finales: SeccionColores(
      fondo: [Color(0xFF166534), Color(0xFF16A34A)],
      // Un tono más oscuro que el original para que el texto blanco cumpla contraste AA.
      boton: Color(0xFF15803D),
      sobreBoton: Color(0xFFFFFFFF),
      suave: Color(0xFFE8F5E9),
      acento: Color(0xFF166534),
    ),
    fondoInicio: [Color(0xFFE0F2FE), Color(0xFFBAE6FD), Color(0xFF7DD3FC)],
    tituloInicio: Color(0xFF1E3A8A),
    cuenta: Color(0xFFFBBF24),
    bordeCuenta: Color(0xFFB45309),
  );

  SeccionColores de(SeccionRosario seccion) => switch (seccion) {
        SeccionRosario.iniciales => iniciales,
        SeccionRosario.misterio => misterio,
        SeccionRosario.finales => finales,
      };

  @override
  SeccionesTema copyWith({
    SeccionColores? iniciales,
    SeccionColores? misterio,
    SeccionColores? finales,
    List<Color>? fondoInicio,
    Color? tituloInicio,
    Color? cuenta,
    Color? bordeCuenta,
  }) {
    return SeccionesTema(
      iniciales: iniciales ?? this.iniciales,
      misterio: misterio ?? this.misterio,
      finales: finales ?? this.finales,
      fondoInicio: fondoInicio ?? this.fondoInicio,
      tituloInicio: tituloInicio ?? this.tituloInicio,
      cuenta: cuenta ?? this.cuenta,
      bordeCuenta: bordeCuenta ?? this.bordeCuenta,
    );
  }

  @override
  SeccionesTema lerp(covariant SeccionesTema? other, double t) {
    if (other == null) return this;
    return SeccionesTema(
      iniciales: SeccionColores.lerp(iniciales, other.iniciales, t),
      misterio: SeccionColores.lerp(misterio, other.misterio, t),
      finales: SeccionColores.lerp(finales, other.finales, t),
      fondoInicio: [
        for (var i = 0; i < fondoInicio.length; i++) Color.lerp(fondoInicio[i], other.fondoInicio[i], t)!,
      ],
      tituloInicio: Color.lerp(tituloInicio, other.tituloInicio, t)!,
      cuenta: Color.lerp(cuenta, other.cuenta, t)!,
      bordeCuenta: Color.lerp(bordeCuenta, other.bordeCuenta, t)!,
    );
  }
}

extension SeccionesDelContexto on BuildContext {
  SeccionesTema get secciones => Theme.of(this).extension<SeccionesTema>() ?? SeccionesTema.claro;

  SeccionColores coloresDe(SeccionRosario seccion) => secciones.de(seccion);
}
```

- [ ] **Step 5: Crear el tema**

`lib/theme/app_theme.dart`:

```dart
import 'package:flutter/material.dart';

import 'app_tokens.dart';
import 'seccion_colores.dart';

/// Temas de la app. El tamaño de letra NO se escala aquí: lo hace `MaterialApp.builder`.
abstract final class AppTheme {
  static const Color semilla = Color(0xFF1E3A8A);

  static ThemeData claro({bool altoContraste = false, bool botonesGrandes = false}) =>
      _crear(Brightness.light, altoContraste: altoContraste, botonesGrandes: botonesGrandes);

  static ThemeData oscuro({bool altoContraste = false, bool botonesGrandes = false}) =>
      _crear(Brightness.dark, altoContraste: altoContraste, botonesGrandes: botonesGrandes);

  /// Estilo del texto de las oraciones.
  static TextStyle oracion(BuildContext context) =>
      Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 18, height: 1.6);

  static ThemeData _crear(Brightness brillo, {required bool altoContraste, required bool botonesGrandes}) {
    final esquema = ColorScheme.fromSeed(
      seedColor: semilla,
      brightness: brillo,
      contrastLevel: altoContraste ? 1.0 : 0.0,
    );
    final alto = botonesGrandes ? AppTokens.botonGrande : AppTokens.botonNormal;
    final forma = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radioM));
    const textoBoton = TextStyle(fontSize: 18, fontWeight: FontWeight.w600);
    final base = ThemeData(colorScheme: esquema);

    return base.copyWith(
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: Size(64, alto), shape: forma, textStyle: textoBoton),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(minimumSize: Size(64, alto), shape: forma, textStyle: textoBoton),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(minimumSize: Size(64, alto), shape: forma),
      ),
      cardTheme: CardThemeData(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radioL),
          side: altoContraste ? BorderSide(color: esquema.onSurface, width: 2) : BorderSide.none,
        ),
      ),
      extensions: const <ThemeExtension<dynamic>>[SeccionesTema.claro],
    );
  }
}
```

- [ ] **Step 6: Correr y ver que pasa**

Run: `flutter test test/theme/app_theme_test.dart`
Expected: `All tests passed!`

- [ ] **Step 7: Usar el tema nuevo en `lib/main.dart` y borrar el viejo**

Reemplazar el import `import 'constants/app_theme.dart';` por `import 'theme/app_theme.dart';` y, dentro de `MaterialApp`, estas líneas:

```dart
// ANTES
      theme: AppTheme.lightTheme(preferencias.textScaleFactor),
      darkTheme: AppTheme.darkTheme(preferencias.textScaleFactor),
// DESPUÉS
      theme: AppTheme.claro(
        altoContraste: preferencias.useHighContrast,
        botonesGrandes: preferencias.useLargeButtons,
      ),
      darkTheme: AppTheme.oscuro(
        altoContraste: preferencias.useHighContrast,
        botonesGrandes: preferencias.useLargeButtons,
      ),
```

```dart
// ANTES
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(preferencias.textScaleFactor),
          highContrast: preferencias.useHighContrast,
        ),
// DESPUÉS
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(preferencias.textScaleFactor),
        ),
```

Run: `git rm -q lib/constants/app_theme.dart && grep -rn "constants/app_theme" lib test`
Expected: sin coincidencias.

- [ ] **Step 8: Verificar y hacer commit**

Run: `flutter analyze && flutter test`
Expected: sin errores ni advertencias; `All tests passed!`

```bash
git add lib/theme lib/main.dart test/theme
git commit -m "feat: tema base con colores por sección y botones grandes desde el tema" -m "El tema ya no multiplica el tamaño de letra (E4). SeccionesTema concentra los colores de cada sección." -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 10: Menú lateral único y diálogo de misterios del día

**Files:**
- Create: `lib/widgets/app_drawer.dart`
- Rewrite: `lib/widgets/misterios_del_dia_modal.dart`
- Delete: `lib/widgets/main_menu_drawer.dart`
- Modify: `lib/screens/inicio_screen.dart` (solo la línea del `drawer` y su import)
- Modify: `lib/main.dart` (proveedor de `RosarioSession`)
- Rewrite: `test/support/app_harness.dart`
- Create: `test/widgets/app_drawer_test.dart`

**Interfaces:**
- Consumes: `RosarioSession`, `nombreDelDia` (Task 8); `misteriosPorTipo`, `TipoMisterio` (Task 7); `context.secciones`, `AppTokens`, `AppTheme` (Task 9); `PreferencesService` (Task 6); `AgendarRosarioScreen({required PreferencesService preferences})` (pantalla existente).
- Produces:
  - `class AppDrawer extends StatelessWidget` (`const AppDrawer()`), lee `RosarioSession` del contexto. Opciones: "Misterios del día" (subtítulo `"<Tipo> · <Día>"`), "Agendar Rosario". La Task 15 agrega "Configuración" y "Acerca de".
  - `class MisteriosDelDiaDialog extends StatelessWidget` (`const MisteriosDelDiaDialog({required TipoMisterio tipo, required String dia})`), botón "Entendido".
  - Harness: `final DateTime lunes` (2026-11-09 8:00) y `Widget envolver(Widget hijo, {required PreferencesService preferencias, RosarioSession? sesion, NotificationService? notificaciones, ThemeData? tema})`.

- [ ] **Step 1: Ampliar el soporte de pruebas**

`test/support/app_harness.dart` (reemplazo completo):

```dart
import 'package:app_resar_rosario/logic/rosario_session.dart';
import 'package:app_resar_rosario/services/notification_service.dart';
import 'package:app_resar_rosario/services/preferences_service.dart';
import 'package:app_resar_rosario/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lunes 9 de noviembre de 2026, 8:00: tocan los misterios Gozosos.
final DateTime lunes = DateTime(2026, 11, 9, 8);

/// Preferencias de prueba, vacías o con [valores] ya guardados.
Future<PreferencesService> preferenciasDePrueba([Map<String, Object> valores = const {}]) async {
  SharedPreferences.setMockInitialValues(valores);
  return PreferencesService(await SharedPreferences.getInstance());
}

/// Pone [hijo] dentro de una MaterialApp con los proveedores que usan las pantallas.
Widget envolver(
  Widget hijo, {
  required PreferencesService preferencias,
  RosarioSession? sesion,
  NotificationService? notificaciones,
  ThemeData? tema,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<PreferencesService>.value(value: preferencias),
      ChangeNotifierProvider<RosarioSession>.value(value: sesion ?? RosarioSession(reloj: () => lunes)),
      if (notificaciones != null) ChangeNotifierProvider<NotificationService>.value(value: notificaciones),
    ],
    child: MaterialApp(theme: tema ?? AppTheme.claro(), home: hijo),
  );
}
```

- [ ] **Step 2: Escribir las pruebas**

`test/widgets/app_drawer_test.dart`:

```dart
import 'package:app_resar_rosario/data/oraciones.dart';
import 'package:app_resar_rosario/models/prayer_models.dart';
import 'package:app_resar_rosario/widgets/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  testWidgets('el menú muestra el misterio de hoy', (tester) async {
    await abrirMenu(tester);
    expect(find.text('Misterios del día'), findsOneWidget);
    expect(find.text('Gozosos · Lunes'), findsOneWidget);
    expect(find.text('Agendar Rosario'), findsOneWidget);
  });

  testWidgets('abre el diálogo con los 5 misterios y se cierra', (tester) async {
    await abrirMenu(tester);
    await tester.tap(find.text('Misterios del día'));
    await tester.pumpAndSettle();

    expect(find.text('Misterios Gozosos'), findsOneWidget);
    for (final misterio in misteriosPorTipo[TipoMisterio.gozosos]!) {
      expect(find.text(misterio), findsOneWidget);
    }

    await tester.tap(find.text('Entendido'));
    await tester.pumpAndSettle();
    expect(find.text('Misterios Gozosos'), findsNothing);
  });
}
```

- [ ] **Step 3: Correr y ver que falla**

Run: `flutter test test/widgets/app_drawer_test.dart`
Expected: FAIL de compilación — `Target of URI doesn't exist: 'package:app_resar_rosario/widgets/app_drawer.dart'`.

- [ ] **Step 4: Escribir el diálogo de misterios del día**

`lib/widgets/misterios_del_dia_modal.dart` (reemplazo completo):

```dart
import 'package:flutter/material.dart';

import '../data/oraciones.dart';
import '../models/prayer_models.dart';
import '../theme/app_tokens.dart';
import '../theme/seccion_colores.dart';

/// Diálogo con los cinco misterios que se rezan hoy.
class MisteriosDelDiaDialog extends StatelessWidget {
  const MisteriosDelDiaDialog({super.key, required this.tipo, required this.dia});

  final TipoMisterio tipo;
  final String dia;

  @override
  Widget build(BuildContext context) {
    final colores = context.coloresDe(SeccionRosario.iniciales);
    final textos = Theme.of(context).textTheme;
    final misterios = misteriosPorTipo[tipo]!;

    return AlertDialog(
      icon: Icon(Icons.auto_awesome, color: colores.acento),
      title: Text('Misterios ${tipo.nombre}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dia, style: textos.titleSmall?.copyWith(color: colores.acento)),
            const SizedBox(height: AppTokens.espacioM),
            for (var i = 0; i < misterios.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: AppTokens.espacioS),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: colores.boton,
                      foregroundColor: colores.sobreBoton,
                      child: Text('${i + 1}'),
                    ),
                    const SizedBox(width: AppTokens.espacioM),
                    Expanded(child: Text(misterios[i], style: textos.bodyLarge)),
                  ],
                ),
              ),
            const SizedBox(height: AppTokens.espacioS),
            Text(
              'Medita en cada uno de estos misterios durante el rezo del Rosario.',
              style: textos.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Entendido')),
      ],
    );
  }
}
```

- [ ] **Step 5: Escribir el menú lateral**

`lib/widgets/app_drawer.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/rosario_session.dart';
import '../screens/agendar_rosario_screen.dart';
import '../services/preferences_service.dart';
import '../theme/app_tokens.dart';
import '../theme/seccion_colores.dart';
import 'misterios_del_dia_modal.dart';

/// El único menú lateral de la app.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final sesion = context.watch<RosarioSession>();
    final colores = context.secciones.iniciales;
    final textos = Theme.of(context).textTheme;
    final dia = nombreDelDia(sesion.hoy);

    return Drawer(
      child: Column(
        children: [
          ColoredBox(
            color: colores.boton,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(AppTokens.espacioL),
                child: Row(
                  children: [
                    Icon(Icons.favorite, size: 32, color: colores.sobreBoton),
                    const SizedBox(width: AppTokens.espacioM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Santo Rosario',
                            style: textos.titleLarge?.copyWith(color: colores.sobreBoton, fontWeight: FontWeight.bold),
                          ),
                          Text('Menú principal', style: textos.bodyMedium?.copyWith(color: colores.sobreBoton)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppTokens.espacioS),
              children: [
                ListTile(
                  leading: const Icon(Icons.auto_awesome),
                  title: const Text('Misterios del día'),
                  subtitle: Text('${sesion.tipoMisterio.nombre} · $dia'),
                  onTap: () {
                    final tipo = sesion.tipoMisterio;
                    Navigator.pop(context);
                    showDialog<void>(
                      context: context,
                      builder: (_) => MisteriosDelDiaDialog(tipo: tipo, dia: dia),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.schedule),
                  title: const Text('Agendar Rosario'),
                  subtitle: const Text('Programar recordatorios'),
                  onTap: () => abrirDesdeMenu(
                    context,
                    (_) => AgendarRosarioScreen(preferences: context.read<PreferencesService>()),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Cierra el menú y abre [pantalla].
void abrirDesdeMenu(BuildContext context, WidgetBuilder pantalla) {
  final navegador = Navigator.of(context);
  navegador.pop();
  navegador.push(MaterialPageRoute<void>(builder: pantalla));
}
```

- [ ] **Step 6: Conectar con la app vieja y borrar el menú anterior**

En `lib/screens/inicio_screen.dart`, reemplazar el import `import '../widgets/main_menu_drawer.dart';` por `import '../widgets/app_drawer.dart';` y el bloque:

```dart
// ANTES
      drawer: MainMenuDrawer(
        preferences: widget.preferences,
        todayMystery: widget.todayMystery,
        todayDay: widget.todayDay,
      ),
// DESPUÉS
      drawer: const AppDrawer(),
```

En `lib/main.dart`, agregar `import 'logic/rosario_session.dart';` y un proveedor más en `runApp`:

```dart
      providers: [
        ChangeNotifierProvider.value(value: preferencias),
        ChangeNotifierProvider.value(value: notificaciones),
        ChangeNotifierProvider(create: (_) => RosarioSession()),
      ],
```

En `test/widget_test.dart`, agregar `import 'package:app_resar_rosario/logic/rosario_session.dart';` y el mismo proveedor (la pantalla de inicio lo lee a partir de la Task 11):

```dart
        providers: [
          ChangeNotifierProvider.value(value: preferencias),
          ChangeNotifierProvider(create: (_) => NotificationService()),
          ChangeNotifierProvider(create: (_) => RosarioSession(reloj: () => lunes)),
        ],
```

Run: `git rm -q lib/widgets/main_menu_drawer.dart && grep -rn "MainMenuDrawer\|todayMystery: widget" lib`
Expected: sin coincidencias.

- [ ] **Step 7: Correr y ver que pasa**

Run: `flutter test`
Expected: `All tests passed!`

- [ ] **Step 8: Commit**

Run: `flutter analyze` → sin errores ni advertencias.

```bash
git add lib test
git commit -m "feat: menú lateral único y diálogo de misterios del día" -m "AppDrawer reemplaza a MainMenuDrawer y lee el misterio de RosarioSession. El diálogo usa los colores del tema y ya no tiene animaciones ni toques sin acción." -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 11: Una sola pantalla de rezo y la nueva pantalla de inicio

**Files:**
- Create: `lib/widgets/paso_oracion_layout.dart`
- Create: `lib/screens/rezo_screen.dart`
- Create: `lib/screens/principal_screen.dart`
- Rewrite: `lib/screens/inicio_screen.dart`
- Modify: `lib/models/prayer_models.dart` (borrar la fachada `PrayerData`)
- Modify: `lib/main.dart` (`MainScreen` muestra `PrincipalScreen`)
- Delete: `lib/resar_rosario_app.dart`, `lib/screens/oraciones_iniciales_screen.dart`, `lib/screens/misterios_screen.dart`, `lib/screens/oraciones_finales_screen.dart`
- Create: `test/screens/rezo_screen_test.dart`, `test/screens/principal_screen_test.dart`

**Interfaces:**
- Consumes: `RosarioSession`, `PasoRosario`, `misteriosPorRosario`, `nombreDelDia` (Task 8); `SeccionColores`, `context.secciones`, `context.coloresDe`, `AppTokens`, `AppTheme.oracion` (Task 9); `AppDrawer` (Task 10); `RosaryBeadsWidget(current:, total:)`, `RosaryImageWidget(width:, height:, imagePath:)` (existentes).
- Produces:
  - `class PasoOracionLayout` con `{required SeccionColores colores, required String titulo, required Widget encabezado, required Widget contenido, required VoidCallback onSiguiente, required VoidCallback onInicio, VoidCallback? onAnterior, String textoSiguiente = 'Continuar', Widget? progreso}` (sin `onAnterior` no hay botón "Atrás").
  - `class RezoScreen` (`const`), `String tituloDelPaso(PasoRosario, TipoMisterio)`.
  - `class PrincipalScreen` (`const`): muestra `InicioScreen` si `sesion.enInicio`, si no `RezoScreen`.
  - `class InicioScreen` (`const InicioScreen()`, sin parámetros).

- [ ] **Step 1: Escribir las pruebas**

`test/screens/rezo_screen_test.dart`:

```dart
import 'package:app_resar_rosario/logic/rosario_session.dart';
import 'package:app_resar_rosario/screens/rezo_screen.dart';
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

  testWidgets('primer paso: oraciones iniciales, sin botón Atrás', (tester) async {
    await mostrarEnPaso(tester, 0);
    expect(find.text('Oraciones Iniciales'), findsOneWidget);
    expect(find.text('Señal de la Cruz'), findsOneWidget);
    expect(find.text('Paso 1 de 3'), findsOneWidget);
    expect(find.text('Atrás'), findsNothing);
  });

  testWidgets('Continuar avanza y aparece Atrás', (tester) async {
    await mostrarEnPaso(tester, 0);
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('Acto de contrición'), findsOneWidget);
    expect(find.text('Atrás'), findsOneWidget);
  });

  testWidgets('anuncio del primer misterio', (tester) async {
    await mostrarEnPaso(tester, 3);
    expect(find.text('Misterios Gozosos · 1/5'), findsOneWidget);
    expect(find.text('1° Misterio Gozoso'), findsOneWidget);
    expect(find.text('Medita en este Misterio'), findsOneWidget);
    expect(find.text('La Encarnación del Hijo de Dios'), findsNWidgets(2));
  });

  testWidgets('Ave María con sus cuentas', (tester) async {
    await mostrarEnPaso(tester, 5);
    expect(find.text('Ave María (1°)'), findsOneWidget);
    expect(find.text('Ave María 1 de 10'), findsOneWidget);
    expect(find.byType(RosaryBeadsWidget), findsOneWidget);
  });

  testWidgets('el último paso dice Terminar Rosario y regresa al inicio', (tester) async {
    final sesion = await mostrarEnPaso(tester, 92);
    expect(find.text('Dulce Madre'), findsOneWidget);
    await tester.tap(find.text('Terminar Rosario'));
    await tester.pumpAndSettle();
    expect(sesion.enInicio, isTrue);
  });

  testWidgets('el botón Atrás del sistema retrocede un paso', (tester) async {
    final sesion = await mostrarEnPaso(tester, 2);
    await tester.state<NavigatorState>(find.byType(Navigator)).maybePop();
    await tester.pumpAndSettle();
    expect(sesion.indice, 1);
  });
}
```

`test/screens/principal_screen_test.dart`:

```dart
import 'package:app_resar_rosario/screens/principal_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('inicio muestra el día y el misterio, y empieza a rezar', (tester) async {
    await tester.pumpWidget(envolver(const PrincipalScreen(), preferencias: await preferenciasDePrueba()));
    await tester.pumpAndSettle();
    expect(find.text('Lunes'), findsOneWidget);
    expect(find.text('Misterios Gozosos'), findsOneWidget);

    await tester.tap(find.text('Comenzar a Rezar'));
    await tester.pumpAndSettle();
    expect(find.text('Oraciones Iniciales'), findsOneWidget);

    await tester.tap(find.byTooltip('Volver al inicio'));
    await tester.pumpAndSettle();
    expect(find.text('Comenzar a Rezar'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Correr y ver que falla**

Run: `flutter test test/screens`
Expected: FAIL de compilación — `Target of URI doesn't exist: 'package:app_resar_rosario/screens/rezo_screen.dart'`.

- [ ] **Step 3: Escribir la estructura común de cada paso**

`lib/widgets/paso_oracion_layout.dart`:

```dart
import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../theme/seccion_colores.dart';

/// Estructura común de cada paso: fondo de la sección, tarjeta con encabezado y texto,
/// y los botones para avanzar o retroceder.
class PasoOracionLayout extends StatelessWidget {
  const PasoOracionLayout({
    super.key,
    required this.colores,
    required this.titulo,
    required this.encabezado,
    required this.contenido,
    required this.onSiguiente,
    required this.onInicio,
    this.onAnterior,
    this.textoSiguiente = 'Continuar',
    this.progreso,
  });

  final SeccionColores colores;
  final String titulo;
  final Widget encabezado;

  /// Texto de la oración. No debe tener su propio desplazamiento: el layout ya lo da.
  final Widget contenido;
  final VoidCallback onSiguiente;
  final VoidCallback onInicio;

  /// Si es `null` no se muestra el botón "Atrás".
  final VoidCallback? onAnterior;
  final String textoSiguiente;
  final Widget? progreso;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final borde = colores.borde;

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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (progreso != null) ...[progreso!, const SizedBox(height: AppTokens.espacioM)],
                        Row(
                          children: [
                            Expanded(
                              child: Text(titulo, style: textos.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                            ),
                            IconButton(
                              onPressed: onInicio,
                              icon: const Icon(Icons.home_outlined),
                              tooltip: 'Volver al inicio',
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTokens.espacioM),
                        // Encabezado y oración se desplazan juntos: con texto grande nada se desborda.
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: colores.suave,
                                    borderRadius: BorderRadius.circular(AppTokens.radioM),
                                    border: borde == null ? null : Border.all(color: borde, width: 2),
                                  ),
                                  child: Padding(padding: const EdgeInsets.all(AppTokens.espacioM), child: encabezado),
                                ),
                                const SizedBox(height: AppTokens.espacioM),
                                contenido,
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTokens.espacioL),
                        Row(
                          children: [
                            if (onAnterior != null) ...[
                              Expanded(child: OutlinedButton(onPressed: onAnterior, child: const Text('Atrás'))),
                              const SizedBox(width: AppTokens.espacioM),
                            ],
                            Expanded(
                              flex: 2,
                              child: FilledButton(
                                onPressed: onSiguiente,
                                style: FilledButton.styleFrom(
                                  backgroundColor: colores.boton,
                                  foregroundColor: colores.sobreBoton,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(child: Text(textoSiguiente, textAlign: TextAlign.center)),
                                    const SizedBox(width: AppTokens.espacioS),
                                    const Icon(Icons.chevron_right),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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

- [ ] **Step 4: Escribir la pantalla de rezo**

`lib/screens/rezo_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../logic/rosario_session.dart';
import '../models/prayer_models.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../theme/seccion_colores.dart';
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
        titulo: tituloDelPaso(paso, sesion.tipoMisterio),
        encabezado: _Encabezado(paso: paso, sesion: sesion, colores: colores),
        contenido: _Contenido(paso: paso, sesion: sesion, colores: colores),
        onAnterior: sesion.indice > 0 ? sesion.anterior : null,
        onSiguiente: () {
          HapticFeedback.selectionClick();
          sesion.siguiente();
        },
        onInicio: sesion.reiniciar,
        textoSiguiente: sesion.esUltimo ? 'Terminar Rosario' : 'Continuar',
      ),
    );
  }
}

/// Título de la tarjeta en cada paso.
String tituloDelPaso(PasoRosario paso, TipoMisterio tipo) => switch (paso.seccion) {
      SeccionRosario.iniciales => 'Oraciones Iniciales',
      SeccionRosario.misterio => 'Misterios ${tipo.nombre} · ${paso.misterio! + 1}/$misteriosPorRosario',
      SeccionRosario.finales => 'Oraciones Finales',
    };

class _Encabezado extends StatelessWidget {
  const _Encabezado({required this.paso, required this.sesion, required this.colores});

  final PasoRosario paso;
  final RosarioSession sesion;
  final SeccionColores colores;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final principal = textos.titleMedium?.copyWith(color: colores.acento, fontWeight: FontWeight.w600);
    final secundario = textos.bodyMedium?.copyWith(color: colores.acento);

    final (linea1, linea2) = paso.seccion == SeccionRosario.misterio
        ? ('${paso.misterio! + 1}° Misterio ${sesion.tipoMisterio.singular}', sesion.tituloMisterioActual)
        : (paso.oracion.title, 'Paso ${paso.indiceEnSeccion + 1} de ${paso.totalEnSeccion}');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(linea1, style: principal),
        const SizedBox(height: AppTokens.espacioXS),
        Text(linea2, style: secundario),
      ],
    );
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido({required this.paso, required this.sesion, required this.colores});

  final PasoRosario paso;
  final RosarioSession sesion;
  final SeccionColores colores;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    if (paso.esAnuncioDeMisterio) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTokens.espacioL),
        child: Column(
          children: [
            Icon(Icons.auto_awesome, size: 32, color: colores.acento),
            const SizedBox(height: AppTokens.espacioM),
            Text(
              'Medita en este Misterio',
              textAlign: TextAlign.center,
              style: textos.titleLarge?.copyWith(color: colores.acento),
            ),
            const SizedBox(height: AppTokens.espacioS),
            Text(sesion.tituloMisterioActual, textAlign: TextAlign.center, style: AppTheme.oracion(context)),
          ],
        ),
      );
    }

    final repeticion = paso.repeticion;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (paso.seccion == SeccionRosario.misterio) ...[
          Text(
            repeticion == null ? paso.oracion.title : '${paso.oracion.title} (${repeticion + 1}°)',
            style: textos.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppTokens.espacioM),
        ],
        if (repeticion != null) ...[
          RosaryBeadsWidget(current: repeticion, total: paso.oracion.count!),
          const SizedBox(height: AppTokens.espacioS),
          Text(
            'Ave María ${repeticion + 1} de ${paso.oracion.count}',
            textAlign: TextAlign.center,
            style: textos.labelLarge?.copyWith(color: colores.acento),
          ),
          const SizedBox(height: AppTokens.espacioM),
        ],
        Text(paso.oracion.text, style: AppTheme.oracion(context)),
      ],
    );
  }
}
```

- [ ] **Step 5: Escribir la nueva pantalla de inicio**

`lib/screens/inicio_screen.dart` (reemplazo completo):

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../logic/rosario_session.dart';
import '../models/prayer_models.dart';
import '../theme/app_tokens.dart';
import '../theme/seccion_colores.dart';
import '../widgets/app_drawer.dart';
import '../widgets/rosary_image_widget.dart';

class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _animacion =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..forward();
  late final Animation<double> _aparecer =
      CurvedAnimation(parent: _animacion, curve: const Interval(0, 0.6, curve: Curves.easeOut));
  late final Animation<Offset> _subir = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
      .animate(CurvedAnimation(parent: _animacion, curve: const Interval(0.3, 1, curve: Curves.easeOutCubic)));

  @override
  void dispose() {
    _animacion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sesion = context.watch<RosarioSession>();
    final secciones = context.secciones;
    final colores = secciones.iniciales;
    final textos = Theme.of(context).textTheme;
    final altoImagen = MediaQuery.sizeOf(context).height * 0.32;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: secciones.tituloInicio,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      drawer: const AppDrawer(),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: secciones.fondoInicio,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppTokens.anchoMaximo),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTokens.espacioL),
                child: FadeTransition(
                  opacity: _aparecer,
                  child: Column(
                    children: [
                      Text(
                        'Santo Rosario',
                        textAlign: TextAlign.center,
                        style: textos.displaySmall?.copyWith(
                          color: secciones.tituloInicio,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: AppTokens.espacioL),
                      SlideTransition(
                        position: _subir,
                        child: RosaryImageWidget(
                          width: double.infinity,
                          height: altoImagen,
                          imagePath: 'assets/images/imagen-rosario.png',
                        ),
                      ),
                      const SizedBox(height: AppTokens.espacioXL),
                      _MisterioDelDia(dia: nombreDelDia(sesion.hoy), tipo: sesion.tipoMisterio, colores: colores),
                      const SizedBox(height: AppTokens.espacioXL),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            sesion.comenzar();
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: colores.boton,
                            foregroundColor: colores.sobreBoton,
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.favorite_rounded),
                              SizedBox(width: AppTokens.espacioS),
                              Flexible(child: Text('Comenzar a Rezar')),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTokens.espacioXL),
                      Text(
                        '"El Rosario es la oración más hermosa que podemos ofrecer a la Virgen María"',
                        textAlign: TextAlign.center,
                        style: textos.bodyMedium?.copyWith(fontStyle: FontStyle.italic, color: secciones.tituloInicio),
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

class _MisterioDelDia extends StatelessWidget {
  const _MisterioDelDia({required this.dia, required this.tipo, required this.colores});

  final String dia;
  final TipoMisterio tipo;
  final SeccionColores colores;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.espacioL),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today_rounded, size: 20, color: colores.acento),
                const SizedBox(width: AppTokens.espacioS),
                Text(dia, style: textos.titleMedium?.copyWith(color: colores.acento)),
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
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 6: Escribir la pantalla principal**

`lib/screens/principal_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/rosario_session.dart';
import 'inicio_screen.dart';
import 'rezo_screen.dart';

/// Muestra el inicio o el rezo según la sesión.
class PrincipalScreen extends StatelessWidget {
  const PrincipalScreen({super.key});

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

- [ ] **Step 7: Conectar, borrar las pantallas viejas y la fachada**

En `lib/main.dart`, reemplazar `import 'resar_rosario_app.dart';` por `import 'screens/principal_screen.dart';` y en `MainScreen`:

```dart
// ANTES
      body: RosarioApp(preferences: preferences),
// DESPUÉS
      body: const PrincipalScreen(),
```

En `lib/models/prayer_models.dart`, borrar la clase `PrayerData` completa y el import `import '../data/oraciones.dart';` (ya no se usa en ese archivo).

Run:

```bash
git rm -q lib/resar_rosario_app.dart lib/screens/oraciones_iniciales_screen.dart lib/screens/misterios_screen.dart lib/screens/oraciones_finales_screen.dart
grep -rn "PrayerData\|RosarioApp(" lib test
```

Expected: sin coincidencias.

- [ ] **Step 8: Correr y ver que pasa**

Run: `flutter test`
Expected: `All tests passed!`

- [ ] **Step 9: Commit**

Run: `flutter analyze && flutter build apk --debug` → sin errores ni advertencias; APK compila.

```bash
git add lib test
git commit -m "feat: una sola pantalla de rezo y nueva pantalla de inicio" -m "RezoScreen y PasoOracionLayout reemplazan las tres pantallas de oraciones (~600 renglones duplicados). Colores desde el tema, sin escalado manual del texto. El botón Atrás del sistema retrocede un paso." -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
graphify update .
```

**Cierre de la Fase 2A:** el rosario completo se recorre con `RezoScreen`; las preferencias persisten; el tema ya no duplica el tamaño de letra.
