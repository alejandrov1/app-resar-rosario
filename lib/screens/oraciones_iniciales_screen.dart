import 'package:app_resar_rosario/services/preferences_service.dart';
import 'package:flutter/material.dart';
import '../models/prayer_models.dart';

class OracionesInicialesScreen extends StatelessWidget {
  final int currentPrayer;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onHome;

  const OracionesInicialesScreen({
    super.key,
    required this.currentPrayer,
    required this.onNext,
    required this.onPrevious,
    required this.onHome,
    required PreferencesService preferences,
  });

  @override
  Widget build(BuildContext context) {
    final prayer = PrayerData.initialPrayers[currentPrayer];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1E40AF), // blue-800
              Color(0xFF2563EB), // blue-600
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              onPressed: onHome,
                              icon: const Icon(
                                Icons.home,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            const Text(
                              'Oraciones Iniciales',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(width: 48) // Espacio para alinear el título
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF2563EB),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${currentPrayer + 1}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      prayer.title,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1E40AF),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Paso ${currentPrayer + 1} de ${PrayerData.initialPrayers.length}',
                                style: const TextStyle(
                                  color: Color(0xFF2563EB),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: SingleChildScrollView(
                              child: Text(
                                prayer.text,
                                style: const TextStyle(
                                  fontSize: 16,
                                  height: 1.6,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            if (currentPrayer > 0)
                              Expanded(
                                flex: 1, // Botón Atrás: 1 parte del espacio
                                child: OutlinedButton(
                                  onPressed: onPrevious,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF6B7280),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                                  ),
                                  child: const Text('Atrás', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            if (currentPrayer > 0)
                              const SizedBox(width: 16),
                            Expanded(
                              flex: 2, // Botón Continuar: 2 partes del espacio
                              child: ElevatedButton(
                                onPressed: onNext,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Continuar',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Icon(Icons.chevron_right, size: 20),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}