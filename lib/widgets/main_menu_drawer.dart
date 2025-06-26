import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_constants.dart';
import '../services/preferences_service.dart';
import 'misterios_del_dia_modal.dart';

/// Menú lateral principal de la aplicación
class MainMenuDrawer extends StatelessWidget {
  final PreferencesService preferences;
  final String todayMystery;
  final String todayDay;

  const MainMenuDrawer({
    super.key,
    required this.preferences,
    required this.todayMystery,
    required this.todayDay,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Header del menú
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
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
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.spacingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icono y título
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.favorite,
                            size: 32,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: AppConstants.spacingS),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Santo Rosario',
                                style: TextStyle(
                                  fontSize: AppConstants.fontSizeL * preferences.textScaleFactor,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Menú Principal',
                                style: TextStyle(
                                  fontSize: AppConstants.fontSizeS * preferences.textScaleFactor,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Lista de opciones
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const SizedBox(height: AppConstants.spacingS),
                
                // Opción: Misterios del día
                _buildMenuItem(
                  context: context,
                  icon: Icons.auto_awesome,
                  title: 'Misterios del día',
                  subtitle: 'Ver los misterios de hoy',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context); // Cerrar el drawer
                    showDialog(
                      context: context,
                      barrierDismissible: true,
                      barrierColor: Colors.black54,
                      builder: (context) => MisteriosDelDia(
                        todayMystery: todayMystery,
                        todayDay: todayDay,
                        preferences: preferences,
                      ),
                    );
                  },
                ),
                
                const Divider(height: 32),
                
                // Espacio para futuras opciones
                // TODO: Agregar más opciones aquí
                
                // Ejemplo de estructura para futuras opciones (comentado):
                /*
                _buildMenuItem(
                  context: context,
                  icon: Icons.history,
                  title: 'Historial',
                  subtitle: 'Ver rosarios rezados',
                  onTap: () {
                    // TODO: Implementar navegación
                  },
                ),
                
                _buildMenuItem(
                  context: context,
                  icon: Icons.book,
                  title: 'Oraciones',
                  subtitle: 'Biblioteca de oraciones',
                  onTap: () {
                    // TODO: Implementar navegación
                  },
                ),
                
                _buildMenuItem(
                  context: context,
                  icon: Icons.notifications,
                  title: 'Recordatorios',
                  subtitle: 'Configurar notificaciones',
                  onTap: () {
                    // TODO: Implementar navegación
                  },
                ),
                */
              ],
            ),
          ),
          
          // Footer del menú
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.spacingS),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppConstants.textSecondary,
                  ),
                  const SizedBox(width: AppConstants.spacingXS),
                  Text(
                    'Versión 1.0.0',
                    style: TextStyle(
                      fontSize: AppConstants.fontSizeXS * preferences.textScaleFactor,
                      color: AppConstants.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
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
      title: Text(
        title,
        style: TextStyle(
          fontSize: AppConstants.fontSizeM * preferences.textScaleFactor,
          fontWeight: FontWeight.w600,
          color: AppConstants.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: AppConstants.fontSizeS * preferences.textScaleFactor,
          color: AppConstants.textSecondary,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: AppConstants.textSecondary,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingS,
        vertical: AppConstants.spacingXS,
      ),
      onTap: onTap,
    );
  }
}