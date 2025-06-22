import 'package:flutter/material.dart';

/// Widget especializado para mostrar la imagen del rosario con diferentes estilos
class RosaryImageWidget extends StatelessWidget {
  final double width;
  final double height;
  final String imagePath;
  final BoxFit fit;
  final BorderRadius borderRadius;
  final List<BoxShadow>? boxShadow;
  final Widget? placeholder;
  final Widget? errorWidget;

  const RosaryImageWidget({
    super.key,
    required this.width,
    required this.height,
    required this.imagePath,
    this.fit = BoxFit.contain,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.boxShadow,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withOpacity(0.9),
                Colors.white.withOpacity(0.7),
              ],
            ),
          ),
          child: Image.asset(
            imagePath,
            fit: fit,
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded) {
                return child;
              }
              return AnimatedOpacity(
                opacity: frame == null ? 0 : 1,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
                child: child,
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return errorWidget ?? _buildDefaultErrorWidget();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultErrorWidget() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade100,
            Colors.blue.shade200,
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance,
            size: 60,
            color: Colors.blue.shade700,
          ),
          const SizedBox(height: 12),
          Text(
            'Santo Rosario',
            style: TextStyle(
              color: Colors.blue.shade700,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget alternativo con efecto parallax para la imagen
class ParallaxRosaryImage extends StatefulWidget {
  final double width;
  final double height;
  final String imagePath;

  const ParallaxRosaryImage({
    super.key,
    required this.width,
    required this.height,
    required this.imagePath,
  });

  @override
  State<ParallaxRosaryImage> createState() => _ParallaxRosaryImageState();
}

class _ParallaxRosaryImageState extends State<ParallaxRosaryImage> {
  double _offsetY = 0;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollNotification) {
        if (scrollNotification is ScrollUpdateNotification) {
          setState(() {
            _offsetY = scrollNotification.metrics.pixels * 0.5;
          });
        }
        return true;
      },
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Transform.translate(
                offset: Offset(0, -_offsetY),
                child: Image.asset(
                  widget.imagePath,
                  fit: BoxFit.cover,
                  height: widget.height + 100,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.3),
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

/// Widget con efecto de zoom al tocar
class InteractiveRosaryImage extends StatefulWidget {
  final double width;
  final double height;
  final String imagePath;
  final VoidCallback? onTap;

  const InteractiveRosaryImage({
    super.key,
    required this.width,
    required this.height,
    required this.imagePath,
    this.onTap,
  });

  @override
  State<InteractiveRosaryImage> createState() => _InteractiveRosaryImageState();
}

class _InteractiveRosaryImageState extends State<InteractiveRosaryImage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: RosaryImageWidget(
              width: widget.width,
              height: widget.height,
              imagePath: widget.imagePath,
            ),
          );
        },
      ),
    );
  }
}