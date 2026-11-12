import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../logic/rosario_session.dart';
import '../models/prayer_models.dart';
import '../theme/app_tokens.dart';
import '../theme/seccion_colores.dart';
import '../widgets/app_drawer.dart';
import '../widgets/rosary_image_widget.dart';

class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _animacion =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..forward();
  late final Animation<double> _aparecer =
      CurvedAnimation(parent: _animacion, curve: const Interval(0, 0.6, curve: Curves.easeOut));
  late final Animation<Offset> _subir = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
      .animate(CurvedAnimation(parent: _animacion, curve: const Interval(0.3, 1, curve: Curves.easeOutCubic)));

  @override
  void dispose() {
    _animacion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sesion = context.watch<RosarioSession>();
    final secciones = context.secciones;
    final colores = secciones.iniciales;
    final textos = Theme.of(context).textTheme;
    final altoImagen = MediaQuery.sizeOf(context).height * 0.32;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: secciones.tituloInicio,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      drawer: const AppDrawer(),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: secciones.fondoInicio,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppTokens.anchoMaximo),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTokens.espacioL),
                child: FadeTransition(
                  opacity: _aparecer,
                  child: Column(
                    children: [
                      Text(
                        'Santo Rosario',
                        textAlign: TextAlign.center,
                        style: textos.displaySmall?.copyWith(
                          color: secciones.tituloInicio,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: AppTokens.espacioL),
                      SlideTransition(
                        position: _subir,
                        child: RosaryImageWidget(
                          width: double.infinity,
                          height: altoImagen,
                          imagePath: 'assets/images/imagen-rosario.png',
                        ),
                      ),
                      const SizedBox(height: AppTokens.espacioXL),
                      _MisterioDelDia(dia: nombreDelDia(sesion.hoy), tipo: sesion.tipoMisterio, colores: colores),
                      const SizedBox(height: AppTokens.espacioXL),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            sesion.comenzar();
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: colores.boton,
                            foregroundColor: colores.sobreBoton,
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.favorite_rounded),
                              SizedBox(width: AppTokens.espacioS),
                              Flexible(child: Text('Comenzar a Rezar')),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTokens.espacioXL),
                      Text(
                        '"El Rosario es la oración más hermosa que podemos ofrecer a la Virgen María"',
                        textAlign: TextAlign.center,
                        style: textos.bodyMedium?.copyWith(fontStyle: FontStyle.italic, color: secciones.tituloInicio),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MisterioDelDia extends StatelessWidget {
  const _MisterioDelDia({required this.dia, required this.tipo, required this.colores});

  final String dia;
  final TipoMisterio tipo;
  final SeccionColores colores;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.espacioL),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today_rounded, size: 20, color: colores.acento),
                const SizedBox(width: AppTokens.espacioS),
                Flexible(child: Text(dia, textAlign: TextAlign.center, style: textos.titleMedium?.copyWith(color: colores.acento))),
              ],
            ),
            const SizedBox(height: AppTokens.espacioM),
            DecoratedBox(
              decoration: BoxDecoration(color: colores.boton, borderRadius: BorderRadius.circular(999)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTokens.espacioL, vertical: AppTokens.espacioS),
                child: Text(
                  'Misterios ${tipo.nombre}',
                  textAlign: TextAlign.center,
                  style: textos.titleLarge?.copyWith(color: colores.sobreBoton, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
