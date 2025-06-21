import 'package:flutter/material.dart';
import 'dart:math' as math;

class RosarioWidget extends StatelessWidget {
  final double size;

  const RosarioWidget({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: RosarioPainter(),
    );
  }
}

class RosarioPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2563EB)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = const Color(0xFF2563EB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final center = Offset(size.width / 2, size.height / 2);
    final mainRadius = size.width * 0.35;

    // Círculo principal del rosario
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy - size.height * 0.1),
        width: mainRadius * 2,
        height: mainRadius * 1.8,
      ),
      strokePaint,
    );

    // 5 cuentas principales (Padre Nuestro)
    final mainBeadRadius = size.width * 0.025;
    final positions = [
      Offset(center.dx, center.dy - size.height * 0.35), // arriba
      Offset(center.dx + mainRadius * 0.9, center.dy - size.height * 0.1), // derecha
      Offset(center.dx, center.dy + size.height * 0.15), // abajo
      Offset(center.dx - mainRadius * 0.9, center.dy - size.height * 0.1), // izquierda
      Offset(center.dx + mainRadius * 0.65, center.dy - size.height * 0.25), // diagonal
    ];

    for (final pos in positions) {
      canvas.drawCircle(pos, mainBeadRadius, paint);
    }

    // Cuentas pequeñas (Ave María) distribuidas en el círculo
    final smallBeadRadius = size.width * 0.015;
    final beadCount = 40; // Aproximadamente 10 por cada cuarto del círculo

    for (int i = 0; i < beadCount; i++) {
      final angle = (i * 2 * math.pi) / beadCount;
      final x = center.dx + (mainRadius * 0.75) * math.cos(angle);
      final y = (center.dy - size.height * 0.1) + (mainRadius * 0.65) * math.sin(angle);
      canvas.drawCircle(Offset(x, y), smallBeadRadius, paint);
    }

    // Cadena hacia la cruz
    canvas.drawLine(
      Offset(center.dx, center.dy + size.height * 0.15),
      Offset(center.dx, center.dy + size.height * 0.35),
      strokePaint,
    );

    // Cuentas iniciales antes de la cruz
    final initialBeads = [
      size.width * 0.02, // Credo
      size.width * 0.015, // Padre Nuestro
      size.width * 0.01, // Ave María 1
      size.width * 0.01, // Ave María 2
      size.width * 0.01, // Ave María 3
      size.width * 0.015, // Gloria
    ];

    double currentY = center.dy + size.height * 0.2;
    for (int i = 0; i < initialBeads.length; i++) {
      canvas.drawCircle(
        Offset(center.dx, currentY),
        initialBeads[i],
        paint,
      );
      currentY += size.height * 0.025;
    }

    // Cruz
    final crossPaint = Paint()
      ..color = const Color(0xFF2563EB)
      ..style = PaintingStyle.fill;

    final crossCenter = Offset(center.dx, center.dy + size.height * 0.42);
    final crossWidth = size.width * 0.08;
    final crossHeight = size.width * 0.12;
    final crossThickness = size.width * 0.02;

    // Cuerpo vertical de la cruz
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: crossCenter,
          width: crossThickness,
          height: crossHeight,
        ),
        const Radius.circular(2),
      ),
      crossPaint,
    );

    // Brazo horizontal de la cruz
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(crossCenter.dx, crossCenter.dy - crossHeight * 0.15),
          width: crossWidth,
          height: crossThickness,
        ),
        const Radius.circular(2),
      ),
      crossPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}