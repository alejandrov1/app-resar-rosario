# Mejora integral — Fase 2B: Recordatorios y estructura de la app

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Recordatorios a la hora local correcta (E1), sin colisiones, con alarma real y errores visibles (E5, E6, E7, E13); un solo menú con Configuración accesible (E2); texto escalado una vez (E4); interfaz en español (E9); formulario sin hueco del teclado (E10).

**Architecture:** `NotificationService` deja de hablar directo con el plugin: usa la interfaz `NotificationsGateway` (implementación real `FlutterNotificationsGateway`, doble `FakeNotificationsGateway` en pruebas). El cálculo de fechas e IDs vive en funciones puras (`schedule_calculator.dart`). `SantoRosarioApp` (en `app.dart`) arma proveedores, temas, idioma y escalado de texto.

**Tech Stack:** flutter_local_notifications 22.3.3, timezone 0.11.2, flutter_timezone 5.1.1, shared_preferences, flutter_localizations, provider.

**Spec:** `docs/superpowers/specs/2026-11-09-mejora-integral-design.md` (§4.2, §4.3, §7) · **Índice:** `docs/superpowers/plans/2026-11-09-mejora-integral.md`

## Global Constraints

- Rama `mejora-integral`; cada commit termina con `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; sin `git push` sin autorización.
- Modelos y servicios con nombres en inglés; pantallas, widgets y tema en español.
- Recordatorios: dos tipos (`notification`, `alarm`); IDs secuenciales de 1 a `maxReminderId = 100000`; ID de notificación = `idRecordatorio * 10 + díaSemana` (1 = lunes … 7 = domingo).
- Canales Android: `rosario_notifications` (aviso normal) y `rosario_alarms_v2` (sonido `alarm_sound`). Ícono pequeño: `ic_notification`.
- Permisos: se piden al entrar a "Agendar Rosario", nunca al arrancar.
- Colores solo en `lib/theme/`; sin multiplicar tamaños de letra por `textScaleFactor`.
- Cierre de cada tarea: `flutter analyze` sin errores ni advertencias y `flutter test` en verde.

---

### Task 12: Zona horaria real del teléfono (E1)

**Files:**
- Create: `lib/services/zona_horaria.dart`
- Create: `test/services/zona_horaria_test.dart`
- Modify: `lib/main.dart`
- Modify: `lib/services/notification_service.dart` (quitar la inicialización de zona horaria que no hacía nada)

**Interfaces:**
- Consumes: —
- Produces: `Future<void> configurarZonaHoraria({Future<String> Function() obtenerZona})`. Deja `tz.local` con la zona del teléfono, o UTC si falla.

- [ ] **Step 1: Escribir las pruebas**

`test/services/zona_horaria_test.dart`:

```dart
import 'package:app_resar_rosario/services/zona_horaria.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  test('usa la zona horaria del teléfono', () async {
    await configurarZonaHoraria(obtenerZona: () async => 'America/Hermosillo');
    expect(tz.local.name, 'America/Hermosillo');
  });

  test('si la zona no existe, usa UTC', () async {
    await configurarZonaHoraria(obtenerZona: () async => 'Zona/Inexistente');
    expect(tz.local.name, 'UTC');
  });

  test('si no se puede consultar, usa UTC', () async {
    await configurarZonaHoraria(obtenerZona: () => Future<String>.error(Exception('sin canal')));
    expect(tz.local.name, 'UTC');
  });
}
```

- [ ] **Step 2: Correr y ver que falla**

Run: `flutter test test/services/zona_horaria_test.dart`
Expected: FAIL de compilación — `Target of URI doesn't exist: 'package:app_resar_rosario/services/zona_horaria.dart'`.

- [ ] **Step 3: Implementar**

`lib/services/zona_horaria.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

Future<String> _zonaDelTelefono() async => (await FlutterTimezone.getLocalTimezone()).identifier;

/// Carga las zonas horarias y fija la del teléfono como zona local.
/// Antes la app quedaba siempre en UTC: un recordatorio de 7:00 sonaba a otra hora.
Future<void> configurarZonaHoraria({Future<String> Function() obtenerZona = _zonaDelTelefono}) async {
  tzdata.initializeTimeZones();
  try {
    tz.setLocalLocation(tz.getLocation(await obtenerZona()));
  } catch (e) {
    tz.setLocalLocation(tz.UTC);
    debugPrint('No se pudo detectar la zona horaria; se usa UTC. Detalle: $e');
  }
}
```

- [ ] **Step 4: Correr y ver que pasa**

Run: `flutter test test/services/zona_horaria_test.dart`
Expected: `All tests passed!`

- [ ] **Step 5: Usarla al arrancar y quitar la versión que no hacía nada**

En `lib/main.dart`, agregar `import 'services/zona_horaria.dart';` y, justo después de `WidgetsFlutterBinding.ensureInitialized();`:

```dart
  await configurarZonaHoraria();
```

En `lib/services/notification_service.dart`, borrar el import `import 'package:timezone/data/latest_all.dart' as tz;` y, dentro de `initialize()`, estas dos líneas:

```dart
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.local);
```

Run: `grep -n "setLocalLocation(tz.local)\|initializeTimeZones" lib/services/notification_service.dart`
Expected: sin coincidencias.

- [ ] **Step 6: Verificar y hacer commit**

Run: `flutter analyze && flutter test`
Expected: sin errores ni advertencias; `All tests passed!`

```bash
git add lib/services/zona_horaria.dart lib/services/notification_service.dart lib/main.dart test/services/zona_horaria_test.dart
git commit -m "fix: usar la zona horaria del teléfono para los recordatorios" -m "tz.setLocalLocation(tz.local) dejaba la app en UTC y los recordatorios sonaban a otra hora (E1)." -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 13: Cálculo de fechas e IDs y modelo de recordatorio con dos tipos

**Files:**
- Create: `lib/services/schedule_calculator.dart`
- Rewrite: `lib/models/reminder_model.dart`
- Modify: `lib/services/notification_service.dart` (una línea: ya no existe `ReminderType.both`)
- Create: `test/services/schedule_calculator_test.dart`, `test/models/reminder_model_test.dart`

**Interfaces:**
- Consumes: —
- Produces:
  - `lib/models/reminder_model.dart`: `const int maxReminderId = 100000;` `class RosarioReminder` (mismos campos y métodos que hoy: `id`, `title`, `description`, `time`, `daysOfWeek`, `isActive`, `type`, `createdAt`, `fromMap`, `toMap`, `copyWith`, `daysText`, `timeText`); `enum ReminderType { notification, alarm }` con `static ReminderType fromStoredIndex(int)`; extensión con `displayName`, `description`, `icon`; `List<RosarioReminder>? renumberIfNeeded(List<RosarioReminder>)`; `ReminderTemplates.templates` (`static const List<ReminderTemplate>`).
  - `lib/services/schedule_calculator.dart`: `tz.TZDateTime nextWeeklyDate({required tz.TZDateTime now, required int weekday, required int hour, required int minute})`; `int notificationIdFor(int reminderId, int weekday)`; `int nextReminderId(Iterable<int> existing)`.

- [ ] **Step 1: Escribir las pruebas del cálculo**

`test/services/schedule_calculator_test.dart`:

```dart
import 'package:app_resar_rosario/services/schedule_calculator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

void main() {
  late tz.Location mx;
  late tz.Location ny;

  setUpAll(() {
    tzdata.initializeTimeZones();
    mx = tz.getLocation('America/Mexico_City');
    ny = tz.getLocation('America/New_York');
  });

  group('nextWeeklyDate', () {
    test('hoy mismo si la hora todavía no llega', () {
      final ahora = tz.TZDateTime(mx, 2026, 11, 9, 6); // lunes 6:00
      expect(
        nextWeeklyDate(now: ahora, weekday: DateTime.monday, hour: 7, minute: 0),
        tz.TZDateTime(mx, 2026, 11, 9, 7),
      );
    });

    test('la semana siguiente si la hora ya pasó', () {
      final ahora = tz.TZDateTime(mx, 2026, 11, 9, 8);
      expect(
        nextWeeklyDate(now: ahora, weekday: DateTime.monday, hour: 7, minute: 0),
        tz.TZDateTime(mx, 2026, 11, 16, 7),
      );
    });

    test('a la hora exacta pasa a la semana siguiente', () {
      final ahora = tz.TZDateTime(mx, 2026, 11, 9, 7);
      expect(
        nextWeeklyDate(now: ahora, weekday: DateTime.monday, hour: 7, minute: 0),
        tz.TZDateTime(mx, 2026, 11, 16, 7),
      );
    });

    test('otro día de la semana', () {
      final ahora = tz.TZDateTime(mx, 2026, 11, 9, 8);
      expect(
        nextWeeklyDate(now: ahora, weekday: DateTime.sunday, hour: 10, minute: 30),
        tz.TZDateTime(mx, 2026, 11, 15, 10, 30),
      );
    });

    test('conserva la hora local al cruzar el cambio de horario', () {
      final ahora = tz.TZDateTime(ny, 2026, 10, 30, 12); // viernes; el horario cambia el domingo 1 de noviembre
      final fecha = nextWeeklyDate(now: ahora, weekday: DateTime.monday, hour: 7, minute: 0);
      expect([fecha.month, fecha.day, fecha.hour, fecha.minute], [11, 2, 7, 0]);
    });

    test('rechaza días fuera de 1 a 7', () {
      final ahora = tz.TZDateTime(mx, 2026, 11, 9);
      expect(() => nextWeeklyDate(now: ahora, weekday: 0, hour: 7, minute: 0), throwsRangeError);
    });
  });

  test('notificationIdFor', () {
    expect(notificationIdFor(1, 1), 11);
    expect(notificationIdFor(100000, 7), 1000007);
    expect(() => notificationIdFor(0, 1), throwsRangeError);
    expect(() => notificationIdFor(100001, 1), throwsRangeError);
    expect(() => notificationIdFor(1, 8), throwsRangeError);
  });

  test('nextReminderId', () {
    expect(nextReminderId(const []), 1);
    expect(nextReminderId(const [3, 7, 2]), 8);
  });
}
```

- [ ] **Step 2: Escribir las pruebas del modelo**

`test/models/reminder_model_test.dart`:

```dart
import 'package:app_resar_rosario/models/reminder_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

RosarioReminder ejemplo({int id = 1, String title = 'Rosario', ReminderType type = ReminderType.notification}) {
  return RosarioReminder(
    id: id,
    title: title,
    description: 'Es hora',
    time: const TimeOfDay(hour: 7, minute: 30),
    daysOfWeek: const [1, 3, 5],
    isActive: true,
    type: type,
    createdAt: DateTime(2026, 11, 1),
  );
}

void main() {
  test('se guarda y se lee igual', () {
    final r = ejemplo(type: ReminderType.alarm);
    expect(RosarioReminder.fromMap(r.toMap()).toMap(), r.toMap());
  });

  test('el antiguo tipo "Notificación y Alarma" se lee como Alarma', () {
    final mapa = ejemplo().toMap()..['type'] = 2;
    expect(RosarioReminder.fromMap(mapa).type, ReminderType.alarm);
  });

  test('un tipo desconocido se lee como Notificación', () {
    final mapa = ejemplo().toMap()..['type'] = 99;
    expect(RosarioReminder.fromMap(mapa).type, ReminderType.notification);
  });

  test('rechaza días inválidos', () {
    final mapa = ejemplo().toMap()..['daysOfWeek'] = [0, 8];
    expect(() => RosarioReminder.fromMap(mapa), throwsFormatException);
  });

  test('textos legibles', () {
    expect(ejemplo().timeText, '07:30');
    expect(ejemplo().daysText, 'Lun, Mié, Vie');
    expect(ejemplo().copyWith(daysOfWeek: [1, 2, 3, 4, 5, 6, 7]).daysText, 'Todos los días');
  });

  group('renumberIfNeeded', () {
    test('no cambia nada si los IDs ya son válidos', () {
      expect(renumberIfNeeded([ejemplo(id: 1), ejemplo(id: 2)]), isNull);
    });

    test('renumera los IDs antiguos y conserva lo demás', () {
      final resultado = renumberIfNeeded([ejemplo(id: 1500000, title: 'A'), ejemplo(id: 2000000, title: 'B')])!;
      expect(resultado.map((r) => r.id), [1, 2]);
      expect(resultado.map((r) => r.title), ['A', 'B']);
    });

    test('renumera si hay IDs repetidos', () {
      expect(renumberIfNeeded([ejemplo(id: 3), ejemplo(id: 3)])!.map((r) => r.id), [1, 2]);
    });
  });

  test('las plantillas rápidas son válidas', () {
    expect(ReminderTemplates.templates, hasLength(4));
    for (final plantilla in ReminderTemplates.templates) {
      expect(plantilla.daysOfWeek, isNotEmpty);
      expect(plantilla.daysOfWeek.every((d) => d >= 1 && d <= 7), isTrue);
    }
  });
}
```

- [ ] **Step 3: Correr y ver que falla**

Run: `flutter test test/services/schedule_calculator_test.dart test/models/reminder_model_test.dart`
Expected: FAIL de compilación — `schedule_calculator.dart` no existe y `renumberIfNeeded` / `fromStoredIndex` no están definidos.

- [ ] **Step 4: Implementar el modelo**

`lib/models/reminder_model.dart` (reemplazo completo):

```dart
import 'package:flutter/material.dart';

/// Mayor ID de recordatorio permitido. El ID de cada notificación es `id * 10 + día`.
const int maxReminderId = 100000;

class RosarioReminder {
  const RosarioReminder({
    required this.id,
    required this.title,
    required this.description,
    required this.time,
    required this.daysOfWeek,
    required this.isActive,
    required this.type,
    required this.createdAt,
  });

  final int id;
  final String title;
  final String description;
  final TimeOfDay time;

  /// Días en que suena: 1 = lunes … 7 = domingo.
  final List<int> daysOfWeek;
  final bool isActive;
  final ReminderType type;
  final DateTime createdAt;

  /// Lee un recordatorio guardado. Lanza [FormatException] si los datos no son válidos.
  factory RosarioReminder.fromMap(Map<String, dynamic> map) {
    final dias = List<int>.from(map['daysOfWeek'] as List);
    if (dias.isEmpty || dias.any((d) => d < 1 || d > 7)) {
      throw FormatException('Días inválidos: $dias');
    }
    return RosarioReminder(
      id: map['id'] as int,
      title: map['title'] as String,
      description: map['description'] as String,
      time: TimeOfDay(hour: map['hour'] as int, minute: map['minute'] as int),
      daysOfWeek: dias,
      isActive: map['isActive'] as bool,
      type: ReminderType.fromStoredIndex(map['type'] as int),
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'hour': time.hour,
        'minute': time.minute,
        'daysOfWeek': daysOfWeek,
        'isActive': isActive,
        'type': type.index,
        'createdAt': createdAt.toIso8601String(),
      };

  RosarioReminder copyWith({
    int? id,
    String? title,
    String? description,
    TimeOfDay? time,
    List<int>? daysOfWeek,
    bool? isActive,
    ReminderType? type,
    DateTime? createdAt,
  }) {
    return RosarioReminder(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      time: time ?? this.time,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      isActive: isActive ?? this.isActive,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get daysText {
    if (daysOfWeek.toSet().length == 7) return 'Todos los días';
    const nombres = {1: 'Lun', 2: 'Mar', 3: 'Mié', 4: 'Jue', 5: 'Vie', 6: 'Sáb', 7: 'Dom'};
    final ordenados = [...daysOfWeek]..sort();
    return ordenados.map((d) => nombres[d]!).join(', ');
  }

  String get timeText =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  @override
  String toString() => 'RosarioReminder(id: $id, title: $title, time: $timeText, days: $daysText, active: $isActive)';

  @override
  bool operator ==(Object other) => identical(this, other) || other is RosarioReminder && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

enum ReminderType {
  notification,
  alarm;

  /// Convierte el índice guardado. El antiguo tipo "Notificación y Alarma" (2) era igual a Alarma.
  static ReminderType fromStoredIndex(int index) => switch (index) {
        1 || 2 => ReminderType.alarm,
        _ => ReminderType.notification,
      };
}

extension ReminderTypeExtension on ReminderType {
  String get displayName => switch (this) {
        ReminderType.notification => 'Notificación',
        ReminderType.alarm => 'Alarma',
      };

  String get description => switch (this) {
        ReminderType.notification => 'Aviso con el sonido normal del teléfono',
        ReminderType.alarm => 'Sonido de alarma y aviso en pantalla completa',
      };

  IconData get icon => switch (this) {
        ReminderType.notification => Icons.notifications_outlined,
        ReminderType.alarm => Icons.alarm,
      };
}

/// Renumera los recordatorios si algún ID está fuera de rango o repetido (los antiguos eran aleatorios
/// de 1,000,000 en adelante). Devuelve `null` si no hace falta.
List<RosarioReminder>? renumberIfNeeded(List<RosarioReminder> reminders) {
  final ids = reminders.map((r) => r.id).toList();
  final validos = ids.every((id) => id >= 1 && id <= maxReminderId);
  final unicos = ids.toSet().length == ids.length;
  if (validos && unicos) return null;
  return [for (var i = 0; i < reminders.length; i++) reminders[i].copyWith(id: i + 1)];
}

/// Plantillas para crear recordatorios con un toque.
class ReminderTemplates {
  static const List<ReminderTemplate> templates = [
    ReminderTemplate(
      title: 'Rosario Matutino',
      description: 'Momento perfecto para comenzar el día con oración',
      time: TimeOfDay(hour: 7, minute: 0),
      daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
      type: ReminderType.notification,
    ),
    ReminderTemplate(
      title: 'Rosario de Mediodía',
      description: 'Una pausa espiritual en medio del día',
      time: TimeOfDay(hour: 12, minute: 0),
      daysOfWeek: [1, 2, 3, 4, 5],
      type: ReminderType.notification,
    ),
    ReminderTemplate(
      title: 'Rosario Vespertino',
      description: 'Termina tu día con la oración del Rosario',
      time: TimeOfDay(hour: 19, minute: 0),
      daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
      type: ReminderType.notification,
    ),
    ReminderTemplate(
      title: 'Rosario Dominical',
      description: 'Dedica tiempo especial los domingos',
      time: TimeOfDay(hour: 10, minute: 0),
      daysOfWeek: [7],
      type: ReminderType.alarm,
    ),
  ];
}

class ReminderTemplate {
  const ReminderTemplate({
    required this.title,
    required this.description,
    required this.time,
    required this.daysOfWeek,
    required this.type,
  });

  final String title;
  final String description;
  final TimeOfDay time;
  final List<int> daysOfWeek;
  final ReminderType type;
}
```

- [ ] **Step 5: Implementar el cálculo**

`lib/services/schedule_calculator.dart`:

```dart
import 'dart:math' as math;

import 'package:timezone/timezone.dart' as tz;

import '../models/reminder_model.dart';

/// Siguiente fecha, estrictamente posterior a [now], que cae en [weekday] (1 = lunes … 7 = domingo)
/// a la hora indicada, en la zona horaria de [now]. Se avanza por días de calendario (no por 24 horas)
/// para conservar la hora local cuando cambia el horario de verano.
tz.TZDateTime nextWeeklyDate({
  required tz.TZDateTime now,
  required int weekday,
  required int hour,
  required int minute,
}) {
  RangeError.checkValueInInterval(weekday, DateTime.monday, DateTime.sunday, 'weekday');
  var candidata = tz.TZDateTime(now.location, now.year, now.month, now.day, hour, minute);
  while (candidata.weekday != weekday || !candidata.isAfter(now)) {
    candidata = tz.TZDateTime(now.location, candidata.year, candidata.month, candidata.day + 1, hour, minute);
  }
  return candidata;
}

/// ID único de la notificación de un recordatorio para un día de la semana.
int notificationIdFor(int reminderId, int weekday) {
  RangeError.checkValueInInterval(reminderId, 1, maxReminderId, 'reminderId');
  RangeError.checkValueInInterval(weekday, DateTime.monday, DateTime.sunday, 'weekday');
  return reminderId * 10 + weekday;
}

/// Siguiente ID libre para un recordatorio nuevo.
int nextReminderId(Iterable<int> existing) => existing.isEmpty ? 1 : existing.reduce(math.max) + 1;
```

- [ ] **Step 6: Ajustar la línea del servicio actual que usaba `ReminderType.both`**

En `lib/services/notification_service.dart`:

```dart
// ANTES
    final isAlarm = type == ReminderType.alarm || type == ReminderType.both;
// DESPUÉS
    final isAlarm = type == ReminderType.alarm;
```

- [ ] **Step 7: Correr y ver que pasa**

Run: `flutter test`
Expected: `All tests passed!`

- [ ] **Step 8: Commit**

Run: `flutter analyze` → sin errores ni advertencias.

```bash
git add lib/models/reminder_model.dart lib/services/schedule_calculator.dart lib/services/notification_service.dart test
git commit -m "feat: cálculo de fechas e IDs de recordatorios y dos tipos de aviso" -m "IDs secuenciales sin colisiones, fechas que respetan el horario de verano y migración de 'Notificación y Alarma' a Alarma." -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 14: Servicio de recordatorios nuevo con alarma real y errores visibles (E5, E6, E7, E13)

**Files:**
- Create: `lib/services/notifications_gateway.dart`
- Rewrite: `lib/services/notification_service.dart`
- Create: `android/app/src/main/res/drawable/ic_notification.xml`
- Create: `android/app/src/main/res/raw/keep.xml`
- Modify: `pubspec.yaml` (quitar `permission_handler` y su comentario)
- Modify: `lib/main.dart`
- Create: `test/support/fake_notifications_gateway.dart`
- Rewrite: `test/support/app_harness.dart`
- Create: `test/services/notification_service_test.dart`
- Modify: `test/widget_test.dart`

**Interfaces:**
- Consumes: `RosarioReminder`, `ReminderType`, `renumberIfNeeded` (Task 13); `nextWeeklyDate`, `notificationIdFor`, `nextReminderId` (Task 13).
- Produces:
  - `class NotificationPermissions { const NotificationPermissions({required bool notifications, required bool exactAlarms}); static const none; }`
  - `abstract interface class NotificationsGateway` con `initialize()`, `checkPermissions()`, `requestPermissions()`, `requestExactAlarms()`, `openSettings()`, `scheduleWeekly({required int id, required String title, required String body, required tz.TZDateTime date, required bool isAlarm, required bool exact, String? payload})`, `cancel(int id)`, `cancelAll()`.
  - `class FlutterNotificationsGateway implements NotificationsGateway` (`FlutterNotificationsGateway([FlutterLocalNotificationsPlugin? plugin])`).
  - `class ReminderResult { const ReminderResult.success(); const ReminderResult.failure(String message); bool ok; String? message; }`
  - `class NotificationService extends ChangeNotifier`: constructor `NotificationService({required NotificationsGateway gateway, tz.TZDateTime Function()? now})`; `static const String storageKey = 'rosario_reminders'`; getters `reminders`, `permissions`, `isAvailable`, `initError`; métodos `Future<void> initialize()` (nunca lanza), `Future<NotificationPermissions> requestPermissions()`, `Future<void> requestExactAlarms()`, `Future<void> refreshPermissions()`, `Future<void> openSettings()`, `Future<ReminderResult> addReminder(RosarioReminder)`, `updateReminder(RosarioReminder)`, `removeReminder(int id)`, `toggleReminder(int id)`.
  - `test/support/fake_notifications_gateway.dart`: `FakeNotificationsGateway` con `permissions`, `permissionsAfterRequest`, `failInitialize`, `failSchedule`, `scheduled` (`Map<int, AvisoProgramado>`), `cancelled`, `cancelAllCalls`, `openSettingsCalls`, `requestExactAlarmsCalls`; `AvisoProgramado { title, date, isAlarm, exact }`.
  - Harness: `Future<NotificationService> notificacionesDePrueba(FakeNotificationsGateway gateway, {tz.TZDateTime Function()? ahora})`.

- [ ] **Step 1: Crear la interfaz con el sistema de notificaciones**

`lib/services/notifications_gateway.dart`:

```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// Estado de los permisos de notificación.
class NotificationPermissions {
  const NotificationPermissions({required this.notifications, required this.exactAlarms});

  static const none = NotificationPermissions(notifications: false, exactAlarms: false);

  final bool notifications;

  /// Android 12+: permiso de "Alarmas y recordatorios". En iOS siempre es `true`.
  final bool exactAlarms;
}

/// Lo mínimo que la app necesita del sistema de notificaciones. En pruebas se usa un doble.
abstract interface class NotificationsGateway {
  Future<void> initialize();
  Future<NotificationPermissions> checkPermissions();
  Future<NotificationPermissions> requestPermissions();
  Future<void> requestExactAlarms();
  Future<void> openSettings();
  Future<void> scheduleWeekly({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime date,
    required bool isAlarm,
    required bool exact,
    String? payload,
  });
  Future<void> cancel(int id);
  Future<void> cancelAll();
}

/// Implementación real con flutter_local_notifications.
class FlutterNotificationsGateway implements NotificationsGateway {
  FlutterNotificationsGateway([FlutterLocalNotificationsPlugin? plugin])
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  static const String _icono = 'ic_notification';
  static const String _sonidoAlarma = 'alarm_sound';

  static const AndroidNotificationChannel _canalAvisos = AndroidNotificationChannel(
    'rosario_notifications',
    'Recordatorios del Rosario',
    description: 'Avisos para rezar el Santo Rosario',
    importance: Importance.high,
  );

  // Canal nuevo: Android no deja cambiar el sonido de un canal que ya existe.
  static const AndroidNotificationChannel _canalAlarmas = AndroidNotificationChannel(
    'rosario_alarms_v2',
    'Alarmas del Rosario',
    description: 'Alarmas con sonido para rezar el Santo Rosario',
    importance: Importance.max,
    sound: RawResourceAndroidNotificationSound(_sonidoAlarma),
    audioAttributesUsage: AudioAttributesUsage.alarm,
  );

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  IOSFlutterLocalNotificationsPlugin? get _ios =>
      _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

  @override
  Future<void> initialize() async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings(_icono),
        // Los permisos se piden al entrar a "Agendar Rosario", no al arrancar.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    final android = _android;
    if (android != null) {
      await android.createNotificationChannel(_canalAvisos);
      await android.createNotificationChannel(_canalAlarmas);
      await android.deleteNotificationChannel(channelId: 'rosario_alarms'); // canal anterior, sin sonido propio
    }
  }

  @override
  Future<NotificationPermissions> checkPermissions() async {
    final android = _android;
    if (android != null) {
      return NotificationPermissions(
        notifications: await android.areNotificationsEnabled() ?? false,
        exactAlarms: await android.canScheduleExactNotifications() ?? false,
      );
    }
    final ios = _ios;
    if (ios != null) {
      final opciones = await ios.checkPermissions();
      return NotificationPermissions(notifications: opciones?.isEnabled ?? false, exactAlarms: true);
    }
    return NotificationPermissions.none;
  }

  @override
  Future<NotificationPermissions> requestPermissions() async {
    await _android?.requestNotificationsPermission();
    await _ios?.requestPermissions(alert: true, badge: true, sound: true);
    return checkPermissions();
  }

  @override
  Future<void> requestExactAlarms() async {
    await _android?.requestExactAlarmsPermission();
  }

  @override
  Future<void> openSettings() async {
    await _plugin.openAppNotificationSettings();
  }

  @override
  Future<void> scheduleWeekly({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime date,
    required bool isAlarm,
    required bool exact,
    String? payload,
  }) {
    return _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: date,
      notificationDetails: _detalles(isAlarm: isAlarm),
      androidScheduleMode: exact ? AndroidScheduleMode.exactAllowWhileIdle : AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: payload,
    );
  }

  @override
  Future<void> cancel(int id) => _plugin.cancel(id: id);

  @override
  Future<void> cancelAll() => _plugin.cancelAll();

  NotificationDetails _detalles({required bool isAlarm}) {
    final android = isAlarm
        ? AndroidNotificationDetails(
            _canalAlarmas.id,
            _canalAlarmas.name,
            channelDescription: _canalAlarmas.description,
            icon: _icono,
            importance: Importance.max,
            priority: Priority.max,
            sound: const RawResourceAndroidNotificationSound(_sonidoAlarma),
            fullScreenIntent: true,
            category: AndroidNotificationCategory.alarm,
            audioAttributesUsage: AudioAttributesUsage.alarm,
          )
        : AndroidNotificationDetails(
            _canalAvisos.id,
            _canalAvisos.name,
            channelDescription: _canalAvisos.description,
            icon: _icono,
            importance: Importance.high,
            priority: Priority.high,
            category: AndroidNotificationCategory.reminder,
          );
    return NotificationDetails(
      android: android,
      iOS: const DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
    );
  }
}
```

- [ ] **Step 2: Crear el doble para pruebas y ampliar el soporte**

`test/support/fake_notifications_gateway.dart`:

```dart
import 'package:app_resar_rosario/services/notifications_gateway.dart';
import 'package:timezone/timezone.dart' as tz;

/// Lo que el servicio pidió programar.
class AvisoProgramado {
  const AvisoProgramado({required this.title, required this.date, required this.isAlarm, required this.exact});

  final String title;
  final tz.TZDateTime date;
  final bool isAlarm;
  final bool exact;
}

/// Doble del sistema de notificaciones: guarda lo que se le pide en memoria.
class FakeNotificationsGateway implements NotificationsGateway {
  NotificationPermissions permissions = const NotificationPermissions(notifications: true, exactAlarms: true);
  NotificationPermissions permissionsAfterRequest = const NotificationPermissions(notifications: true, exactAlarms: true);
  bool failInitialize = false;
  bool failSchedule = false;

  final Map<int, AvisoProgramado> scheduled = {};
  final List<int> cancelled = [];
  int cancelAllCalls = 0;
  int openSettingsCalls = 0;
  int requestExactAlarmsCalls = 0;

  @override
  Future<void> initialize() async {
    if (failInitialize) throw Exception('El plugin no está disponible');
  }

  @override
  Future<NotificationPermissions> checkPermissions() async => permissions;

  @override
  Future<NotificationPermissions> requestPermissions() async => permissions = permissionsAfterRequest;

  @override
  Future<void> requestExactAlarms() async {
    requestExactAlarmsCalls++;
  }

  @override
  Future<void> openSettings() async {
    openSettingsCalls++;
  }

  @override
  Future<void> scheduleWeekly({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime date,
    required bool isAlarm,
    required bool exact,
    String? payload,
  }) async {
    if (failSchedule) throw Exception('No se pudo programar');
    scheduled[id] = AvisoProgramado(title: title, date: date, isAlarm: isAlarm, exact: exact);
  }

  @override
  Future<void> cancel(int id) async {
    cancelled.add(id);
    scheduled.remove(id);
  }

  @override
  Future<void> cancelAll() async {
    cancelAllCalls++;
    scheduled.clear();
  }
}
```

En `test/support/app_harness.dart`, agregar estos imports y la función (el resto del archivo no cambia):

```dart
import 'package:timezone/timezone.dart' as tz;

import 'fake_notifications_gateway.dart';
```

```dart
/// Servicio de recordatorios con el doble del sistema. Usa las preferencias simuladas que ya estén puestas
/// (llamar antes a [preferenciasDePrueba] o a `SharedPreferences.setMockInitialValues`).
Future<NotificationService> notificacionesDePrueba(
  FakeNotificationsGateway gateway, {
  tz.TZDateTime Function()? ahora,
}) async {
  final servicio = NotificationService(
    gateway: gateway,
    now: ahora ?? () => tz.TZDateTime(tz.UTC, 2026, 11, 9, 6),
  );
  await servicio.initialize();
  return servicio;
}
```

- [ ] **Step 3: Escribir las pruebas del servicio**

`test/services/notification_service_test.dart`:

```dart
import 'dart:convert';

import 'package:app_resar_rosario/models/reminder_model.dart';
import 'package:app_resar_rosario/services/notification_service.dart';
import 'package:app_resar_rosario/services/notifications_gateway.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../support/fake_notifications_gateway.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late tz.Location mx;
  late FakeNotificationsGateway gateway;
  late NotificationService servicio;

  tz.TZDateTime lunes6am() => tz.TZDateTime(mx, 2026, 11, 9, 6);

  RosarioReminder borrador({List<int> dias = const [1, 3], ReminderType tipo = ReminderType.notification}) {
    return RosarioReminder(
      id: 0,
      title: 'Rosario',
      description: 'Es hora de tu oración',
      time: const TimeOfDay(hour: 7, minute: 0),
      daysOfWeek: dias,
      isActive: true,
      type: tipo,
      createdAt: DateTime(2026, 11, 1),
    );
  }

  Future<void> iniciar({Map<String, Object> guardado = const {}}) async {
    SharedPreferences.setMockInitialValues(guardado);
    servicio = NotificationService(gateway: gateway, now: lunes6am);
    await servicio.initialize();
  }

  setUpAll(() {
    tzdata.initializeTimeZones();
    mx = tz.getLocation('America/Mexico_City');
  });

  setUp(() => gateway = FakeNotificationsGateway());

  test('agregar asigna el ID 1, guarda y programa un aviso por día', () async {
    await iniciar();
    final resultado = await servicio.addReminder(borrador());

    expect(resultado.ok, isTrue);
    expect(servicio.reminders.single.id, 1);
    expect(gateway.scheduled.keys, unorderedEquals([11, 13]));
    expect(gateway.scheduled[11]!.date, tz.TZDateTime(mx, 2026, 11, 9, 7));
    expect(gateway.scheduled[13]!.date, tz.TZDateTime(mx, 2026, 11, 11, 7));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList(NotificationService.storageKey), hasLength(1));
  });

  test('la alarma usa el canal de alarma', () async {
    await iniciar();
    await servicio.addReminder(borrador(tipo: ReminderType.alarm));
    expect(gateway.scheduled.values.every((a) => a.isAlarm), isTrue);
  });

  test('sin permiso de alarmas exactas programa en modo inexacto', () async {
    gateway.permissions = const NotificationPermissions(notifications: true, exactAlarms: false);
    await iniciar();
    await servicio.addReminder(borrador());
    expect(gateway.scheduled.values.every((a) => !a.exact), isTrue);
  });

  test('al conceder permisos se reprograma en modo exacto', () async {
    gateway
      ..permissions = const NotificationPermissions(notifications: true, exactAlarms: false)
      ..permissionsAfterRequest = const NotificationPermissions(notifications: true, exactAlarms: true);
    await iniciar();
    await servicio.addReminder(borrador());
    await servicio.requestPermissions();
    expect(servicio.permissions.exactAlarms, isTrue);
    expect(gateway.scheduled.values.every((a) => a.exact), isTrue);
  });

  test('editar cancela los 7 días anteriores y programa los nuevos', () async {
    await iniciar();
    await servicio.addReminder(borrador(dias: [1, 3]));
    await servicio.updateReminder(servicio.reminders.single.copyWith(daysOfWeek: [5]));
    expect(gateway.cancelled, containsAll([11, 12, 13, 14, 15, 16, 17]));
    expect(gateway.scheduled.keys, [15]);
  });

  test('desactivar cancela sin volver a programar', () async {
    await iniciar();
    await servicio.addReminder(borrador());
    await servicio.toggleReminder(1);
    expect(servicio.reminders.single.isActive, isFalse);
    expect(gateway.scheduled, isEmpty);
  });

  test('eliminar cancela y borra', () async {
    await iniciar();
    await servicio.addReminder(borrador());
    await servicio.removeReminder(1);
    expect(servicio.reminders, isEmpty);
    expect(gateway.scheduled, isEmpty);
  });

  test('si no se puede programar lo dice, pero conserva el recordatorio', () async {
    await iniciar();
    gateway.failSchedule = true;
    final resultado = await servicio.addReminder(borrador());
    expect(resultado.ok, isFalse);
    expect(resultado.message, contains('no se pudo programar'));
    expect(servicio.reminders, hasLength(1));
  });

  test('al iniciar migra IDs antiguos y el tipo "ambos", y descarta registros dañados', () async {
    Map<String, Object> registro(int id, int tipo) => {
          'id': id,
          'title': 'R$id',
          'description': 'd',
          'hour': 7,
          'minute': 0,
          'daysOfWeek': [1],
          'isActive': true,
          'type': tipo,
          'createdAt': '2026-11-01T00:00:00.000',
        };
    await iniciar(guardado: {
      NotificationService.storageKey: [
        jsonEncode(registro(1500000, 2)),
        'esto-no-es-json',
        jsonEncode(registro(2000000, 0)),
      ],
    });

    expect(servicio.reminders.map((r) => r.id), [1, 2]);
    expect(servicio.reminders.first.type, ReminderType.alarm);
    expect(gateway.cancelAllCalls, 1);
    expect(gateway.scheduled.keys, unorderedEquals([11, 21]));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList(NotificationService.storageKey), hasLength(2));
  });

  test('si el plugin no inicia, queda no disponible con un mensaje', () async {
    gateway.failInitialize = true;
    await iniciar();
    expect(servicio.isAvailable, isFalse);
    expect(servicio.initError, isNotNull);
  });

  test('pedir alarmas exactas vuelve a revisar los permisos', () async {
    await iniciar();
    await servicio.requestExactAlarms();
    expect(gateway.requestExactAlarmsCalls, 1);
  });
}
```

- [ ] **Step 4: Correr y ver que falla**

Run: `flutter test test/services/notification_service_test.dart`
Expected: FAIL de compilación — `No named parameter with the name 'gateway'`.

- [ ] **Step 5: Reescribir el servicio**

`lib/services/notification_service.dart` (reemplazo completo):

```dart
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../models/reminder_model.dart';
import 'notifications_gateway.dart';
import 'schedule_calculator.dart';

/// Resultado de una operación sobre recordatorios, para mostrarlo a la persona.
class ReminderResult {
  const ReminderResult.success()
      : ok = true,
        message = null;

  const ReminderResult.failure(String this.message) : ok = false;

  final bool ok;
  final String? message;
}

/// Guarda los recordatorios y los programa como avisos semanales.
class NotificationService extends ChangeNotifier {
  NotificationService({required NotificationsGateway gateway, tz.TZDateTime Function()? now})
      : _gateway = gateway,
        _now = now ?? (() => tz.TZDateTime.now(tz.local));

  static const String storageKey = 'rosario_reminders';
  static const String _errorGuardar = 'No se pudo guardar el recordatorio. Intenta de nuevo.';
  static const String _errorProgramar = 'El recordatorio se guardó, pero no se pudo programar el aviso.';
  static const String _errorNoExiste = 'Ese recordatorio ya no existe.';

  final NotificationsGateway _gateway;
  final tz.TZDateTime Function() _now;

  List<RosarioReminder> _reminders = const [];
  NotificationPermissions _permissions = NotificationPermissions.none;
  bool _isAvailable = false;
  String? _initError;

  List<RosarioReminder> get reminders => List.unmodifiable(_reminders);
  NotificationPermissions get permissions => _permissions;
  bool get isAvailable => _isAvailable;
  String? get initError => _initError;

  /// Prepara el plugin, carga lo guardado y reprograma. Nunca lanza: si algo falla, queda "no disponible".
  Future<void> initialize() async {
    try {
      await _gateway.initialize();
      _isAvailable = true;
    } catch (e) {
      _initError = 'Las notificaciones no están disponibles en este dispositivo.';
      debugPrint('$_initError Detalle: $e');
    }
    await _load();
    if (_isAvailable) {
      _permissions = await _gateway.checkPermissions();
      await _rescheduleAll();
    }
    notifyListeners();
  }

  Future<NotificationPermissions> requestPermissions() async {
    if (!_isAvailable) return _permissions;
    _permissions = await _gateway.requestPermissions();
    await _rescheduleAll();
    notifyListeners();
    return _permissions;
  }

  Future<void> requestExactAlarms() async {
    if (!_isAvailable) return;
    await _gateway.requestExactAlarms();
    await refreshPermissions();
  }

  /// Se llama al volver a la app (por ejemplo, desde los ajustes del sistema).
  Future<void> refreshPermissions() async {
    if (!_isAvailable) return;
    final antes = _permissions;
    _permissions = await _gateway.checkPermissions();
    if (antes.exactAlarms != _permissions.exactAlarms || antes.notifications != _permissions.notifications) {
      await _rescheduleAll();
    }
    notifyListeners();
  }

  Future<void> openSettings() => _gateway.openSettings();

  Future<ReminderResult> addReminder(RosarioReminder draft) {
    final creado = draft.copyWith(id: nextReminderId(_reminders.map((r) => r.id)));
    return _apply([..._reminders, creado], () async {
      if (creado.isActive) await _schedule(creado);
    });
  }

  Future<ReminderResult> updateReminder(RosarioReminder updated) async {
    final indice = _reminders.indexWhere((r) => r.id == updated.id);
    if (indice == -1) return const ReminderResult.failure(_errorNoExiste);
    final anterior = _reminders[indice];
    return _apply([..._reminders]..[indice] = updated, () async {
      await _cancel(anterior);
      if (updated.isActive) await _schedule(updated);
    });
  }

  Future<ReminderResult> removeReminder(int id) async {
    final indice = _reminders.indexWhere((r) => r.id == id);
    if (indice == -1) return const ReminderResult.failure(_errorNoExiste);
    final eliminado = _reminders[indice];
    return _apply([..._reminders]..removeAt(indice), () => _cancel(eliminado));
  }

  Future<ReminderResult> toggleReminder(int id) async {
    final indice = _reminders.indexWhere((r) => r.id == id);
    if (indice == -1) return const ReminderResult.failure(_errorNoExiste);
    final actual = _reminders[indice];
    return updateReminder(actual.copyWith(isActive: !actual.isActive));
  }

  /// Guarda [siguiente]; si no se puede, deja todo como estaba. Después sincroniza los avisos.
  Future<ReminderResult> _apply(List<RosarioReminder> siguiente, Future<void> Function() sincronizar) async {
    final anterior = _reminders;
    _reminders = siguiente;
    try {
      await _save();
    } catch (e) {
      _reminders = anterior;
      debugPrint('Error al guardar recordatorios: $e');
      notifyListeners();
      return const ReminderResult.failure(_errorGuardar);
    }
    notifyListeners();
    // Sin plugin no hay nada que programar; la pantalla ya avisa que no está disponible.
    if (!_isAvailable) return const ReminderResult.success();
    try {
      await sincronizar();
    } catch (e) {
      debugPrint('Error al programar avisos: $e');
      return const ReminderResult.failure(_errorProgramar);
    }
    return const ReminderResult.success();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final guardados = prefs.getStringList(storageKey) ?? const <String>[];
    final leidos = <RosarioReminder>[];
    for (final json in guardados) {
      try {
        leidos.add(RosarioReminder.fromMap(jsonDecode(json) as Map<String, dynamic>));
      } catch (e) {
        debugPrint('Recordatorio dañado descartado: $e');
      }
    }
    final renumerados = renumberIfNeeded(leidos);
    _reminders = renumerados ?? leidos;
    if (renumerados != null || leidos.length != guardados.length) {
      try {
        await _save();
      } catch (e) {
        debugPrint('No se pudo guardar la migración de recordatorios: $e');
      }
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final guardado = await prefs.setStringList(storageKey, [for (final r in _reminders) jsonEncode(r.toMap())]);
    if (!guardado) throw StateError('No se guardaron los recordatorios');
  }

  Future<void> _schedule(RosarioReminder reminder) async {
    final ahora = _now();
    for (final dia in reminder.daysOfWeek) {
      await _gateway.scheduleWeekly(
        id: notificationIdFor(reminder.id, dia),
        title: reminder.title,
        body: reminder.description,
        date: nextWeeklyDate(now: ahora, weekday: dia, hour: reminder.time.hour, minute: reminder.time.minute),
        isAlarm: reminder.type == ReminderType.alarm,
        exact: _permissions.exactAlarms,
        payload: 'reminder_${reminder.id}',
      );
    }
  }

  /// Cancela los 7 días posibles: cubre los días que se quitaron al editar.
  Future<void> _cancel(RosarioReminder reminder) async {
    for (var dia = DateTime.monday; dia <= DateTime.sunday; dia++) {
      await _gateway.cancel(notificationIdFor(reminder.id, dia));
    }
  }

  Future<void> _rescheduleAll() async {
    try {
      await _gateway.cancelAll();
      for (final reminder in _reminders.where((r) => r.isActive)) {
        await _schedule(reminder);
      }
    } catch (e) {
      debugPrint('Error al reprogramar recordatorios: $e');
    }
  }
}
```

- [ ] **Step 6: Correr y ver que pasa**

Run: `flutter test test/services/notification_service_test.dart`
Expected: `All tests passed!`

- [ ] **Step 7: Recursos de Android: ícono monocromático y lista de recursos que R8 no debe borrar**

`android/app/src/main/res/drawable/ic_notification.xml` (cruz latina blanca; Android pinta en blanco el ícono pequeño, por eso el ícono a color se veía como un cuadro):

```xml
<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
    <path
        android:fillColor="#FFFFFFFF"
        android:pathData="M10.5,2h3v5h5v3h-5v12h-3V10h-5V7h5z" />
</vector>
```

`android/app/src/main/res/raw/keep.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources xmlns:tools="http://schemas.android.com/tools"
    tools:keep="@drawable/ic_notification,@raw/alarm_sound,@mipmap/launcher_icon" />
```

- [ ] **Step 8: Quitar `permission_handler`, conectar en `main.dart` y ajustar la prueba de arranque**

En `pubspec.yaml`, borrar estas dos líneas:

```yaml
  # Se elimina en la Tarea 14, cuando el servicio de notificaciones deje de usarlo.
  permission_handler: ^13.0.2
```

En `lib/main.dart`, agregar `import 'services/notifications_gateway.dart';` y reemplazar:

```dart
// ANTES
  final notificaciones = NotificationService();
  try {
    await notificaciones.initialize();
    if (notificaciones.isInitialized) {
      await notificaciones.cleanInvalidReminders();
    }
  } catch (e) {
    debugPrint('Error al inicializar las notificaciones: $e');
  }
// DESPUÉS
  final notificaciones = NotificationService(gateway: FlutterNotificationsGateway());
  await notificaciones.initialize(); // nunca lanza: si algo falla queda "no disponible"
```

En `test/widget_test.dart`, agregar `import 'support/fake_notifications_gateway.dart';` y reemplazar `ChangeNotifierProvider(create: (_) => NotificationService()),` por:

```dart
          ChangeNotifierProvider(create: (_) => NotificationService(gateway: FakeNotificationsGateway())),
```

Run: `flutter pub get && grep -rn "permission_handler" lib pubspec.yaml`
Expected: `Got dependencies!` y sin coincidencias.

- [ ] **Step 9: Verificar y hacer commit**

Run: `flutter analyze && flutter test && flutter build apk --debug`
Expected: sin errores ni advertencias; `All tests passed!`; APK compila (incluye `ic_notification` y `keep.xml`).

```bash
git add lib/services lib/main.dart pubspec.yaml pubspec.lock android/app/src/main/res test
git commit -m "feat: servicio de recordatorios con alarma real y errores visibles" -m "Interfaz NotificationsGateway para probar sin dispositivo. Alarma con sonido propio en un canal nuevo, ícono monocromático, alarma inexacta si no hay permiso exacto, migración de datos antiguos y resultados para mostrar al usuario (E5, E6, E7, E13). Sin permission_handler." -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 15: Estructura final de la app: menú único con Configuración, español y escalado único (E2, E4, E9)

**Files:**
- Create: `lib/app.dart`
- Create: `lib/screens/configuracion_screen.dart`
- Rewrite: `lib/widgets/app_drawer.dart`
- Rewrite: `lib/main.dart`
- Delete: `lib/widgets/settings_drawer.dart`, `test/widget_test.dart`
- Rewrite: `test/support/app_harness.dart`
- Create: `test/app_test.dart`, `test/screens/configuracion_screen_test.dart`

**Interfaces:**
- Consumes: `PreferencesService` (Task 6); `RosarioSession` (Task 8); `AppTheme` (Task 9); `PrincipalScreen`, `InicioScreen` (Task 11); `NotificationService`, `FlutterNotificationsGateway` (Task 14); `configurarZonaHoraria` (Task 12).
- Produces:
  - `class SantoRosarioApp extends StatelessWidget` (`const SantoRosarioApp({required PreferencesService preferencias, required NotificationService notificaciones, DateTime Function()? reloj})`).
  - `class ConfiguracionScreen` (`const`).
  - `AppDrawer` con 4 opciones: "Misterios del día", "Agendar Rosario", "Configuración", "Acerca de"; `void mostrarAcercaDe(BuildContext context, {String? version})`; `void abrirDesdeMenu(BuildContext, WidgetBuilder)`.
  - Harness: `Future<({PreferencesService preferencias, NotificationService notificaciones, FakeNotificationsGateway gateway})> dependenciasDePrueba({Map<String, Object> preferencias})`, `Future<Widget> appDePrueba({Map<String, Object> preferencias})`.

- [ ] **Step 1: Ampliar el soporte de pruebas**

`test/support/app_harness.dart` (reemplazo completo):

```dart
import 'package:app_resar_rosario/app.dart';
import 'package:app_resar_rosario/logic/rosario_session.dart';
import 'package:app_resar_rosario/services/notification_service.dart';
import 'package:app_resar_rosario/services/preferences_service.dart';
import 'package:app_resar_rosario/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import 'fake_notifications_gateway.dart';

/// Lunes 9 de noviembre de 2026, 8:00: tocan los misterios Gozosos.
final DateTime lunes = DateTime(2026, 11, 9, 8);

/// Preferencias de prueba, vacías o con [valores] ya guardados.
Future<PreferencesService> preferenciasDePrueba([Map<String, Object> valores = const {}]) async {
  SharedPreferences.setMockInitialValues(valores);
  return PreferencesService(await SharedPreferences.getInstance());
}

/// Servicio de recordatorios con el doble del sistema. Usa las preferencias simuladas que ya estén puestas.
Future<NotificationService> notificacionesDePrueba(
  FakeNotificationsGateway gateway, {
  tz.TZDateTime Function()? ahora,
}) async {
  final servicio = NotificationService(
    gateway: gateway,
    now: ahora ?? () => tz.TZDateTime(tz.UTC, 2026, 11, 9, 6),
  );
  await servicio.initialize();
  return servicio;
}

/// Todo lo que necesita la app completa, con dobles.
Future<({PreferencesService preferencias, NotificationService notificaciones, FakeNotificationsGateway gateway})>
    dependenciasDePrueba({Map<String, Object> preferencias = const {}}) async {
  final prefs = await preferenciasDePrueba(preferencias);
  final gateway = FakeNotificationsGateway();
  return (preferencias: prefs, notificaciones: await notificacionesDePrueba(gateway), gateway: gateway);
}

/// La app completa, lista para `pumpWidget`.
Future<Widget> appDePrueba({Map<String, Object> preferencias = const {}}) async {
  final d = await dependenciasDePrueba(preferencias: preferencias);
  return SantoRosarioApp(preferencias: d.preferencias, notificaciones: d.notificaciones, reloj: () => lunes);
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

`test/app_test.dart`:

```dart
import 'package:app_resar_rosario/app.dart';
import 'package:app_resar_rosario/screens/configuracion_screen.dart';
import 'package:app_resar_rosario/screens/inicio_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/app_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('arranca en la pantalla de inicio, en español (E9)', (tester) async {
    await tester.pumpWidget(await appDePrueba());
    await tester.pumpAndSettle();

    expect(find.text('Comenzar a Rezar'), findsOneWidget);
    final contexto = tester.element(find.byType(InicioScreen));
    expect(Localizations.localeOf(contexto).languageCode, 'es');
    expect(MaterialLocalizations.of(contexto).cancelButtonLabel, 'Cancelar');
  });

  testWidgets('el tamaño de texto se aplica una sola vez (E4)', (tester) async {
    final d = await dependenciasDePrueba(preferencias: {'pref_text_scale': 1.5});
    await tester.pumpWidget(SantoRosarioApp(preferencias: d.preferencias, notificaciones: d.notificaciones, reloj: () => lunes));
    await tester.pumpAndSettle();

    final contexto = tester.element(find.byType(InicioScreen));
    expect(MediaQuery.textScalerOf(contexto).scale(10), closeTo(15, 0.01));
    expect(Theme.of(contexto).textTheme.bodyLarge!.fontSize, 16);
  });

  testWidgets('el menú lateral abre Configuración (E2)', (tester) async {
    await tester.pumpWidget(await appDePrueba());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Configuración'));
    await tester.pumpAndSettle();

    expect(find.byType(ConfiguracionScreen), findsOneWidget);
    expect(find.text('Tamaño del texto'), findsOneWidget);
  });

  testWidgets('activar botones grandes cambia el tema de toda la app', (tester) async {
    await tester.pumpWidget(await appDePrueba(preferencias: {'pref_large_buttons': true}));
    await tester.pumpAndSettle();

    final contexto = tester.element(find.byType(InicioScreen));
    final alto = Theme.of(contexto).filledButtonTheme.style!.minimumSize!.resolve(<WidgetState>{})!.height;
    expect(alto, 64);
  });
}
```

`test/screens/configuracion_screen_test.dart`:

```dart
import 'package:app_resar_rosario/screens/configuracion_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('cambiar tema, contraste y botones se refleja en las preferencias', (tester) async {
    final preferencias = await preferenciasDePrueba();
    await tester.pumpWidget(envolver(const ConfiguracionScreen(), preferencias: preferencias));

    await tester.tap(find.text('Alto contraste'));
    await tester.tap(find.text('Botones grandes'));
    await tester.pump();
    await tester.scrollUntilVisible(find.text('Oscuro'), 200);
    await tester.tap(find.text('Oscuro'));
    await tester.pump();

    expect(preferencias.useHighContrast, isTrue);
    expect(preferencias.useLargeButtons, isTrue);
    expect(preferencias.themeMode, ThemeMode.dark);
  });

  testWidgets('restablecer pide confirmación y vuelve a los valores por defecto', (tester) async {
    final preferencias = await preferenciasDePrueba({'pref_large_buttons': true});
    await tester.pumpWidget(envolver(const ConfiguracionScreen(), preferencias: preferencias));

    await tester.scrollUntilVisible(find.text('Restablecer configuración'), 200);
    await tester.tap(find.text('Restablecer configuración'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Restablecer'));
    await tester.pumpAndSettle();

    expect(preferencias.useLargeButtons, isFalse);
    expect(find.text('Configuración restablecida'), findsOneWidget);
  });
}
```

- [ ] **Step 3: Correr y ver que falla**

Run: `flutter test test/app_test.dart test/screens/configuracion_screen_test.dart`
Expected: FAIL de compilación — `Target of URI doesn't exist: 'package:app_resar_rosario/app.dart'`.

- [ ] **Step 4: Escribir la app**

`lib/app.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'logic/rosario_session.dart';
import 'screens/principal_screen.dart';
import 'services/notification_service.dart';
import 'services/preferences_service.dart';
import 'theme/app_theme.dart';

/// Raíz de la app: proveedores, temas, idioma y escalado de texto.
class SantoRosarioApp extends StatelessWidget {
  const SantoRosarioApp({super.key, required this.preferencias, required this.notificaciones, this.reloj});

  final PreferencesService preferencias;
  final NotificationService notificaciones;

  /// Reloj para pruebas; en la app es `DateTime.now`.
  final DateTime Function()? reloj;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<PreferencesService>.value(value: preferencias),
        ChangeNotifierProvider<NotificationService>.value(value: notificaciones),
        ChangeNotifierProvider<RosarioSession>(create: (_) => RosarioSession(reloj: reloj)),
      ],
      child: Consumer<PreferencesService>(
        builder: (context, prefs, _) => MaterialApp(
          title: 'Santo Rosario',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.claro(altoContraste: prefs.useHighContrast, botonesGrandes: prefs.useLargeButtons),
          darkTheme: AppTheme.oscuro(altoContraste: prefs.useHighContrast, botonesGrandes: prefs.useLargeButtons),
          themeMode: prefs.themeMode,
          locale: const Locale('es', 'MX'),
          supportedLocales: const [Locale('es', 'MX'), Locale('es')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          builder: (context, child) {
            // El tamaño elegido en la app se suma al del sistema, una sola vez.
            final sistema = MediaQuery.textScalerOf(context).scale(16) / 16;
            final escala = (sistema * prefs.textScaleFactor).clamp(0.8, 3.0);
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(escala)),
              child: child!,
            );
          },
          home: const PrincipalScreen(),
        ),
      ),
    );
  }
}
```

`lib/main.dart` (reemplazo completo):

```dart
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'services/notification_service.dart';
import 'services/notifications_gateway.dart';
import 'services/preferences_service.dart';
import 'services/zona_horaria.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configurarZonaHoraria();

  final preferencias = PreferencesService(await SharedPreferences.getInstance());
  final notificaciones = NotificationService(gateway: FlutterNotificationsGateway());
  await notificaciones.initialize(); // nunca lanza: si algo falla queda "no disponible"

  runApp(SantoRosarioApp(preferencias: preferencias, notificaciones: notificaciones));
}
```

- [ ] **Step 5: Escribir la pantalla de Configuración**

`lib/screens/configuracion_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/preferences_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

/// Accesibilidad y apariencia.
class ConfiguracionScreen extends StatelessWidget {
  const ConfiguracionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<PreferencesService>();
    final porcentaje = '${(prefs.textScaleFactor * 100).round()} %';

    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppTokens.espacioM),
        children: [
          const _Titulo('Accesibilidad'),
          ListTile(
            leading: const Icon(Icons.text_fields),
            title: const Text('Tamaño del texto'),
            trailing: Text(porcentaje),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.espacioS),
            child: Slider(
              value: prefs.textScaleFactor,
              min: PreferencesService.minTextScale,
              max: PreferencesService.maxTextScale,
              divisions: 12,
              label: porcentaje,
              semanticFormatterCallback: (v) => '${(v * 100).round()} por ciento',
              onChanged: prefs.updateTextScaleFactor,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.espacioM),
            child: Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(AppTokens.espacioM),
                child: Text('Padre nuestro, que estás en el cielo…', style: AppTheme.oracion(context)),
              ),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.contrast),
            title: const Text('Alto contraste'),
            subtitle: const Text('Colores más marcados para leer mejor'),
            value: prefs.useHighContrast,
            onChanged: (_) => prefs.toggleHighContrast(),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.touch_app_outlined),
            title: const Text('Botones grandes'),
            subtitle: const Text('Facilita tocar los botones'),
            value: prefs.useLargeButtons,
            onChanged: (_) => prefs.toggleLargeButtons(),
          ),
          const Divider(height: AppTokens.espacioXL),
          const _Titulo('Apariencia'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.espacioM),
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(value: ThemeMode.system, label: Text('Sistema'), icon: Icon(Icons.brightness_auto)),
                ButtonSegment(value: ThemeMode.light, label: Text('Claro'), icon: Icon(Icons.light_mode)),
                ButtonSegment(value: ThemeMode.dark, label: Text('Oscuro'), icon: Icon(Icons.dark_mode)),
              ],
              selected: {prefs.themeMode},
              onSelectionChanged: (seleccion) => prefs.updateThemeMode(seleccion.first),
            ),
          ),
          const Divider(height: AppTokens.espacioXL),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('Restablecer configuración'),
            onTap: () => _confirmarRestablecer(context, prefs),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarRestablecer(BuildContext context, PreferencesService prefs) async {
    final mensajero = ScaffoldMessenger.of(context);
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: const Text('¿Restablecer configuración?'),
        content: const Text('El tamaño del texto, el contraste, los botones y el tema vuelven a sus valores iniciales.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogo, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(dialogo, true), child: const Text('Restablecer')),
        ],
      ),
    );
    if (confirmado ?? false) {
      prefs.resetToDefaults();
      mensajero.showSnackBar(const SnackBar(content: Text('Configuración restablecida')));
    }
  }
}

class _Titulo extends StatelessWidget {
  const _Titulo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTokens.espacioM, AppTokens.espacioS, AppTokens.espacioM, AppTokens.espacioS),
      child: Text(
        texto,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}
```

- [ ] **Step 6: Completar el menú lateral**

`lib/widgets/app_drawer.dart` (reemplazo completo):

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/rosario_session.dart';
import '../screens/agendar_rosario_screen.dart';
import '../screens/configuracion_screen.dart';
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
                    showDialog<void>(context: context, builder: (_) => MisteriosDelDiaDialog(tipo: tipo, dia: dia));
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
                ListTile(
                  leading: const Icon(Icons.tune),
                  title: const Text('Configuración'),
                  subtitle: const Text('Texto, contraste y tema'),
                  onTap: () => abrirDesdeMenu(context, (_) => const ConfiguracionScreen()),
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Acerca de'),
                  onTap: () {
                    Navigator.pop(context);
                    mostrarAcercaDe(context);
                  },
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

void mostrarAcercaDe(BuildContext context, {String? version}) {
  showAboutDialog(
    context: context,
    applicationName: 'Santo Rosario',
    applicationVersion: version,
    applicationIcon: Image.asset('assets/icons/icono-rosario.png', width: 48, height: 48),
    children: const [
      Text('Una aplicación para rezar el Santo Rosario de manera guiada.'),
      SizedBox(height: AppTokens.espacioM),
      Text('Desarrollada con amor y devoción.'),
    ],
  );
}
```

- [ ] **Step 7: Borrar lo que queda de la estructura anterior**

Run:

```bash
git rm -q lib/widgets/settings_drawer.dart test/widget_test.dart
grep -rn "SettingsDrawer\|MainScreen\|MyApp" lib test
```

Expected: sin coincidencias.

- [ ] **Step 8: Correr y ver que pasa**

Run: `flutter test`
Expected: `All tests passed!`

- [ ] **Step 9: Commit**

Run: `flutter analyze && flutter build apk --debug` → sin errores ni advertencias; APK compila.

```bash
git add lib test
git commit -m "feat: menú único con Configuración, interfaz en español y escalado de texto único" -m "SantoRosarioApp arma proveedores, temas e idioma es-MX. Se eliminan los dos menús anidados que tapaban la Configuración (E2), el escalado doble (E4) y los diálogos en inglés (E9)." -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 16: Pantalla de recordatorios y formulario (E10, E13)

**Files:**
- Rewrite: `lib/screens/agendar_rosario_screen.dart`
- Rewrite: `lib/widgets/reminder_form.dart`
- Modify: `lib/widgets/app_drawer.dart` (la pantalla ya no recibe `preferences`)
- Create: `test/widgets/reminder_form_test.dart`, `test/screens/agendar_rosario_screen_test.dart`

**Interfaces:**
- Consumes: `NotificationService`, `ReminderResult`, `NotificationPermissions` (Task 14); `RosarioReminder`, `ReminderType` (Task 13); `AppTokens` (Task 9); harness `envolver`, `preferenciasDePrueba`, `notificacionesDePrueba` (Tasks 10, 14).
- Produces:
  - `class AgendarRosarioScreen` (`const AgendarRosarioScreen()`, sin parámetros).
  - `class ReminderForm` (`const ReminderForm({RosarioReminder? reminder, required ValueChanged<RosarioReminder> onSave})`). Textos: título "Nuevo recordatorio" / "Editar recordatorio", campo "Título", "Hora", "Repetir", chips L M X J V S D, "Tipo", botones "Cancelar" y "Guardar"; errores "Escribe un título" y "Elige al menos un día". El padding del teclado lo aplica **solo** el formulario.

- [ ] **Step 1: Escribir las pruebas del formulario**

`test/widgets/reminder_form_test.dart`:

```dart
import 'package:app_resar_rosario/models/reminder_model.dart';
import 'package:app_resar_rosario/theme/app_theme.dart';
import 'package:app_resar_rosario/widgets/reminder_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<List<RosarioReminder>> mostrar(WidgetTester tester, {RosarioReminder? recordatorio}) async {
    final guardados = <RosarioReminder>[];
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.claro(),
      home: Scaffold(body: ReminderForm(reminder: recordatorio, onSave: guardados.add)),
    ));
    return guardados;
  }

  Future<void> guardar(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Guardar'));
    await tester.tap(find.text('Guardar'));
    await tester.pump();
  }

  testWidgets('sin días no guarda y lo indica', (tester) async {
    final guardados = await mostrar(tester);
    await guardar(tester);
    expect(find.text('Elige al menos un día'), findsOneWidget);
    expect(guardados, isEmpty);
  });

  testWidgets('sin título no guarda y lo indica', (tester) async {
    final guardados = await mostrar(tester);
    await tester.enterText(find.byType(TextFormField), '   ');
    await tester.tap(find.text('L'));
    await guardar(tester);
    expect(find.text('Escribe un título'), findsOneWidget);
    expect(guardados, isEmpty);
  });

  testWidgets('guarda con los días y el tipo elegidos', (tester) async {
    final guardados = await mostrar(tester);
    await tester.tap(find.text('L'));
    await tester.tap(find.text('X'));
    await tester.tap(find.text('Alarma'));
    await guardar(tester);

    final r = guardados.single;
    expect(r.title, 'Rezar el Santo Rosario');
    expect(r.daysOfWeek, [1, 3]);
    expect(r.type, ReminderType.alarm);
    expect(r.time, const TimeOfDay(hour: 19, minute: 0));
    expect(r.isActive, isTrue);
  });

  testWidgets('al editar conserva el ID y los datos', (tester) async {
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
    final guardados = await mostrar(tester, recordatorio: existente);
    expect(find.text('Editar recordatorio'), findsOneWidget);
    await guardar(tester);

    final r = guardados.single;
    expect([r.id, r.title, r.daysOfWeek, r.isActive], [5, 'Mañana', [2], false]);
  });
}
```

- [ ] **Step 2: Escribir las pruebas de la pantalla**

`test/screens/agendar_rosario_screen_test.dart`:

```dart
import 'package:app_resar_rosario/screens/agendar_rosario_screen.dart';
import 'package:app_resar_rosario/services/notifications_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';
import '../support/fake_notifications_gateway.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<FakeNotificationsGateway> mostrar(WidgetTester tester, {FakeNotificationsGateway? gateway}) async {
    final preferencias = await preferenciasDePrueba();
    final g = gateway ?? FakeNotificationsGateway();
    final notificaciones = await notificacionesDePrueba(g);
    await tester.pumpWidget(envolver(
      const AgendarRosarioScreen(),
      preferencias: preferencias,
      notificaciones: notificaciones,
    ));
    await tester.pumpAndSettle();
    return g;
  }

  Future<void> crearRecordatorioDelLunes(WidgetTester tester) async {
    await tester.tap(find.text('Nuevo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('L'));
    await tester.ensureVisible(find.text('Guardar'));
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
  }

  testWidgets('sin recordatorios muestra el estado vacío', (tester) async {
    await mostrar(tester);
    expect(find.text('No hay recordatorios'), findsOneWidget);
  });

  testWidgets('crear un recordatorio lo muestra y lo programa', (tester) async {
    final gateway = await mostrar(tester);
    await crearRecordatorioDelLunes(tester);
    expect(find.text('Rezar el Santo Rosario'), findsOneWidget);
    expect(gateway.scheduled.keys, [11]);
  });

  testWidgets('si no se puede programar, lo dice', (tester) async {
    final gateway = await mostrar(tester);
    gateway.failSchedule = true;
    await crearRecordatorioDelLunes(tester);
    expect(find.textContaining('no se pudo programar'), findsOneWidget);
  });

  testWidgets('sin permiso de notificaciones lo avisa y ofrece abrir los ajustes', (tester) async {
    final gateway = FakeNotificationsGateway()
      ..permissions = NotificationPermissions.none
      ..permissionsAfterRequest = NotificationPermissions.none;
    await mostrar(tester, gateway: gateway);

    expect(find.textContaining('notificaciones están desactivadas'), findsOneWidget);
    await tester.tap(find.text('Permitir notificaciones'));
    await tester.pumpAndSettle();
    expect(gateway.openSettingsCalls, 1);
  });

  testWidgets('sin alarmas exactas ofrece permitirlas', (tester) async {
    final gateway = FakeNotificationsGateway()
      ..permissions = const NotificationPermissions(notifications: true, exactAlarms: false);
    await mostrar(tester, gateway: gateway);

    await tester.tap(find.text('Permitir'));
    await tester.pumpAndSettle();
    expect(gateway.requestExactAlarmsCalls, 1);
  });
}
```

- [ ] **Step 3: Correr y ver que falla**

Run: `flutter test test/widgets/reminder_form_test.dart test/screens/agendar_rosario_screen_test.dart`
Expected: FAIL — `AgendarRosarioScreen` exige `preferences` y el formulario no tiene los textos nuevos.

- [ ] **Step 4: Reescribir el formulario**

`lib/widgets/reminder_form.dart` (reemplazo completo):

```dart
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

/// Formulario para crear o editar un recordatorio. Se muestra en una hoja inferior.
class ReminderForm extends StatefulWidget {
  const ReminderForm({super.key, this.reminder, required this.onSave});

  final RosarioReminder? reminder;
  final ValueChanged<RosarioReminder> onSave;

  @override
  State<ReminderForm> createState() => _ReminderFormState();
}

class _ReminderFormState extends State<ReminderForm> {
  final _formulario = GlobalKey<FormState>();
  late final TextEditingController _titulo =
      TextEditingController(text: widget.reminder?.title ?? 'Rezar el Santo Rosario');
  late TimeOfDay _hora = widget.reminder?.time ?? const TimeOfDay(hour: 19, minute: 0);
  late final Set<int> _dias = {...?widget.reminder?.daysOfWeek};
  late ReminderType _tipo = widget.reminder?.type ?? ReminderType.notification;
  late String _descripcion = widget.reminder?.description ?? 'Es hora de tu oración. El Señor está contigo.';
  bool _faltanDias = false;

  @override
  void dispose() {
    _titulo.dispose();
    super.dispose();
  }

  Future<void> _elegirHora() async {
    final hora = await showTimePicker(context: context, initialTime: _hora);
    if (hora != null) setState(() => _hora = hora);
  }

  void _guardar() {
    final valido = _formulario.currentState!.validate();
    setState(() => _faltanDias = _dias.isEmpty);
    if (!valido || _dias.isEmpty) {
      HapticFeedback.heavyImpact();
      return;
    }
    widget.onSave(RosarioReminder(
      id: widget.reminder?.id ?? 0,
      title: _titulo.text.trim(),
      description: _descripcion,
      time: _hora,
      daysOfWeek: _dias.toList()..sort(),
      isActive: widget.reminder?.isActive ?? true,
      type: _tipo,
      createdAt: widget.reminder?.createdAt ?? DateTime.now(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final esquema = Theme.of(context).colorScheme;

    return Padding(
      // El espacio del teclado se aplica una sola vez, aquí (E10).
      padding: EdgeInsets.only(
        left: AppTokens.espacioL,
        right: AppTokens.espacioL,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppTokens.espacioL,
      ),
      child: Form(
        key: _formulario,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.reminder == null ? 'Nuevo recordatorio' : 'Editar recordatorio', style: textos.titleLarge),
              const SizedBox(height: AppTokens.espacioL),
              TextFormField(
                controller: _titulo,
                maxLength: 50,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Título',
                  prefixIcon: Icon(Icons.edit_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Escribe un título' : null,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.access_time),
                title: const Text('Hora'),
                subtitle: Text(_hora.format(context), style: textos.titleMedium),
                trailing: const Icon(Icons.edit_outlined),
                onTap: _elegirHora,
              ),
              const SizedBox(height: AppTokens.espacioS),
              Text('Repetir', style: textos.titleSmall),
              const SizedBox(height: AppTokens.espacioS),
              Wrap(
                spacing: AppTokens.espacioS,
                runSpacing: AppTokens.espacioS,
                children: [
                  for (final (dia, letra, nombre) in _diasSemana)
                    FilterChip(
                      label: Text(letra),
                      tooltip: nombre,
                      selected: _dias.contains(dia),
                      onSelected: (marcado) => setState(() {
                        marcado ? _dias.add(dia) : _dias.remove(dia);
                        _faltanDias = false;
                      }),
                    ),
                ],
              ),
              if (_faltanDias) ...[
                const SizedBox(height: AppTokens.espacioS),
                Text('Elige al menos un día', style: textos.bodySmall?.copyWith(color: esquema.error)),
              ],
              const SizedBox(height: AppTokens.espacioL),
              Text('Tipo', style: textos.titleSmall),
              const SizedBox(height: AppTokens.espacioS),
              SegmentedButton<ReminderType>(
                segments: [
                  for (final tipo in ReminderType.values)
                    ButtonSegment(value: tipo, label: Text(tipo.displayName), icon: Icon(tipo.icon)),
                ],
                selected: {_tipo},
                onSelectionChanged: (seleccion) => setState(() => _tipo = seleccion.first),
              ),
              const SizedBox(height: AppTokens.espacioS),
              Text(_tipo.description, style: textos.bodySmall),
              const SizedBox(height: AppTokens.espacioXL),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar'))),
                  const SizedBox(width: AppTokens.espacioM),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _guardar,
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Guardar'),
                    ),
                  ),
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

- [ ] **Step 5: Reescribir la pantalla de recordatorios**

`lib/screens/agendar_rosario_screen.dart` (reemplazo completo):

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/reminder_model.dart';
import '../services/notification_service.dart';
import '../theme/app_tokens.dart';
import '../widgets/reminder_form.dart';

/// Lista de recordatorios con alta, edición, activación y borrado.
class AgendarRosarioScreen extends StatefulWidget {
  const AgendarRosarioScreen({super.key});

  @override
  State<AgendarRosarioScreen> createState() => _AgendarRosarioScreenState();
}

class _AgendarRosarioScreenState extends State<AgendarRosarioScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _pedirPermisoSiFalta());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Al volver de los ajustes del sistema, se revisan los permisos.
    if (state == AppLifecycleState.resumed) {
      context.read<NotificationService>().refreshPermissions();
    }
  }

  Future<void> _pedirPermisoSiFalta() async {
    final servicio = context.read<NotificationService>();
    if (servicio.isAvailable && !servicio.permissions.notifications) {
      await servicio.requestPermissions();
    }
  }

  Future<void> _avisar(Future<ReminderResult> operacion) async {
    final mensajero = ScaffoldMessenger.of(context);
    final resultado = await operacion;
    if (!resultado.ok) {
      mensajero.showSnackBar(SnackBar(content: Text(resultado.message!)));
    }
  }

  void _abrirFormulario({RosarioReminder? recordatorio}) {
    HapticFeedback.lightImpact();
    final servicio = context.read<NotificationService>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (hoja) => ReminderForm(
        reminder: recordatorio,
        onSave: (guardado) {
          Navigator.pop(hoja);
          _avisar(recordatorio == null ? servicio.addReminder(guardado) : servicio.updateReminder(guardado));
        },
      ),
    );
  }

  Future<void> _confirmarEliminar(RosarioReminder recordatorio) async {
    final servicio = context.read<NotificationService>();
    final eliminar = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: const Text('Eliminar recordatorio'),
        content: Text('¿Quieres eliminar "${recordatorio.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogo, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(dialogo, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (eliminar ?? false) await _avisar(servicio.removeReminder(recordatorio.id));
  }

  @override
  Widget build(BuildContext context) {
    final servicio = context.watch<NotificationService>();
    final recordatorios = servicio.reminders;

    return Scaffold(
      appBar: AppBar(title: const Text('Mis recordatorios')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirFormulario,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppTokens.espacioM, AppTokens.espacioS, AppTokens.espacioM, 96),
        children: [
          _AvisoPermisos(servicio: servicio),
          if (recordatorios.isEmpty)
            const _SinRecordatorios()
          else
            for (final r in recordatorios)
              _TarjetaRecordatorio(
                recordatorio: r,
                onCambiar: () => _avisar(servicio.toggleReminder(r.id)),
                onEditar: () => _abrirFormulario(recordatorio: r),
                onEliminar: () => _confirmarEliminar(r),
              ),
        ],
      ),
    );
  }
}

class _AvisoPermisos extends StatelessWidget {
  const _AvisoPermisos({required this.servicio});

  final NotificationService servicio;

  @override
  Widget build(BuildContext context) {
    if (!servicio.isAvailable) {
      return _Aviso(
        icono: Icons.notifications_off_outlined,
        texto: servicio.initError ?? 'Las notificaciones no están disponibles.',
      );
    }
    if (!servicio.permissions.notifications) {
      return _Aviso(
        icono: Icons.notifications_off_outlined,
        texto: 'Las notificaciones están desactivadas. Sin ellas, los recordatorios no sonarán.',
        accion: 'Permitir notificaciones',
        onAccion: () async {
          final permisos = await servicio.requestPermissions();
          if (!permisos.notifications) await servicio.openSettings();
        },
      );
    }
    if (!servicio.permissions.exactAlarms) {
      return _Aviso(
        icono: Icons.schedule_outlined,
        texto: 'Los avisos pueden llegar con unos minutos de retraso. Para que suenen a la hora exacta, '
            'permite "Alarmas y recordatorios".',
        accion: 'Permitir',
        onAccion: servicio.requestExactAlarms,
      );
    }
    return const SizedBox.shrink();
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso({required this.icono, required this.texto, this.accion, this.onAccion});

  final IconData icono;
  final String texto;
  final String? accion;
  final VoidCallback? onAccion;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;
    return Card(
      color: esquema.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.espacioM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icono, color: esquema.onSecondaryContainer),
                const SizedBox(width: AppTokens.espacioM),
                Expanded(
                  child: Text(texto, style: textos.bodyMedium?.copyWith(color: esquema.onSecondaryContainer)),
                ),
              ],
            ),
            if (accion != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: onAccion, child: Text(accion!)),
              ),
          ],
        ),
      ),
    );
  }
}

class _SinRecordatorios extends StatelessWidget {
  const _SinRecordatorios();

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.espacioXL * 2, horizontal: AppTokens.espacioL),
      child: Column(
        children: [
          Icon(Icons.alarm_add, size: 80, color: esquema.onSurfaceVariant),
          const SizedBox(height: AppTokens.espacioL),
          Text('No hay recordatorios', style: textos.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: AppTokens.espacioS),
          Text(
            'Toca «Nuevo» para programar tu primer recordatorio del Santo Rosario.',
            textAlign: TextAlign.center,
            style: textos.bodyMedium?.copyWith(color: esquema.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _TarjetaRecordatorio extends StatelessWidget {
  const _TarjetaRecordatorio({
    required this.recordatorio,
    required this.onCambiar,
    required this.onEditar,
    required this.onEliminar,
  });

  final RosarioReminder recordatorio;
  final VoidCallback onCambiar;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;
    final activo = recordatorio.isActive;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: AppTokens.espacioS),
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.espacioM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(recordatorio.type.icon, color: esquema.primary),
                const SizedBox(width: AppTokens.espacioS),
                Expanded(child: Text(recordatorio.title, style: textos.titleMedium)),
                Semantics(
                  label: activo ? 'Desactivar ${recordatorio.title}' : 'Activar ${recordatorio.title}',
                  child: Switch(value: activo, onChanged: (_) => onCambiar()),
                ),
              ],
            ),
            Text(
              recordatorio.time.format(context),
              style: textos.displaySmall?.copyWith(color: activo ? esquema.onSurface : esquema.onSurfaceVariant),
            ),
            Text(recordatorio.daysText, style: textos.bodyMedium),
            const SizedBox(height: AppTokens.espacioS),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(onPressed: onEditar, icon: const Icon(Icons.edit_outlined), label: const Text('Editar')),
                TextButton.icon(
                  onPressed: onEliminar,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Eliminar'),
                  style: TextButton.styleFrom(foregroundColor: esquema.error),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 6: Actualizar el menú**

En `lib/widgets/app_drawer.dart`, borrar el import `import '../services/preferences_service.dart';` y reemplazar:

```dart
// ANTES
                  onTap: () => abrirDesdeMenu(
                    context,
                    (_) => AgendarRosarioScreen(preferences: context.read<PreferencesService>()),
                  ),
// DESPUÉS
                  onTap: () => abrirDesdeMenu(context, (_) => const AgendarRosarioScreen()),
```

- [ ] **Step 7: Correr y ver que pasa**

Run: `flutter test`
Expected: `All tests passed!`

- [ ] **Step 8: Cierre de fase**

Run: `flutter analyze && flutter build apk --debug`
Expected: sin errores ni advertencias; APK compila.

```bash
git add lib test
git commit -m "feat: pantalla de recordatorios con permisos explicados y errores visibles" -m "Avisos cuando faltan permisos, resultado de cada operación en pantalla (E13), formulario con selector de tipo y padding del teclado una sola vez (E10)." -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
graphify update .
```

**Cierre de la Fase 2:** E1 a E7, E9, E10 y E13 resueltos; `flutter test` en verde; APK de depuración compila. Prueba rápida manual opcional: `flutter run` en un dispositivo, crear un recordatorio a +2 minutos y comprobar que suena a la hora local.
