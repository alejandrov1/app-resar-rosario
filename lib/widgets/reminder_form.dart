import 'package:flutter/material.dart';
import '../models/reminder_model.dart';
import '../services/notification_service.dart';

class ReminderForm extends StatefulWidget {
  final RosarioReminder? reminder;
  final Function(RosarioReminder) onSave;

  const ReminderForm({
    Key? key,
    this.reminder,
    required this.onSave,
  }) : super(key: key);

  @override
  _ReminderFormState createState() => _ReminderFormState();
}

class _ReminderFormState extends State<ReminderForm> {
  final _formKey = GlobalKey<FormState>();
  late String _title;
  late TimeOfDay _time;
  late Set<int> _selectedDays;
  late ReminderType _type;

  @override
  void initState() {
    super.initState();
    final reminder = widget.reminder;
    if (reminder != null) {
      // Editando un recordatorio existente
      _title = reminder.title;
      _time = reminder.time;
      _selectedDays = Set.from(reminder.daysOfWeek);
      _type = reminder.type;
    } else {
      // Creando uno nuevo
      _title = 'Rezar el Santo Rosario';
      _time = TimeOfDay.now();
      _selectedDays = {};
      _type = ReminderType.alarm;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.reminder == null ? 'Nuevo Recordatorio' : 'Editar Recordatorio',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextFormField(
              initialValue: _title,
              decoration: const InputDecoration(
                labelText: 'Título del Recordatorio',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, ingresa un título';
                }
                return null;
              },
              onSaved: (value) => _title = value!,
            ),
            const SizedBox(height: 16),
            _buildTimePicker(),
            const SizedBox(height: 16),
            _buildDaySelector(),
             const SizedBox(height: 16),
            _buildTypeSelector(),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveForm,
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker() {
    return ListTile(
      title: const Text('Hora del recordatorio'),
      subtitle: Text(_time.format(context)),
      trailing: const Icon(Icons.edit_outlined),
      onTap: () async {
        final newTime = await showTimePicker(
          context: context,
          initialTime: _time,
        );
        if (newTime != null) {
          setState(() {
            _time = newTime;
          });
        }
      },
    );
  }

  Widget _buildDaySelector() {
    const days = {
      'L': DateTime.monday, 'M': DateTime.tuesday, 'X': DateTime.wednesday,
      'J': DateTime.thursday, 'V': DateTime.friday, 'S': DateTime.saturday, 'D': DateTime.sunday,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Repetir en los días:'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: days.entries.map((entry) {
            final isSelected = _selectedDays.contains(entry.value);
            return FilterChip(
              label: Text(entry.key),
              selected: isSelected,
              onSelected: (bool selected) {
                setState(() {
                  if (selected) {
                    _selectedDays.add(entry.value);
                  } else {
                    _selectedDays.remove(entry.value);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTypeSelector() {
    return DropdownButtonFormField<ReminderType>(
      value: _type,
      decoration: const InputDecoration(
        labelText: 'Tipo de Recordatorio',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(
          value: ReminderType.alarm,
          child: Text('Alarma (con sonido)'),
        ),
        DropdownMenuItem(
          value: ReminderType.notification,
          child: Text('Notificación (silenciosa)'),
        ),
      ],
      onChanged: (ReminderType? newValue) {
        if (newValue != null) {
          setState(() {
            _type = newValue;
          });
        }
      },
    );
  }

  void _saveForm() {
    final form = _formKey.currentState;
    if (form == null || !form.validate() || _selectedDays.isEmpty) {
      if (_selectedDays.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Debes seleccionar al menos un día.'),
            backgroundColor: Colors.orange,
        ));
      }
      return;
    }
    form.save();
    
    final reminderToSave = RosarioReminder(
      id: widget.reminder?.id ?? NotificationService().generateUniqueId(),
      title: _title,
      description: 'Es hora de tu oración diaria. El Señor esté contigo.',
      time: _time,
      daysOfWeek: _selectedDays.toList(),
      type: _type,
      isActive: widget.reminder?.isActive ?? true,
      // SOLUCIÓN: Añadir el campo requerido 'createdAt'.
      // Si estamos editando, usamos la fecha existente. Si es nuevo, usamos la fecha actual.
      createdAt: widget.reminder?.createdAt ?? DateTime.now(),
    );
    
    widget.onSave(reminderToSave);
  }
}