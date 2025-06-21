import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:app_resar_rosario/services/preferences_service.dart';

void main() {
  group('PreferencesService Tests', () {
    late PreferencesService preferences;

    setUp(() {
      preferences = PreferencesService();
    });

    test('Valores por defecto deben ser correctos', () {
      expect(preferences.textScaleFactor, equals(1.0));
      expect(preferences.useHighContrast, isFalse);
      expect(preferences.useLargeButtons, isFalse);
      expect(preferences.themeMode, equals(ThemeMode.system));
    });

    test('updateTextScaleFactor debe actualizar el valor dentro del rango', () {
      preferences.updateTextScaleFactor(1.5);
      expect(preferences.textScaleFactor, equals(1.5));

      // No debe actualizar si está fuera del rango
      preferences.updateTextScaleFactor(0.5);
      expect(preferences.textScaleFactor, equals(1.5));

      preferences.updateTextScaleFactor(3.0);
      expect(preferences.textScaleFactor, equals(1.5));
    });

    test('toggleHighContrast debe alternar el valor', () {
      expect(preferences.useHighContrast, isFalse);
      
      preferences.toggleHighContrast();
      expect(preferences.useHighContrast, isTrue);
      
      preferences.toggleHighContrast();
      expect(preferences.useHighContrast, isFalse);
    });

    test('resetToDefaults debe restaurar todos los valores', () {
      // Cambiar valores
      preferences.updateTextScaleFactor(1.8);
      preferences.toggleHighContrast();
      preferences.toggleLargeButtons();
      preferences.updateThemeMode(ThemeMode.dark);

      // Verificar cambios
      expect(preferences.textScaleFactor, equals(1.8));
      expect(preferences.useHighContrast, isTrue);
      expect(preferences.useLargeButtons, isTrue);
      expect(preferences.themeMode, equals(ThemeMode.dark));

      // Resetear
      preferences.resetToDefaults();

      // Verificar valores por defecto
      expect(preferences.textScaleFactor, equals(1.0));
      expect(preferences.useHighContrast, isFalse);
      expect(preferences.useLargeButtons, isFalse);
      expect(preferences.themeMode, equals(ThemeMode.system));
    });
  });
}