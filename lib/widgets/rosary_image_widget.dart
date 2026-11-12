import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Imagen del rosario de la pantalla de inicio, con aparición suave.
class RosaryImageWidget extends StatelessWidget {
  const RosaryImageWidget({
    super.key,
    required this.width,
    required this.height,
    required this.imagePath,
    this.fit = BoxFit.contain,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
  });

  final double width;
  final double height;
  final String imagePath;
  final BoxFit fit;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTokens.fondoFoto,
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(color: AppTokens.sombraFoto, spreadRadius: 2, blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Image.asset(
          imagePath,
          fit: fit,
          semanticLabel: 'Imagen de un rosario',
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded) return child;
            return AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut,
              child: child,
            );
          },
          errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.image_not_supported_outlined, size: 48)),
        ),
      ),
    );
  }
}
