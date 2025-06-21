import 'package:flutter/material.dart';
import '../services/preferences_service.dart';
import '../constants/app_constants.dart';

/// Drawer con opciones de configuración y accesibilidad
class SettingsDrawer extends StatelessWidget {
  final PreferencesService preferences;

  const SettingsDrawer({
    super.key,
    required this.preferences,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.settings,
                  size: 48,
                  color: Colors.white,
                ),
                const SizedBox(height: AppConstants.spacingS),
                Text(
                  'Configuración',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Personaliza tu experiencia',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          
          // Sección de Accesibilidad
          Padding(
            padding: const EdgeInsets.all(AppConstants.spacingS),
            child: Text(
              'Accesibilidad',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          
          // Control de tamaño de texto
          ListTile(
            leading: const Icon(Icons.text_fields),
            title: const Text('Tamaño del texto'),
            subtitle: Slider(
              value: preferences.textScaleFactor,
              min: 0.8,
              max: 2.0,
              divisions: 12,
              label: '${(preferences.textScaleFactor * 100).toInt()}%',
              onChanged: (value) {
                preferences.updateTextScaleFactor(value);
              },
            ),
          ),
          
          // Ejemplo de texto con el tamaño actual
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingS,
              vertical: AppConstants.spacingXS,
            ),
            child: Container(
              padding: const EdgeInsets.all(AppConstants.spacingS),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(AppConstants.radiusS),
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                ),
              ),
              child: Text(
                'Padre nuestro, que estás en el cielo...',
                style: TextStyle(
                  fontSize: AppConstants.fontSizeS * preferences.textScaleFactor,
                ),
              ),
            ),
          ),
          
          // Alto contraste
          SwitchListTile(
            secondary: const Icon(Icons.contrast),
            title: const Text('Alto contraste'),
            subtitle: const Text('Mejora la visibilidad del texto'),
            value: preferences.useHighContrast,
            onChanged: (value) {
              preferences.toggleHighContrast();
            },
          ),
          
          // Botones grandes
          SwitchListTile(
            secondary: const Icon(Icons.touch_app),
            title: const Text('Botones grandes'),
            subtitle: const Text('Facilita la interacción táctil'),
            value: preferences.useLargeButtons,
            onChanged: (value) {
              preferences.toggleLargeButtons();
            },
          ),
          
          const Divider(),
          
          // Sección de Apariencia
          Padding(
            padding: const EdgeInsets.all(AppConstants.spacingS),
            child: Text(
              'Apariencia',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          
          // Tema
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Tema'),
            trailing: DropdownButton<ThemeMode>(
              value: preferences.themeMode,
              onChanged: (ThemeMode? newMode) {
                if (newMode != null) {
                  preferences.updateThemeMode(newMode);
                }
              },
              items: const [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text('Sistema'),
                ),
                DropdownMenuItem(
                  value: ThemeMode.light,
                  child: Text('Claro'),
                ),
                DropdownMenuItem(
                  value: ThemeMode.dark,
                  child: Text('Oscuro'),
                ),
              ],
            ),
          ),
          
          const Divider(),
          
          // Restablecer configuración
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('Restablecer configuración'),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('¿Restablecer configuración?'),
                  content: const Text(
                    'Esto restablecerá todas las configuraciones a sus valores predeterminados.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () {
                        preferences.resetToDefaults();
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Configuración restablecida'),
                          ),
                        );
                      },
                      child: const Text('Restablecer'),
                    ),
                  ],
                ),
              );
            },
          ),
          
          const Divider(),
          
          // Información de la app
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Acerca de'),
            subtitle: const Text('Santo Rosario v1.0.0'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Santo Rosario',
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(
                  Icons.favorite,
                  size: 48,
                  color: AppConstants.primaryBlue,
                ),
                children: [
                  const Text(
                    'Una aplicación para rezar el Santo Rosario de manera guiada.',
                  ),
                  const SizedBox(height: AppConstants.spacingS),
                  const Text(
                    'Desarrollada con amor y devoción.',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}