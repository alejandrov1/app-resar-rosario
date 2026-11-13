import 'package:flutter/material.dart';

import '../logic/rosario_session.dart';
import '../models/prayer_models.dart';
import '../theme/app_tokens.dart';
import '../theme/seccion_colores.dart';

/// Nombre de la sección del paso: "Oraciones iniciales", "Misterios Gozosos" u "Oraciones finales".
String nombreSeccion(PasoRosario paso, TipoMisterio tipo) => switch (paso.seccion) {
      SeccionRosario.iniciales => 'Oraciones iniciales',
      SeccionRosario.misterio => 'Misterios ${tipo.nombre}',
      SeccionRosario.finales => 'Oraciones finales',
    };

/// Avance dentro de la sección: la oración en iniciales y finales, el misterio en los misterios.
/// Los espacios son duros ("1 de 10" nunca se parte con letra grande).
String avanceSeccion(PasoRosario paso) => switch (paso.seccion) {
      SeccionRosario.misterio => '${paso.misterio! + 1}\u00A0de\u00A0$misteriosPorRosario',
      SeccionRosario.iniciales ||
      SeccionRosario.finales => '${paso.indiceEnSeccion + 1}\u00A0de\u00A0${paso.totalEnSeccion}',
    };

/// Contexto del rezo, dicho una sola vez: inicio, sección con su avance y avance del rosario completo.
class BarraRezo extends StatelessWidget {
  const BarraRezo({
    super.key,
    required this.paso,
    required this.tipo,
    required this.progreso,
    required this.colores,
    required this.onSalir,
  });

  final PasoRosario paso;
  final TipoMisterio tipo;

  /// Avance del rosario completo, de 0 a 1.
  final double progreso;
  final SeccionColores colores;

  /// Se llama solo si la persona confirma que quiere salir.
  final VoidCallback onSalir;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => confirmarSalida(context, onSalir),
              icon: const Icon(Icons.home_outlined),
              tooltip: 'Volver al inicio',
              color: colores.acento,
              // La casita queda al ras del borde del contenido; el área de toque sigue siendo de 48 dp.
              alignment: AlignmentDirectional.centerStart,
              padding: EdgeInsets.zero,
              style: IconButton.styleFrom(
                minimumSize: const Size.square(AppTokens.botonNormal),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: AppTokens.espacioXS),
            Expanded(
              child: Text(
                '${nombreSeccion(paso, tipo)} · ${avanceSeccion(paso)}',
                style: textos.titleSmall?.copyWith(color: colores.acento, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.espacioS),
        Semantics(
          label: 'Progreso del rosario: ${(progreso * 100).round()} por ciento',
          excludeSemantics: true,
          child: LinearProgressIndicator(
            value: progreso,
            minHeight: 6,
            borderRadius: BorderRadius.circular(AppTokens.radioS),
            color: colores.acento,
            backgroundColor: colores.suave,
          ),
        ),
      ],
    );
  }
}

/// Pregunta antes de salir del rosario; si se confirma, llama a [onSalir].
Future<void> confirmarSalida(BuildContext context, VoidCallback onSalir) async {
  final salir = await showDialog<bool>(
    context: context,
    builder: (dialogo) => AlertDialog(
      scrollable: true,
      title: const Text('¿Salir del rosario?'),
      content: const Text('Se perderá el avance de este rosario.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogo, true), child: const Text('Salir')),
        FilledButton(onPressed: () => Navigator.pop(dialogo, false), child: const Text('Seguir rezando')),
      ],
    ),
  );
  if (salir ?? false) onSalir();
}
