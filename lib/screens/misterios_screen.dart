import 'package:app_resar_rosario/services/preferences_service.dart';
import 'package:flutter/material.dart';
import '../models/prayer_models.dart';
import '../widgets/rosary_beads_widget.dart';

class MisteriosScreen extends StatelessWidget {
  final String todayMystery;
  final int currentMystery;
  final int currentPrayer;
  final int currentAveMaria;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onHome;

  const MisteriosScreen({
    super.key,
    required this.todayMystery,
    required this.currentMystery,
    required this.currentPrayer,
    required this.currentAveMaria,
    required this.onNext,
    required this.onPrevious,
    required this.onHome,
    required PreferencesService preferences,
  });

  @override
  Widget build(BuildContext context) {
    final currentMysteryData = PrayerData.mysteryData[todayMystery]!;
    final currentMysteryTitle = currentMysteryData[currentMystery];
    final currentOracion = PrayerData.mysteryPrayers[currentPrayer];
    final showTopBar = currentOracion.type != 'misterio';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF6B21A8), // purple-800
              Color(0xFF9333EA), // purple-600
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
                            if (showTopBar)
                              Text(
                                '$todayMystery • ${currentMystery + 1}/5',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F2937),
                                ),
                              )
                            else
                              const SizedBox.shrink(), // Ocupa espacio sin mostrar nada
                            IconButton(
                              onPressed: onHome,
                              icon: const Icon(
                                Icons.home,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${currentMystery + 1}° Misterio ${todayMystery.substring(0, todayMystery.length - 1)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF6B21A8),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                currentMysteryTitle,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF7C2D92),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: currentOracion.type == 'misterio'
                              ? Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.shade100,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Text(
                                          'Medita en este Misterio',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF6B21A8),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          currentMysteryTitle,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Color(0xFF7C2D92),
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.keyboard_arrow_down,
                                              color: Color(0xFF9333EA),
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                currentOracion.type == 'avemaria' 
                                                    ? '${currentOracion.title} (${currentAveMaria + 1}°)'
                                                    : currentOracion.title,
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF1F2937),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (currentOracion.type == 'avemaria') ...[
                                          const SizedBox(height: 16),
                                          RosaryBeadsWidget(
                                            current: currentAveMaria,
                                            total: 10,
                                          ),
                                          const SizedBox(height: 8),
                                          Center(
                                            child: Text(
                                              'Ave María ${currentAveMaria + 1} de 10',
                                              style: const TextStyle(
                                                color: Color(0xFF9333EA),
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                        ] else ...[
                                          const SizedBox(height: 16),
                                        ],
                                        Text(
                                          currentOracion.text,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            height: 1.6,
                                            color: Color(0xFF1F2937),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
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
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2, // Botón Continuar: 2 partes del espacio
                              child: ElevatedButton(
                                onPressed: onNext,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF9333EA),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      currentPrayer == PrayerData.mysteryPrayers.length - 1 && currentMystery == 4 
                                          ? 'Finalizar Misterios' 
                                          : 'Continuar',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Icon(Icons.chevron_right, size: 20),
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