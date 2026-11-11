import 'package:app_resar_rosario/services/zona_horaria.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
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
