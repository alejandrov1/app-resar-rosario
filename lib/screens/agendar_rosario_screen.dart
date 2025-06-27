import 'package:app_resar_rosario/services/preferences_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';
import '../models/reminder_model.dart';
import '../widgets/reminder_form.dart'; 

class AgendarRosarioScreen extends StatefulWidget {
  // SOLUCIÓN: Añadir el servicio de preferencias que se le pasa desde el menú
  final PreferencesService preferences;

  const AgendarRosarioScreen({Key? key, required this.preferences}) : super(key: key);

  @override
  State<AgendarRosarioScreen> createState() => _AgendarRosarioScreenState();
}

class _AgendarRosarioScreenState extends State<AgendarRosarioScreen> {
  late NotificationService _notificationService;

  @override
  void initState() {
    super.initState();
    // Usamos 'read' en initState, que es más seguro que 'of'
    _notificationService = context.read<NotificationService>();
    _checkAndRequestPermissions();
  }

  Future<void> _checkAndRequestPermissions() async {
    final hasPermissions = await _notificationService.hasPermissions();
    if (!hasPermissions) {
      final requested = await _notificationService.requestPermissions();
      if (!requested && mounted) {
        _showErrorDialog();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Recordatorios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined),
            tooltip: 'Probar Notificación',
            onPressed: _sendTestNotification,
          ),
        ],
      ),
      // Usamos Consumer para escuchar los cambios en NotificationService
      body: Consumer<NotificationService>(
        builder: (context, service, child) {
          if (service.reminders.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'Aún no tienes recordatorios.\n¡Presiona el botón "+" para agregar el primero!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ),
            );
          }
          // Ordenar recordatorios por fecha de creación
          final sortedReminders = List<RosarioReminder>.from(service.reminders)
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80), // Espacio para el FAB
            itemCount: sortedReminders.length,
            itemBuilder: (context, index) {
              final reminder = sortedReminders[index];
              return _buildReminderCard(reminder);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showReminderForm(),
        tooltip: 'Agregar Recordatorio',
        child: const Icon(Icons.add),
      ),
    );
  }

  // Muestra el formulario para crear o editar un recordatorio
  void _showReminderForm({RosarioReminder? reminder}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          // Usamos el nuevo widget ReminderForm
          child: ReminderForm(
            reminder: reminder,
            onSave: (newReminder) async {
              if (reminder == null) {
                // Creando nuevo recordatorio
                await _notificationService.addReminder(newReminder);
              } else {
                // Actualizando recordatorio existente
                await _notificationService.updateReminder(newReminder);
              }
              if (mounted) Navigator.pop(context); // Cierra el BottomSheet
            },
          ),
        );
      },
    );
  }
  
  // Widget para mostrar cada tarjeta de recordatorio
  Widget _buildReminderCard(RosarioReminder reminder) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    reminder.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Switch(
                  value: reminder.isActive,
                  onChanged: (value) {
                    _notificationService.toggleReminder(reminder.id);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${reminder.timeText} - ${reminder.daysText}',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            Text(
              'Tipo: ${reminder.type.displayName}',
               style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.edit, size: 20),
                  label: const Text('Editar'),
                  onPressed: () => _showReminderForm(reminder: reminder),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  label: const Text('Eliminar'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: () => _confirmDelete(reminder),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // Muestra diálogo de confirmación antes de borrar
  void _confirmDelete(RosarioReminder reminder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar Recordatorio?'),
        content: Text('Estás a punto de eliminar el recordatorio "${reminder.title}". Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              _notificationService.removeReminder(reminder.id);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendTestNotification() async {
    final success = await _notificationService.sendTestNotification();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Notificación de prueba enviada.'
              : 'Error al enviar. Revisa los permisos.'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Permisos Requeridos"),
        content: const Text(
            "Para programar alarmas y notificaciones, la app necesita permisos. Por favor, actívalos desde la configuración de tu dispositivo."),
        actions: [
          TextButton(
            child: const Text("OK"),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}