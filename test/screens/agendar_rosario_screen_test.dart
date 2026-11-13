import 'package:app_resar_rosario/screens/agendar_rosario_screen.dart';
import 'package:app_resar_rosario/services/notifications_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';
import '../support/fake_notifications_gateway.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<FakeNotificationsGateway> mostrar(WidgetTester tester, {FakeNotificationsGateway? gateway}) async {
    final preferencias = await preferenciasDePrueba();
    final g = gateway ?? FakeNotificationsGateway();
    final notificaciones = await notificacionesDePrueba(g);
    await tester.pumpWidget(envolver(
      const AgendarRosarioScreen(),
      preferencias: preferencias,
      notificaciones: notificaciones,
    ));
    await tester.pumpAndSettle();
    return g;
  }

  Future<void> crearRecordatorioDelLunes(WidgetTester tester) async {
    await tester.tap(find.text('Nuevo'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('L'));
    await tester.tap(find.text('L'));
    await tester.ensureVisible(find.text('Guardar'));
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
  }

  testWidgets('sin recordatorios muestra el estado vacío', (tester) async {
    await mostrar(tester);
    expect(find.text('No hay recordatorios'), findsOneWidget);
  });

  testWidgets('crear un recordatorio lo muestra y lo programa', (tester) async {
    final gateway = await mostrar(tester);
    await crearRecordatorioDelLunes(tester);
    expect(find.text('Rezar el Santo Rosario'), findsOneWidget);
    expect(gateway.scheduled.keys, [11]);
  });

  testWidgets('si no se puede programar, lo dice', (tester) async {
    final gateway = await mostrar(tester);
    gateway.failSchedule = true;
    await crearRecordatorioDelLunes(tester);
    expect(find.textContaining('no se pudo programar'), findsOneWidget);
  });

  testWidgets('sin permiso de notificaciones lo avisa y ofrece abrir los ajustes', (tester) async {
    final gateway = FakeNotificationsGateway()
      ..permissions = NotificationPermissions.none
      ..permissionsAfterRequest = NotificationPermissions.none;
    await mostrar(tester, gateway: gateway);

    expect(find.textContaining('notificaciones están desactivadas'), findsOneWidget);
    await tester.tap(find.text('Permitir notificaciones'));
    await tester.pumpAndSettle();
    expect(gateway.openSettingsCalls, 1);
  });

  testWidgets('sin alarmas exactas ofrece permitirlas', (tester) async {
    final gateway = FakeNotificationsGateway()
      ..permissions = const NotificationPermissions(notifications: true, exactAlarms: false);
    await mostrar(tester, gateway: gateway);

    await tester.tap(find.text('Permitir'));
    await tester.pumpAndSettle();
    expect(gateway.requestExactAlarmsCalls, 1);
  });
}
