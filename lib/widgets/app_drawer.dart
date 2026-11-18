import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../screens/agendar_rosario_screen.dart';
import '../screens/configuracion_screen.dart';
import '../theme/app_tokens.dart';
import '../theme/barras_sistema.dart';
import '../theme/seccion_colores.dart';

/// El único menú lateral de la app.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final colores = context.secciones.iniciales;
    final textos = Theme.of(context).textTheme;

    // Todo el menú se desplaza junto: con letra grande o en horizontal la cabecera, las opciones y la versión
    // no caben a la vez, y así ninguna se corta.
    return Drawer(
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Los iconos de la barra de estado se leen sobre la cabecera, no sobre la barra de la pantalla de abajo.
            AnnotatedRegion<SystemUiOverlayStyle>(
              value: estiloBarras(iconosSobre(colores.boton)),
              child: ColoredBox(
                color: colores.boton,
                child: SizedBox(
                  width: double.infinity,
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
                                  style: textos.titleLarge?.copyWith(
                                    color: colores.sobreBoton,
                                    fontWeight: FontWeight.bold,
                                  ),
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
              ),
            ),
            const SizedBox(height: AppTokens.espacioS),
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
            const _Version(),
          ],
        ),
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
  // El diálogo es de Flutter y sus botones no se pueden reducir: con letra muy grande "Ver licencias" se parte,
  // así que aquí se limita el aumento (igual que en el selector de hora).
  showDialog<void>(
    context: context,
    builder: (_) => MediaQuery.withClampedTextScaling(
      maxScaleFactor: escalaMaximaAcercaDe,
      child: AboutDialog(
        applicationName: 'Santo Rosario',
        applicationVersion: '${info.version} (${info.buildNumber})',
        applicationIcon: Image.asset('assets/icons/icono-rosario.png', width: 48, height: 48),
        children: const [
          Text('Una aplicación para rezar el Santo Rosario de manera guiada.'),
          SizedBox(height: AppTokens.espacioM),
          Text('Desarrollada con amor y devoción.'),
        ],
      ),
    ),
  );
}

/// Aumento máximo del texto en "Acerca de".
const double escalaMaximaAcercaDe = 1.5;

class _Version extends StatefulWidget {
  const _Version();

  @override
  State<_Version> createState() => _VersionState();
}

class _VersionState extends State<_Version> {
  // Se consulta una sola vez: build puede correr muchas veces.
  late final Future<PackageInfo> _info = PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: _info,
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
