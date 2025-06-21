import 'package:flutter/material.dart';

/// Servicio para manejar las preferencias del usuario
/// Incluye configuraciones de accesibilidad y personalización
class PreferencesService extends ChangeNotifier {
  // Singleton
  static final PreferencesService _instance = PreferencesService._internal();
  factory PreferencesService() => _instance;
  PreferencesService._internal();

  // Valores por defecto
  double _textScaleFactor = 1.0;
  bool _useHighContrast = false;
  bool _useLargeButtons = false;
  ThemeMode _themeMode = ThemeMode.system;

  // Getters
  double get textScaleFactor => _textScaleFactor;
  bool get useHighContrast => _useHighContrast;
  bool get useLargeButtons => _useLargeButtons;
  ThemeMode get themeMode => _themeMode;

  // Métodos para actualizar preferencias
  void updateTextScaleFactor(double factor) {
    if (factor >= 0.8 && factor <= 2.0) {
      _textScaleFactor = factor;
      notifyListeners();
    }
  }

  void toggleHighContrast() {
    _useHighContrast = !_useHighContrast;
    notifyListeners();
  }

  void toggleLargeButtons() {
    _useLargeButtons = !_useLargeButtons;
    notifyListeners();
  }

  void updateThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  // Método para resetear todas las preferencias
  void resetToDefaults() {
    _textScaleFactor = 1.0;
    _useHighContrast = false;
    _useLargeButtons = false;
    _themeMode = ThemeMode.system;
    notifyListeners();
  }
}