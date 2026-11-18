import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../support/app_harness.dart';
import '../support/auditor_contraste.dart';
import '../support/recorridos_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Santo Rosario',
      packageName: 'com.alejandrovaldez.santorosario',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  for (final MapEntry(key: tema, value: preferencias) in variantesDeTema.entries) {
    for (final recorrido in recorridos) {
      testWidgets('$tema · ${recorrido.nombre}: todo texto se lee', (tester) async {
        await tester.pumpWidget(await appDePrueba(preferencias: preferencias, gateway: recorrido.gateway?.call()));
        await tester.pumpAndSettle();
        final fallas = <String>[];
        await recorrido.recorrer(tester, (pantalla) async => fallas.addAll(fallasDeContraste(tester, pantalla)));
        expect(fallas, isEmpty, reason: fallas.join('\n'));
      });
    }
  }
}
