import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/reminder_model.dart';
import '../constants/app_constants.dart';

class ReminderForm extends StatefulWidget {
  final RosarioReminder? reminder;
  final Function(RosarioReminder) onSave;

  const ReminderForm({
    Key? key,
    this.reminder,
    required this.onSave,
  }) : super(key: key);

  @override
  State<ReminderForm> createState() => _ReminderFormState();
}

class _ReminderFormState extends State<ReminderForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TimeOfDay _time;
  late Set<int> _selectedDays;
  late ReminderType _type;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final reminder = widget.reminder;
    if (reminder != null) {
      _titleController = TextEditingController(text: reminder.title);
      _time = reminder.time;
      _selectedDays = Set.from(reminder.daysOfWeek);
      _type = reminder.type;
    } else {
      _titleController = TextEditingController(text: 'Rezar el Santo Rosario');
      _time = TimeOfDay.now();
      _selectedDays = {};
      _type = ReminderType.notification;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }
  
  void _saveForm() {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    
    if (_selectedDays.isEmpty) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Por favor, selecciona al menos un día'),
          backgroundColor: Colors.orange.shade700,
        ),
      );
      return;
    }
    
    setState(() {
      _isSaving = true;
    });

    form.save();
    
    final reminderToSave = RosarioReminder(
      id: widget.reminder?.id ?? 0,
      title: _titleController.text.trim(),
      description: 'Es hora de tu oración diaria. El Señor está contigo.',
      time: _time,
      daysOfWeek: _selectedDays.toList()..sort(),
      type: _type,
      isActive: widget.reminder?.isActive ?? true,
      createdAt: widget.reminder?.createdAt ?? DateTime.now(),
    );
    
    // SOLUCIÓN: Llamar a la función onSave que ahora hará el trabajo asíncrono.
    // El 'setState' de _isSaving se manejará desde la pantalla principal.
    widget.onSave(reminderToSave);
  }

  @override
  Widget build(BuildContext context) {
    // El SingleChildScrollView y Padding ahora envuelven el Form.
    return SingleChildScrollView(
      child: Padding(
        // Padding para evitar que el teclado cubra el formulario.
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: AppConstants.spacingM,
          right: AppConstants.spacingM,
          top: AppConstants.spacingM
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
               Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.reminder == null ? 'Nuevo Recordatorio' : 'Editar Recordatorio',
                    style: const TextStyle(
                      fontSize: AppConstants.fontSizeL,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    color: AppConstants.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.spacingM),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Título del Recordatorio',
                  prefixIcon: const Icon(Icons.edit, color: AppConstants.primaryBlue),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusS),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                maxLength: 50,
                textCapitalization: TextCapitalization.sentences,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, ingresa un título';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppConstants.spacingS),
              _buildTimePicker(),
              const SizedBox(height: AppConstants.spacingM),
              _buildDaySelector(),
              const SizedBox(height: AppConstants.spacingM),
              _buildTypeSelector(),
              const SizedBox(height: AppConstants.spacingL),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacingS),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveForm,
                      icon: _isSaving
                          ? const SizedBox.shrink()
                          : const Icon(Icons.save),
                      label: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                            )
                          : const Text('Guardar'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.spacingS),
            ],
          ),
        ),
      ),
    );
  }

  // Los widgets _buildTimePicker, _buildDaySelector, etc. se quedan igual que antes.
  Widget _buildTimePicker() {
    return InkWell(
      onTap: () async {
        HapticFeedback.lightImpact();
        final newTime = await showTimePicker(
          context: context,
          initialTime: _time,
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: AppConstants.primaryBlue,
                  onPrimary: Colors.white,
                  onSurface: AppConstants.textPrimary,
                ),
              ),
              child: child!,
            );
          },
        );
        if (newTime != null) {
          setState(() {
            _time = newTime;
          });
        }
      },
      borderRadius: BorderRadius.circular(AppConstants.radiusS),
      child: Container(
        padding: const EdgeInsets.all(AppConstants.spacingS),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(AppConstants.radiusS),
          color: Colors.grey.shade50,
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time, color: AppConstants.primaryBlue),
            const SizedBox(width: AppConstants.spacingS),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hora del recordatorio',
                    style: TextStyle(
                      fontSize: AppConstants.fontSizeXS,
                      color: AppConstants.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _time.format(context),
                    style: const TextStyle(
                      fontSize: AppConstants.fontSizeM,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.edit_outlined, color: AppConstants.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDaySelector() {
    const days = [
      {'short': 'L', 'value': DateTime.monday},
      {'short': 'M', 'value': DateTime.tuesday},
      {'short': 'X', 'value': DateTime.wednesday},
      {'short': 'J', 'value': DateTime.thursday},
      {'short': 'V', 'value': DateTime.friday},
      {'short': 'S', 'value': DateTime.saturday},
      {'short': 'D', 'value': DateTime.sunday},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Repetir los días:'),
            if (_selectedDays.isEmpty)
              Text('Selecciona al menos un día', style: TextStyle(color: Colors.red.shade600)),
          ],
        ),
        const SizedBox(height: AppConstants.spacingXS),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: days.map((day) {
            final isSelected = _selectedDays.contains(day['value'] as int);
            return InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  if (isSelected) {
                    _selectedDays.remove(day['value'] as int);
                  } else {
                    _selectedDays.add(day['value'] as int);
                  }
                });
              },
              borderRadius: BorderRadius.circular(AppConstants.radiusCircle),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected ? AppConstants.primaryBlue : Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    day['short'] as String,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppConstants.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tipo de recordatorio:'),
        const SizedBox(height: AppConstants.spacingXS),
        RadioListTile<ReminderType>(
          title: const Text('Notificación'),
          subtitle: const Text('Recordatorio silencioso'),
          value: ReminderType.notification,
          groupValue: _type,
          onChanged: (value) => setState(() => _type = value!),
        ),
        RadioListTile<ReminderType>(
          title: const Text('Alarma'),
          subtitle: const Text('Con sonido y vibración'),
          value: ReminderType.alarm,
          groupValue: _type,
          onChanged: (value) => setState(() => _type = value!),
        ),
      ],
    );
  }
}