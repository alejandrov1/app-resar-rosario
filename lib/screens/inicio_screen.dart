import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../logic/rosario_session.dart';
import '../models/prayer_models.dart';
import '../theme/app_tokens.dart';
import '../theme/barras_sistema.dart';
import '../theme/seccion_colores.dart';
import '../widgets/app_drawer.dart';
import '../widgets/misterios_del_dia_modal.dart';
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
    // Con letra grande o en horizontal la imagen se achica para dejar más contenido a la vista.
    final tamano = MediaQuery.sizeOf(context);
    final escala = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0);
    final horizontal = tamano.width > tamano.height;
    final altoImagen = (tamano.height * (horizontal ? 0.4 : 0.26) / escala).clamp(96.0, 320.0);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: secciones.tituloInicio,
        elevation: 0,
        scrolledUnderElevation: 0,
        // El fondo es un degradado que cambia con el tema: los iconos de la barra de estado también.
        systemOverlayStyle: estiloBarras(iconosParaTema(Theme.of(context).brightness)),
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
              // El botón queda fijo abajo: con letra grande nunca se esconde tras el desplazamiento.
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(AppTokens.espacioL, AppTokens.espacioL, AppTokens.espacioL, 0),
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
                            Text(
                              '"El Rosario es la oración más hermosa que podemos ofrecer a la Virgen María"',
                              textAlign: TextAlign.center,
                              style: textos.bodyMedium?.copyWith(fontStyle: FontStyle.italic, color: secciones.tituloInicio),
                            ),
                            const SizedBox(height: AppTokens.espacioL),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppTokens.espacioL),
                    child: SizedBox(
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
                        // La etiqueta no se parte: si no cabe con letra grande, se reduce.
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.favorite_rounded),
                              SizedBox(width: AppTokens.espacioS),
                              Text('Comenzar a Rezar', maxLines: 1),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
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
    void abrir() => showDialog<void>(context: context, builder: (_) => MisteriosDelDiaDialog(tipo: tipo, dia: dia));
    return Card(
      margin: EdgeInsets.zero,
      child: Semantics(
        button: true,
        label: '$dia: Misterios ${tipo.nombre}. Ver los 5 misterios',
        onTap: abrir,
        excludeSemantics: true,
        child: InkWell(
          onTap: abrir,
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.espacioL),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 20, color: colores.acento),
                    const SizedBox(width: AppTokens.espacioS),
                    Flexible(
                      child: Text(dia, textAlign: TextAlign.center, style: textos.titleMedium?.copyWith(color: colores.acento)),
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.espacioM),
                DecoratedBox(
                  decoration: BoxDecoration(color: colores.boton, borderRadius: BorderRadius.circular(999)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppTokens.espacioL, vertical: AppTokens.espacioS),
                    // La píldora conserva su forma: el texto se reduce en vez de partirse.
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Misterios ${tipo.nombre}',
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        style: textos.titleLarge?.copyWith(color: colores.sobreBoton, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppTokens.espacioM),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        'Ver los 5 misterios',
                        textAlign: TextAlign.center,
                        style: textos.labelLarge?.copyWith(color: colores.acento),
                      ),
                    ),
                    Icon(Icons.chevron_right, color: colores.acento),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
