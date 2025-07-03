import 'package:app_resar_rosario/constants/app_constants.dart';
import 'package:app_resar_rosario/models/reminder_model.dart';
import 'package:app_resar_rosario/services/notification_service.dart';
import 'package:app_resar_rosario/services/preferences_service.dart';
import 'package:app_resar_rosario/widgets/reminder_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class AgendarRosarioScreen extends StatefulWidget {
  final PreferencesService preferences;

  const AgendarRosarioScreen({
    super.key,
    required this.preferences,
  });

  @override
  State<AgendarRosarioScreen> createState() => _AgendarRosarioScreenState();
}

class _AgendarRosarioScreenState extends State<AgendarRosarioScreen> {
  late final NotificationService _notificationService;

  @override
  void initState() {
    super.initState();
    _notificationService = context.read<NotificationService>();
    _notificationService.requestPermissions();
  }

  void _showReminderForm({RosarioReminder? reminder}) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppConstants.radiusM)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ReminderForm(
          reminder: reminder,
          onSave: (reminderToSave) {
            final isCreating = reminder == null;
            if (isCreating) {
              _notificationService.addReminder(reminderToSave);
            } else {
              _notificationService.updateReminder(reminderToSave);
            }
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _showDeleteConfirmation(RosarioReminder reminder) {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar Recordatorio'),
          content: Text('¿Estás seguro de que quieres eliminar el recordatorio "${reminder.title}"?'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusS)),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
              onPressed: () {
                _notificationService.removeReminder(reminder.id);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text('Mis Recordatorios', style: TextStyle(color: AppConstants.textPrimary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppConstants.textPrimary),
      ),
      body: Consumer<NotificationService>(
        builder: (context, service, child) {
          if (service.reminders.isEmpty) {
            return const _EmptyState();
          }
          return ListView.builder(
            itemCount: service.reminders.length,
            padding: const EdgeInsets.all(12),
            itemBuilder: (context, index) {
              final reminder = service.reminders[index];
              return _ReminderCard(
                reminder: reminder,
                onToggle: (isActive) {
                  service.toggleReminder(reminder.id);
                },
                onEdit: () => _showReminderForm(reminder: reminder),
                onDelete: () => _showDeleteConfirmation(reminder),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showReminderForm(),
        backgroundColor: AppConstants.primaryBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final RosarioReminder reminder;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ReminderCard({
    required this.reminder,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final iconData = reminder.type == ReminderType.alarm ? Icons.alarm : Icons.notifications;
    final iconColor = reminder.type == ReminderType.alarm ? Colors.red.shade400 : AppConstants.primaryYellow;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(iconData, color: iconColor),
                    const SizedBox(width: 8),
                    Text(
                      reminder.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                Switch(
                  value: reminder.isActive,
                  onChanged: onToggle,
                  activeColor: AppConstants.primaryGreen,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              reminder.timeText,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: reminder.isActive ? AppConstants.textPrimary : Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6.0,
              runSpacing: 6.0,
              children: reminder.daysOfWeek.map((day) {
                return Chip(
                  label: Text(
                    {1: 'L', 2: 'M', 3: 'X', 4: 'J', 5: 'V', 6: 'S', 7: 'D'}[day]!,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: reminder.isActive ? AppConstants.secondaryBlue : Colors.grey,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                );
              }).toList(),
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  label: const Text('Editar'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 20),
                  label: const Text('Eliminar'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.alarm_add, size: 100, color: Colors.grey.shade300),
            const SizedBox(height: 24),
            const Text(
              'No hay recordatorios',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Presiona el botón + para programar tu primer recordatorio del Santo Rosario.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}