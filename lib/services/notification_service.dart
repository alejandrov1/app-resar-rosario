// lib/services/notification_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
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

  List<RosarioReminder> get reminders => List.unmodifiable(_reminders);

  Future<void> initialize() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();
    final String timeZoneName = DateTime.now().timeZoneName;
    tz.setLocalLocation(tz.getLocation(timeZoneName));

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
      onDidReceiveNotificationResponse: (response) {
        debugPrint('Notificación tocada: ${response.payload}');
      },
    );

    if (Platform.isAndroid) {
      await _createNotificationChannels();
    }

    await _loadReminders();
    _isInitialized = true;
    debugPrint('NotificationService inicializado correctamente');
  }

  Future<void> _createNotificationChannels() async {
    final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(const AndroidNotificationChannel(
        _channelIdNotification,
        _channelNameNotification,
        description: _channelDescNotification,
        importance: Importance.high,
      ));
      await androidPlugin.createNotificationChannel(const AndroidNotificationChannel(
        _channelIdAlarm,
        _channelNameAlarm,
        description: _channelDescAlarm,
        importance: Importance.max,
        sound: RawResourceAndroidNotificationSound('alarm_sound'), // Asegúrate de tener un sonido en res/raw/alarm_sound.mp3
        playSound: true,
      ));
      debugPrint('Canales de notificación creados');
    }
  }

  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      await Permission.notification.request();
      await Permission.scheduleExactAlarm.request();
      await Permission.ignoreBatteryOptimizations.request();
    }
  }

  Future<void> scheduleReminder(RosarioReminder reminder) async {
    if (!reminder.isActive) return;

    for (int dayOfWeek in reminder.daysOfWeek) {
      final scheduledDate = _getNextDateForDayOfWeek(dayOfWeek, reminder.time);
      final notificationId = _generateNotificationId(reminder.id, dayOfWeek);

      await _notificationsPlugin.zonedSchedule(
        notificationId,
        reminder.title,
        reminder.description,
        scheduledDate,
        _getNotificationDetails(reminder),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: jsonEncode({'id': reminder.id}),
      );
      debugPrint('Programado: ID $notificationId para ${reminder.title} el día $dayOfWeek a las ${reminder.time}');
    }
  }

  tz.TZDateTime _getNextDateForDayOfWeek(int dayOfWeek, TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, time.hour, time.minute);

    while (scheduledDate.weekday != dayOfWeek) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }
    return scheduledDate;
  }

  NotificationDetails _getNotificationDetails(RosarioReminder reminder) {
    if (reminder.type == ReminderType.alarm) {
      final AndroidNotificationSound sound = reminder.sound != null
      ? UriAndroidNotificationSound(reminder.sound!) // Usa el sonido personalizado
      : const RawResourceAndroidNotificationSound('alarm_sound');
     
      return NotificationDetails(
        android: AndroidNotificationDetails(
          _channelIdAlarm,
          _channelNameAlarm,
          channelDescription: _channelDescAlarm,
          importance: Importance.max,
          priority: Priority.high,
          fullScreenIntent: true,
          sound: sound,
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(
          presentSound: true,
          // En iOS, el sonido se especifica con el nombre del archivo
          sound: reminder.sound?.split('/').last ?? 'default',
        ),
      );
    }
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelIdNotification,
        _channelNameNotification,
        channelDescription: _channelDescNotification,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentSound: true, // Sonido por defecto de iOS
      ),
    );
  }

  Future<void> cancelReminder(int reminderId) async {
    for (int dayOfWeek = 1; dayOfWeek <= 7; dayOfWeek++) {
      final notificationId = _generateNotificationId(reminderId, dayOfWeek);
      await _notificationsPlugin.cancel(notificationId);
    }
    debugPrint('Recordatorio cancelado: ID $reminderId');
  }
  
  // Métodos para gestionar la lista de recordatorios (add, update, remove, etc.)
  Future<void> addReminder(RosarioReminder reminder) async {
    final newReminder = reminder.copyWith(id: generateUniqueId());
    _reminders.add(newReminder);
    await scheduleReminder(newReminder);
    await _saveReminders();
    notifyListeners();
  }

  Future<void> updateReminder(RosarioReminder reminder) async {
    await cancelReminder(reminder.id);
    await scheduleReminder(reminder);
    final index = _reminders.indexWhere((r) => r.id == reminder.id);
    if (index != -1) {
      _reminders[index] = reminder;
    }
    await _saveReminders();
    notifyListeners();
  }

  Future<void> removeReminder(int reminderId) async {
    await cancelReminder(reminderId);
    _reminders.removeWhere((r) => r.id == reminderId);
    await _saveReminders();
    notifyListeners();
  }
  
  Future<void> toggleReminder(int reminderId) async {
    final index = _reminders.indexWhere((r) => r.id == reminderId);
    if (index != -1) {
      final reminder = _reminders[index];
      final updatedReminder = reminder.copyWith(isActive: !reminder.isActive);
      _reminders[index] = updatedReminder;
      if (updatedReminder.isActive) {
        await scheduleReminder(updatedReminder);
      } else {
        await cancelReminder(updatedReminder.id);
      }
      await _saveReminders();
      notifyListeners();
    }
  }

  Future<void> _saveReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final remindersJson = _reminders.map((r) => jsonEncode(r.toMap())).toList();
    await prefs.setStringList('rosario_reminders', remindersJson);
  }

  Future<void> _loadReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final remindersJson = prefs.getStringList('rosario_reminders') ?? [];
    _reminders = remindersJson.map((json) => RosarioReminder.fromMap(jsonDecode(json))).toList();
    notifyListeners();
  }

  int generateUniqueId() {
    return DateTime.now().millisecondsSinceEpoch.remainder(100000);
  }

  int _generateNotificationId(int reminderId, int dayOfWeek) {
    return int.parse('$reminderId$dayOfWeek');
  }
}