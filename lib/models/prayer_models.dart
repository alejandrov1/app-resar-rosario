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
