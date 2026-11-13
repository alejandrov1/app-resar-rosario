import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../logic/rosario_session.dart';
import '../models/prayer_models.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../theme/seccion_colores.dart';
import '../widgets/paso_oracion_layout.dart';
import '../widgets/letanias_widget.dart';
import '../widgets/progreso_rosario.dart';
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
        titulo: tituloDelPaso(paso, sesion.tipoMisterio),
        encabezado: _Encabezado(paso: paso, sesion: sesion, colores: colores),
        progreso: ProgresoRosario(paso: paso, progreso: sesion.progreso, colores: colores),
        contenido: _Contenido(paso: paso, sesion: sesion, colores: colores),
        onAnterior: sesion.indice > 0 ? sesion.anterior : null,
        onSiguiente: () {
          HapticFeedback.selectionClick();
          sesion.siguiente();
        },
        onInicio: sesion.reiniciar,
        textoSiguiente: sesion.esUltimo ? 'Terminar Rosario' : 'Continuar',
      ),
    );
  }
}

/// Título de la tarjeta en cada paso.
String tituloDelPaso(PasoRosario paso, TipoMisterio tipo) => switch (paso.seccion) {
      SeccionRosario.iniciales => 'Oraciones Iniciales',
      SeccionRosario.misterio => 'Misterios ${tipo.nombre} · ${paso.misterio! + 1}/$misteriosPorRosario',
      SeccionRosario.finales => 'Oraciones Finales',
    };

class _Encabezado extends StatelessWidget {
  const _Encabezado({required this.paso, required this.sesion, required this.colores});

  final PasoRosario paso;
  final RosarioSession sesion;
  final SeccionColores colores;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final principal = textos.titleMedium?.copyWith(color: colores.acento, fontWeight: FontWeight.w600);
    final secundario = textos.bodyMedium?.copyWith(color: colores.acento);

    final (linea1, linea2) = paso.seccion == SeccionRosario.misterio
        ? ('${paso.misterio! + 1}° Misterio ${sesion.tipoMisterio.singular}', sesion.tituloMisterioActual)
        : (paso.oracion.title, 'Paso ${paso.indiceEnSeccion + 1} de ${paso.totalEnSeccion}');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(linea1, style: principal),
        const SizedBox(height: AppTokens.espacioXS),
        Text(linea2, style: secundario),
      ],
    );
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido({required this.paso, required this.sesion, required this.colores});

  final PasoRosario paso;
  final RosarioSession sesion;
  final SeccionColores colores;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    if (paso.esAnuncioDeMisterio) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTokens.espacioL),
        child: Column(
          children: [
            Icon(Icons.auto_awesome, size: 32, color: colores.acento),
            const SizedBox(height: AppTokens.espacioM),
            Text(
              'Medita en este Misterio',
              textAlign: TextAlign.center,
              style: textos.titleLarge?.copyWith(color: colores.acento),
            ),
            const SizedBox(height: AppTokens.espacioS),
            Text(sesion.tituloMisterioActual, textAlign: TextAlign.center, style: AppTheme.oracion(context)),
          ],
        ),
      );
    }

    final repeticion = paso.repeticion;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (paso.seccion == SeccionRosario.misterio) ...[
          Text(
            repeticion == null ? paso.oracion.title : '${paso.oracion.title} (${repeticion + 1}°)',
            style: textos.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppTokens.espacioM),
        ],
        if (repeticion != null) ...[
          RosaryBeadsWidget(current: repeticion, total: paso.oracion.count!),
          const SizedBox(height: AppTokens.espacioM),
        ],
        if (paso.oracion.type == 'letanias')
          LetaniasWidget(texto: paso.oracion.text, colores: colores)
        else
          Text(paso.oracion.text, style: AppTheme.oracion(context)),
      ],
    );
  }
}
