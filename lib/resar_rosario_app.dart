import 'package:flutter/material.dart';
import 'models/prayer_models.dart';
import 'screens/inicio_screen.dart';
import 'screens/oraciones_iniciales_screen.dart';
import 'screens/misterios_screen.dart';
import 'screens/oraciones_finales_screen.dart';

class RosarioApp extends StatefulWidget {
  const RosarioApp({super.key});

  @override
  State<RosarioApp> createState() => _RosarioAppState();
}

class _RosarioAppState extends State<RosarioApp> {
  String currentStep = 'inicio';
  int currentMystery = 0;
  int currentPrayer = 0;
  int currentAveMaria = 0;
  String todayMystery = '';
  String todayDay = '';

  @override
  void initState() {
    super.initState();
    _setTodayMystery();
  }

  void _setTodayMystery() {
    const List<String> days = [
      'Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'
    ];
    final int today = DateTime.now().weekday % 7;
    final String currentDay = days[today];
    
    setState(() {
      todayDay = currentDay;
      todayMystery = PrayerData.mysteries[currentDay] ?? 'Gozosos';
    });
  }

  void resetApp() {
    setState(() {
      currentStep = 'inicio';
      currentMystery = 0;
      currentPrayer = 0;
      currentAveMaria = 0;
    });
  }

  void nextStep() {
    setState(() {
      if (currentStep == 'inicio') {
        currentStep = 'oraciones-iniciales';
        currentPrayer = 0;
      } else if (currentStep == 'oraciones-iniciales') {
        if (currentPrayer < PrayerData.initialPrayers.length - 1) {
          currentPrayer++;
        } else {
          currentStep = 'misterios';
          currentMystery = 0;
          currentPrayer = 0;
          currentAveMaria = 0;
        }
      } else if (currentStep == 'misterios') {
        if (currentPrayer == 2 && PrayerData.mysteryPrayers[currentPrayer].type == 'avemaria') {
          if (currentAveMaria < 9) {
            currentAveMaria++;
          } else {
            currentAveMaria = 0;
            currentPrayer++;
          }
        } else if (currentPrayer < PrayerData.mysteryPrayers.length - 1) {
          currentPrayer++;
        } else if (currentMystery < 4) {
          currentMystery++;
          currentPrayer = 0;
          currentAveMaria = 0;
        } else {
          currentStep = 'oraciones-finales';
          currentPrayer = 0;
        }
      } else if (currentStep == 'oraciones-finales') {
        if (currentPrayer < PrayerData.finalPrayers.length - 1) {
          currentPrayer++;
        } else {
          resetApp();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (currentStep) {
      case 'inicio':
        return InicioScreen(
          todayMystery: todayMystery,
          todayDay: todayDay,
          onNext: nextStep,
        );
      case 'oraciones-iniciales':
        return OracionesInicialesScreen(
          currentPrayer: currentPrayer,
          onNext: nextStep,
          onHome: resetApp,
        );
      case 'misterios':
        return MisteriosScreen(
          todayMystery: todayMystery,
          currentMystery: currentMystery,
          currentPrayer: currentPrayer,
          currentAveMaria: currentAveMaria,
          onNext: nextStep,
          onHome: resetApp,
        );
      case 'oraciones-finales':
        return OracionesFinalesScreen(
          currentPrayer: currentPrayer,
          onNext: nextStep,
          onHome: resetApp,
        );
      default:
        return InicioScreen(
          todayMystery: todayMystery,
          todayDay: todayDay,
          onNext: nextStep,
        );
    }
  }
}