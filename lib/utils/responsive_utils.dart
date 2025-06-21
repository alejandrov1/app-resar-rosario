import 'package:flutter/material.dart';

/// Enumeración para los tipos de dispositivo
enum DeviceType {
  mobile,
  tablet,
  desktop,
}

/// Clase con utilidades para diseño responsivo
class ResponsiveUtils {
  /// Obtiene el tipo de dispositivo basado en el ancho de pantalla
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < 600) {
      return DeviceType.mobile;
    } else if (width < 1200) {
      return DeviceType.tablet;
    } else {
      return DeviceType.desktop;
    }
  }
  
  /// Verifica si el dispositivo está en orientación horizontal
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }
  
  /// Obtiene el padding adaptativo según el tipo de dispositivo
  static EdgeInsets getAdaptivePadding(BuildContext context) {
    switch (getDeviceType(context)) {
      case DeviceType.mobile:
        return const EdgeInsets.all(16.0);
      case DeviceType.tablet:
        return const EdgeInsets.all(24.0);
      case DeviceType.desktop:
        return const EdgeInsets.all(32.0);
    }
  }
  
  /// Obtiene el ancho máximo del contenido según el dispositivo
  static double getMaxContentWidth(BuildContext context) {
    switch (getDeviceType(context)) {
      case DeviceType.mobile:
        return double.infinity;
      case DeviceType.tablet:
        return 600.0;
      case DeviceType.desktop:
        return 800.0;
    }
  }
  
  /// Obtiene el número de columnas para layouts de grid
  static int getGridColumns(BuildContext context) {
    final deviceType = getDeviceType(context);
    final isLandscape = ResponsiveUtils.isLandscape(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return isLandscape ? 2 : 1;
      case DeviceType.tablet:
        return isLandscape ? 3 : 2;
      case DeviceType.desktop:
        return 4;
    }
  }
}