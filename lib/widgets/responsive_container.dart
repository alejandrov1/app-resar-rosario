import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';

/// Container responsivo que se adapta al tamaño de la pantalla
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final BoxDecoration? decoration;
  final double? maxWidth;
  
  const ResponsiveContainer({
    super.key,
    required this.child,
    this.padding,
    this.decoration,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final adaptivePadding = padding ?? ResponsiveUtils.getAdaptivePadding(context);
    final contentMaxWidth = maxWidth ?? ResponsiveUtils.getMaxContentWidth(context);
    
    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: contentMaxWidth,
        ),
        padding: adaptivePadding,
        decoration: decoration,
        child: child,
      ),
    );
  }
}