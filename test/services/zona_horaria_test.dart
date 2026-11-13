import 'package:app_resar_rosario/services/zona_horaria.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

void main() {
  // Parte siempre de una zona distinta de UTC: el orden de las pruebas no cuenta y el respaldo a UTC se nota.
  setUp(() {
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Mexico_City'));
  });

  test('usa la zona horaria del teléfono', () async {
    await configurarZonaHoraria(obtenerZona: () async => 'America/Hermosillo');
    expect(tz.local.name, 'America/Hermosillo');
  });

  test('si la zona no existe, usa UTC', () async {
    await configurarZonaHoraria(obtenerZona: () async => 'Zona/Inexistente');
    expect(tz.local.name, tz.UTC.name);
  });

  test('si no se puede consultar, usa UTC', () async {
    await configurarZonaHoraria(obtenerZona: () => Future<String>.error(Exception('sin canal')));
    expect(tz.local.name, tz.UTC.name);
  });
}
