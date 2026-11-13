import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../logic/rosario_session.dart';
import '../models/prayer_models.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../theme/seccion_colores.dart';
import '../widgets/barra_rezo.dart';
import '../widgets/letanias_widget.dart';
import '../widgets/paso_oracion_layout.dart';
import '../widgets/rosary_beads_widget.dart';

/// Pantalla única para todo el recorrido del rosario.
class RezoScreen extends StatelessWidget {
  const RezoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sesion = context.watch<RosarioSession>();
    // Durante la transición de salida la sesión ya volvió al inicio.
    if (sesion.enInicio) return const Scaffold();

    final paso = sesion.pasoActual;
    final colores = context.coloresDe(paso.seccion);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) sesion.anterior();
      },
      child: PasoOracionLayout(
        colores: colores,
        barra: BarraRezo(
          paso: paso,
          tipo: sesion.tipoMisterio,
          progreso: sesion.progreso,
          colores: colores,
          onSalir: sesion.reiniciar,
        ),
        cuerpo: _Cuerpo(paso: paso, sesion: sesion, colores: colores),
        claveCuerpo: ValueKey(sesion.indice),
        onAnterior: sesion.indice > 0 ? sesion.anterior : null,
        onSiguiente: () {
          HapticFeedback.selectionClick();
          sesion.siguiente();
        },
        textoSiguiente: sesion.esUltimo ? 'Terminar Rosario' : 'Continuar',
      ),
    );
  }
}

/// Título del anuncio de un misterio: "2.º Misterio Luminoso".
String tituloAnuncio(PasoRosario paso, TipoMisterio tipo) => '${paso.misterio! + 1}.º Misterio ${tipo.singular}';

/// Título de la oración del paso; durante la decena lleva el número: "Ave María · 3 de 10".
String tituloOracion(PasoRosario paso) => paso.repeticion == null
    ? paso.oracion.title
    : '${paso.oracion.title} · ${paso.repeticion! + 1} de ${paso.oracion.count}';

class _Cuerpo extends StatelessWidget {
  const _Cuerpo({required this.paso, required this.sesion, required this.colores});

  final PasoRosario paso;
  final RosarioSession sesion;
  final SeccionColores colores;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final titulo = textos.titleLarge?.copyWith(fontWeight: FontWeight.w600);

    if (paso.esAnuncioDeMisterio) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppTokens.espacioS),
          Icon(Icons.auto_awesome, size: 32, color: colores.acento),
          const SizedBox(height: AppTokens.espacioM),
          Text(
            tituloAnuncio(paso, sesion.tipoMisterio),
            textAlign: TextAlign.center,
            style: titulo?.copyWith(color: colores.acento),
          ),
          const SizedBox(height: AppTokens.espacioL),
          Text(
            sesion.tituloMisterioActual,
            textAlign: TextAlign.center,
            style: AppTheme.oracion(context).copyWith(fontSize: 22),
          ),
          const SizedBox(height: AppTokens.espacioL),
          Text(
            'Medita en este misterio.',
            textAlign: TextAlign.center,
            style: textos.bodyLarge?.copyWith(
              fontStyle: FontStyle.italic,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (paso.seccion == SeccionRosario.misterio) ...[
          _RecordatorioMisterio(nombre: sesion.tituloMisterioActual, colores: colores),
          const SizedBox(height: AppTokens.espacioM),
        ],
        Text(tituloOracion(paso), style: titulo),
        if (paso.repeticion != null) ...[
          const SizedBox(height: AppTokens.espacioM),
          RosaryBeadsWidget(current: paso.repeticion!, total: paso.oracion.count!),
        ],
        const SizedBox(height: AppTokens.espacioM),
        if (paso.oracion.type == 'letanias')
          LetaniasWidget(texto: paso.oracion.text, colores: colores)
        else
          Text(paso.oracion.text, style: AppTheme.oracion(context)),
      ],
    );
  }
}

/// Línea pequeña con el misterio que se está meditando.
class _RecordatorioMisterio extends StatelessWidget {
  const _RecordatorioMisterio({required this.nombre, required this.colores});

  final String nombre;
  final SeccionColores colores;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.auto_awesome, size: 18, color: colores.acento),
        const SizedBox(width: AppTokens.espacioS),
        Expanded(
          child: Text(nombre, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colores.acento)),
        ),
      ],
    );
  }
}
