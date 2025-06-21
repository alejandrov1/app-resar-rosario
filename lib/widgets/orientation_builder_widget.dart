import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget que maneja cambios de orientación y bloqueo
class OrientationBuilderWidget extends StatefulWidget {
  final Widget Function(BuildContext, Orientation) builder;
  final bool lockPortrait;
  
  const OrientationBuilderWidget({
    super.key,
    required this.builder,
    this.lockPortrait = false,
  });

  @override
  State<OrientationBuilderWidget> createState() => _OrientationBuilderWidgetState();
}

class _OrientationBuilderWidgetState extends State<OrientationBuilderWidget> {
  @override
  void initState() {
    super.initState();
    if (widget.lockPortrait) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  @override
  void dispose() {
    // Restaurar todas las orientaciones al salir
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: widget.builder,
    );
  }
}