import 'package:flutter_test/flutter_test.dart';
import 'package:app_resar_rosario/models/prayer_models.dart';

void main() {
  group('PrayerData Tests', () {
    test('Los misterios deben estar correctamente asignados por día', () {
      expect(PrayerData.mysteries['Lunes'], equals('Gozosos'));
      expect(PrayerData.mysteries['Martes'], equals('Dolorosos'));
      expect(PrayerData.mysteries['Miércoles'], equals('Gloriosos'));
      expect(PrayerData.mysteries['Jueves'], equals('Luminosos'));
      expect(PrayerData.mysteries['Viernes'], equals('Dolorosos'));
      expect(PrayerData.mysteries['Sábado'], equals('Gozosos'));
      expect(PrayerData.mysteries['Domingo'], equals('Gloriosos'));
    });

    test('Cada tipo de misterio debe tener exactamente 5 misterios', () {
      for (final mysteryType in PrayerData.mysteryData.values) {
        expect(mysteryType.length, equals(5));
      }
    });

    test('Las oraciones iniciales deben estar en el orden correcto', () {
      expect(PrayerData.initialPrayers.length, equals(3));
      expect(PrayerData.initialPrayers[0].type, equals('inicio'));
      expect(PrayerData.initialPrayers[1].type, equals('contricion'));
      expect(PrayerData.initialPrayers[2].type, equals('invocacion'));
    });

    test('Las oraciones del misterio deben estar en el orden correcto', () {
      final prayers = PrayerData.mysteryPrayers;
      expect(prayers[0].type, equals('misterio'));
      expect(prayers[1].type, equals('padrenuestro'));
      expect(prayers[2].type, equals('avemaria'));
      expect(prayers[2].count, equals(10));
      expect(prayers[3].type, equals('gloria'));
    });
  });

  group('Prayer Model Tests', () {
    test('Prayer debe crear correctamente con todos los campos', () {
      final prayer = Prayer(
        type: 'test',
        title: 'Test Prayer',
        text: 'This is a test prayer',
        count: 5,
      );

      expect(prayer.type, equals('test'));
      expect(prayer.title, equals('Test Prayer'));
      expect(prayer.text, equals('This is a test prayer'));
      expect(prayer.count, equals(5));
    });

    test('Prayer debe aceptar count como null', () {
      final prayer = Prayer(
        type: 'test',
        title: 'Test Prayer',
        text: 'This is a test prayer',
      );

      expect(prayer.count, isNull);
    });
  });
}