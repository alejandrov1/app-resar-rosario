import 'package:flutter/material.dart';
import 'models/prayer_models.dart';
import 'screens/inicio_screen.dart';
import 'screens/oraciones_iniciales_screen.dart';
import 'screens/misterios_screen.dart';
import 'screens/oraciones_finales_screen.dart';
import 'services/preferences_service.dart';

/// Widget principal que maneja el estado y navegación de la aplicación del Rosario
/// 
/// Esta clase gestiona:
/// - El flujo de navegación entre las diferentes secciones del rosario
/// - El estado actual del rezo (qué oración, misterio, etc.)
/// - La determinación automática del tipo de misterio según el día
class RosarioApp extends StatefulWidget {
  final PreferencesService preferences;
  
  const RosarioApp({
    super.key,
    required this.preferences,
  });

  @override
  State<RosarioApp> createState() => _RosarioAppState();
}

class _RosarioAppState extends State<RosarioApp> {
  // Estados de navegación
  String currentStep = 'inicio';
  
  // Contadores para el progreso
  int currentMystery = 0;      // Misterio actual (0-4)
  int currentPrayer = 0;       // Oración actual dentro de la sección
  int currentAveMaria = 0;     // Ave María actual (0-9)
  
  // Información del día
  String todayMystery = '';    // Tipo de misterio del día
  String todayDay = '';        // Día de la semana

  @override
  void initState() {
    super.initState();
    _setTodayMystery();
  }

  /// Determina el tipo de misterio según el día de la semana
  /// Sigue la tradición católica de asignación de misterios por día
  void _setTodayMystery() {
    const List<String> days = [
      'Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'
    ];
    
    // DateTime.weekday va de 1 (Lunes) a 7 (Domingo)
    // Necesitamos ajustar para que 0 sea Domingo
    final int today = DateTime.now().weekday % 7;
    final String currentDay = days[today];
    
    setState(() {
      todayDay = currentDay;
      todayMystery = PrayerData.mysteries[currentDay] ?? 'Gozosos';
    });
  }

  /// Reinicia la aplicación al estado inicial
  void resetApp() {
    setState(() {
      currentStep = 'inicio';
      currentMystery = 0;
      currentPrayer = 0;
      currentAveMaria = 0;
    });
  }

  /// Avanza al siguiente paso en el flujo del rosario
  /// 
  /// La lógica de navegación sigue este flujo:
  /// 1. Inicio -> Oraciones Iniciales
  /// 2. Oraciones Iniciales -> Misterios
  /// 3. Misterios (5 veces con sus oraciones) -> Oraciones Finales
  /// 4. Oraciones Finales -> Inicio
  void nextStep() {
    setState(() {
      switch (currentStep) {
        case 'inicio':
          // Pasar a las oraciones iniciales
          currentStep = 'oraciones-iniciales';
          currentPrayer = 0;
          break;
          
        case 'oraciones-iniciales':
          // Avanzar por las oraciones iniciales o pasar a misterios
          if (currentPrayer < PrayerData.initialPrayers.length - 1) {
            currentPrayer++;
          } else {
            currentStep = 'misterios';
            currentMystery = 0;
            currentPrayer = 0;
            currentAveMaria = 0;
          }
          break;
          
        case 'misterios':
          // Lógica para navegar por los misterios
          final currentOration = PrayerData.mysteryPrayers[currentPrayer];
          
          // Si estamos en las Ave Marías
          if (currentPrayer == 2 && currentOration.type == 'avemaria') {
            if (currentAveMaria < 9) {
              // Avanzar a la siguiente Ave María
              currentAveMaria++;
            } else {
              // Completadas las 10 Ave Marías, pasar a la siguiente oración
              currentAveMaria = 0;
              currentPrayer++;
            }
          } else if (currentPrayer < PrayerData.mysteryPrayers.length - 1) {
            // Avanzar a la siguiente oración del misterio
            currentPrayer++;
          } else if (currentMystery < 4) {
            // Pasar al siguiente misterio
            currentMystery++;
            currentPrayer = 0;
            currentAveMaria = 0;
          } else {
            // Completados los 5 misterios, pasar a oraciones finales
            currentStep = 'oraciones-finales';
            currentPrayer = 0;
          }
          break;
          
        case 'oraciones-finales':
          // Avanzar por las oraciones finales o terminar
          if (currentPrayer < PrayerData.finalPrayers.length - 1) {
            currentPrayer++;
          } else {
            // Rosario completado, volver al inicio
            resetApp();
          }
          break;
      }
    });
  }

  /// Retrocede al paso anterior en el flujo del rosario
  void previousStep() {
    setState(() {
      switch (currentStep) {
        case 'oraciones-iniciales':
          if (currentPrayer > 0) {
            currentPrayer--;
          } else {
            currentStep = 'inicio';
          }
          break;
          
        case 'misterios':
          // Si estamos en las Ave Marías y no es la primera
          if (currentPrayer == 2 && currentAveMaria > 0) {
            currentAveMaria--;
          } else if (currentPrayer > 0) {
            // Retroceder a la oración anterior
            currentPrayer--;
            // Si la oración anterior era Ave María, ir a la última
            if (currentPrayer == 2) {
              currentAveMaria = 9;
            }
          } else if (currentMystery > 0) {
            // Retroceder al misterio anterior, a la última oración
            currentMystery--;
            currentPrayer = PrayerData.mysteryPrayers.length - 1;
            currentAveMaria = 0;
          } else {
            // Desde el primer misterio, volver a la última oración inicial
            currentStep = 'oraciones-iniciales';
            currentPrayer = PrayerData.initialPrayers.length - 1;
          }
          break;
          
        case 'oraciones-finales':
          if (currentPrayer > 0) {
            currentPrayer--;
          } else {
            // Desde la primera oración final, volver al último misterio
            currentStep = 'misterios';
            currentMystery = 4;
            currentPrayer = PrayerData.mysteryPrayers.length - 1;
            currentAveMaria = 0;
          }
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Construir la pantalla correspondiente según el paso actual
    switch (currentStep) {
      case 'inicio':
        return InicioScreen(
          todayMystery: todayMystery,
          todayDay: todayDay,
          onNext: nextStep,
          preferences: widget.preferences,
        );
        
      case 'oraciones-iniciales':
        return OracionesInicialesScreen(
          currentPrayer: currentPrayer,
          onNext: nextStep,
          onPrevious: previousStep,
          onHome: resetApp,
          preferences: widget.preferences,
        );
        
      case 'misterios':
        return MisteriosScreen(
          todayMystery: todayMystery,
          currentMystery: currentMystery,
          currentPrayer: currentPrayer,
          currentAveMaria: currentAveMaria,
          onNext: nextStep,
          onPrevious: previousStep,
          onHome: resetApp,
          preferences: widget.preferences,
        );
        
      case 'oraciones-finales':
        return OracionesFinalesScreen(
          currentPrayer: currentPrayer,
          onNext: nextStep,
          onPrevious: previousStep,
          onHome: resetApp,
          preferences: widget.preferences,
        );
        
      default:
        // Fallback al inicio si hay un estado desconocido
        return InicioScreen(
          todayMystery: todayMystery,
          todayDay: todayDay,
          onNext: nextStep,
          preferences: widget.preferences,
        );
    }
  }
}