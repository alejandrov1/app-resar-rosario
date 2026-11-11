import 'package:flutter/material.dart';

import '../logic/rosario_session.dart';
import '../models/prayer_models.dart';
import '../theme/app_tokens.dart';
import '../theme/seccion_colores.dart';

/// Texto corto que dice en qué parte del rosario se va.
String etiquetaProgreso(PasoRosario paso) => switch (paso.seccion) {
      SeccionRosario.iniciales => 'Oraciones iniciales · ${paso.indiceEnSeccion + 1}/${paso.totalEnSeccion}',
      SeccionRosario.misterio => paso.repeticion == null
          ? 'Misterio ${paso.misterio! + 1}/$misteriosPorRosario'
          : 'Misterio ${paso.misterio! + 1}/$misteriosPorRosario · '
              'Ave María ${paso.repeticion! + 1}/${paso.oracion.count}',
      SeccionRosario.finales => 'Oraciones finales · ${paso.indiceEnSeccion + 1}/${paso.totalEnSeccion}',
    };

/// Etiqueta y barra con el avance del rosario completo.
class ProgresoRosario extends StatelessWidget {
  const ProgresoRosario({super.key, required this.paso, required this.progreso, required this.colores});

  final PasoRosario paso;
  final double progreso;
  final SeccionColores colores;

  @override
  Widget build(BuildContext context) {
    final etiqueta = etiquetaProgreso(paso);
    return Semantics(
      label: 'Progreso del rosario: $etiqueta, ${(progreso * 100).round()} por ciento',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(etiqueta, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: colores.acento)),
          const SizedBox(height: AppTokens.espacioXS),
          LinearProgressIndicator(
            value: progreso,
            minHeight: 6,
            borderRadius: BorderRadius.circular(AppTokens.radioS),
            color: colores.acento,
            backgroundColor: colores.suave,
          ),
        ],
      ),
    );
  }
}
