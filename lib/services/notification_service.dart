import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:intl/intl.dart';
import '../models/reminder_model.dart';

/// Servicio para manejar las notificaciones y recordatorios del Rosario
class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  List<RosarioReminder> _reminders = [];
  bool _isInitialized = false;
  
  // Constantes para canales de notificación
  static const String _channelIdNotification = 'rosario_notifications';
  static const String _channelNameNotification = 'Recordatorios del Rosario';
  static const String _channelDescNotification = 'Notificaciones para recordar el Rosario';
  
  static const String _channelIdAlarm = 'rosario_alarms';
  static const String _channelNameAlarm = 'Alarmas del Rosario';
  static const String _channelDescAlarm = 'Alarmas sonoras para el Rosario';

  /// Getters
  List<RosarioReminder> get reminders => List.unmodifiable(_reminders);
  bool get isInitialized => _isInitialized;

  /// Inicializa el servicio de notificaciones
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Inicializar timezone con la base de datos completa y obtener la zona horaria local
      tz.initializeTimeZones();
      final String localTimeZone = tz.local.name;
      tz.setLocalLocation(tz.getLocation(localTimeZone));
      
      const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
      
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      if (Platform.isAndroid) {
        await _createNotificationChannels();
      }

      await _loadReminders();
      
      _isInitialized = true;
      debugPrint('NotificationService inicializado en zona horaria: $localTimeZone');
    } catch (e) {
      debugPrint('Error al inicializar NotificationService: $e');
      _isInitialized = false;
    }
  }

  /// Crea los canales de notificación para Android
  Future<void> _createNotificationChannels() async {
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin = 
        _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin == null) return;

    // Canal para notificaciones
    const notificationChannel = AndroidNotificationChannel(
      _channelIdNotification,
      _channelNameNotification,
      description: _channelDescNotification,
      importance: Importance.defaultImportance, // Menos intrusivo
      playSound: true,
    );

    // Canal para alarmas (más intrusivo y con sonido)
    const alarmChannel = AndroidNotificationChannel(
      _channelIdAlarm,
      _channelNameAlarm,
      description: _channelDescAlarm,
      importance: Importance.max, // Máxima importancia para alarmas
      playSound: true,
      sound: RawResourceAndroidNotificationSound('notification'), // Sonido por defecto, puedes cambiarlo
      enableVibration: true,
      enableLights: true,
      ledColor: Colors.blue,
      showBadge: true,
    );

    await androidPlugin.createNotificationChannel(notificationChannel);
    await androidPlugin.createNotificationChannel(alarmChannel);
    
    debugPrint('Canales de notificación creados');
  }

  /// Solicita permisos necesarios
  Future<bool> requestPermissions() async {
    try {
      if (Platform.isAndroid) {
        // Permiso de notificaciones (Android 13+)
        final notificationStatus = await Permission.notification.request();
        if (notificationStatus.isDenied || notificationStatus.isPermanentlyDenied) {
           debugPrint('Permiso de notificación denegado.');
           return false;
        }

        // Permiso de alarmas exactas (Android 12+)
        final alarmStatus = await Permission.scheduleExactAlarm.request();
        if (alarmStatus.isDenied || alarmStatus.isPermanentlyDenied) {
          debugPrint('Permiso de alarma exacta denegado.');
          return false;
        }
      }
      return true;
    } catch (e) {
      debugPrint('Error al solicitar permisos: $e');
      return false;
    }
  }

  /// Verifica si los permisos están concedidos
  Future<bool> hasPermissions() async {
    if (Platform.isAndroid) {
      final hasNotificationPermission = await Permission.notification.isGranted;
      final hasExactAlarmPermission = await Permission.scheduleExactAlarm.isGranted;
      return hasNotificationPermission && hasExactAlarmPermission;
    }
    return true;
  }
  
  /// Envía una notificación de prueba inmediata
  Future<bool> sendTestNotification() async {
    try {
      // Usa el canal de Alarma para la prueba para que sea bien visible y sonora
      final details = _getNotificationDetails(ReminderType.alarm);

      await _notificationsPlugin.show(
        -1, // ID único para la prueba
        '¡Prueba de Alarma!',
        'Si ves y escuchas esto, las notificaciones funcionan. ¡Es hora de rezar!',
        details,
        payload: 'test_payload',
      );
      
      debugPrint('Notificación de prueba enviada');
      return true;
    } catch (e) {
      debugPrint('Error al enviar notificación de prueba: $e');
      return false;
    }
  }
  
  /// Programa las notificaciones para un recordatorio
  Future<void> _scheduleReminderNotifications(RosarioReminder reminder) async {
    for (int dayOfWeek in reminder.daysOfWeek) {
      await _scheduleWeeklyNotification(reminder, dayOfWeek);
    }
    debugPrint('Notificaciones programadas para: ${reminder.title}');
    await getPendingNotifications(); // Para depuración
  }

  /// Programa una notificación semanal para un día específico
  Future<void> _scheduleWeeklyNotification(RosarioReminder reminder, int dayOfWeek) async {
    try {
      final scheduledDate = _getNextDateForDayOfWeek(dayOfWeek, reminder.time);
      final scheduledTZ = tz.TZDateTime.from(scheduledDate, tz.local);
      
      final notificationId = reminder.id * 10 + dayOfWeek;
      
      await _notificationsPlugin.zonedSchedule(
        notificationId,
        reminder.title,
        reminder.description,
        scheduledTZ,
        _getNotificationDetails(reminder.type),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: 'reminder_${reminder.id}',
      );
      
      debugPrint('Programada: ID $notificationId, ${reminder.title}, Día $dayOfWeek a las ${reminder.timeText}');
      debugPrint('Fecha TZ: $scheduledTZ');
    } catch (e) {
      debugPrint('Error al programar notificación semanal: $e');
    }
  }

  /// Obtiene la próxima fecha para un día de la semana y hora específicos
  tz.TZDateTime _getNextDateForDayOfWeek(int dayOfWeek, TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, time.hour, time.minute);

    // Ajusta al día de la semana correcto
    while (scheduledDate.weekday != dayOfWeek) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // Si la fecha ya pasó hoy, programa para la próxima semana
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }
    
    return scheduledDate;
  }
  
  /// Obtiene la configuración de notificación según el tipo
  NotificationDetails _getNotificationDetails(ReminderType type) {
    // Definimos los detalles de Android para alarma primero (el más completo)
    final alarmAndroidDetails = AndroidNotificationDetails(
      _channelIdAlarm,
      _channelNameAlarm,
      channelDescription: _channelDescAlarm,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('notification'), // Asegura sonido
      enableVibration: true,
      fullScreenIntent: true, // ¡CRÍTICO para que aparezca como alarma!
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      autoCancel: true,
      color: const Color(0xFF2563EB),
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/launcher_icon'),
      styleInformation: const BigTextStyleInformation(''),
    );
    
    // Detalles para notificación normal
    final notificationAndroidDetails = AndroidNotificationDetails(
      _channelIdNotification,
      _channelNameNotification,
      channelDescription: _channelDescNotification,
      importance: Importance.high, // Usar High para que sea visible
      priority: Priority.high,
      playSound: false,
      enableVibration: true,
      category: AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.public,
      autoCancel: true,
      color: const Color(0xFF2563EB),
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/launcher_icon'),
      styleInformation: const BigTextStyleInformation(''),
    );

    AndroidNotificationDetails androidDetails;
    switch (type) {
      case ReminderType.notification:
        androidDetails = notificationAndroidDetails;
        break;
      case ReminderType.alarm:
      case ReminderType.both:
        androidDetails = alarmAndroidDetails;
        break;
    }

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive, // Para iOS 15+
    );

    return NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  /// Cancela las notificaciones de un recordatorio
  Future<void> _cancelReminderNotifications(RosarioReminder reminder) async {
    for (int dayOfWeek in reminder.daysOfWeek) {
      final notificationId = reminder.id * 10 + dayOfWeek;
      await _notificationsPlugin.cancel(notificationId);
      debugPrint('Notificación cancelada: ID $notificationId');
    }
  }

  /// Reprograma todos los recordatorios activos al iniciar la app
  Future<void> _rescheduleActiveReminders() async {
    await _notificationsPlugin.cancelAll();
    for (final reminder in _reminders.where((r) => r.isActive)) {
      await _scheduleReminderNotifications(reminder);
    }
    debugPrint('Recordatorios activos reprogramados: ${_reminders.where((r) => r.isActive).length}');
  }

  // --- Métodos de gestión de recordatorios (CRUD) ---
  
  Future<void> _loadReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final remindersJson = prefs.getStringList('rosario_reminders') ?? [];
    _reminders = remindersJson.map((json) => RosarioReminder.fromMap(jsonDecode(json))).toList();
    await _rescheduleActiveReminders();
    notifyListeners();
  }

  Future<void> _saveReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final remindersJson = _reminders.map((r) => jsonEncode(r.toMap())).toList();
    await prefs.setStringList('rosario_reminders', remindersJson);
  }
  
  Future<bool> addReminder(RosarioReminder reminder) async {
    if (_reminders.any((r) => r.id == reminder.id)) return false;
    _reminders.add(reminder);
    await _saveReminders();
    if (reminder.isActive) {
      await _scheduleReminderNotifications(reminder);
    }
    notifyListeners();
    return true;
  }
  
  Future<bool> updateReminder(RosarioReminder updatedReminder) async {
    final index = _reminders.indexWhere((r) => r.id == updatedReminder.id);
    if (index == -1) return false;
    await _cancelReminderNotifications(_reminders[index]);
    _reminders[index] = updatedReminder;
    await _saveReminders();
    if (updatedReminder.isActive) {
      await _scheduleReminderNotifications(updatedReminder);
    }
    notifyListeners();
    return true;
  }
  
  Future<bool> removeReminder(int reminderId) async {
    final index = _reminders.indexWhere((r) => r.id == reminderId);
    if (index == -1) return false;
    await _cancelReminderNotifications(_reminders[index]);
    _reminders.removeAt(index);
    await _saveReminders();
    notifyListeners();
    return true;
  }
  
  Future<bool> toggleReminder(int reminderId) async {
    final index = _reminders.indexWhere((r) => r.id == reminderId);
    if (index == -1) return false;
    final reminder = _reminders[index];
    final updatedReminder = reminder.copyWith(isActive: !reminder.isActive);
    return await updateReminder(updatedReminder);
  }

  int generateUniqueId() {
    return DateTime.now().millisecondsSinceEpoch;
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notificación tocada con payload: ${response.payload}');
    // Aquí puedes agregar lógica para navegar a una pantalla específica
  }

  Future<void> getPendingNotifications() async {
    final pending = await _notificationsPlugin.pendingNotificationRequests();
    debugPrint('--- Notificaciones Pendientes (${pending.length}) ---');
    for (final p in pending) {
      debugPrint('ID: ${p.id}, Título: ${p.title}, Payload: ${p.payload}');
    }
    debugPrint('-----------------------------------------');
  }
}