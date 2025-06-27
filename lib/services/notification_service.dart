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
  
  // Constantes para canales de notificación
  static const String _channelIdNotification = 'rosario_notifications';
  static const String _channelNameNotification = 'Recordatorios del Rosario';
  static const String _channelDescNotification = 'Notificaciones silenciosas para recordar el Rosario';
  
  static const String _channelIdAlarm = 'rosario_alarms';
  static const String _channelNameAlarm = 'Alarmas del Rosario';
  static const String _channelDescAlarm = 'Alarmas sonoras para recordar el Rosario';

  /// Getters
  List<RosarioReminder> get reminders => List.unmodifiable(_reminders);
  bool get isInitialized => _isInitialized;

  /// Inicializa el servicio de notificaciones
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Inicializar timezone con la zona horaria del dispositivo
      tz.initializeTimeZones();
      final String timeZoneName = await _getTimeZoneName();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      
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

      // Crear canales de notificación para Android 8.0+
      if (Platform.isAndroid) {
        await _createNotificationChannels();
      }

      // Cargar recordatorios guardados
      await _loadReminders();
      
      _isInitialized = true;
      debugPrint('NotificationService inicializado correctamente');
    } catch (e) {
      debugPrint('Error al inicializar NotificationService: $e');
      _isInitialized = false;
    }
  }

  /// Obtiene el nombre de la zona horaria del dispositivo
  Future<String> _getTimeZoneName() async {
    // Por defecto usar America/Mexico_City
    return 'America/Mexico_City';
  }

  /// Crea los canales de notificación para Android
  Future<void> _createNotificationChannels() async {
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin = 
        _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin == null) return;

    // Canal para notificaciones silenciosas
    const notificationChannel = AndroidNotificationChannel(
      _channelIdNotification,
      _channelNameNotification,
      description: _channelDescNotification,
      importance: Importance.defaultImportance,
      playSound: false,
      enableVibration: false,
      showBadge: true,
    );

    // Canal para alarmas
    const alarmChannel = AndroidNotificationChannel(
      _channelIdAlarm,
      _channelNameAlarm,
      description: _channelDescAlarm,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      ledColor: Color(0xFF2563EB),
      showBadge: true,
    );

    await androidPlugin.createNotificationChannel(notificationChannel);
    await androidPlugin.createNotificationChannel(alarmChannel);
    
    debugPrint('Canales de notificación creados');
  }

  /// Solicita permisos necesarios para las notificaciones
  Future<bool> requestPermissions() async {
    try {
      bool allGranted = true;
      
      if (Platform.isAndroid) {
        // Android 13+ requiere permiso explícito para notificaciones
        if (await Permission.notification.isDenied) {
          final status = await Permission.notification.request();
          allGranted = allGranted && status.isGranted;
        }
        
        // Android 12+ requiere permiso para alarmas exactas
        if (await Permission.scheduleExactAlarm.isDenied) {
          final status = await Permission.scheduleExactAlarm.request();
          allGranted = allGranted && status.isGranted;
        }
        
        // Opcional: Ignorar optimización de batería para mejor confiabilidad
        if (await Permission.ignoreBatteryOptimizations.isDenied) {
          await Permission.ignoreBatteryOptimizations.request();
        }
        
        // Verificar si se otorgaron los permisos
        final notificationGranted = await Permission.notification.isGranted;
        final alarmGranted = await Permission.scheduleExactAlarm.isGranted;
        
        debugPrint('Permisos: Notificación=$notificationGranted, Alarma=$alarmGranted');
        
        return notificationGranted && alarmGranted;
      } else if (Platform.isIOS) {
        // iOS maneja permisos durante la inicialización
        return true;
      }
      
      return allGranted;
    } catch (e) {
      debugPrint('Error al solicitar permisos: $e');
      return false;
    }
  }

  /// Verifica si los permisos están concedidos
  Future<bool> hasPermissions() async {
    if (Platform.isAndroid) {
      final notificationStatus = await Permission.notification.status;
      final alarmStatus = await Permission.scheduleExactAlarm.status;
      
      debugPrint('Estado permisos: Notificación=${notificationStatus.isGranted}, Alarma=${alarmStatus.isGranted}');
      
      return notificationStatus.isGranted && alarmStatus.isGranted;
    }
    return true; // iOS maneja permisos automáticamente
  }

  /// Envía una notificación de prueba inmediata
  Future<bool> sendTestNotification() async {
    try {
      const androidDetails = AndroidNotificationDetails(
        _channelIdAlarm,
        _channelNameAlarm,
        channelDescription: _channelDescAlarm,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        autoCancel: true,
        colorized: true,
        color: Color(0xFF2563EB),
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/launcher_icon'),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.active,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.show(
        9999, // ID especial para prueba
        '¡Prueba de Notificación!',
        'Las notificaciones están funcionando correctamente. ¡Es hora de rezar el Rosario!',
        details,
      );
      
      debugPrint('Notificación de prueba enviada');
      return true;
    } catch (e) {
      debugPrint('Error al enviar notificación de prueba: $e');
      return false;
    }
  }

  /// Carga los recordatorios desde SharedPreferences
  Future<void> _loadReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final remindersJson = prefs.getStringList('rosario_reminders') ?? [];
      
      _reminders = remindersJson
          .map((json) => RosarioReminder.fromMap(jsonDecode(json)))
          .toList();
      
      debugPrint('Recordatorios cargados: ${_reminders.length}');
      
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
      debugPrint('Recordatorios guardados: ${_reminders.length}');
    } catch (e) {
      debugPrint('Error al guardar recordatorios: $e');
    }
  }

  /// Agrega un nuevo recordatorio
  Future<bool> addReminder(RosarioReminder reminder) async {
    try {
      // Verificar que no exista un recordatorio con la misma ID
      if (_reminders.any((r) => r.id == reminder.id)) {
        debugPrint('Ya existe un recordatorio con ID ${reminder.id}');
        return false;
      }

      _reminders.add(reminder);
      await _saveReminders();
      
      if (reminder.isActive) {
        await _scheduleReminderNotifications(reminder);
      }
      
      notifyListeners();
      debugPrint('Recordatorio agregado: ${reminder.title}');
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
      if (index == -1) {
        debugPrint('No se encontró recordatorio con ID ${updatedReminder.id}');
        return false;
      }

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
      debugPrint('Recordatorio actualizado: ${updatedReminder.title}');
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
      if (index == -1) {
        debugPrint('No se encontró recordatorio con ID $reminderId');
        return false;
      }

      // Cancelar notificaciones
      await _cancelReminderNotifications(_reminders[index]);
      
      // Eliminar recordatorio
      final removedReminder = _reminders.removeAt(index);
      await _saveReminders();
      
      notifyListeners();
      debugPrint('Recordatorio eliminado: ${removedReminder.title}');
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
      if (index == -1) {
        debugPrint('No se encontró recordatorio con ID $reminderId');
        return false;
      }

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
      debugPrint('Programando notificaciones para: ${reminder.title}');
      
      for (int dayOfWeek in reminder.daysOfWeek) {
        await _scheduleWeeklyNotification(reminder, dayOfWeek);
      }
      
      debugPrint('Notificaciones programadas para ${reminder.daysOfWeek.length} días');
    } catch (e) {
      debugPrint('Error al programar notificaciones: $e');
    }
  }

  /// Programa una notificación semanal para un día específico
  Future<void> _scheduleWeeklyNotification(RosarioReminder reminder, int dayOfWeek) async {
    try {
      final scheduledDate = _getNextDateForDayOfWeek(dayOfWeek, reminder.time);
      
      // ID único para cada día de la semana de cada recordatorio
      final notificationId = reminder.id * 10 + dayOfWeek;
      
      final scheduledTZ = tz.TZDateTime.from(scheduledDate, tz.local);
      
      await _notificationsPlugin.zonedSchedule(
        notificationId,
        reminder.title,
        reminder.description,
        scheduledTZ,
        _getNotificationDetails(reminder.type),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
      
      debugPrint('Notificación programada: ID $notificationId para ${reminder.title} el día $dayOfWeek a las ${reminder.timeText}');
      debugPrint('Fecha programada: $scheduledTZ');
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
    AndroidNotificationDetails androidDetails;

    switch (type) {
      case ReminderType.notification:
        androidDetails = const AndroidNotificationDetails(
          _channelIdNotification,
          _channelNameNotification,
          channelDescription: _channelDescNotification,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          playSound: false,
          enableVibration: false,
          category: AndroidNotificationCategory.reminder,
          visibility: NotificationVisibility.public,
          autoCancel: true,
          colorized: true,
          color: Color(0xFF2563EB),
          largeIcon: DrawableResourceAndroidBitmap('@mipmap/launcher_icon'),
          styleInformation: BigTextStyleInformation(''),
        );
        break;
        
      case ReminderType.alarm:
      case ReminderType.both:
        androidDetails = const AndroidNotificationDetails(
          _channelIdAlarm,
          _channelNameAlarm,
          channelDescription: _channelDescAlarm,
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          ledColor: Color(0xFF2563EB),
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
          autoCancel: true,
          ongoing: false,
          colorized: true,
          color: Color(0xFF2563EB),
          largeIcon: DrawableResourceAndroidBitmap('@mipmap/launcher_icon'),
          styleInformation: BigTextStyleInformation(''),
        );
        break;
    }

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
    return DateTime.now().millisecondsSinceEpoch;
  }

  /// Callback cuando se toca una notificación
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notificación tocada: ${response.payload}');
    // Aquí puedes agregar lógica para abrir la app en una pantalla específica
    // Por ejemplo, abrir directamente la pantalla del Rosario
  }

  /// Obtiene las notificaciones pendientes (para debugging)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    final pending = await _notificationsPlugin.pendingNotificationRequests();
    debugPrint('Notificaciones pendientes: ${pending.length}');
    for (final notification in pending) {
      debugPrint('ID: ${notification.id}, Título: ${notification.title}');
    }
    return pending;
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
    debugPrint('Todos los recordatorios eliminados');
  }
}