import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

Future<String> _zonaDelTelefono() async => (await FlutterTimezone.getLocalTimezone()).identifier;

/// Carga las zonas horarias y fija la del teléfono como zona local.
/// Antes la app quedaba siempre en UTC: un recordatorio de 7:00 sonaba a otra hora.
Future<void> configurarZonaHoraria({Future<String> Function() obtenerZona = _zonaDelTelefono}) async {
  tzdata.initializeTimeZones();
  try {
    tz.setLocalLocation(tz.getLocation(await obtenerZona()));
  } catch (e) {
    tz.setLocalLocation(tz.UTC);
    debugPrint('No se pudo detectar la zona horaria; se usa UTC. Detalle: $e');
  }
}
