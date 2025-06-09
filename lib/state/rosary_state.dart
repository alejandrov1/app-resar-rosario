import 'package:flutter/material.dart';
import '../data/mysteries.dart';

class RosaryState with ChangeNotifier {
  String currentStep = 'inicio';
  int currentMystery = 0;
  int currentPrayer = 0;
  int currentAveMaria = 0;

  String todayDay = '';
  String todayMystery = '';

  RosaryState() {
    final days = [
      'Domingo',
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado'
    ];
    final now = DateTime.now();
    todayDay = days[now.weekday % 7];
    todayMystery = mysteries[todayDay]!;
  }

  void nextStep() {
    if (currentStep == 'inicio') {
      currentStep = 'oraciones-iniciales';
      currentPrayer = 0;
    } else if (currentStep == 'oraciones-iniciales') {
      currentPrayer++;
      if (currentPrayer >= 3) {
        currentStep = 'misterios';
        currentPrayer = 0;
        currentAveMaria = 0;
        currentMystery = 0;
      }
    } else if (currentStep == 'misterios') {
      if (currentPrayer == 2 && currentAveMaria < 9) {
        currentAveMaria++;
      } else {
        if (currentPrayer < 5) {
          currentPrayer++;
          currentAveMaria = 0;
        } else if (currentMystery < 4) {
          currentMystery++;
          currentPrayer = 0;
          currentAveMaria = 0;
        } else {
          currentStep = 'oraciones-finales';
          currentPrayer = 0;
        }
      }
    } else if (currentStep == 'oraciones-finales') {
      currentPrayer++;
      if (currentPrayer >= 8) reset();
    }

    notifyListeners();
  }

  void reset() {
    currentStep = 'inicio';
    currentPrayer = 0;
    currentAveMaria = 0;
    currentMystery = 0;
    notifyListeners();
  }
}
