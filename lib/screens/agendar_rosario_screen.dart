import 'package:app_resar_rosario/services/preferences_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/notification_service.dart';
import '../models/reminder_model.dart';
import '../widgets/reminder_form.dart';
import '../constants/app_constants.dart';

class AgendarRosarioScreen extends StatefulWidget {
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
    _notificationService = context.read<NotificationService>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndRequestPermissions();
    });
  }

  Future<void> _checkAndRequestPermissions() async {
    final hasPermissions = await _notificationService.hasPermissions();
    if (!hasPermissions && mounted) {
      final requested = await _notificationService.requestPermissions();
      if (!requested && mounted) {
        _showPermissionsErrorDialog();
      }
    }
  }
  
  void _showReminderForm({RosarioReminder? reminder}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppConstants.radiusM)),
      ),
      builder: (ctx) { // Usamos un nuevo BuildContext 'ctx' del builder
        return ReminderForm(
          reminder: reminder,
          onSave: (newReminder) async {
            // SOLUCIÓN: Lógica de guardado robusta.
            bool success = false;
            try {
              // El 'id' es 0 si es un recordatorio nuevo.
              if (newReminder.id == 0) {
                success = await _notificationService.addReminder(newReminder);
              } else {
                success = await _notificationService.updateReminder(newReminder);
              }

              // Solo interactuar con la UI si el widget sigue montado.
              if (!ctx.mounted) return;
              
              Navigator.pop(ctx); // Cerrar el modal DESPUÉS de guardar.
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success ? 'Recordatorio guardado.' : 'Error al guardar el recordatorio.'),
                  backgroundColor: success ? Colors.green : Colors.red,
                ),
              );

            } catch (e) {
               debugPrint("Error al guardar: $e");
               if (ctx.mounted) Navigator.pop(ctx);
               _showSaveErrorDialog();
            }
          },
        );
      },
    );
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
      body: Consumer<NotificationService>( // Consumer reconstruye la lista cuando hay cambios.
        builder: (context, service, child) {
          if (service.reminders.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(AppConstants.spacingL),
                child: Text(
                  'Aún no tienes recordatorios.\n¡Presiona el botón "+" para agregar el primero!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: AppConstants.fontSizeM, color: AppConstants.textSecondary),
                ),
              ),
            );
          }
          final sortedReminders = List<RosarioReminder>.from(service.reminders)
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80, top: 8),
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

  Widget _buildReminderCard(RosarioReminder reminder) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.spacingS, vertical: AppConstants.spacingXS),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusS)),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingS),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    reminder.title,
                    style: const TextStyle(fontSize: AppConstants.fontSizeM, fontWeight: FontWeight.bold),
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
            const SizedBox(height: AppConstants.spacingXS),
            Text(
              '${reminder.timeText} - ${reminder.daysText}',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            Text(
              'Tipo: ${reminder.type.displayName}',
               style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: AppConstants.spacingXS),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.edit, size: 20),
                  label: const Text('Editar'),
                  onPressed: () => _showReminderForm(reminder: reminder),
                ),
                const SizedBox(width: AppConstants.spacingXS),
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

  void _confirmDelete(RosarioReminder reminder) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar Recordatorio?'),
        content: Text('Estás a punto de eliminar "${reminder.title}". Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _notificationService.removeReminder(reminder.id);
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

  void _showPermissionsErrorDialog() {
    if(!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Permisos Requeridos"),
        content: const Text(
            "Para programar alarmas, la app necesita permisos especiales. Por favor, actívalos desde la configuración de tu dispositivo."),
        actions: [
          TextButton(
            child: const Text("Abrir configuración"),
            onPressed: () {
              openAppSettings();
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: const Text("OK"),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
  
  void _showSaveErrorDialog() {
    if(!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Error al Guardar"),
        content: const Text(
            "No se pudo guardar el recordatorio. Por favor, revisa que la aplicación tenga todos los permisos necesarios en la configuración del sistema."),
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