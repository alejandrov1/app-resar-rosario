import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
  final gradle = File('android/app/build.gradle.kts').readAsStringSync();

  test('paquete propio', () {
    expect(gradle, contains('namespace = "com.alejandrovaldez.santorosario"'));
    expect(gradle, contains('applicationId = "com.alejandrovaldez.santorosario"'));
    expect(File('android/app/src/main/kotlin/com/alejandrovaldez/santorosario/MainActivity.kt').existsSync(), isTrue);
  });

  test('solo los permisos necesarios', () {
    final permisos = RegExp(r'uses-permission android:name="android\.permission\.([A-Z_]+)"')
        .allMatches(manifest)
        .map((m) => m.group(1))
        .toSet();
    expect(permisos, {
      'POST_NOTIFICATIONS',
      'RECEIVE_BOOT_COMPLETED',
      'SCHEDULE_EXACT_ALARM',
      'USE_FULL_SCREEN_INTENT',
      'VIBRATE',
      'WAKE_LOCK',
    });
  });

  test('sin configuraciones que las tiendas rechazan', () {
    for (final prohibido in [
      'usesCleartextTraffic',
      'requestLegacyExternalStorage',
      'com.google.android.gms.ads',
      'FLUTTER_NOTIFICATION_CLICK',
    ]) {
      expect(manifest, isNot(contains(prohibido)), reason: prohibido);
    }
  });

  test('los receivers del plugin no se exponen a otras apps', () {
    final receivers = RegExp(r'<receiver[^>]*>').allMatches(manifest).map((m) => m.group(0)!).toList();
    expect(receivers, hasLength(2));
    expect(receivers.every((r) => r.contains('android:exported="false"')), isTrue);
  });

  test('la firma de release se lee de key.properties, que no está en git', () {
    expect(gradle, contains('rootProject.file("key.properties")'));
    expect(gradle, contains('signingConfigs.getByName("release")'));
    expect(File('.gitignore').readAsStringSync(), contains('/android/key.properties'));
  });
}
