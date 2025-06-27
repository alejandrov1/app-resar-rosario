import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/reminder_model.dart';
import '../services/notification_service.dart';
import '../services/preferences_service.dart';
import '../constants/app_constants.dart';
import 'package:permission_handler/permission_handler.dart' as permission_handler;

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
  bool _isCreatingReminder = false;

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
      // Asegurar que el servicio esté inicializado
      if (!_notificationService.isInitialized) {
        await _notificationService.initialize();
      }
      
      final hasPermissions = await _notificationService.hasPermissions();
      
      if (mounted) {
        setState(() {
          _hasPermissions = hasPermissions;
          _isCheckingPermissions = false;
        });
      }
    } catch (e) {
      debugPrint('Error al verificar permisos: $e');
      if (mounted) {
        setState(() {
          _hasPermissions = false;
          _isCheckingPermissions = false;
        });
      }
    }
  }

  Future<void> _requestPermissions() async {
    setState(() {
      _isCheckingPermissions = true;
    });
    
    try {
      final granted = await _notificationService.requestPermissions();
      
      if (mounted) {
        setState(() {
          _hasPermissions = granted;
          _isCheckingPermissions = false;
        });

        if (granted) {
          _showSnackBar('✓ Permisos concedidos correctamente', isSuccess: true);
          // Probar notificación
          _testNotification();
        } else {
          _showErrorDialog();
        }
      }
    } catch (e) {
      debugPrint('Error al solicitar permisos: $e');
      if (mounted) {
        setState(() {
          _isCheckingPermissions = false;
        });
        _showSnackBar('Error al solicitar permisos', isSuccess: false);
      }
    }
  }

  Future<void> _testNotification() async {
    final success = await _notificationService.sendTestNotification();
    if (success) {
      _showSnackBar('✓ Notificación de prueba enviada', isSuccess: true);
    }
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permisos Requeridos'),
        content: const Text(
          'Para programar recordatorios, necesitamos acceso a las notificaciones.\n\n'
          'Por favor, ve a Configuración > Aplicaciones > Santo Rosario > Permisos '
          'y activa las notificaciones manualmente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              permission_handler.openAppSettings();
            },
            child: const Text('Ir a Configuración'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {required bool isSuccess}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: Duration(seconds: isSuccess ? 3 : 5),
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
            // Botón de ayuda
            IconButton(
              onPressed: _showHelpDialog,
              icon: const Icon(
                Icons.help_outline,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cómo funciona?'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '1. Selecciona una plantilla rápida o crea un recordatorio personalizado.\n\n'
                '2. Elige los días y la hora en que quieres recibir el recordatorio.\n\n'
                '3. Selecciona el tipo:\n'
                '   • Notificación: Silenciosa\n'
                '   • Alarma: Con sonido\n\n'
                '4. Los recordatorios se repetirán cada semana en los días seleccionados.\n\n'
                '5. Puedes activar o desactivar los recordatorios cuando quieras.',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
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
            'Verificando permisos...',
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
      child: SingleChildScrollView(
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
              'Para programar recordatorios del Rosario, necesitamos tu permiso para:',
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
              'Te recordaremos cuando sea hora de rezar',
            ),
            _buildPermissionItem(
              Icons.alarm,
              'Programar alarmas',
              'Para que no olvides tu momento de oración',
            ),
            _buildPermissionItem(
              Icons.phone_android,
              'Funcionar en segundo plano',
              'Los recordatorios funcionarán aunque la app esté cerrada',
            ),
            const SizedBox(height: AppConstants.spacingL),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isCheckingPermissions ? null : _requestPermissions,
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
            ),
            const SizedBox(height: AppConstants.spacingS),
            TextButton(
              onPressed: () => permission_handler.openAppSettings(),
              child: const Text(
                'Abrir configuración del teléfono',
                style: TextStyle(color: AppConstants.primaryBlue),
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
      child: Container(
        padding: const EdgeInsets.all(AppConstants.spacingS),
        decoration: BoxDecoration(
          color: AppConstants.primaryBlue.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppConstants.primaryBlue.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppConstants.primaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
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
                  const SizedBox(height: 2),
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
                  const SizedBox(height: AppConstants.spacingM),
                  _buildTestNotificationButton(),
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
              gradient: const LinearGradient(
                colors: [
                  AppConstants.primaryBlue,
                  AppConstants.secondaryBlue,
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppConstants.primaryBlue.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.schedule,
              color: Colors.white,
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
                const SizedBox(height: 4),
                Text(
                  'Nunca olvides rezar el Santo Rosario',
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
        Row(
          children: [
            Icon(
              Icons.flash_on,
              color: Colors.orange,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Plantillas Rápidas',
              style: TextStyle(
                fontSize: AppConstants.fontSizeM * widget.preferences.textScaleFactor,
                fontWeight: FontWeight.bold,
                color: AppConstants.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spacingXS),
        Text(
          'Toca para agregar un recordatorio predefinido',
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
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusS),
        side: BorderSide(
          color: AppConstants.primaryBlue.withOpacity(0.2),
        ),
      ),
      child: InkWell(
        onTap: _isCreatingReminder ? null : () => _useTemplate(template),
        borderRadius: BorderRadius.circular(AppConstants.radiusS),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingS),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: template.type.icon == Icons.alarm 
                        ? [Colors.orange.shade400, Colors.orange.shade600]
                        : [AppConstants.primaryBlue, AppConstants.secondaryBlue],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  template.type.icon,
                  color: Colors.white,
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
                        fontWeight: FontWeight.bold,
                        color: AppConstants.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      template.description,
                      style: TextStyle(
                        fontSize: AppConstants.fontSizeXS * widget.preferences.textScaleFactor,
                        color: AppConstants.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: AppConstants.primaryBlue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          template.time.format(context),
                          style: TextStyle(
                            fontSize: AppConstants.fontSizeXS * widget.preferences.textScaleFactor,
                            color: AppConstants.primaryBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: AppConstants.primaryBlue,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _getDaysText(template.daysOfWeek),
                            style: TextStyle(
                              fontSize: AppConstants.fontSizeXS * widget.preferences.textScaleFactor,
                              color: AppConstants.primaryBlue,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppConstants.primaryBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add,
                  color: AppConstants.primaryBlue,
                  size: 20,
                ),
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
        Row(
          children: [
            Icon(
              Icons.tune,
              color: AppConstants.primaryBlue,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Recordatorio Personalizado',
              style: TextStyle(
                fontSize: AppConstants.fontSizeM * widget.preferences.textScaleFactor,
                fontWeight: FontWeight.bold,
                color: AppConstants.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spacingS),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isCreatingReminder ? null : _createCustomReminder,
            icon: const Icon(Icons.add_circle_outline),
            label: Text(
              'Crear Recordatorio Personalizado',
              style: TextStyle(
                fontSize: AppConstants.fontSizeS * widget.preferences.textScaleFactor,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppConstants.primaryBlue,
              padding: EdgeInsets.symmetric(
                horizontal: AppConstants.spacingM,
                vertical: widget.preferences.useLargeButtons 
                    ? AppConstants.spacingS 
                    : AppConstants.spacingXS,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusS),
              ),
              side: const BorderSide(
                color: AppConstants.primaryBlue,
                width: 2,
              ),
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
                Row(
                  children: [
                    Icon(
                      Icons.notifications_active,
                      color: Colors.green,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Recordatorios Activos',
                      style: TextStyle(
                        fontSize: AppConstants.fontSizeM * widget.preferences.textScaleFactor,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.textPrimary,
                      ),
                    ),
                    if (activeReminders.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${activeReminders.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                if (_notificationService.reminders.isNotEmpty)
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
              Column(
                children: activeReminders.take(3).map((reminder) => 
                  _buildReminderCard(reminder),
                ).toList(),
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
        gradient: LinearGradient(
          colors: [
            Colors.grey.shade50,
            Colors.grey.shade100,
          ],
        ),
        borderRadius: BorderRadius.circular(AppConstants.radiusS),
        border: Border.all(color: Colors.grey.shade300),
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
            'No hay recordatorios activos',
            style: TextStyle(
              fontSize: AppConstants.fontSizeS * widget.preferences.textScaleFactor,
              color: AppConstants.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Agrega uno usando las plantillas rápidas',
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
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusS),
        side: BorderSide(
          color: Colors.green.withOpacity(0.3),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppConstants.radiusS),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.green.withOpacity(0.05),
              Colors.green.withOpacity(0.02),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingS),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  reminder.type.icon,
                  color: Colors.green.shade700,
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
                        fontWeight: FontWeight.bold,
                        color: AppConstants.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: AppConstants.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          reminder.timeText,
                          style: TextStyle(
                            fontSize: AppConstants.fontSizeXS * widget.preferences.textScaleFactor,
                            color: AppConstants.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('•', style: TextStyle(color: AppConstants.textSecondary)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            reminder.daysText,
                            style: TextStyle(
                              fontSize: AppConstants.fontSizeXS * widget.preferences.textScaleFactor,
                              color: AppConstants.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: reminder.isActive,
                onChanged: (value) => _toggleReminder(reminder.id),
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTestNotificationButton() {
    return Center(
      child: TextButton.icon(
        onPressed: _testNotification,
        icon: const Icon(Icons.notifications_active),
        label: const Text('Probar Notificación'),
        style: TextButton.styleFrom(
          foregroundColor: AppConstants.primaryBlue,
        ),
      ),
    );
  }

  String _getDaysText(List<int> daysOfWeek) {
    if (daysOfWeek.length == 7) return 'Todos los días';
    if (daysOfWeek.length == 5 && 
        daysOfWeek.contains(1) && daysOfWeek.contains(2) && 
        daysOfWeek.contains(3) && daysOfWeek.contains(4) && 
        daysOfWeek.contains(5)) {
      return 'Lun-Vie';
    }
    if (daysOfWeek.length == 2 && 
        daysOfWeek.contains(6) && daysOfWeek.contains(7)) {
      return 'Fines de semana';
    }
    
    const dayNames = {
      1: 'Lun', 2: 'Mar', 3: 'Mié', 4: 'Jue',
      5: 'Vie', 6: 'Sáb', 7: 'Dom',
    };
    
    final sortedDays = List<int>.from(daysOfWeek)..sort();
    return sortedDays.map((day) => dayNames[day]).join(', ');
  }

  Future<void> _useTemplate(ReminderTemplate template) async {
    setState(() {
      _isCreatingReminder = true;
    });
    
    try {
      final id = _notificationService.generateUniqueId();
      final reminder = template.toReminder(id);
      
      final success = await _notificationService.addReminder(reminder);
      
      if (success) {
        HapticFeedback.mediumImpact();
        _showSnackBar('✓ Recordatorio "${template.title}" creado', isSuccess: true);
        
        // Mostrar notificaciones pendientes (debug)
        await _notificationService.getPendingNotifications();
      } else {
        _showSnackBar('Error al crear el recordatorio', isSuccess: false);
      }
    } finally {
      setState(() {
        _isCreatingReminder = false;
      });
    }
  }

  void _createCustomReminder() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CustomReminderBottomSheet(
        preferences: widget.preferences,
        onReminderCreated: (reminder) async {
          setState(() {
            _isCreatingReminder = true;
          });
          
          try {
            final success = await _notificationService.addReminder(reminder);
            if (success) {
              _showSnackBar('✓ Recordatorio creado exitosamente', isSuccess: true);
            } else {
              _showSnackBar('Error al crear el recordatorio', isSuccess: false);
            }
          } finally {
            setState(() {
              _isCreatingReminder = false;
            });
          }
        },
      ),
    );
  }

  Future<void> _toggleReminder(int reminderId) async {
    final success = await _notificationService.toggleReminder(reminderId);
    if (!success) {
      _showSnackBar('Error al cambiar el recordatorio', isSuccess: false);
    } else {
      HapticFeedback.lightImpact();
    }
  }

  void _manageAllReminders() {
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

// Widget mejorado para crear recordatorios personalizados
class CustomReminderBottomSheet extends StatefulWidget {
  final PreferencesService preferences;
  final Function(RosarioReminder) onReminderCreated;

  const CustomReminderBottomSheet({
    super.key,
    required this.preferences,
    required this.onReminderCreated,
  });

  @override
  State<CustomReminderBottomSheet> createState() => _CustomReminderBottomSheetState();
}

class _CustomReminderBottomSheetState extends State<CustomReminderBottomSheet> {
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
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppConstants.radiusM),
          topRight: Radius.circular(AppConstants.radiusM),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingM),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.spacingM),
              
              // Título
              Text(
                'Nuevo Recordatorio',
                style: TextStyle(
                  fontSize: AppConstants.fontSizeL * widget.preferences.textScaleFactor,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textPrimary,
                ),
              ),
              const SizedBox(height: AppConstants.spacingM),
              
              // Campo de título
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Título del recordatorio',
                  hintText: 'Ej: Rosario Familiar',
                  prefixIcon: const Icon(Icons.title),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: AppConstants.spacingS),
              
              // Campo de descripción
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Descripción (opcional)',
                  hintText: 'Una breve descripción...',
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: AppConstants.spacingM),
              
              // Selector de hora
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryBlue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.access_time,
                    color: AppConstants.primaryBlue,
                  ),
                ),
                title: const Text('Hora'),
                subtitle: Text(
                  _selectedTime.format(context),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppConstants.primaryBlue,
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                onTap: _selectTime,
              ),
              const SizedBox(height: AppConstants.spacingS),
              
              // Selector de días
              Text(
                'Días de la semana',
                style: TextStyle(
                  fontSize: AppConstants.fontSizeS * widget.preferences.textScaleFactor,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textPrimary,
                ),
              ),
              const SizedBox(height: AppConstants.spacingXS),
              Wrap(
                spacing: 8,
                children: [
                  for (int i = 1; i <= 7; i++)
                    FilterChip(
                      label: Text(_getDayName(i)),
                      selected: _selectedDays.contains(i),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedDays.add(i);
                          } else if (_selectedDays.length > 1) {
                            _selectedDays.remove(i);
                          }
                        });
                      },
                      selectedColor: AppConstants.primaryBlue.withOpacity(0.2),
                      checkmarkColor: AppConstants.primaryBlue,
                    ),
                ],
              ),
              const SizedBox(height: AppConstants.spacingM),
              
              // Selector de tipo
              Text(
                'Tipo de recordatorio',
                style: TextStyle(
                  fontSize: AppConstants.fontSizeS * widget.preferences.textScaleFactor,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textPrimary,
                ),
              ),
              const SizedBox(height: AppConstants.spacingXS),
              ...ReminderType.values.map((type) => RadioListTile<ReminderType>(
                title: Text(type.displayName),
                subtitle: Text(
                  type.description,
                  style: const TextStyle(fontSize: 12),
                ),
                secondary: Icon(type.icon),
                value: type,
                groupValue: _selectedType,
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                  });
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              )),
              const SizedBox(height: AppConstants.spacingL),
              
              // Botones
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingS),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacingS),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _createReminder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingS),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Crear Recordatorio',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
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

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
              dialHandColor: AppConstants.primaryBlue,
              dayPeriodTextColor: AppConstants.primaryBlue,
              hourMinuteColor: AppConstants.primaryBlue.withOpacity(0.1),
              hourMinuteTextColor: AppConstants.primaryBlue,
            ),
          ),
          child: child!,
        );
      },
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
        const SnackBar(
          content: Text('Por favor completa todos los campos'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final reminder = RosarioReminder(
      id: NotificationService().generateUniqueId(),
      title: _titleController.text,
      description: _descriptionController.text.isEmpty 
          ? 'Es hora de rezar el Santo Rosario'
          : _descriptionController.text,
      time: _selectedTime,
      daysOfWeek: List<int>.from(_selectedDays)..sort(),
      isActive: true,
      type: _selectedType,
      createdAt: DateTime.now(),
    );

    widget.onReminderCreated(reminder);
    Navigator.pop(context);
  }
}

// Pantalla mejorada para gestionar todos los recordatorios
class ManageRemindersScreen extends StatelessWidget {
  final PreferencesService preferences;

  const ManageRemindersScreen({
    super.key,
    required this.preferences,
  });

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
              // Header
              Padding(
                padding: const EdgeInsets.all(AppConstants.spacingS),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Todos los Recordatorios',
                        style: TextStyle(
                          fontSize: AppConstants.fontSizeL * preferences.textScaleFactor,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              
              // Contenido
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(AppConstants.spacingS),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                  ),
                  child: ListenableBuilder(
                    listenable: NotificationService(),
                    builder: (context, child) {
                      final reminders = NotificationService().reminders;
                      
                      if (reminders.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.notifications_none,
                                size: 64,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No hay recordatorios',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey.shade600,
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
                          return Dismissible(
                            key: Key(reminder.id.toString()),
                            background: Container(
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (direction) async {
                              return await showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Eliminar Recordatorio'),
                                  content: Text(
                                    '¿Deseas eliminar el recordatorio "${reminder.title}"?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('Cancelar'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: const Text(
                                        'Eliminar',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            onDismissed: (direction) {
                              NotificationService().removeReminder(reminder.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Recordatorio "${reminder.title}" eliminado'),
                                  action: SnackBarAction(
                                    label: 'Deshacer',
                                    onPressed: () {
                                      NotificationService().addReminder(reminder);
                                    },
                                  ),
                                ),
                              );
                            },
                            child: Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: reminder.isActive 
                                      ? Colors.green.withOpacity(0.3)
                                      : Colors.grey.withOpacity(0.3),
                                ),
                              ),
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: reminder.isActive
                                        ? Colors.green.withOpacity(0.1)
                                        : Colors.grey.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    reminder.type.icon,
                                    color: reminder.isActive 
                                        ? Colors.green
                                        : Colors.grey,
                                  ),
                                ),
                                title: Text(
                                  reminder.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(reminder.description),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          size: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          reminder.timeText,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        const SizedBox(width: 8),
                                        Text('•', style: TextStyle(color: Colors.grey.shade600)),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            reminder.daysText,
                                            style: const TextStyle(fontSize: 12),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: Switch.adaptive(
                                  value: reminder.isActive,
                                  onChanged: (value) {
                                    NotificationService().toggleReminder(reminder.id);
                                  },
                                  activeColor: AppConstants.primaryBlue,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}