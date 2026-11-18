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
  NotificationService({required this._gateway, tz.TZDateTime Function()? now})
      : _now = now ?? (() => tz.TZDateTime.now(tz.local));

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
      await _gateway.cancelAllPending();
      for (final reminder in _reminders.where((r) => r.isActive)) {
        await _schedule(reminder);
      }
    } catch (e) {
      debugPrint('Error al reprogramar recordatorios: $e');
    }
  }
}
