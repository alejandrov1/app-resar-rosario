import 'package:flutter/material.dart';

import '../data/oraciones.dart';
import '../models/prayer_models.dart';
import '../theme/app_tokens.dart';
import '../theme/seccion_colores.dart';

/// Diálogo con los cinco misterios que se rezan hoy.
class MisteriosDelDiaDialog extends StatelessWidget {
  const MisteriosDelDiaDialog({super.key, required this.tipo, required this.dia});

  final TipoMisterio tipo;
  final String dia;

  @override
  Widget build(BuildContext context) {
    final colores = context.coloresDe(SeccionRosario.iniciales);
    final textos = Theme.of(context).textTheme;
    final misterios = misteriosPorTipo[tipo]!;

    return AlertDialog(
      icon: Icon(Icons.auto_awesome, color: colores.acento),
      title: Text('Misterios ${tipo.nombre}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dia, style: textos.titleSmall?.copyWith(color: colores.acento)),
            const SizedBox(height: AppTokens.espacioM),
            for (var i = 0; i < misterios.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: AppTokens.espacioS),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: colores.boton,
                      foregroundColor: colores.sobreBoton,
                      child: Text('${i + 1}'),
                    ),
                    const SizedBox(width: AppTokens.espacioM),
                    Expanded(child: Text(misterios[i], style: textos.bodyLarge)),
                  ],
                ),
              ),
            const SizedBox(height: AppTokens.espacioS),
            Text(
              'Medita en cada uno de estos misterios durante el rezo del Rosario.',
              style: textos.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Entendido')),
      ],
    );
  }
}
