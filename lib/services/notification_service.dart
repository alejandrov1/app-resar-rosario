import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/reminder_model.dart';

/// Servicio para manejar las notificaciones y recordatorios del Rosario
class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  List<RosarioReminder> _reminders = [];
  bool _isInitialized = false;

  /// Getters
  List<RosarioReminder> get reminders => List.unmodifiable(_reminders);
  bool get isInitialized => _isInitialized;

  /// Inicializa el servicio de notificaciones
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Inicializar timezone
      tz.initializeTimeZones();
      
      // Configuración para Android
      const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
      
      // Configuración para iOS
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

      // Cargar recordatorios guardados
      await _loadReminders();
      
      _isInitialized = true;
      debugPrint('NotificationService inicializado correctamente');
    } catch (e) {
      debugPrint('Error al inicializar NotificationService: $e');
    }
  }

  /// Solicita permisos necesarios para las notificaciones
  Future<bool> requestPermissions() async {
    try {
      if (Platform.isAndroid) {
        // Solicitar permisos de notificación para Android 13+
        final notificationStatus = await Permission.notification.request();
        
        // Solicitar permiso de alarma exacta para Android 12+
        final alarmStatus = await Permission.scheduleExactAlarm.request();
        
        // Verificar si se puede ignorar optimización de batería
        await Permission.ignoreBatteryOptimizations.request();
        
        return notificationStatus.isGranted && alarmStatus.isGranted;
      } else if (Platform.isIOS) {
        // Para iOS, los permisos se solicitan automáticamente en initialize()
        return true;
      }
    } catch (e) {
      debugPrint('Error al solicitar permisos: $e');
    }
    return false;
  }

  /// Verifica si los permisos están concedidos
  Future<bool> hasPermissions() async {
    if (Platform.isAndroid) {
      final notificationStatus = await Permission.notification.status;
      final alarmStatus = await Permission.scheduleExactAlarm.status;
      return notificationStatus.isGranted && alarmStatus.isGranted;
    }
    return true; // iOS maneja permisos automáticamente
  }

  /// Carga los recordatorios desde SharedPreferences
  Future<void> _loadReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final remindersJson = prefs.getStringList('rosario_reminders') ?? [];
      
      _reminders = remindersJson
          .map((json) => RosarioReminder.fromMap(jsonDecode(json)))
          .toList();
      
      // Reprogramar notificaciones activas
      await _rescheduleActiveReminders();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error al cargar recordatorios: $e');
      _reminders = [];
    }
  }

  /// Guarda los recordatorios en SharedPreferences
  Future<void> _saveReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final remindersJson = _reminders
          .map((reminder) => jsonEncode(reminder.toMap()))
          .toList();
      
      await prefs.setStringList('rosario_reminders', remindersJson);
    } catch (e) {
      debugPrint('Error al guardar recordatorios: $e');
    }
  }

  /// Agrega un nuevo recordatorio
  Future<bool> addReminder(RosarioReminder reminder) async {
    try {
      // Verificar que no exista un recordatorio con la misma ID
      if (_reminders.any((r) => r.id == reminder.id)) {
        return false;
      }

      _reminders.add(reminder);
      await _saveReminders();
      
      if (reminder.isActive) {
        await _scheduleReminderNotifications(reminder);
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error al agregar recordatorio: $e');
      return false;
    }
  }

  /// Actualiza un recordatorio existente
  Future<bool> updateReminder(RosarioReminder updatedReminder) async {
    try {
      final index = _reminders.indexWhere((r) => r.id == updatedReminder.id);
      if (index == -1) return false;

      // Cancelar notificaciones del recordatorio anterior
      await _cancelReminderNotifications(_reminders[index]);
      
      // Actualizar recordatorio
      _reminders[index] = updatedReminder;
      await _saveReminders();
      
      // Programar nuevas notificaciones si está activo
      if (updatedReminder.isActive) {
        await _scheduleReminderNotifications(updatedReminder);
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error al actualizar recordatorio: $e');
      return false;
    }
  }

  /// Elimina un recordatorio
  Future<bool> removeReminder(int reminderId) async {
    try {
      final index = _reminders.indexWhere((r) => r.id == reminderId);
      if (index == -1) return false;

      // Cancelar notificaciones
      await _cancelReminderNotifications(_reminders[index]);
      
      // Eliminar recordatorio
      _reminders.removeAt(index);
      await _saveReminders();
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error al eliminar recordatorio: $e');
      return false;
    }
  }

  /// Activa o desactiva un recordatorio
  Future<bool> toggleReminder(int reminderId) async {
    try {
      final index = _reminders.indexWhere((r) => r.id == reminderId);
      if (index == -1) return false;

      final reminder = _reminders[index];
      final updatedReminder = reminder.copyWith(isActive: !reminder.isActive);
      
      return await updateReminder(updatedReminder);
    } catch (e) {
      debugPrint('Error al cambiar estado del recordatorio: $e');
      return false;
    }
  }

  /// Programa las notificaciones para un recordatorio
  Future<void> _scheduleReminderNotifications(RosarioReminder reminder) async {
    try {
      for (int dayOfWeek in reminder.daysOfWeek) {
        await _scheduleWeeklyNotification(reminder, dayOfWeek);
      }
    } catch (e) {
      debugPrint('Error al programar notificaciones: $e');
    }
  }

  /// Programa una notificación semanal para un día específico
  Future<void> _scheduleWeeklyNotification(RosarioReminder reminder, int dayOfWeek) async {
    try {
      final now = DateTime.now();
      final scheduledDate = _getNextDateForDayOfWeek(dayOfWeek, reminder.time);
      
      // ID único para cada día de la semana de cada recordatorio
      final notificationId = reminder.id * 10 + dayOfWeek;
      
      await _notificationsPlugin.zonedSchedule(
        notificationId,
        reminder.title,
        reminder.description,
        tz.TZDateTime.from(scheduledDate, tz.local),
        _getNotificationDetails(reminder.type),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
      
      debugPrint('Notificación programada: ID $notificationId para ${reminder.title} el día $dayOfWeek a las ${reminder.timeText}');
    } catch (e) {
      debugPrint('Error al programar notificación semanal: $e');
    }
  }

  /// Obtiene la próxima fecha para un día de la semana y hora específicos
  DateTime _getNextDateForDayOfWeek(int dayOfWeek, TimeOfDay time) {
    final now = DateTime.now();
    final today = now.weekday;
    
    int daysToAdd;
    if (dayOfWeek == today) {
      // Si es hoy, verificar si ya pasó la hora
      final scheduledTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);
      if (scheduledTime.isAfter(now)) {
        daysToAdd = 0; // Programar para hoy
      } else {
        daysToAdd = 7; // Programar para la próxima semana
      }
    } else if (dayOfWeek > today) {
      daysToAdd = dayOfWeek - today;
    } else {
      daysToAdd = 7 - today + dayOfWeek;
    }
    
    return DateTime(
      now.year,
      now.month,
      now.day + daysToAdd,
      time.hour,
      time.minute,
    );
  }

  /// Obtiene la configuración de notificación según el tipo
  NotificationDetails _getNotificationDetails(ReminderType type) {
    String channelId;
    String channelName;
    String channelDescription;
    Importance importance;
    Priority priority;
    bool playSound;
    String? sound;

    switch (type) {
      case ReminderType.notification:
        channelId = 'rosario_notifications';
        channelName = 'Recordatorios del Rosario';
        channelDescription = 'Notificaciones silenciosas para recordar el Rosario';
        importance = Importance.defaultImportance;
        priority = Priority.defaultPriority;
        playSound = false;
        sound = null;
        break;
      case ReminderType.alarm:
        channelId = 'rosario_alarms';
        channelName = 'Alarmas del Rosario';
        channelDescription = 'Alarmas sonoras para recordar el Rosario';
        importance = Importance.high;
        priority = Priority.high;
        playSound = true;
        sound = 'alarm_sound';
        break;
      case ReminderType.both:
        channelId = 'rosario_both';
        channelName = 'Recordatorios Completos del Rosario';
        channelDescription = 'Notificaciones y alarmas para recordar el Rosario';
        importance = Importance.high;
        priority = Priority.high;
        playSound = true;
        sound = 'notification_sound';
        break;
    }

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: importance,
      priority: priority,
      playSound: playSound,
      sound: sound != null ? RawResourceAndroidNotificationSound(sound) : null,
      enableVibration: type != ReminderType.notification,
      fullScreenIntent: type == ReminderType.alarm,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      autoCancel: true,
      ongoing: false,
      colorized: true,
      color: const Color(0xFF2563EB),
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/launcher_icon'),
      styleInformation: const BigTextStyleInformation(''),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.active,
    );

    return NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  /// Cancela las notificaciones de un recordatorio
  Future<void> _cancelReminderNotifications(RosarioReminder reminder) async {
    try {
      for (int dayOfWeek in reminder.daysOfWeek) {
        final notificationId = reminder.id * 10 + dayOfWeek;
        await _notificationsPlugin.cancel(notificationId);
        debugPrint('Notificación cancelada: ID $notificationId');
      }
    } catch (e) {
      debugPrint('Error al cancelar notificaciones: $e');
    }
  }

  /// Reprograma todos los recordatorios activos
  Future<void> _rescheduleActiveReminders() async {
    try {
      // Cancelar todas las notificaciones pendientes
      await _notificationsPlugin.cancelAll();
      
      // Reprogramar solo los recordatorios activos
      for (final reminder in _reminders.where((r) => r.isActive)) {
        await _scheduleReminderNotifications(reminder);
      }
      
      debugPrint('Recordatorios reprogramados: ${_reminders.where((r) => r.isActive).length}');
    } catch (e) {
      debugPrint('Error al reprogramar recordatorios: $e');
    }
  }

  /// Genera un ID único para nuevos recordatorios
  int generateUniqueId() {
    if (_reminders.isEmpty) return 1;
    return _reminders.map((r) => r.id).reduce((a, b) => a > b ? a : b) + 1;
  }

  /// Callback cuando se toca una notificación
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notificación tocada: ${response.payload}');
    // Aquí puedes agregar lógica para abrir la app en una pantalla específica
    // Por ejemplo, abrir directamente la pantalla del Rosario
  }

  /// Obtiene las notificaciones pendientes (para debugging)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notificationsPlugin.pendingNotificationRequests();
  }

  /// Cancela todas las notificaciones
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
    debugPrint('Todas las notificaciones canceladas');
  }

  /// Limpia todos los recordatorios (para testing o reset)
  Future<void> clearAllReminders() async {
    await cancelAllNotifications();
    _reminders.clear();
    await _saveReminders();
    notifyListeners();
  }
}