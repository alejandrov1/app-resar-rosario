import 'package:flutter/material.dart';
import 'app_constants.dart';

class AppTheme {
  static ThemeData lightTheme(double textScaleFactor) {
    return ThemeData(
      useMaterial3: true,
      primaryColor: AppConstants.primaryBlue,
      colorScheme: const ColorScheme.light(
        primary: AppConstants.primaryBlue,
        secondary: AppConstants.secondaryBlue,
        surface: Colors.white,
        background: Colors.white,
        error: Colors.red,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingS),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusS),
          ),
          elevation: 0,
          textStyle: TextStyle(
            fontSize: AppConstants.fontSizeM * textScaleFactor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: AppConstants.fontSizeXL * textScaleFactor,
          fontWeight: FontWeight.bold,
          color: AppConstants.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: AppConstants.fontSizeL * textScaleFactor,
          fontWeight: FontWeight.bold,
          color: AppConstants.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: AppConstants.fontSizeM * textScaleFactor,
          fontWeight: FontWeight.w600,
          color: AppConstants.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: AppConstants.fontSizeS * textScaleFactor,
          height: 1.6,
          color: AppConstants.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: AppConstants.fontSizeXS * textScaleFactor,
          color: AppConstants.textSecondary,
        ),
      ),
    );
  }
  
  static ThemeData darkTheme(double textScaleFactor) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppConstants.primaryBlue,
      colorScheme: const ColorScheme.dark(
        primary: AppConstants.primaryBlue,
        secondary: AppConstants.secondaryBlue,
        surface: Color(0xFF1F2937),
        background: Color(0xFF111827),
        error: Colors.red,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingS),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusS),
          ),
          elevation: 0,
          textStyle: TextStyle(
            fontSize: AppConstants.fontSizeM * textScaleFactor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: AppConstants.fontSizeXL * textScaleFactor,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        headlineMedium: TextStyle(
          fontSize: AppConstants.fontSizeL * textScaleFactor,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        titleMedium: TextStyle(
          fontSize: AppConstants.fontSizeM * textScaleFactor,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        bodyLarge: TextStyle(
          fontSize: AppConstants.fontSizeS * textScaleFactor,
          height: 1.6,
          color: Colors.white,
        ),
        bodyMedium: TextStyle(
          fontSize: AppConstants.fontSizeXS * textScaleFactor,
          color: Colors.grey.shade400,
        ),
      ),
    );
  }
}