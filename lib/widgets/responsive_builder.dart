import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';

/// Widget que construye diferentes layouts según el tipo de dispositivo
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext, BoxConstraints) mobile;
  final Widget Function(BuildContext, BoxConstraints)? tablet;
  final Widget Function(BuildContext, BoxConstraints)? desktop;

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final deviceType = ResponsiveUtils.getDeviceType(context);
        
        switch (deviceType) {
          case DeviceType.desktop:
            return desktop?.call(context, constraints) ?? 
                   tablet?.call(context, constraints) ?? 
                   mobile(context, constraints);
          case DeviceType.tablet:
            return tablet?.call(context, constraints) ?? 
                   mobile(context, constraints);
          case DeviceType.mobile:
            return mobile(context, constraints);
        }
      },
    );
  }
}