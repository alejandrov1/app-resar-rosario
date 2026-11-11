import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/reminder_model.dart';

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  List<RosarioReminder> _reminders = [];
  bool _isInitialized = false;
  
  static const String _channelIdNotification = 'rosario_notifications';
  static const String _channelNameNotification = 'Recordatorios del Rosario';
  static const String _channelDescNotification = 'Notificaciones para recordar el Rosario';
  
  static const String _channelIdAlarm = 'rosario_alarms';
  static const String _channelNameAlarm = 'Alarmas del Rosario';
  static const String _channelDescAlarm = 'Alarmas sonoras para el Rosario';

  static const int _maxId = 2147483647;
  static const int _minId = 1000000;

  List<RosarioReminder> get reminders => List.unmodifiable(_reminders);
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');

      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        defaultPresentAlert: true,
        defaultPresentBadge: true,
        defaultPresentSound: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings, 
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      if (Platform.isAndroid) {
        await _createNotificationChannels();
      }

      await _loadReminders();
      _isInitialized = true;
      debugPrint('NotificationService inicializado correctamente');
    } catch (e) {
      debugPrint('Error al inicializar NotificationService: $e');
      _isInitialized = false;
    }
  }

  Future<void> _createNotificationChannels() async {
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return;

    const notificationChannel = AndroidNotificationChannel(
      _channelIdNotification, 
      _channelNameNotification,
      description: _channelDescNotification, 
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    const alarmChannel = AndroidNotificationChannel(
      _channelIdAlarm, 
      _channelNameAlarm,
      description: _channelDescAlarm,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
    );

    await androidPlugin.createNotificationChannel(notificationChannel);
    await androidPlugin.createNotificationChannel(alarmChannel);
    debugPrint('Canales de notificación creados');
  }

  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      // Android 13+ requiere permiso explícito para notificaciones
      if (await Permission.notification.isDenied) {
        final notificationStatus = await Permission.notification.request();
        if (!notificationStatus.isGranted) {
          debugPrint('Permiso de notificación denegado');
          return false;
        }
      }

      // Android 12+ requiere permiso para alarmas exactas
      if (await Permission.scheduleExactAlarm.isDenied) {
        final alarmStatus = await Permission.scheduleExactAlarm.request();
        if (!alarmStatus.isGranted) {
          debugPrint('Permiso de alarma exacta denegado');
          return false;
        }
      }
      
      return true;
    }
    return true;
  }

  Future<bool> hasPermissions() async {
    if (Platform.isAndroid) {
      final hasNotificationPermission = await Permission.notification.isGranted;
      final hasExactAlarmPermission = await Permission.scheduleExactAlarm.isGranted;
      return hasNotificationPermission && hasExactAlarmPermission;
    }
    return true;
  }

  Future<void> _scheduleReminderNotifications(RosarioReminder reminder) async {
    await _cancelReminderNotifications(reminder);
    for (int dayOfWeek in reminder.daysOfWeek) {
      await _scheduleWeeklyNotification(reminder, dayOfWeek);
    }
    debugPrint('Notificaciones programadas para: ${reminder.title}');
  }

  Future<void> _scheduleWeeklyNotification(RosarioReminder reminder, int dayOfWeek) async {
    try {
      final scheduledDate = _getNextDateForDayOfWeek(dayOfWeek, reminder.time);
      final notificationId = _generateNotificationId(reminder.id, dayOfWeek);
      
      await _notificationsPlugin.zonedSchedule(
        id: notificationId,
        title: reminder.title,
        body: reminder.description,
        scheduledDate: scheduledDate,
        notificationDetails: _getNotificationDetails(reminder.type),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: 'reminder_${reminder.id}',
      );
      
      debugPrint('Notificación programada: ID $notificationId para el día $dayOfWeek a las ${reminder.timeText}');
    } catch (e) {
      debugPrint('Error al programar notificación semanal: $e');
    }
  }

  tz.TZDateTime _getNextDateForDayOfWeek(int dayOfWeek, TimeOfDay time) {
    var now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local, 
      now.year, 
      now.month, 
      now.day, 
      time.hour, 
      time.minute,
    );
    
    while (scheduledDate.weekday != dayOfWeek) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }
    
    return scheduledDate;
  }
  
  NotificationDetails _getNotificationDetails(ReminderType type) {
    final isAlarm = type == ReminderType.alarm || type == ReminderType.both;
    
    final androidDetails = AndroidNotificationDetails(
      isAlarm ? _channelIdAlarm : _channelIdNotification,
      isAlarm ? _channelNameAlarm : _channelNameNotification,
      channelDescription: isAlarm ? _channelDescAlarm : _channelDescNotification,
      importance: isAlarm ? Importance.max : Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      fullScreenIntent: isAlarm,
      category: isAlarm ? AndroidNotificationCategory.alarm : AndroidNotificationCategory.reminder,
      audioAttributesUsage: isAlarm ? AudioAttributesUsage.alarm : AudioAttributesUsage.notification,
      icon: '@mipmap/launcher_icon',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/launcher_icon'),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true, 
      presentBadge: true, 
      presentSound: true,
      sound: 'default',
    );

    return NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  Future<void> _cancelReminderNotifications(RosarioReminder reminder) async {
    for (int dayOfWeek = 1; dayOfWeek <= 7; dayOfWeek++) {
      final notificationId = _generateNotificationId(reminder.id, dayOfWeek);
      await _notificationsPlugin.cancel(id: notificationId);
    }
    debugPrint('Notificaciones canceladas para: ${reminder.title}');
  }
  
  Future<void> _loadReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final remindersJson = prefs.getStringList('rosario_reminders') ?? [];
      _reminders = remindersJson.map((json) {
        final map = jsonDecode(json) as Map<String, dynamic>;
        return RosarioReminder.fromMap(map);
      }).toList();
      
      await _rescheduleActiveReminders();
      notifyListeners();
      debugPrint('Recordatorios cargados: ${_reminders.length}');
    } catch (e) {
      debugPrint('Error al cargar recordatorios: $e');
      _reminders = [];
    }
  }

  Future<void> _saveReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final remindersJson = _reminders.map((r) => jsonEncode(r.toMap())).toList();
      await prefs.setStringList('rosario_reminders', remindersJson);
      debugPrint('Recordatorios guardados: ${_reminders.length}');
    } catch (e) {
      debugPrint('Error al guardar recordatorios: $e');
    }
  }

  Future<bool> addReminder(RosarioReminder reminder) async {
    try {
      final newReminder = reminder.copyWith(id: generateUniqueId());
      _reminders.add(newReminder);
      await _saveReminders();
      
      if (newReminder.isActive) {
        await _scheduleReminderNotifications(newReminder);
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Error al añadir recordatorio: $e");
      return false;
    }
  }
  
  Future<bool> updateReminder(RosarioReminder updatedReminder) async {
    final index = _reminders.indexWhere((r) => r.id == updatedReminder.id);
    if (index == -1) return false;
    
    try {
      await _cancelReminderNotifications(_reminders[index]);
      _reminders[index] = updatedReminder;
      await _saveReminders();
      
      if (updatedReminder.isActive) {
        await _scheduleReminderNotifications(updatedReminder);
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Error al actualizar recordatorio: $e");
      return false;
    }
  }
  
  Future<bool> removeReminder(int reminderId) async {
    final index = _reminders.indexWhere((r) => r.id == reminderId);
    if (index == -1) return false;

    try {
      await _cancelReminderNotifications(_reminders[index]);
      _reminders.removeAt(index);
      await _saveReminders();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Error al eliminar recordatorio: $e");
      return false;
    }
  }
  
  Future<bool> toggleReminder(int reminderId) async {
    final index = _reminders.indexWhere((r) => r.id == reminderId);
    if (index == -1) return false;
    
    final updated = _reminders[index].copyWith(isActive: !_reminders[index].isActive);
    return await updateReminder(updated);
  }

  Future<void> _rescheduleActiveReminders() async {
    await _notificationsPlugin.cancelAll();
    for (final reminder in _reminders.where((r) => r.isActive)) {
      await _scheduleReminderNotifications(reminder);
    }
    debugPrint('${_reminders.where((r) => r.isActive).length} recordatorios activos reprogramados');
  }

  int generateUniqueId() {
    final random = Random();
    int id;
    do {
      id = _minId + random.nextInt(_maxId - _minId);
    } while (_reminders.any((r) => r.id == id));
    return id;
  }

  int _generateNotificationId(int reminderId, int dayOfWeek) {
    // Asegurar que el ID sea único y válido
    return (reminderId % 100000) * 10 + dayOfWeek;
  }
  
  Future<bool> sendTestNotification() async {
    try {
      await _notificationsPlugin.show(
        id: 999999,
        title: '¡Prueba de Notificación del Rosario!',
        body: 'Si ves y escuchas esto, las notificaciones funcionan correctamente.',
        notificationDetails: _getNotificationDetails(ReminderType.alarm),
        payload: 'test_notification',
      );
      return true;
    } catch (e) {
      debugPrint('Error al enviar notificación de prueba: $e');
      return false;
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notificación tocada: ${response.payload}');
    // Aquí puedes agregar navegación si lo deseas
  }

  // Método para limpiar recordatorios con IDs inválidos
  Future<void> cleanInvalidReminders() async {
    final validReminders = <RosarioReminder>[];
    bool needsSave = false;
    
    for (final reminder in _reminders) {
      if (reminder.id > 0 && reminder.id <= _maxId) {
        validReminders.add(reminder);
      } else {
        needsSave = true;
        validReminders.add(reminder.copyWith(id: generateUniqueId()));
        debugPrint('Recordatorio con ID inválido corregido: ${reminder.title}');
      }
    }
    
    if (needsSave) {
      _reminders = validReminders;
      await _saveReminders();
      await _rescheduleActiveReminders();
      notifyListeners();
      debugPrint('Recordatorios con IDs inválidos limpiados');
    }
  }
}