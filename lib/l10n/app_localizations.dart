import 'package:flutter/material.dart';

/// Clase base para las traducciones de la aplicación
/// 
/// Actualmente solo soporta español, pero está preparada
/// para agregar más idiomas en el futuro
class AppLocalizations {
  final Locale locale;
  
  AppLocalizations(this.locale);
  
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }
  
  // Singleton para español (idioma por defecto)
  static final Map<String, AppLocalizations> _localizations = {
    'es': AppLocalizations(const Locale('es', 'ES')),
  };
  
  // Títulos y etiquetas generales
  String get appTitle => 'Santo Rosario';
  String get settings => 'Configuración';
  String get about => 'Acerca de';
  String get cancel => 'Cancelar';
  String get accept => 'Aceptar';
  String get reset => 'Restablecer';
  String get continue_ => 'Continuar';
  String get start => 'Comenzar';
  String get finish => 'Terminar';
  
  // Días de la semana
  String get monday => 'Lunes';
  String get tuesday => 'Martes';
  String get wednesday => 'Miércoles';
  String get thursday => 'Jueves';
  String get friday => 'Viernes';
  String get saturday => 'Sábado';
  String get sunday => 'Domingo';
  
  // Tipos de misterios
  String get joyfulMysteries => 'Misterios Gozosos';
  String get sorrowfulMysteries => 'Misterios Dolorosos';
  String get gloriousMysteries => 'Misterios Gloriosos';
  String get luminousMysteries => 'Misterios Luminosos';
  
  // Pantalla de inicio
  String get startRosary => 'Comenzar Rosario';
  String todaysMysteries(String mystery, String day) => 
      'Misterios $mystery • $day';
  
  // Oraciones
  String get initialPrayers => 'Oraciones Iniciales';
  String get mysteries => 'Misterios';
  String get finalPrayers => 'Oraciones Finales';
  String get signOfCross => 'Señal de la Cruz';
  String get actOfContrition => 'Acto de contrición';
  String get invocations => 'Invocaciones';
  String get ourFather => 'Padre Nuestro';
  String get hailMary => 'Ave María';
  String get glory => 'Gloria';
  
  // Navegación
  String get openSettings => 'Abrir menú de configuración';
  String get backToHome => 'Volver al inicio';
  String get rosaryIcon => 'Icono del Santo Rosario';
  
  // Progreso
  String mysteryNumber(int current, int total) => 
      '$current° Misterio';
  String stepProgress(int current, int total) => 
      'Paso $current de $total';
  String hailMaryProgress(int current, int total) => 
      'Ave María $current de $total';
  
  // Configuración
  String get accessibility => 'Accesibilidad';
  String get textSize => 'Tamaño del texto';
  String get highContrast => 'Alto contraste';
  String get highContrastDescription => 'Mejora la visibilidad del texto';
  String get largeButtons => 'Botones grandes';
  String get largeButtonsDescription => 'Facilita la interacción táctil';
  String get appearance => 'Apariencia';
  String get theme => 'Tema';
  String get system => 'Sistema';
  String get light => 'Claro';
  String get dark => 'Oscuro';
  String get resetSettings => 'Restablecer configuración';
  String get resetSettingsConfirmation => 
      'Esto restablecerá todas las configuraciones a sus valores predeterminados.';
  String get settingsReset => 'Configuración restablecida';
  
  // Información de la app
  String get aboutDescription => 
      'Una aplicación para rezar el Santo Rosario de manera guiada.';
  String get developedWith => 'Desarrollada con amor y devoción.';
  String get version => 'Versión';
  
  // Accesibilidad
  String get meditateOnMystery => 'Medita en este Misterio';
  String get todayIs => 'Hoy es';
  String get todaysMysteriesAre => 'Los misterios de hoy son';
  String get customizeExperience => 'Personaliza tu experiencia';
  
  // Método helper para obtener el día actual traducido
  String getDayName(int weekday) {
    switch (weekday % 7) {
      case 0: return sunday;
      case 1: return monday;
      case 2: return tuesday;
      case 3: return wednesday;
      case 4: return thursday;
      case 5: return friday;
      case 6: return saturday;
      default: return '';
    }
  }
  
  // Método helper para obtener el nombre del misterio traducido
  String getMysteryTypeName(String mysteryType) {
    switch (mysteryType) {
      case 'Gozosos': return joyfulMysteries;
      case 'Dolorosos': return sorrowfulMysteries;
      case 'Gloriosos': return gloriousMysteries;
      case 'Luminosos': return luminousMysteries;
      default: return mysteryType;
    }
  }
}

/// Delegate para cargar las localizaciones
class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();
  
  @override
  bool isSupported(Locale locale) {
    return ['es', 'en'].contains(locale.languageCode);
  }
  
  @override
  Future<AppLocalizations> load(Locale locale) async {
    // Por ahora solo retornamos español
    // En el futuro, aquí se cargarían diferentes archivos según el idioma
    return AppLocalizations._localizations['es']!;
  }
  
  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}