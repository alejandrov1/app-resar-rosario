import 'package:app_resar_rosario/services/preferences_service.dart';
import 'package:flutter/material.dart';

class InicioScreen extends StatelessWidget {
  final String todayMystery;
  final String todayDay;
  final VoidCallback onNext;

  const InicioScreen({
    super.key,
    required this.todayMystery,
    required this.todayDay,
    required this.onNext,
    required PreferencesService preferences,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE0F2FE), // light-blue-100
              Color(0xFFBAE6FD), // light-blue-200
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Rezar el Santo Rosario',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0C4A6E), // cyan-900
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // --- Widget para mostrar la imagen ---
                    // Usamos ClipRRect para aplicar las esquinas redondeadas a la imagen.
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16.0),
                      child: Image.asset(
                        'assets/images/imagen-rosario.png',
                        height: 200,

                        // Esta es la propiedad MÁS IMPORTANTE para el ajuste.
                        // BoxFit.cover asegura que la imagen llene todo el contenedor,
                        // manteniendo su proporción y recortando lo que sobre.
                        // ¡Justo como el fondo de color original!
                        fit: BoxFit.cover,
                        
                        // Este es un widget de respaldo que se mostrará si por alguna
                        // razón la imagen no se encuentra o no se puede cargar.
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200,
                            decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(16.0),
                            ),
                            child: const Center(
                              child: Text(
                                'Imagen no encontrada',
                                style: TextStyle(color: Colors.black54),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // --- Fin del widget de la imagen ---

                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Misterios para hoy',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF0E7490), // cyan-700
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$todayDay: $todayMystery',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF155E75), // cyan-800
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: onNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0369A1), // light-blue-700
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 48, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 5,
                      ),
                      child: const Text(
                        'Comenzar a Rezar',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}