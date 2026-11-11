import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/preferences_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

/// Accesibilidad y apariencia.
class ConfiguracionScreen extends StatelessWidget {
  const ConfiguracionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<PreferencesService>();
    final porcentaje = '${(prefs.textScaleFactor * 100).round()} %';

    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppTokens.espacioM),
        children: [
          const _Titulo('Accesibilidad'),
          ListTile(
            leading: const Icon(Icons.text_fields),
            title: const Text('Tamaño del texto'),
            trailing: Text(porcentaje),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.espacioS),
            child: Slider(
              value: prefs.textScaleFactor,
              min: PreferencesService.minTextScale,
              max: PreferencesService.maxTextScale,
              divisions: 12,
              label: porcentaje,
              semanticFormatterCallback: (v) => '${(v * 100).round()} por ciento',
              onChanged: prefs.updateTextScaleFactor,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.espacioM),
            child: Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(AppTokens.espacioM),
                child: Text('Padre nuestro, que estás en el cielo…', style: AppTheme.oracion(context)),
              ),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.contrast),
            title: const Text('Alto contraste'),
            subtitle: const Text('Colores más marcados para leer mejor'),
            value: prefs.useHighContrast,
            onChanged: (_) => prefs.toggleHighContrast(),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.touch_app_outlined),
            title: const Text('Botones grandes'),
            subtitle: const Text('Facilita tocar los botones'),
            value: prefs.useLargeButtons,
            onChanged: (_) => prefs.toggleLargeButtons(),
          ),
          const Divider(height: AppTokens.espacioXL),
          const _Titulo('Apariencia'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.espacioM),
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(value: ThemeMode.system, label: Text('Sistema'), icon: Icon(Icons.brightness_auto)),
                ButtonSegment(value: ThemeMode.light, label: Text('Claro'), icon: Icon(Icons.light_mode)),
                ButtonSegment(value: ThemeMode.dark, label: Text('Oscuro'), icon: Icon(Icons.dark_mode)),
              ],
              selected: {prefs.themeMode},
              onSelectionChanged: (seleccion) => prefs.updateThemeMode(seleccion.first),
            ),
          ),
          const Divider(height: AppTokens.espacioXL),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('Restablecer configuración'),
            onTap: () => _confirmarRestablecer(context, prefs),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarRestablecer(BuildContext context, PreferencesService prefs) async {
    final mensajero = ScaffoldMessenger.of(context);
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: const Text('¿Restablecer configuración?'),
        content: const Text('El tamaño del texto, el contraste, los botones y el tema vuelven a sus valores iniciales.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogo, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(dialogo, true), child: const Text('Restablecer')),
        ],
      ),
    );
    if (confirmado ?? false) {
      prefs.resetToDefaults();
      mensajero.showSnackBar(const SnackBar(content: Text('Configuración restablecida')));
    }
  }
}

class _Titulo extends StatelessWidget {
  const _Titulo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTokens.espacioM, AppTokens.espacioS, AppTokens.espacioM, AppTokens.espacioS),
      child: Text(
        texto,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}
