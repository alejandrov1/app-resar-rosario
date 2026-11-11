import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../logic/rosario_session.dart';
import '../screens/agendar_rosario_screen.dart';
import '../screens/configuracion_screen.dart';
import '../theme/app_tokens.dart';
import '../theme/seccion_colores.dart';
import 'misterios_del_dia_modal.dart';

/// El único menú lateral de la app.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final sesion = context.watch<RosarioSession>();
    final colores = context.secciones.iniciales;
    final textos = Theme.of(context).textTheme;
    final dia = nombreDelDia(sesion.hoy);

    return Drawer(
      child: Column(
        children: [
          ColoredBox(
            color: colores.boton,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(AppTokens.espacioL),
                child: Row(
                  children: [
                    Icon(Icons.favorite, size: 32, color: colores.sobreBoton),
                    const SizedBox(width: AppTokens.espacioM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Santo Rosario',
                            style: textos.titleLarge?.copyWith(color: colores.sobreBoton, fontWeight: FontWeight.bold),
                          ),
                          Text('Menú principal', style: textos.bodyMedium?.copyWith(color: colores.sobreBoton)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppTokens.espacioS),
              children: [
                ListTile(
                  leading: const Icon(Icons.auto_awesome),
                  title: const Text('Misterios del día'),
                  subtitle: Text('${sesion.tipoMisterio.nombre} · $dia'),
                  onTap: () {
                    final tipo = sesion.tipoMisterio;
                    Navigator.pop(context);
                    showDialog<void>(context: context, builder: (_) => MisteriosDelDiaDialog(tipo: tipo, dia: dia));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.schedule),
                  title: const Text('Agendar Rosario'),
                  subtitle: const Text('Programar recordatorios'),
                  onTap: () => abrirDesdeMenu(context, (_) => const AgendarRosarioScreen()),
                ),
                ListTile(
                  leading: const Icon(Icons.tune),
                  title: const Text('Configuración'),
                  subtitle: const Text('Texto, contraste y tema'),
                  onTap: () => abrirDesdeMenu(context, (_) => const ConfiguracionScreen()),
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Acerca de'),
                  onTap: () {
                    final navegador = Navigator.of(context);
                    navegador.pop();
                    // El contexto del menú se cierra; el del navegador sigue vivo.
                    mostrarAcercaDe(navegador.context);
                  },
                ),
              ],
            ),
          ),
          const _Version(),
        ],
      ),
    );
  }
}

/// Cierra el menú y abre [pantalla].
void abrirDesdeMenu(BuildContext context, WidgetBuilder pantalla) {
  final navegador = Navigator.of(context);
  navegador.pop();
  navegador.push(MaterialPageRoute<void>(builder: pantalla));
}

Future<void> mostrarAcercaDe(BuildContext context) async {
  final info = await PackageInfo.fromPlatform();
  if (!context.mounted) return;
  showAboutDialog(
    context: context,
    applicationName: 'Santo Rosario',
    applicationVersion: '${info.version} (${info.buildNumber})',
    applicationIcon: Image.asset('assets/icons/icono-rosario.png', width: 48, height: 48),
    children: const [
      Text('Una aplicación para rezar el Santo Rosario de manera guiada.'),
      SizedBox(height: AppTokens.espacioM),
      Text('Desarrollada con amor y devoción.'),
    ],
  );
}

class _Version extends StatelessWidget {
  const _Version();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, info) {
        final version = info.data?.version;
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.espacioM),
            child: Text(
              version == null ? '' : 'Versión $version',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        );
      },
    );
  }
}
