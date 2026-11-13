import 'package:app_resar_rosario/services/notifications_gateway.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_notifications_gateway.dart';

/// Se llama en cada pantalla que hay que revisar, con un nombre que la identifica.
typedef Revisar = Future<void> Function(String pantalla);

/// Un camino por la app, desde el inicio recién abierto, que pasa por varias pantallas.
class Recorrido {
  const Recorrido(this.nombre, this.recorrer, {this.gateway});

  final String nombre;
  final Future<void> Function(WidgetTester tester, Revisar revisar) recorrer;

  /// Doble del sistema de notificaciones para este recorrido (p. ej. sin permisos).
  final FakeNotificationsGateway Function()? gateway;
}

/// Las 4 variantes de tema como preferencias guardadas (ThemeMode: 1 claro, 2 oscuro).
const variantesDeTema = <String, Map<String, Object>>{
  'claro': {'pref_theme_mode': 1},
  'oscuro': {'pref_theme_mode': 2},
  'claro alto contraste': {'pref_theme_mode': 1, 'pref_high_contrast': true},
  'oscuro alto contraste': {'pref_theme_mode': 2, 'pref_high_contrast': true},
};

/// Desplaza hasta [objetivo], lo toca y espera a que todo se asiente.
Future<void> tocar(WidgetTester tester, Finder objetivo) async {
  await tester.ensureVisible(objetivo);
  await tester.pumpAndSettle();
  await tester.tap(objetivo);
  await tester.pumpAndSettle();
}

Future<void> _abrirDesdeMenu(WidgetTester tester, String opcion) async {
  await tester.tap(find.byIcon(Icons.menu));
  await tester.pumpAndSettle();
  await tocar(tester, find.text(opcion));
}

Future<void> _soloAgendar(WidgetTester tester, Revisar revisar, String pantalla) async {
  await _abrirDesdeMenu(tester, 'Agendar Rosario');
  await revisar(pantalla);
}

final recorridos = <Recorrido>[
  Recorrido('inicio, menú y misterios del día', (tester, revisar) async {
    await revisar('inicio');
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await revisar('menú');
    Navigator.of(tester.element(find.text('Agendar Rosario'))).pop();
    await tester.pumpAndSettle();
    await tocar(tester, find.text('Ver los 5 misterios'));
    await revisar('misterios del día');
    await tocar(tester, find.text('Entendido'));
  }),
  Recorrido('rezo completo', (tester, revisar) async {
    await tocar(tester, find.text('Comenzar a Rezar'));
    for (var paso = 0; paso < 93; paso++) {
      await revisar('paso $paso');
      if (paso == 4) {
        await tocar(tester, find.byTooltip('Volver al inicio'));
        await revisar('¿Salir del rosario?');
        await tocar(tester, find.text('Seguir rezando'));
      }
      await tocar(tester, find.text(paso == 92 ? 'Terminar Rosario' : 'Continuar'));
    }
  }),
  Recorrido('recordatorios', (tester, revisar) async {
    await _abrirDesdeMenu(tester, 'Agendar Rosario');
    await revisar('lista vacía');
    await tocar(tester, find.text('Nuevo'));
    await revisar('formulario nuevo');
    await tocar(tester, find.text('Guardar'));
    await revisar('formulario con error de días');
    await tocar(tester, find.text('L'));
    await tocar(tester, find.text('Toca para cambiarla'));
    await revisar('selector de hora');
    Navigator.of(tester.element(find.byType(TimePickerDialog))).pop();
    await tester.pumpAndSettle();
    await tocar(tester, find.text('Guardar'));
    await revisar('lista con un recordatorio');
    await tocar(tester, find.byType(Switch));
    await revisar('recordatorio desactivado');
    await tocar(tester, find.text('Rezar el Santo Rosario'));
    await revisar('formulario de edición');
    await tocar(tester, find.byTooltip('Cerrar'));
  }),
  Recorrido(
    'aviso sin notificaciones',
    (tester, revisar) => _soloAgendar(tester, revisar, 'aviso sin notificaciones'),
    gateway: () => FakeNotificationsGateway()
      ..permissions = NotificationPermissions.none
      ..permissionsAfterRequest = NotificationPermissions.none,
  ),
  Recorrido(
    'aviso sin alarmas exactas',
    (tester, revisar) => _soloAgendar(tester, revisar, 'aviso sin alarmas exactas'),
    gateway: () =>
        FakeNotificationsGateway()..permissions = const NotificationPermissions(notifications: true, exactAlarms: false),
  ),
  Recorrido(
    'aviso sin servicio de notificaciones',
    (tester, revisar) => _soloAgendar(tester, revisar, 'aviso sin servicio'),
    gateway: () => FakeNotificationsGateway()..failInitialize = true,
  ),
  Recorrido('configuración y acerca de', (tester, revisar) async {
    await _abrirDesdeMenu(tester, 'Configuración');
    await revisar('configuración');
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await _abrirDesdeMenu(tester, 'Acerca de');
    await revisar('acerca de');
  }),
];
