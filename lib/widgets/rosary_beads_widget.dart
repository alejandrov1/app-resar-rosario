import 'package:flutter/material.dart';

import '../theme/seccion_colores.dart';

/// Diez cuentas: las rezadas se rellenan con el dorado del tema.
class RosaryBeadsWidget extends StatelessWidget {
  const RosaryBeadsWidget({super.key, required this.current, required this.total});

  /// Cuenta actual, empezando en 0.
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final secciones = context.secciones;
    final pendiente = Theme.of(context).colorScheme.outline;
    return Semantics(
      label: 'Ave María ${current + 1} de $total',
      excludeSemantics: true,
      child: Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 6,
          runSpacing: 8,
          children: List.generate(total, (i) {
            final rezada = i <= current;
            return Container(
              key: ValueKey('cuenta-$i'),
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: rezada ? secciones.cuenta : Colors.transparent,
                border: Border.all(color: rezada ? secciones.bordeCuenta : pendiente, width: 2),
              ),
            );
          }),
        ),
      ),
    );
  }
}
