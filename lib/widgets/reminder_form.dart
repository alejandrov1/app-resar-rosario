import 'package:app_resar_rosario/constants/app_constants.dart';
import 'package:app_resar_rosario/models/reminder_model.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ReminderForm extends StatefulWidget {
  final RosarioReminder? reminder;
  final Function(RosarioReminder) onSave;

  const ReminderForm({
    super.key,
    this.reminder,
    required this.onSave,
  });

  @override
  State<ReminderForm> createState() => _ReminderFormState();
}

class _ReminderFormState extends State<ReminderForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TimeOfDay _time;
  late Set<int> _selectedDays;
  late ReminderType _type;
  String? _soundPath;
  String _soundName = 'Sonido de alarma por defecto';

  @override
  void initState() {
    super.initState();
    final reminder = widget.reminder;
    if (reminder != null) {
      _titleController = TextEditingController(text: reminder.title);
      _time = reminder.time;
      _selectedDays = Set.from(reminder.daysOfWeek);
      _type = reminder.type;
      _soundPath = reminder.sound;
      if (reminder.sound != null) {
        _soundName = reminder.sound!.split('/').last;
      }
    } else {
      _titleController = TextEditingController(text: 'Rezar el Santo Rosario');
      _time = const TimeOfDay(hour: 20, minute: 0);
      _selectedDays = {1, 2, 3, 4, 5, 6, 7};
      _type = ReminderType.notification;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickSound() async {
    HapticFeedback.lightImpact();
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );

    if (result != null) {
      setState(() {
        _soundPath = result.files.single.path;
        _soundName = result.files.single.name;
      });
    }
  }

  void _saveForm() {
    if (!_formKey.currentState!.validate() || _selectedDays.isEmpty) {
      if (_selectedDays.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Debes seleccionar al menos un día.'),
          backgroundColor: Colors.orange,
        ));
      }
      return;
    }

    final reminderToSave = RosarioReminder(
      id: widget.reminder?.id ?? DateTime.now().millisecondsSinceEpoch,
      title: _titleController.text.trim(),
      description: 'Es hora de tu oración del Santo Rosario.',
      time: _time,
      daysOfWeek: _selectedDays.toList()..sort(),
      type: _type,
      isActive: widget.reminder?.isActive ?? true,
      createdAt: widget.reminder?.createdAt ?? DateTime.now(),
      sound: _soundPath,
    );
    widget.onSave(reminderToSave);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.reminder == null ? 'Nuevo Recordatorio' : 'Editar Recordatorio',
                  style: const TextStyle(fontSize: AppConstants.fontSizeL, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingM),

            // Campo de título
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Título'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor ingresa un título';
                }
                return null;
              },
            ),
            const SizedBox(height: AppConstants.spacingM),

            // Selector de hora
            _buildTimePicker(),
            const SizedBox(height: AppConstants.spacingM),

            // Selector de días
            _buildDaySelector(),
            const SizedBox(height: AppConstants.spacingM),
            
            // Selector de tipo (Notificación/Alarma)
            _buildTypeSelector(),

            // **SINTAXIS CORREGIDA para añadir widget condicional**
            if (_type == ReminderType.alarm) ...[
              const SizedBox(height: AppConstants.spacingM),
              _buildSoundPicker(),
            ],

            const SizedBox(height: AppConstants.spacingL),
            
            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: AppConstants.spacingS),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveForm,
                    child: const Text('Guardar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // --- WIDGETS AUXILIARES REINCORPORADOS ---

  Widget _buildTimePicker() {
    return ListTile(
      leading: const Icon(Icons.access_time),
      title: const Text('Hora del recordatorio'),
      subtitle: Text(_time.format(context)),
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
    const days = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Días de recordatorio', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ToggleButtons(
          isSelected: List.generate(7, (index) => _selectedDays.contains(index + 1)),
          onPressed: (index) {
            setState(() {
              final day = index + 1;
              if (_selectedDays.contains(day)) {
                _selectedDays.remove(day);
              } else {
                _selectedDays.add(day);
              }
            });
          },
          children: days.map((day) => Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text(day))).toList(),
        ),
      ],
    );
  }
  
  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tipo de recordatorio', style: TextStyle(fontWeight: FontWeight.bold)),
        RadioListTile<ReminderType>(
          title: const Text('Notificación'),
          subtitle: const Text('Recordatorio silencioso'),
          value: ReminderType.notification,
          groupValue: _type,
          onChanged: (value) {
            setState(() {
              if (value != null) _type = value;
            });
          },
        ),
        RadioListTile<ReminderType>(
          title: const Text('Alarma'),
          subtitle: const Text('Con sonido y vibración'),
          value: ReminderType.alarm,
          groupValue: _type,
          onChanged: (value) {
            setState(() {
              if (value != null) _type = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildSoundPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sonido de Alarma',
          style: TextStyle(fontSize: AppConstants.fontSizeM, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppConstants.spacingS),
        InkWell(
          onTap: _pickSound,
          borderRadius: BorderRadius.circular(AppConstants.radiusS),
          child: Container(
            padding: const EdgeInsets.all(AppConstants.spacingS),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(AppConstants.radiusS),
            ),
            child: Row(
              children: [
                const Icon(Icons.music_note_outlined, color: AppConstants.primaryBlue),
                const SizedBox(width: AppConstants.spacingS),
                Expanded(
                  child: Text(
                    _soundName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppConstants.textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }
}