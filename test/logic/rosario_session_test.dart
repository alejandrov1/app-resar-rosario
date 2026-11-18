import 'package:app_resar_rosario/logic/rosario_session.dart';
import 'package:app_resar_rosario/models/prayer_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('construirPasos', () {
    final pasos = construirPasos();

    test('el rosario completo tiene 93 pasos', () {
      expect(pasos, hasLength(93));
    });

    test('empieza con las 3 oraciones iniciales', () {
      expect(pasos.take(3).map((p) => p.seccion), everyElement(SeccionRosario.iniciales));
      expect(pasos.first.oracion.type, 'inicio');
      expect(pasos[2].indiceEnSeccion, 2);
      expect(pasos[2].totalEnSeccion, 3);
    });

    test('cada misterio tiene 16 pasos: anuncio, Padre Nuestro, 10 Ave Marías y 4 oraciones', () {
      for (var m = 0; m < misteriosPorRosario; m++) {
        final delMisterio = pasos.where((p) => p.misterio == m).toList();
        expect(delMisterio, hasLength(16), reason: 'misterio $m');
        expect(delMisterio.first.esAnuncioDeMisterio, isTrue);
        final aves = delMisterio.where((p) => p.oracion.type == 'avemaria');
        expect(aves.map((p) => p.repeticion), [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]);
      }
    });

    test('termina con las 10 oraciones finales', () {
      final finales = pasos.skip(83).toList();
      expect(finales, hasLength(10));
      expect(finales.map((p) => p.seccion), everyElement(SeccionRosario.finales));
      expect(finales.last.oracion.type, 'dulce_madre');
    });
  });

  test('misterio y nombre de cada día', () {
    expect(misterioDelDia(DateTime(2026, 11, 9)), TipoMisterio.gozosos); // lunes
    expect(misterioDelDia(DateTime(2026, 11, 10)), TipoMisterio.dolorosos);
    expect(misterioDelDia(DateTime(2026, 11, 11)), TipoMisterio.gloriosos);
    expect(misterioDelDia(DateTime(2026, 11, 12)), TipoMisterio.luminosos);
    expect(misterioDelDia(DateTime(2026, 11, 13)), TipoMisterio.dolorosos);
    expect(misterioDelDia(DateTime(2026, 11, 14)), TipoMisterio.gozosos);
    expect(misterioDelDia(DateTime(2026, 11, 15)), TipoMisterio.gloriosos);
    expect(nombreDelDia(DateTime(2026, 11, 9)), 'Lunes');
    expect(nombreDelDia(DateTime(2026, 11, 15)), 'Domingo');
  });

  group('RosarioSession', () {
    late DateTime ahora;
    RosarioSession nueva() => RosarioSession(reloj: () => ahora);

    setUp(() => ahora = DateTime(2026, 11, 9, 8)); // lunes

    test('empieza en la pantalla de inicio', () {
      final s = nueva();
      expect(s.enInicio, isTrue);
      expect(s.indice, -1);
      expect(s.progreso, 0);
      expect(() => s.pasoActual, throwsStateError);
    });

    test('comenzar lleva al primer paso', () {
      final s = nueva()..comenzar();
      expect(s.enInicio, isFalse);
      expect(s.pasoActual.oracion.type, 'inicio');
    });

    test('siguiente avanza y anterior retrocede', () {
      final s = nueva()..comenzar();
      s.siguiente();
      expect(s.pasoActual.oracion.type, 'contricion');
      s.anterior();
      expect(s.pasoActual.oracion.type, 'inicio');
    });

    test('anterior desde el primer paso vuelve al inicio', () {
      final s = nueva()..comenzar();
      s.anterior();
      expect(s.enInicio, isTrue);
    });

    test('desde el Gloria, anterior vuelve a la décima Ave María', () {
      final s = nueva()..comenzar();
      while (s.pasoActual.oracion.type != 'gloria') {
        s.siguiente();
      }
      s.anterior();
      expect(s.pasoActual.oracion.type, 'avemaria');
      expect(s.pasoActual.repeticion, 9);
    });

    test('el último paso marca 100 % y al seguir vuelve al inicio', () {
      final s = nueva()..comenzar();
      for (var i = 0; i < 92; i++) {
        s.siguiente();
      }
      expect(s.esUltimo, isTrue);
      expect(s.progreso, 1.0);
      s.siguiente();
      expect(s.enInicio, isTrue);
    });

    test('el misterio se fija al comenzar aunque cambie el día', () {
      final s = nueva()..comenzar();
      ahora = DateTime(2026, 11, 10, 0, 1); // ya es martes
      expect(s.tipoMisterio, TipoMisterio.gozosos);
      s.reiniciar();
      expect(s.tipoMisterio, TipoMisterio.dolorosos);
    });

    test('título del misterio actual', () {
      final s = nueva()..comenzar();
      for (var i = 0; i < 3; i++) {
        s.siguiente();
      }
      expect(s.pasoActual.esAnuncioDeMisterio, isTrue);
      expect(s.tituloMisterioActual, 'La Encarnación del Hijo de Dios');
    });

    test('avisa a quien escucha', () {
      final s = nueva();
      var avisos = 0;
      s.addListener(() => avisos++);
      s
        ..comenzar()
        ..siguiente()
        ..anterior()
        ..reiniciar();
      expect(avisos, 4);
    });
  });
}
