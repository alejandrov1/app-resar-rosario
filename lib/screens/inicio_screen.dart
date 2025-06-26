import 'package:app_resar_rosario/services/preferences_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_constants.dart';
import '../widgets/rosary_image_widget.dart';
import '../widgets/main_menu_drawer.dart';

class InicioScreen extends StatefulWidget {
  final String todayMystery;
  final String todayDay;
  final VoidCallback onNext;
  final PreferencesService preferences;

  const InicioScreen({
    super.key,
    required this.todayMystery,
    required this.todayDay,
    required this.onNext,
    required this.preferences,
  });

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      drawer: MainMenuDrawer(
        preferences: widget.preferences,
        todayMystery: widget.todayMystery,
        todayDay: widget.todayDay,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE0F2FE),
              Color(0xFFBAE6FD),
              Color(0xFF7DD3FC),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header con menú hamburguesa
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingS,
                  vertical: AppConstants.spacingXS,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Botón de menú hamburguesa
                    Builder(
                      builder: (context) => IconButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Scaffold.of(context).openDrawer();
                        },
                        icon: Icon(
                          Icons.menu,
                          color: AppConstants.primaryBlue,
                          size: widget.preferences.useLargeButtons ? 32 : 28,
                        ),
                        tooltip: 'Abrir menú',
                      ),
                    ),
                    // Espacio para mantener el título centrado
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              
              // Título de la app
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    Text(
                      'Santo Rosario',
                      style: TextStyle(
                        fontSize: AppConstants.fontSizeXL * widget.preferences.textScaleFactor,
                        fontWeight: FontWeight.w300,
                        color: AppConstants.primaryBlue,
                        letterSpacing: 2.0,
                        shadows: [
                          Shadow(
                            blurRadius: 10.0,
                            color: Colors.white.withOpacity(0.5),
                            offset: const Offset(2.0, 2.0),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingXS),
                    Container(
                      width: 100,
                      height: 2,
                      decoration: BoxDecoration(
                        color: AppConstants.secondaryBlue,
                        borderRadius: BorderRadius.circular(1),
                        boxShadow: [
                          BoxShadow(
                            color: AppConstants.secondaryBlue.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingM),
                  child: Column(
                    children: [
                      const SizedBox(height: AppConstants.spacingM),
                      
                      SlideTransition(
                        position: _slideAnimation,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: RosaryImageWidget(
                            width: screenWidth * 0.85,
                            height: screenHeight * 0.35,
                            imagePath: 'assets/images/imagen-rosario.png',
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: AppConstants.spacingL),
                      
                      // Widget de misterios del día (sin funcionalidad de tap)
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          padding: const EdgeInsets.all(AppConstants.spacingL),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppConstants.radiusM),
                            boxShadow: [
                              BoxShadow(
                                color: AppConstants.secondaryBlue.withOpacity(0.1),
                                spreadRadius: 2,
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.calendar_today_rounded,
                                    color: AppConstants.secondaryBlue,
                                    size: 20,
                                  ),
                                  const SizedBox(width: AppConstants.spacingXS),
                                  Text(
                                    widget.todayDay,
                                    style: TextStyle(
                                      fontSize: AppConstants.fontSizeS * widget.preferences.textScaleFactor,
                                      color: AppConstants.primaryBlue,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppConstants.spacingS),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppConstants.spacingS,
                                  vertical: AppConstants.spacingXS,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppConstants.primaryBlue,
                                      AppConstants.secondaryBlue,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Text(
                                  'Misterios ${widget.todayMystery}',
                                  style: TextStyle(
                                    fontSize: AppConstants.fontSizeL * widget.preferences.textScaleFactor,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: AppConstants.spacingL),
                      
                      SlideTransition(
                        position: _slideAnimation,
                        child: Hero(
                          tag: 'start-button',
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                widget.onNext();
                              },
                              borderRadius: BorderRadius.circular(30),
                              child: Container(
                                width: screenWidth * 0.8,
                                padding: EdgeInsets.symmetric(
                                  horizontal: AppConstants.spacingL,
                                  vertical: widget.preferences.useLargeButtons 
                                      ? AppConstants.spacingM 
                                      : AppConstants.spacingS,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppConstants.primaryBlue,
                                      AppConstants.secondaryBlue,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppConstants.primaryBlue.withOpacity(0.4),
                                      spreadRadius: 1,
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.favorite_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    const SizedBox(width: AppConstants.spacingS),
                                    Text(
                                      'Comenzar a Rezar',
                                      style: TextStyle(
                                        fontSize: AppConstants.fontSizeL * widget.preferences.textScaleFactor,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: AppConstants.spacingL),
                      
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          padding: const EdgeInsets.all(AppConstants.spacingS),
                          child: Text(
                            '"El Rosario es la oración más hermosa que podemos ofrecer a la Virgen María"',
                            style: TextStyle(
                              fontSize: AppConstants.fontSizeXS * widget.preferences.textScaleFactor,
                              fontStyle: FontStyle.italic,
                              color: AppConstants.primaryBlue.withOpacity(0.8),
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: AppConstants.spacingL),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}