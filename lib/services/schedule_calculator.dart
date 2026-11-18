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
