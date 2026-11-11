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
