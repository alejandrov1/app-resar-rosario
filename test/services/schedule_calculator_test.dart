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
