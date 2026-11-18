import 'package:app_resar_rosario/data/oraciones.dart';
import 'package:app_resar_rosario/models/prayer_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cada tipo de misterio tiene 5 misterios', () {
    for (final tipo in TipoMisterio.values) {
      expect(misteriosPorTipo[tipo], hasLength(5), reason: tipo.nombre);
    }
  });

  test('a cada día le toca su misterio', () {
    expect(misterioPorDia, {
      DateTime.monday: TipoMisterio.gozosos,
      DateTime.tuesday: TipoMisterio.dolorosos,
      DateTime.wednesday: TipoMisterio.gloriosos,
      DateTime.thursday: TipoMisterio.luminosos,
      DateTime.friday: TipoMisterio.dolorosos,
      DateTime.saturday: TipoMisterio.gozosos,
      DateTime.sunday: TipoMisterio.gloriosos,
    });
    expect(nombresDias, ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo']);
  });

  test('oraciones iniciales en orden', () {
    expect(oracionesIniciales.map((o) => o.type), ['inicio', 'contricion', 'invocacion']);
  });

  test('oraciones de cada misterio en orden, con 10 Ave Marías', () {
    expect(oracionesPorMisterio.map((o) => o.type), [
      'misterio',
      'padrenuestro',
      'avemaria',
      'gloria',
      'maria_madre',
      'sagrado_corazon',
      'oh_jesus',
    ]);
    expect(oracionesPorMisterio[2].count, 10);
  });

  test('oraciones finales en orden', () {
    expect(oracionesFinales.map((o) => o.type), [
      'letanias',
      'cordero',
      'oracion_final',
      'intenciones_papa',
      'avemaria_final',
      'gloria_final',
      'salve',
      'jaculatoria',
      'senal_final',
      'dulce_madre',
    ]);
  });

  test('las oraciones repetidas usan el mismo texto', () {
    expect(oracionesFinales[3].text, oracionesPorMisterio[1].text); // Padre Nuestro
    expect(oracionesFinales[4].text, oracionesPorMisterio[2].text); // Ave María
    expect(oracionesFinales[5].text, oracionesPorMisterio[3].text); // Gloria
    expect(oracionesFinales[8].text, oracionesIniciales[0].text); // Señal de la Cruz
    expect(oracionesIniciales[2].text, endsWith(oracionesPorMisterio[3].text)); // termina con el Gloria
  });

  test('erratas corregidas', () {
    final todo = [...oracionesIniciales, ...oracionesPorMisterio, ...oracionesFinales]
        .map((o) => '${o.title}\n${o.text}')
        .join('\n');
    expect(todo, contains('Sagrado Corazón de Jesús,\nen vos confío.'));
    expect(todo, contains('ampáranos, gran Señora'));
    expect(todo, contains('Por ser Tú quien eres'));
    expect(todo, isNot(contains('Santo.Amén')));
    expect(todo, isNot(contains('corazon')));
  });
}
