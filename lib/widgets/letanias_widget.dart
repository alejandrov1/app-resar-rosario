import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../theme/seccion_colores.dart';

/// Una línea de las letanías: la invocación y, si la tiene, la respuesta del pueblo.
@immutable
class LineaLetania {
  const LineaLetania(this.invocacion, [this.respuesta]);

  final String invocacion;
  final String? respuesta;

  @override
  bool operator ==(Object other) =>
      other is LineaLetania && other.invocacion == invocacion && other.respuesta == respuesta;

  @override
  int get hashCode => Object.hash(invocacion, respuesta);

  @override
  String toString() => 'LineaLetania($invocacion, $respuesta)';
}

const _respuestas = ['ruega por nosotros.', 'ten misericordia de nosotros.'];

/// Divide el texto en bloques (separados por una línea en blanco) y separa cada respuesta.
List<List<LineaLetania>> analizarLetanias(String texto) {
  final grupos = <List<LineaLetania>>[];
  for (final bloque in texto.split(RegExp(r'\n\s*\n'))) {
    final lineas = <LineaLetania>[];
    for (final linea in bloque.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty)) {
      final respuesta = _respuestas.where((r) => linea.endsWith(', $r')).firstOrNull;
      if (respuesta == null) {
        lineas.add(LineaLetania(linea));
      } else {
        final invocacion = linea.substring(0, linea.length - respuesta.length - 2);
        lineas.add(LineaLetania('$invocacion,', '${respuesta[0].toUpperCase()}${respuesta.substring(1)}'));
      }
    }
    if (lineas.isNotEmpty) grupos.add(lineas);
  }
  return grupos;
}

/// Letanías con la respuesta resaltada en cada línea.
class LetaniasWidget extends StatelessWidget {
  const LetaniasWidget({super.key, required this.texto, required this.colores});

  final String texto;
  final SeccionColores colores;

  @override
  Widget build(BuildContext context) {
    final estilo = AppTheme.oracion(context);
    final grupos = analizarLetanias(texto);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var g = 0; g < grupos.length; g++) ...[
          if (g > 0) const SizedBox(height: AppTokens.espacioM),
          for (final linea in grupos[g])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppTokens.espacioXS / 2),
              child: linea.respuesta == null
                  ? Text(
                      linea.invocacion,
                      style: estilo.copyWith(
                        fontWeight: FontWeight.w600,
                        fontVariations: const [FontVariation.weight(600)],
                      ),
                    )
                  : Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: '${linea.invocacion} '),
                          TextSpan(
                            text: linea.respuesta,
                            style: TextStyle(
                              color: colores.acento,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      style: estilo,
                    ),
            ),
        ],
      ],
    );
  }
}
