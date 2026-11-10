import 'package:app_resar_rosario/main.dart';
import 'package:app_resar_rosario/services/notification_service.dart';
import 'package:app_resar_rosario/services/preferences_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('la app arranca en la pantalla de inicio', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => PreferencesService()),
          ChangeNotifierProvider(create: (_) => NotificationService()),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Santo Rosario'), findsWidgets);
    expect(find.text('Comenzar a Rezar'), findsOneWidget);
  });
}
