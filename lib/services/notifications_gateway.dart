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
  /// Cancela solo lo programado: los avisos que ya se muestran (una alarma sonando) se quedan.
  Future<void> cancelAllPending();
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
  Future<void> cancelAllPending() => _plugin.cancelAllPendingNotifications();

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
