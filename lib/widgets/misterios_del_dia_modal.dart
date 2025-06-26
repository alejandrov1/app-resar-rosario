import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/prayer_models.dart';
import '../constants/app_constants.dart';
import '../services/preferences_service.dart';

/// Modal mejorado con animaciones para mostrar los misterios del día
class MisteriosDelDia extends StatefulWidget {
  final String todayMystery;
  final String todayDay;
  final PreferencesService preferences;

  const MisteriosDelDia({
    super.key,
    required this.todayMystery,
    required this.todayDay,
    required this.preferences,
  });

  @override
  State<MisteriosDelDia> createState() => _MisteriosDelDiaState();
}

class _MisteriosDelDiaState extends State<MisteriosDelDia>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _itemController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late List<Animation<double>> _itemAnimations;

  @override
  void initState() {
    super.initState();
    
    // Animación principal del modal
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    // Animación para los items de la lista
    _itemController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Crear animaciones escalonadas para cada item
    final mysteryList = PrayerData.mysteryData[widget.todayMystery] ?? [];
    _itemAnimations = List.generate(
      mysteryList.length,
      (index) => Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(
        CurvedAnimation(
          parent: _itemController,
          curve: Interval(
            index * 0.15,
            0.4 + index * 0.15,
            curve: Curves.easeOutCubic,
          ),
        ),
      ),
    );

    _controller.forward().then((_) {
      _itemController.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _itemController.dispose();
    super.dispose();
  }

  void _closeModal() {
    HapticFeedback.lightImpact();
    _itemController.reverse().then((_) {
      _controller.reverse().then((_) {
        Navigator.of(context).pop();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final mysteryList = PrayerData.mysteryData[widget.todayMystery] ?? [];
    final screenHeight = MediaQuery.of(context).size.height;
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Dialog(
              backgroundColor: Colors.white,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingS,
                vertical: AppConstants.spacingM,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: 500,
                  maxHeight: screenHeight * 0.9,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header animado
                    _buildAnimatedHeader(),
                    
                    // Lista de misterios con animación
                    Flexible(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.spacingM,
                          vertical: AppConstants.spacingS,
                        ),
                        child: Column(
                          children: [
                            // Decoración superior
                            _buildTopDecoration(),
                            
                            const SizedBox(height: AppConstants.spacingS),
                            
                            // Lista animada de misterios
                            ...mysteryList.asMap().entries.map((entry) {
                              final index = entry.key;
                              final mystery = entry.value;
                              
                              return AnimatedBuilder(
                                animation: _itemAnimations[index],
                                builder: (context, child) {
                                  return Transform.translate(
                                    offset: Offset(
                                      0,
                                      30 * (1 - _itemAnimations[index].value),
                                    ),
                                    child: Opacity(
                                      opacity: _itemAnimations[index].value,
                                      child: _buildMysteryItem(index, mystery),
                                    ),
                                  );
                                },
                              );
                            }).toList(),
                            
                            const SizedBox(height: AppConstants.spacingS),
                            
                            // Nota informativa animada
                            AnimatedBuilder(
                              animation: _fadeAnimation,
                              builder: (context, child) {
                                return Opacity(
                                  opacity: _fadeAnimation.value,
                                  child: _buildInfoNote(),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Footer con botón
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppConstants.primaryBlue,
            AppConstants.secondaryBlue,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppConstants.radiusM),
          topRight: Radius.circular(AppConstants.radiusM),
        ),
      ),
      child: Stack(
        children: [
          // Patrón de fondo
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              Icons.auto_awesome,
              size: 100,
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          
          // Contenido
          Column(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Misterios ${widget.todayMystery}',
                    style: TextStyle(
                      fontSize: AppConstants.fontSizeL * widget.preferences.textScaleFactor,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.todayDay,
                        style: TextStyle(
                          fontSize: AppConstants.fontSizeS * widget.preferences.textScaleFactor,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopDecoration() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 40,
          height: 2,
          color: AppConstants.secondaryBlue.withOpacity(0.3),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingS),
          child: Icon(
            Icons.auto_awesome,
            size: 24,
            color: AppConstants.secondaryBlue.withOpacity(0.5),
          ),
        ),
        Container(
          width: 40,
          height: 2,
          color: AppConstants.secondaryBlue.withOpacity(0.3),
        ),
      ],
    );
  }

  Widget _buildMysteryItem(int index, String mystery) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingS),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
          },
          borderRadius: BorderRadius.circular(AppConstants.radiusS),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Número con efecto de elevación
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppConstants.primaryBlue,
                        AppConstants.secondaryBlue,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppConstants.secondaryBlue.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Texto del misterio con borde decorativo
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.spacingS,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.shade50,
                          Colors.blue.shade50.withOpacity(0.5),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(AppConstants.radiusS),
                      border: Border.all(
                        color: Colors.blue.shade100,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      mystery,
                      style: TextStyle(
                        fontSize: AppConstants.fontSizeS * widget.preferences.textScaleFactor,
                        height: 1.4,
                        color: AppConstants.textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoNote() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.shade50,
            Colors.amber.shade50.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(AppConstants.radiusS),
        border: Border.all(
          color: Colors.amber.shade200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lightbulb_outline,
              color: Colors.amber.shade700,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Medita en cada uno de estos misterios durante el rezo del Rosario',
              style: TextStyle(
                fontSize: (AppConstants.fontSizeXS - 1) * widget.preferences.textScaleFactor,
                color: Colors.amber.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.spacingS),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.grey.shade100,
            Colors.grey.shade50,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(AppConstants.radiusM),
          bottomRight: Radius.circular(AppConstants.radiusM),
        ),
      ),
      child: ElevatedButton.icon(
        onPressed: _closeModal,
        icon: const Icon(Icons.check_circle_outline),
        label: Text(
          'Entendido',
          style: TextStyle(
            fontSize: AppConstants.fontSizeM * widget.preferences.textScaleFactor,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryBlue,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: AppConstants.spacingL,
            vertical: widget.preferences.useLargeButtons 
                ? AppConstants.spacingM 
                : AppConstants.spacingS,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusS),
          ),
          elevation: 2,
        ),
      ),
    );
  }
}