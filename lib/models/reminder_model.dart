import 'package:flutter/material.dart';

/// Modelo para representar un recordatorio del Rosario
class RosarioReminder {
  final int id;
  final String title;
  final String description;
  final TimeOfDay time;
  final List<int> daysOfWeek; // 1-7 (Lunes a Domingo)
  final bool isActive;
  final ReminderType type;
  final DateTime createdAt;

  RosarioReminder({
    required this.id,
    required this.title,
    required this.description,
    required this.time,
    required this.daysOfWeek,
    required this.isActive,
    required this.type,
    required this.createdAt,
  });

  /// Constructor para crear un recordatorio desde un Map (para SharedPreferences)
  factory RosarioReminder.fromMap(Map<String, dynamic> map) {
    return RosarioReminder(
      id: map['id'] as int,
      title: map['title'] as String,
      description: map['description'] as String,
      time: TimeOfDay(
        hour: map['hour'] as int,
        minute: map['minute'] as int,
      ),
      daysOfWeek: List<int>.from(map['daysOfWeek'] as List),
      isActive: map['isActive'] as bool,
      type: ReminderType.values[map['type'] as int],
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  /// Convierte el recordatorio a un Map (para SharedPreferences)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'hour': time.hour,
      'minute': time.minute,
      'daysOfWeek': daysOfWeek,
      'isActive': isActive,
      'type': type.index,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Crea una copia del recordatorio con algunos valores modificados
  RosarioReminder copyWith({
    int? id,
    String? title,
    String? description,
    TimeOfDay? time,
    List<int>? daysOfWeek,
    bool? isActive,
    ReminderType? type,
    DateTime? createdAt,
  }) {
    return RosarioReminder(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      time: time ?? this.time,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      isActive: isActive ?? this.isActive,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Obtiene el nombre de los días de la semana en formato legible
  String get daysText {
    if (daysOfWeek.length == 7) {
      return 'Todos los días';
    }
    
    const dayNames = {
      1: 'Lun',
      2: 'Mar',
      3: 'Mié',
      4: 'Jue',
      5: 'Vie',
      6: 'Sáb',
      7: 'Dom',
    };
    
    final sortedDays = List<int>.from(daysOfWeek)..sort();
    return sortedDays.map((day) => dayNames[day]).join(', ');
  }

  /// Obtiene la hora en formato legible
  String get timeText {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Verifica si el recordatorio debe activarse hoy
  bool shouldActivateToday() {
    final today = DateTime.now().weekday;
    return isActive && daysOfWeek.contains(today);
  }

  @override
  String toString() {
    return 'RosarioReminder(id: $id, title: $title, time: $timeText, days: $daysText, active: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RosarioReminder && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Tipos de recordatorio disponibles
enum ReminderType {
  notification,
  alarm,
  both,
}

extension ReminderTypeExtension on ReminderType {
  String get displayName {
    switch (this) {
      case ReminderType.notification:
        return 'Notificación';
      case ReminderType.alarm:
        return 'Alarma';
      case ReminderType.both:
        return 'Notificación y Alarma';
    }
  }

  String get description {
    switch (this) {
      case ReminderType.notification:
        return 'Solo notificación silenciosa';
      case ReminderType.alarm:
        return 'Alarma con sonido';
      case ReminderType.both:
        return 'Notificación y alarma';
    }
  }

  IconData get icon {
    switch (this) {
      case ReminderType.notification:
        return Icons.notifications;
      case ReminderType.alarm:
        return Icons.alarm;
      case ReminderType.both:
        return Icons.notifications_active;
    }
  }
}

/// Plantillas predefinidas para recordatorios comunes
class ReminderTemplates {
  static List<ReminderTemplate> get templates => [
    ReminderTemplate(
      title: 'Rosario Matutino',
      description: 'Momento perfecto para comenzar el día con oración',
      time: const TimeOfDay(hour: 7, minute: 0),
      daysOfWeek: [1, 2, 3, 4, 5, 6, 7], // Todos los días
      type: ReminderType.notification,
    ),
    ReminderTemplate(
      title: 'Rosario Vespertino',
      description: 'Termina tu día con la oración del Rosario',
      time: const TimeOfDay(hour: 19, minute: 0),
      daysOfWeek: [1, 2, 3, 4, 5, 6, 7], // Todos los días
      type: ReminderType.notification,
    ),
    ReminderTemplate(
      title: 'Rosario Dominical',
      description: 'Dedica tiempo especial los domingos',
      time: const TimeOfDay(hour: 10, minute: 0),
      daysOfWeek: [7], // Solo domingos
      type: ReminderType.alarm,
    ),
    ReminderTemplate(
      title: 'Rosario de Mediodía',
      description: 'Una pausa espiritual en medio del día',
      time: const TimeOfDay(hour: 12, minute: 0),
      daysOfWeek: [1, 2, 3, 4, 5], // Días laborales
      type: ReminderType.notification,
    ),
  ];
}

/// Plantilla para crear recordatorios rápidamente
class ReminderTemplate {
  final String title;
  final String description;
  final TimeOfDay time;
  final List<int> daysOfWeek;
  final ReminderType type;

  const ReminderTemplate({
    required this.title,
    required this.description,
    required this.time,
    required this.daysOfWeek,
    required this.type,
  });

  /// Convierte la plantilla en un recordatorio real
  RosarioReminder toReminder(int id) {
    return RosarioReminder(
      id: id,
      title: title,
      description: description,
      time: time,
      daysOfWeek: daysOfWeek,
      isActive: true,
      type: type,
      createdAt: DateTime.now(),
    );
  }
}