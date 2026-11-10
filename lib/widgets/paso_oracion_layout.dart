import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../theme/seccion_colores.dart';

/// Estructura común de cada paso: fondo de la sección, tarjeta con encabezado y texto,
/// y los botones para avanzar o retroceder.
class PasoOracionLayout extends StatelessWidget {
  const PasoOracionLayout({
    super.key,
    required this.colores,
    required this.titulo,
    required this.encabezado,
    required this.contenido,
    required this.onSiguiente,
    required this.onInicio,
    this.onAnterior,
    this.textoSiguiente = 'Continuar',
    this.progreso,
  });

  final SeccionColores colores;
  final String titulo;
  final Widget encabezado;

  /// Texto de la oración. No debe tener su propio desplazamiento: el layout ya lo da.
  final Widget contenido;
  final VoidCallback onSiguiente;
  final VoidCallback onInicio;

  /// Si es `null` no se muestra el botón "Atrás".
  final VoidCallback? onAnterior;
  final String textoSiguiente;
  final Widget? progreso;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final borde = colores.borde;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: colores.fondo),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppTokens.anchoMaximo),
              child: Padding(
                padding: const EdgeInsets.all(AppTokens.espacioM),
                child: Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(AppTokens.espacioL),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (progreso != null) ...[progreso!, const SizedBox(height: AppTokens.espacioM)],
                        Row(
                          children: [
                            Expanded(
                              child: Text(titulo, style: textos.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                            ),
                            IconButton(
                              onPressed: onInicio,
                              icon: const Icon(Icons.home_outlined),
                              tooltip: 'Volver al inicio',
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTokens.espacioM),
                        // Encabezado y oración se desplazan juntos: con texto grande nada se desborda.
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: colores.suave,
                                    borderRadius: BorderRadius.circular(AppTokens.radioM),
                                    border: borde == null ? null : Border.all(color: borde, width: 2),
                                  ),
                                  child: Padding(padding: const EdgeInsets.all(AppTokens.espacioM), child: encabezado),
                                ),
                                const SizedBox(height: AppTokens.espacioM),
                                contenido,
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTokens.espacioL),
                        Row(
                          children: [
                            if (onAnterior != null) ...[
                              Expanded(child: OutlinedButton(onPressed: onAnterior, child: const Text('Atrás'))),
                              const SizedBox(width: AppTokens.espacioM),
                            ],
                            Expanded(
                              flex: 2,
                              child: FilledButton(
                                onPressed: onSiguiente,
                                style: FilledButton.styleFrom(
                                  backgroundColor: colores.boton,
                                  foregroundColor: colores.sobreBoton,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(child: Text(textoSiguiente, textAlign: TextAlign.center)),
                                    const SizedBox(width: AppTokens.espacioS),
                                    const Icon(Icons.chevron_right),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
