import 'package:flutter/foundation.dart';

import '../data/oraciones.dart';
import '../models/prayer_models.dart';

/// Misterios que se rezan en cada rosario.
const int misteriosPorRosario = 5;

/// Un paso del recorrido del rosario.
@immutable
class PasoRosario {
  const PasoRosario({
    required this.seccion,
    required this.oracion,
    required this.indiceEnSeccion,
    required this.totalEnSeccion,
    this.misterio,
    this.repeticion,
  });

  final SeccionRosario seccion;
  final Prayer oracion;

  /// Posición de la oración en su lista (iniciales, finales o las de cada misterio).
  final int indiceEnSeccion;
  final int totalEnSeccion;

  /// Misterio actual (0 a 4). Solo en la sección de misterios.
  final int? misterio;

  /// Repetición actual (0 a 9). Solo durante las diez Ave Marías.
  final int? repeticion;

  bool get esAnuncioDeMisterio => oracion.type == 'misterio';
}

/// Arma la lista completa de pasos del rosario.
List<PasoRosario> construirPasos({
  List<Prayer> iniciales = oracionesIniciales,
  List<Prayer> porMisterio = oracionesPorMisterio,
  List<Prayer> finales = oracionesFinales,
  int misterios = misteriosPorRosario,
}) {
  final pasos = <PasoRosario>[
    for (var i = 0; i < iniciales.length; i++)
      PasoRosario(
        seccion: SeccionRosario.iniciales,
        oracion: iniciales[i],
        indiceEnSeccion: i,
        totalEnSeccion: iniciales.length,
      ),
  ];
  for (var m = 0; m < misterios; m++) {
    for (var i = 0; i < porMisterio.length; i++) {
      final oracion = porMisterio[i];
      final veces = oracion.count ?? 1;
      for (var r = 0; r < veces; r++) {
        pasos.add(PasoRosario(
          seccion: SeccionRosario.misterio,
          oracion: oracion,
          indiceEnSeccion: i,
          totalEnSeccion: porMisterio.length,
          misterio: m,
          repeticion: oracion.count == null ? null : r,
        ));
      }
    }
  }
  pasos.addAll([
    for (var i = 0; i < finales.length; i++)
      PasoRosario(
        seccion: SeccionRosario.finales,
        oracion: finales[i],
        indiceEnSeccion: i,
        totalEnSeccion: finales.length,
      ),
  ]);
  return List.unmodifiable(pasos);
}

TipoMisterio misterioDelDia(DateTime fecha) => misterioPorDia[fecha.weekday]!;

String nombreDelDia(DateTime fecha) => nombresDias[fecha.weekday - 1];

/// Estado del rezo: en qué paso va la persona.
class RosarioSession extends ChangeNotifier {
  RosarioSession({DateTime Function()? reloj, List<PasoRosario>? pasos})
      : _reloj = reloj ?? DateTime.now,
        pasos = pasos ?? construirPasos();

  final DateTime Function() _reloj;
  final List<PasoRosario> pasos;

  int _indice = -1;
  TipoMisterio? _tipoFijado;

  DateTime get hoy => _reloj();
  bool get enInicio => _indice < 0;
  int get indice => _indice;
  bool get esUltimo => _indice == pasos.length - 1;
  double get progreso => enInicio ? 0 : (_indice + 1) / pasos.length;

  /// El misterio de hoy. Mientras se reza no cambia, aunque pase la medianoche.
  TipoMisterio get tipoMisterio => _tipoFijado ?? misterioDelDia(_reloj());

  PasoRosario get pasoActual {
    if (enInicio) throw StateError('El rosario no ha comenzado.');
    return pasos[_indice];
  }

  String get tituloMisterioActual {
    final misterio = pasoActual.misterio;
    if (misterio == null) throw StateError('El paso actual no es de un misterio.');
    return misteriosPorTipo[tipoMisterio]![misterio];
  }

  void comenzar() {
    _tipoFijado = misterioDelDia(_reloj());
    _indice = 0;
    notifyListeners();
  }

  void siguiente() {
    if (enInicio) {
      comenzar();
      return;
    }
    if (esUltimo) {
      reiniciar();
      return;
    }
    _indice++;
    notifyListeners();
  }

  void anterior() {
    if (enInicio) return;
    if (_indice == 0) {
      reiniciar();
      return;
    }
    _indice--;
    notifyListeners();
  }

  void reiniciar() {
    _indice = -1;
    _tipoFijado = null;
    notifyListeners();
  }
}
