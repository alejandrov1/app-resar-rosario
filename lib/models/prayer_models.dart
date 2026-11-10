import '../data/oraciones.dart';

/// Una oración del rosario.
class Prayer {
  const Prayer({required this.type, required this.title, required this.text, this.count});

  final String type;
  final String title;
  final String text;

  /// Veces seguidas que se reza (solo el Ave María de cada misterio: 10).
  final int? count;
}

/// Las tres partes del rosario.
enum SeccionRosario { iniciales, misterio, finales }

/// Tipos de misterios.
enum TipoMisterio {
  gozosos('Gozosos', 'Gozoso'),
  dolorosos('Dolorosos', 'Doloroso'),
  gloriosos('Gloriosos', 'Glorioso'),
  luminosos('Luminosos', 'Luminoso');

  const TipoMisterio(this.nombre, this.singular);

  final String nombre;
  final String singular;
}

/// Compatibilidad temporal con las pantallas antiguas. Se elimina en la Task 11.
class PrayerData {
  static final Map<String, String> mysteries = {
    for (var dia = DateTime.monday; dia <= DateTime.sunday; dia++) nombresDias[dia - 1]: misterioPorDia[dia]!.nombre,
  };
  static final Map<String, List<String>> mysteryData = {
    for (final tipo in TipoMisterio.values) tipo.nombre: misteriosPorTipo[tipo]!,
  };
  static const List<Prayer> initialPrayers = oracionesIniciales;
  static const List<Prayer> mysteryPrayers = oracionesPorMisterio;
  static const List<Prayer> finalPrayers = oracionesFinales;
}
