import 'package:flutter/material.dart';
import '../widgets/rosario_widget.dart';
import '../widgets/settings_drawer.dart';
import '../widgets/responsive_container.dart';
import '../widgets/orientation_builder_widget.dart';
import '../constants/app_constants.dart';
import '../services/preferences_service.dart';
import '../utils/responsive_utils.dart';

/// Pantalla inicial de la aplicación del Santo Rosario
/// 
/// Muestra:
/// - El tipo de misterio del día
/// - Un widget visual del rosario
/// - Botón para comenzar el rezo
/// - Acceso a configuración mediante drawer
class InicioScreen extends StatelessWidget {
  final String todayMystery;
  final String todayDay;
  final VoidCallback onNext;
  final PreferencesService preferences;

  const InicioScreen({
    super.key,
    required this.todayMystery,
    required this.todayDay,
    required this.onNext,
    required this.preferences,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: SettingsDrawer(preferences: preferences),
      body: OrientationBuilderWidget(
        builder: (context, orientation) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: preferences.useHighContrast
                    ? [
                        Colors.black87,
                        Colors.black,
                      ]
                    : [
                        AppConstants.primaryBlue,
                        AppConstants.secondaryBlue.withOpacity(0.8),
                      ],
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  // Botón del menú
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Semantics(
                      label: 'Abrir menú de configuración',
                      button: true,
                      child: IconButton(
                        icon: Icon(
                          Icons.menu,
                          color: preferences.useHighContrast 
                              ? Colors.white 
                              : Colors.white.withOpacity(0.9),
                          size: preferences.useLargeButtons ? 32 : 24,
                        ),
                        onPressed: () {
                          Scaffold.of(context).openDrawer();
                        },
                      ),
                    ),
                  ),
                  
                  // Contenido principal
                  Center(
                    child: ResponsiveContainer(
                      child: SingleChildScrollView(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(AppConstants.radiusM),
                            boxShadow: preferences.useHighContrast
                                ? []
                                : [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                            border: preferences.useHighContrast
                                ? Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  )
                                : null,
                          ),
                          padding: EdgeInsets.all(
                            orientation == Orientation.landscape
                                ? AppConstants.spacingM
                                : AppConstants.spacingL,
                          ),
                          child: _buildContent(context, orientation),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, Orientation orientation) {
    final isLandscape = orientation == Orientation.landscape;
    final deviceType = ResponsiveUtils.getDeviceType(context);
    
    if (isLandscape && deviceType != DeviceType.mobile) {
      // Layout horizontal para tablets y desktop en landscape
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icono del rosario
          Expanded(
            child: _buildRosarioIcon(context),
          ),
          const SizedBox(width: AppConstants.spacingL),
          // Información y botón
          Expanded(
            child: _buildInfoSection(context),
          ),
        ],
      );
    } else {
      // Layout vertical para móviles y portrait
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildRosarioIcon(context),
          const SizedBox(height: AppConstants.spacingM),
          _buildInfoSection(context),
        ],
      );
    }
  }

  Widget _buildRosarioIcon(BuildContext context) {
    final size = ResponsiveUtils.getDeviceType(context) == DeviceType.mobile
        ? 80.0
        : 112.0;
        
    return Semantics(
      label: 'Icono del Santo Rosario',
      child: Container(
        width: size + 32,
        height: size + 32,
        decoration: BoxDecoration(
          color: preferences.useHighContrast
              ? Colors.white
              : Colors.blue.shade50,
          borderRadius: BorderRadius.circular(AppConstants.radiusCircle),
        ),
        child: Center(
          child: RosarioWidget(
            size: size,
            color: preferences.useHighContrast
                ? Colors.black
                : AppConstants.secondaryBlue,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          header: true,
          child: Text(
            'Santo Rosario',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              color: preferences.useHighContrast
                  ? Theme.of(context).colorScheme.onSurface
                  : AppConstants.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: AppConstants.spacingXS),
        
        Semantics(
          label: 'Hoy es $todayDay. Los misterios de hoy son $todayMystery',
          child: Text(
            'Misterios $todayMystery • $todayDay',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: preferences.useHighContrast
                  ? Theme.of(context).colorScheme.onSurface.withOpacity(0.8)
                  : AppConstants.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: AppConstants.spacingL),
        
        SizedBox(
          width: double.infinity,
          child: Semantics(
            label: 'Comenzar a rezar el rosario',
            button: true,
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: preferences.useHighContrast
                    ? Colors.white
                    : AppConstants.secondaryBlue,
                foregroundColor: preferences.useHighContrast
                    ? Colors.black
                    : Colors.white,
                padding: EdgeInsets.symmetric(
                  vertical: preferences.useLargeButtons
                      ? AppConstants.spacingM
                      : AppConstants.spacingS,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.play_arrow,
                    size: preferences.useLargeButtons ? 28 : 24,
                  ),
                  const SizedBox(width: AppConstants.spacingXS),
                  Text(
                    'Comenzar Rosario',
                    style: TextStyle(
                      fontSize: (preferences.useLargeButtons
                          ? AppConstants.fontSizeL
                          : AppConstants.fontSizeM) * preferences.textScaleFactor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}