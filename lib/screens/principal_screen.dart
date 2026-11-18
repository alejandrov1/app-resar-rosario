import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/rosario_session.dart';
import 'inicio_screen.dart';
import 'rezo_screen.dart';

/// Muestra el inicio o el rezo según la sesión.
class PrincipalScreen extends StatelessWidget {
  const PrincipalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final enInicio = context.select<RosarioSession, bool>((s) => s.enInicio);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: enInicio ? const InicioScreen(key: ValueKey('inicio')) : const RezoScreen(key: ValueKey('rezo')),
    );
  }
}
