import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/reminder_model.dart';
import '../services/notification_service.dart';
import '../services/preferences_service.dart';
import '../constants/app_constants.dart';

class AgendarRosarioScreen extends StatefulWidget {
  final PreferencesService preferences;

  const AgendarRosarioScreen({
    super.key,
    required this.preferences,
  });

  @override
  State<AgendarRosarioScreen> createState() => _AgendarRosarioScreenState();
}

class _AgendarRosarioScreenState extends State<AgendarRosarioScreen>
    with TickerProviderStateMixin {
  final NotificationService _notificationService = NotificationService();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _hasPermissions = false;
  bool _isCheckingPermissions = true;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _checkPermissionsAndInitialize();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));

    _animationController.forward();
  }

  Future<void> _checkPermissionsAndInitialize() async {
    try {
      await _notificationService.initialize();
      final hasPermissions = await _notificationService.hasPermissions();
      
      setState(() {
        _hasPermissions = hasPermissions;
        _isCheckingPermissions = false;
      });
    } catch (e) {
      setState(() {
        _hasPermissions = false;
        _isCheckingPermissions = false;
      });
    }
  }

  Future<void> _requestPermissions() async {
    final granted = await _notificationService.requestPermissions();
    setState(() {
      _hasPermissions = granted;
    });

    if (granted) {
      _showSnackBar('Permisos concedidos correctamente', isSuccess: true);
    } else {
      _showSnackBar('Se necesitan permisos para programar recordatorios', isSuccess: false);
    }
  }

  void _showSnackBar(String message, {required bool isSuccess}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppConstants.primaryBlue,
              AppConstants.secondaryBlue,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(AppConstants.spacingS),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: _isCheckingPermissions
                      ? _buildLoadingView()
                      : _hasPermissions
                          ? _buildMainContent()
                          : _buildPermissionsView(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingS),
        child: Row(
          children: [
            IconButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 28,
              ),
            ),
            Expanded(
              child: Text(
                'Agendar Rosario',
                style: TextStyle(
                  fontSize: AppConstants.fontSizeL * widget.preferences.textScaleFactor,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 48), // Para centrar el título
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppConstants.primaryBlue),
          SizedBox(height: AppConstants.spacingM),
          Text(
            'Inicializando...',
            style: TextStyle(
              fontSize: AppConstants.fontSizeM,
              color: AppConstants.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsView() {
    return SlideTransition(
      position: _slideAnimation,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 80,
              color: AppConstants.primaryBlue.withOpacity(0.7),
            ),
            const SizedBox(height: AppConstants.spacingM),
            Text(
              'Permisos Necesarios',
              style: TextStyle(
                fontSize: AppConstants.fontSizeL * widget.preferences.textScaleFactor,
                fontWeight: FontWeight.bold,
                color: AppConstants.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingS),
            Text(
              'Para programar recordatorios del Rosario, necesitamos permisos para:',
              style: TextStyle(
                fontSize: AppConstants.fontSizeS * widget.preferences.textScaleFactor,
                color: AppConstants.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingM),
            _buildPermissionItem(
              Icons.notifications,
              'Mostrar notificaciones',
              'Para recordarte la hora del Rosario',
            ),
            _buildPermissionItem(
              Icons.alarm,
              'Programar alarmas',
              'Para alarmas sonoras precisas',
            ),
            _buildPermissionItem(
              Icons.battery_saver,
              'Optimización de batería',
              'Para funcionar en segundo plano',
            ),
            const SizedBox(height: AppConstants.spacingL),
            ElevatedButton.icon(
              onPressed: _requestPermissions,
              icon: const Icon(Icons.check_circle),
              label: Text(
                'Conceder Permisos',
                style: TextStyle(
                  fontSize: AppConstants.fontSizeM * widget.preferences.textScaleFactor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryBlue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingL,
                  vertical: widget.preferences.useLargeButtons 
                      ? AppConstants.spacingM 
                      : AppConstants.spacingS,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusS),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingXS),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppConstants.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppConstants.primaryBlue,
              size: 24,
            ),
          ),
          const SizedBox(width: AppConstants.spacingS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: AppConstants.fontSizeS * widget.preferences.textScaleFactor,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textPrimary,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: AppConstants.fontSizeXS * widget.preferences.textScaleFactor,
                    color: AppConstants.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          _buildTopSection(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.spacingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildQuickTemplatesSection(),
                  const SizedBox(height: AppConstants.spacingL),
                  _buildCustomReminderSection(),
                  const SizedBox(height: AppConstants.spacingL),
                  _buildActiveRemindersSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSection() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppConstants.primaryBlue.withOpacity(0.1),
            AppConstants.secondaryBlue.withOpacity(0.05),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppConstants.radiusM),
          topRight: Radius.circular(AppConstants.radiusM),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppConstants.primaryBlue.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.schedule,
              color: AppConstants.primaryBlue,
              size: 32,
            ),
          ),
          const SizedBox(width: AppConstants.spacingS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Programa tu tiempo de oración',
                  style: TextStyle(
                    fontSize: AppConstants.fontSizeM * widget.preferences.textScaleFactor,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.textPrimary,
                  ),
                ),
                Text(
                  'Crea recordatorios personalizados para no olvidar el Rosario',
                  style: TextStyle(
                    fontSize: AppConstants.fontSizeXS * widget.preferences.textScaleFactor,
                    color: AppConstants.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTemplatesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Plantillas Rápidas',
          style: TextStyle(
            fontSize: AppConstants.fontSizeM * widget.preferences.textScaleFactor,
            fontWeight: FontWeight.bold,
            color: AppConstants.textPrimary,
          ),
        ),
        const SizedBox(height: AppConstants.spacingS),
        Text(
          'Configura recordatorios comunes con un toque',
          style: TextStyle(
            fontSize: AppConstants.fontSizeXS * widget.preferences.textScaleFactor,
            color: AppConstants.textSecondary,
          ),
        ),
        const SizedBox(height: AppConstants.spacingS),
        ...ReminderTemplates.templates.map((template) => 
          _buildTemplateCard(template),
        ),
      ],
    );
  }

  Widget _buildTemplateCard(ReminderTemplate template) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingS),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusS),
      ),
      child: InkWell(
        onTap: () => _useTemplate(template),
        borderRadius: BorderRadius.circular(AppConstants.radiusS),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingS),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: template.type.icon == Icons.alarm 
                      ? Colors.orange.withOpacity(0.1)
                      : AppConstants.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  template.type.icon,
                  color: template.type.icon == Icons.alarm 
                      ? Colors.orange
                      : AppConstants.primaryBlue,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppConstants.spacingS),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.title,
                      style: TextStyle(
                        fontSize: AppConstants.fontSizeS * widget.preferences.textScaleFactor,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.textPrimary,
                      ),
                    ),
                    Text(
                      template.description,
                      style: TextStyle(
                        fontSize: AppConstants.fontSizeXS * widget.preferences.textScaleFactor,
                        color: AppConstants.textSecondary,
                      ),
                    ),
                    Text(
                      '${template.time.format(context)} • ${_getDaysText(template.daysOfWeek)}',
                      style: TextStyle(
                        fontSize: AppConstants.fontSizeXS * widget.preferences.textScaleFactor,
                        color: AppConstants.primaryBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.add_circle_outline,
                color: AppConstants.primaryBlue,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomReminderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recordatorio Personalizado',
          style: TextStyle(
            fontSize: AppConstants.fontSizeM * widget.preferences.textScaleFactor,
            fontWeight: FontWeight.bold,
            color: AppConstants.textPrimary,
          ),
        ),
        const SizedBox(height: AppConstants.spacingS),
        ElevatedButton.icon(
          onPressed: _createCustomReminder,
          icon: const Icon(Icons.add),
          label: Text(
            'Crear Nuevo Recordatorio',
            style: TextStyle(
              fontSize: AppConstants.fontSizeS * widget.preferences.textScaleFactor,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.primaryBlue,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
              horizontal: AppConstants.spacingM,
              vertical: widget.preferences.useLargeButtons 
                  ? AppConstants.spacingS 
                  : AppConstants.spacingXS,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusS),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveRemindersSection() {
    return ListenableBuilder(
      listenable: _notificationService,
      builder: (context, child) {
        final activeReminders = _notificationService.reminders
            .where((r) => r.isActive)
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recordatorios Activos',
                  style: TextStyle(
                    fontSize: AppConstants.fontSizeM * widget.preferences.textScaleFactor,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.textPrimary,
                  ),
                ),
                if (activeReminders.isNotEmpty)
                  TextButton(
                    onPressed: _manageAllReminders,
                    child: Text(
                      'Ver todos',
                      style: TextStyle(
                        fontSize: AppConstants.fontSizeXS * widget.preferences.textScaleFactor,
                        color: AppConstants.primaryBlue,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingS),
            if (activeReminders.isEmpty)
              _buildEmptyRemindersView()
            else
              ...activeReminders.take(3).map((reminder) => 
                _buildReminderCard(reminder),
              ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyRemindersView() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(AppConstants.radiusS),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.notifications_none,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: AppConstants.spacingS),
          Text(
            'No tienes recordatorios activos',
            style: TextStyle(
              fontSize: AppConstants.fontSizeS * widget.preferences.textScaleFactor,
              color: AppConstants.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            'Crea tu primer recordatorio para no olvidar el Rosario',
            style: TextStyle(
              fontSize: AppConstants.fontSizeXS * widget.preferences.textScaleFactor,
              color: AppConstants.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReminderCard(RosarioReminder reminder) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingS),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusS),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingS),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                reminder.type.icon,
                color: Colors.green,
                size: 20,
              ),
            ),
            const SizedBox(width: AppConstants.spacingS),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reminder.title,
                    style: TextStyle(
                      fontSize: AppConstants.fontSizeS * widget.preferences.textScaleFactor,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                  Text(
                    '${reminder.timeText} • ${reminder.daysText}',
                    style: TextStyle(
                      fontSize: AppConstants.fontSizeXS * widget.preferences.textScaleFactor,
                      color: AppConstants.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: reminder.isActive,
              onChanged: (value) => _toggleReminder(reminder.id),
              activeColor: AppConstants.primaryBlue,
            ),
          ],
        ),
      ),
    );
  }

  String _getDaysText(List<int> daysOfWeek) {
    if (daysOfWeek.length == 7) return 'Todos los días';
    
    const dayNames = {
      1: 'Lun', 2: 'Mar', 3: 'Mié', 4: 'Jue',
      5: 'Vie', 6: 'Sáb', 7: 'Dom',
    };
    
    final sortedDays = List<int>.from(daysOfWeek)..sort();
    return sortedDays.map((day) => dayNames[day]).join(', ');
  }

  Future<void> _useTemplate(ReminderTemplate template) async {
    final id = _notificationService.generateUniqueId();
    final reminder = template.toReminder(id);
    
    final success = await _notificationService.addReminder(reminder);
    if (success) {
      HapticFeedback.mediumImpact();
      _showSnackBar('Recordatorio "${template.title}" creado', isSuccess: true);
    } else {
      _showSnackBar('Error al crear el recordatorio', isSuccess: false);
    }
  }

  void _createCustomReminder() {
    // Navegar a una pantalla de creación personalizada
    // Por ahora mostraremos un diálogo simple
    _showCustomReminderDialog();
  }

  void _showCustomReminderDialog() {
    showDialog(
      context: context,
      builder: (context) => CustomReminderDialog(
        preferences: widget.preferences,
        onReminderCreated: (reminder) async {
          final success = await _notificationService.addReminder(reminder);
          if (success) {
            _showSnackBar('Recordatorio creado exitosamente', isSuccess: true);
          } else {
            _showSnackBar('Error al crear el recordatorio', isSuccess: false);
          }
        },
      ),
    );
  }

  Future<void> _toggleReminder(int reminderId) async {
    final success = await _notificationService.toggleReminder(reminderId);
    if (!success) {
      _showSnackBar('Error al cambiar el recordatorio', isSuccess: false);
    }
  }

  void _manageAllReminders() {
    // Navegar a una pantalla de gestión de todos los recordatorios
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManageRemindersScreen(
          preferences: widget.preferences,
        ),
      ),
    );
  }
}

// Diálogo para crear recordatorios personalizados
class CustomReminderDialog extends StatefulWidget {
  final PreferencesService preferences;
  final Function(RosarioReminder) onReminderCreated;

  const CustomReminderDialog({
    super.key,
    required this.preferences,
    required this.onReminderCreated,
  });

  @override
  State<CustomReminderDialog> createState() => _CustomReminderDialogState();
}

class _CustomReminderDialogState extends State<CustomReminderDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  List<int> _selectedDays = [1, 2, 3, 4, 5, 6, 7];
  ReminderType _selectedType = ReminderType.notification;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuevo Recordatorio'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Título',
                hintText: 'Ej: Rosario Matutino',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                hintText: 'Una breve descripción...',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Hora'),
              subtitle: Text(_selectedTime.format(context)),
              trailing: const Icon(Icons.access_time),
              onTap: _selectTime,
            ),
            const SizedBox(height: 16),
            const Text('Días de la semana:'),
            Wrap(
              children: [
                for (int i = 1; i <= 7; i++)
                  FilterChip(
                    label: Text(_getDayName(i)),
                    selected: _selectedDays.contains(i),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedDays.add(i);
                        } else {
                          _selectedDays.remove(i);
                        }
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ReminderType>(
              value: _selectedType,
              decoration: const InputDecoration(labelText: 'Tipo'),
              items: ReminderType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.displayName),
                );
              }).toList(),
              onChanged: (type) {
                if (type != null) {
                  setState(() {
                    _selectedType = type;
                  });
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _createReminder,
          child: const Text('Crear'),
        ),
      ],
    );
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  String _getDayName(int day) {
    const names = ['', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return names[day];
  }

  void _createReminder() {
    if (_titleController.text.isEmpty || _selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    final reminder = RosarioReminder(
      id: DateTime.now().millisecondsSinceEpoch,
      title: _titleController.text,
      description: _descriptionController.text.isEmpty 
          ? 'Hora de rezar el Santo Rosario'
          : _descriptionController.text,
      time: _selectedTime,
      daysOfWeek: _selectedDays,
      isActive: true,
      type: _selectedType,
      createdAt: DateTime.now(),
    );

    widget.onReminderCreated(reminder);
    Navigator.pop(context);
  }
}

// Pantalla para gestionar todos los recordatorios
class ManageRemindersScreen extends StatelessWidget {
  final PreferencesService preferences;

  const ManageRemindersScreen({
    super.key,
    required this.preferences,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionar Recordatorios'),
        backgroundColor: AppConstants.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: ListenableBuilder(
        listenable: NotificationService(),
        builder: (context, child) {
          final reminders = NotificationService().reminders;
          
          if (reminders.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No tienes recordatorios',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reminders.length,
            itemBuilder: (context, index) {
              final reminder = reminders[index];
              return Card(
                child: ListTile(
                  leading: Icon(reminder.type.icon),
                  title: Text(reminder.title),
                  subtitle: Text('${reminder.timeText} • ${reminder.daysText}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch.adaptive(
                        value: reminder.isActive,
                        onChanged: (value) {
                          NotificationService().toggleReminder(reminder.id);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          NotificationService().removeReminder(reminder.id);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}