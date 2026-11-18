import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferencias de accesibilidad y apariencia, guardadas en el teléfono.
class PreferencesService extends ChangeNotifier {
  PreferencesService(this._prefs)
      : _textScaleFactor = _leerEscala(_prefs),
        _useHighContrast = _prefs.getBool(_kContraste) ?? false,
        _useLargeButtons = _prefs.getBool(_kBotones) ?? false,
        _themeMode = _leerTema(_prefs);

  static const double minTextScale = 0.8;
  static const double maxTextScale = 2.0;

  static const String _kEscala = 'pref_text_scale';
  static const String _kContraste = 'pref_high_contrast';
  static const String _kBotones = 'pref_large_buttons';
  static const String _kTema = 'pref_theme_mode';

  final SharedPreferences _prefs;
  double _textScaleFactor;
  bool _useHighContrast;
  bool _useLargeButtons;
  ThemeMode _themeMode;

  double get textScaleFactor => _textScaleFactor;
  bool get useHighContrast => _useHighContrast;
  bool get useLargeButtons => _useLargeButtons;
  ThemeMode get themeMode => _themeMode;

  void updateTextScaleFactor(double factor) {
    if (factor < minTextScale || factor > maxTextScale) return;
    _textScaleFactor = factor;
    unawaited(_prefs.setDouble(_kEscala, factor));
    notifyListeners();
  }

  void toggleHighContrast() {
    _useHighContrast = !_useHighContrast;
    unawaited(_prefs.setBool(_kContraste, _useHighContrast));
    notifyListeners();
  }

  void toggleLargeButtons() {
    _useLargeButtons = !_useLargeButtons;
    unawaited(_prefs.setBool(_kBotones, _useLargeButtons));
    notifyListeners();
  }

  void updateThemeMode(ThemeMode mode) {
    _themeMode = mode;
    unawaited(_prefs.setInt(_kTema, mode.index));
    notifyListeners();
  }

  void resetToDefaults() {
    _textScaleFactor = 1.0;
    _useHighContrast = false;
    _useLargeButtons = false;
    _themeMode = ThemeMode.system;
    for (final clave in [_kEscala, _kContraste, _kBotones, _kTema]) {
      unawaited(_prefs.remove(clave));
    }
    notifyListeners();
  }

  static double _leerEscala(SharedPreferences prefs) {
    final valor = prefs.getDouble(_kEscala) ?? 1.0;
    return valor < minTextScale || valor > maxTextScale ? 1.0 : valor;
  }

  static ThemeMode _leerTema(SharedPreferences prefs) {
    final indice = prefs.getInt(_kTema);
    if (indice == null || indice < 0 || indice >= ThemeMode.values.length) {
      return ThemeMode.system;
    }
    return ThemeMode.values[indice];
  }
}
