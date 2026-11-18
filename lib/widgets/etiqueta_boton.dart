import 'package:flutter/material.dart';

/// Texto de un botón: siempre en una línea. Si con la letra grande no cabe, se reduce en lugar de partir una palabra.
class EtiquetaBoton extends StatelessWidget {
  const EtiquetaBoton(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return FittedBox(fit: BoxFit.scaleDown, child: Text(texto, maxLines: 1));
  }
}
