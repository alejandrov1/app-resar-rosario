import 'package:app_resar_rosario/logic/rosario_session.dart';
import 'package:app_resar_rosario/main.dart';
import 'package:app_resar_rosario/services/notification_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'support/app_harness.dart';

void main() {
  testWidgets('la app arranca en la pantalla de inicio', (tester) async {
    final preferencias = await preferenciasDePrueba();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: preferencias),
          ChangeNotifierProvider(create: (_) => NotificationService()),
          ChangeNotifierProvider(create: (_) => RosarioSession(reloj: () => lunes)),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Santo Rosario'), findsWidgets);
    expect(find.text('Comenzar a Rezar'), findsOneWidget);
  });
}
