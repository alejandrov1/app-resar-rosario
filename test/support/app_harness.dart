import 'package:app_resar_rosario/services/preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferencias de prueba, vacías o con [valores] ya guardados.
Future<PreferencesService> preferenciasDePrueba([Map<String, Object> valores = const {}]) async {
  SharedPreferences.setMockInitialValues(valores);
  return PreferencesService(await SharedPreferences.getInstance());
}
