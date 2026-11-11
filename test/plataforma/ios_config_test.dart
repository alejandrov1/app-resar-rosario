import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('identificador propio en todos los destinos', () {
    final proyecto = File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
    final ids = RegExp(r'PRODUCT_BUNDLE_IDENTIFIER = ([^;]+);').allMatches(proyecto).map((m) => m.group(1)).toSet();
    expect(ids, {'com.alejandrovaldez.santorosario', 'com.alejandrovaldez.santorosario.RunnerTests'});
  });

  test('nombre visible "Santo Rosario"', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    expect(plist, matches(RegExp(r'<key>CFBundleDisplayName</key>\s*<string>Santo Rosario</string>')));
  });

  test('muestra notificaciones con la app abierta', () {
    final delegado = File('ios/Runner/AppDelegate.swift').readAsStringSync();
    expect(delegado, contains('UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate'));
  });
}
