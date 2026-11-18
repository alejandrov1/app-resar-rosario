import 'package:app_resar_rosario/services/notifications_gateway.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

/// Registra solo las llamadas de cancelación; el resto del plugin no se usa aquí.
class _PluginStub implements FlutterLocalNotificationsPlugin {
  final List<String> llamadas = [];

  @override
  Future<void> cancelAll() async => llamadas.add('cancelAll');

  @override
  Future<void> cancelAllPendingNotifications() async => llamadas.add('cancelAllPendingNotifications');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('cancelAllPending cancela solo lo pendiente y no borra los avisos que ya se muestran', () async {
    final plugin = _PluginStub();
    final gateway = FlutterNotificationsGateway(plugin);

    await gateway.cancelAllPending();

    expect(plugin.llamadas, ['cancelAllPendingNotifications']);
    expect(plugin.llamadas, isNot(contains('cancelAll')));
  });
}
