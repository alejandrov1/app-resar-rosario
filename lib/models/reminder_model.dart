import 'package:flutter/material.dart';

/// Mayor ID de recordatorio permitido. El ID de cada notificación es `id * 10 + día`.
const int maxReminderId = 100000;

class RosarioReminder {
  const RosarioReminder({
    required this.id,
    required this.title,
    required this.description,
    required this.time,
    required this.daysOfWeek,
    required this.isActive,
    required this.type,
    required this.createdAt,
  });

  final int id;
  final String title;
  final String description;
  final TimeOfDay time;

  /// Días en que suena: 1 = lunes … 7 = domingo.
  final List<int> daysOfWeek;
  final bool isActive;
  final ReminderType type;
  final DateTime createdAt;

  /// Lee un recordatorio guardado. Lanza [FormatException] si los datos no son válidos.
  factory RosarioReminder.fromMap(Map<String, dynamic> map) {
    final dias = List<int>.from(map['daysOfWeek'] as List);
    if (dias.isEmpty || dias.any((d) => d < 1 || d > 7)) {
      throw FormatException('Días inválidos: $dias');
    }
    return RosarioReminder(
      id: map['id'] as int,
      title: map['title'] as String,
      description: map['description'] as String,
      time: TimeOfDay(hour: map['hour'] as int, minute: map['minute'] as int),
      daysOfWeek: dias,
      isActive: map['isActive'] as bool,
      type: ReminderType.fromStoredIndex(map['type'] as int),
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
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

  String get daysText {
    if (daysOfWeek.toSet().length == 7) return 'Todos los días';
    const nombres = {1: 'Lun', 2: 'Mar', 3: 'Mié', 4: 'Jue', 5: 'Vie', 6: 'Sáb', 7: 'Dom'};
    final ordenados = [...daysOfWeek]..sort();
    return ordenados.map((d) => nombres[d]!).join(', ');
  }

  String get timeText =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  @override
  String toString() => 'RosarioReminder(id: $id, title: $title, time: $timeText, days: $daysText, active: $isActive)';

  @override
  bool operator ==(Object other) => identical(this, other) || other is RosarioReminder && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

enum ReminderType {
  notification,
  alarm;

  /// Convierte el índice guardado. El antiguo tipo "Notificación y Alarma" (2) era igual a Alarma.
  static ReminderType fromStoredIndex(int index) => switch (index) {
        1 || 2 => ReminderType.alarm,
        _ => ReminderType.notification,
      };
}

extension ReminderTypeExtension on ReminderType {
  String get displayName => switch (this) {
        ReminderType.notification => 'Notificación',
        ReminderType.alarm => 'Alarma',
      };

  String get description => switch (this) {
        ReminderType.notification => 'Aviso con el sonido normal del teléfono',
        ReminderType.alarm => 'Sonido de alarma y aviso en pantalla completa',
      };

  IconData get icon => switch (this) {
        ReminderType.notification => Icons.notifications_outlined,
        ReminderType.alarm => Icons.alarm,
      };
}

/// Renumera los recordatorios si algún ID está fuera de rango o repetido (los antiguos eran aleatorios
/// de 1,000,000 en adelante). Devuelve `null` si no hace falta.
List<RosarioReminder>? renumberIfNeeded(List<RosarioReminder> reminders) {
  final ids = reminders.map((r) => r.id).toList();
  final validos = ids.every((id) => id >= 1 && id <= maxReminderId);
  final unicos = ids.toSet().length == ids.length;
  if (validos && unicos) return null;
  return [for (var i = 0; i < reminders.length; i++) reminders[i].copyWith(id: i + 1)];
}

/// Plantillas para crear recordatorios con un toque.
class ReminderTemplates {
  static const List<ReminderTemplate> templates = [
    ReminderTemplate(
      title: 'Rosario Matutino',
      description: 'Momento perfecto para comenzar el día con oración',
      time: TimeOfDay(hour: 7, minute: 0),
      daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
      type: ReminderType.notification,
    ),
    ReminderTemplate(
      title: 'Rosario de Mediodía',
      description: 'Una pausa espiritual en medio del día',
      time: TimeOfDay(hour: 12, minute: 0),
      daysOfWeek: [1, 2, 3, 4, 5],
      type: ReminderType.notification,
    ),
    ReminderTemplate(
      title: 'Rosario Vespertino',
      description: 'Termina tu día con la oración del Rosario',
      time: TimeOfDay(hour: 19, minute: 0),
      daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
      type: ReminderType.notification,
    ),
    ReminderTemplate(
      title: 'Rosario Dominical',
      description: 'Dedica tiempo especial los domingos',
      time: TimeOfDay(hour: 10, minute: 0),
      daysOfWeek: [7],
      type: ReminderType.alarm,
    ),
  ];
}

class ReminderTemplate {
  const ReminderTemplate({
    required this.title,
    required this.description,
    required this.time,
    required this.daysOfWeek,
    required this.type,
  });

  final String title;
  final String description;
  final TimeOfDay time;
  final List<int> daysOfWeek;
  final ReminderType type;
}
