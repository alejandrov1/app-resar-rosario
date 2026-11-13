import 'package:app_resar_rosario/services/preferences_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/app_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('valores por defecto', () async {
    final p = await preferenciasDePrueba();
    expect(p.textScaleFactor, 1.0);
    expect(p.useHighContrast, isFalse);
    expect(p.useLargeButtons, isFalse);
    expect(p.themeMode, ThemeMode.system);
  });

  test('los cambios se guardan y se recuperan al volver a abrir la app', () async {
    final p = await preferenciasDePrueba();
    p
      ..updateTextScaleFactor(1.5)
      ..toggleHighContrast()
      ..toggleLargeButtons()
      ..updateThemeMode(ThemeMode.dark);

    final reabierta = PreferencesService(await SharedPreferences.getInstance());
    expect(reabierta.textScaleFactor, 1.5);
    expect(reabierta.useHighContrast, isTrue);
    expect(reabierta.useLargeButtons, isTrue);
    expect(reabierta.themeMode, ThemeMode.dark);
  });

  test('ignora tamaños de texto fuera de rango', () async {
    final p = await preferenciasDePrueba();
    p.updateTextScaleFactor(1.4);
    p.updateTextScaleFactor(0.5);
    p.updateTextScaleFactor(3.0);
    expect(p.textScaleFactor, 1.4);
  });

  test('si lo guardado está dañado usa los valores por defecto', () async {
    final p = await preferenciasDePrueba({'pref_text_scale': 9.0, 'pref_theme_mode': 7});
    expect(p.textScaleFactor, 1.0);
    expect(p.themeMode, ThemeMode.system);
  });

  test('restablecer borra lo guardado', () async {
    final p = await preferenciasDePrueba({'pref_large_buttons': true, 'pref_text_scale': 1.8});
    p.resetToDefaults();
    final reabierta = PreferencesService(await SharedPreferences.getInstance());
    expect(reabierta.useLargeButtons, isFalse);
    expect(reabierta.textScaleFactor, 1.0);
  });

  test('avisa a quien escucha en cada cambio', () async {
    final p = await preferenciasDePrueba();
    var avisos = 0;
    p.addListener(() => avisos++);
    p
      ..toggleHighContrast()
      ..updateThemeMode(ThemeMode.light);
    expect(avisos, 2);
  });
}
