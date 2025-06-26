import 'package:app_resar_rosario/services/preferences_service.dart';
import 'package:flutter/material.dart';
import '../models/prayer_models.dart';
import '../widgets/rosary_beads_widget.dart';
import '../constants/app_constants.dart';

class MisteriosScreen extends StatelessWidget {
  final String todayMystery;
  final int currentMystery;
  final int currentPrayer;
  final int currentAveMaria;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onHome;
  final PreferencesService preferences;

  const MisteriosScreen({
    super.key,
    required this.todayMystery,
    required this.currentMystery,
    required this.currentPrayer,
    required this.currentAveMaria,
    required this.onNext,
    required this.onPrevious,
    required this.onHome,
    required this.preferences,
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
              AppConstants.primaryPurple,
              AppConstants.secondaryPurple,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.spacingS),
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white, // CAMBIADO A BLANCO EXPLÍCITAMENTE
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(AppConstants.spacingM),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (showTopBar)
                              Text(
                                '$todayMystery • ${currentMystery + 1}/5',
                                style: TextStyle(
                                  fontSize: AppConstants.fontSizeL * preferences.textScaleFactor,
                                  fontWeight: FontWeight.bold,
                                  color: AppConstants.textPrimary,
                                ),
                              )
                            else
                              const SizedBox.shrink(),
                            IconButton(
                              onPressed: onHome,
                              icon: Icon(
                                Icons.home,
                                color: AppConstants.textSecondary,
                                size: preferences.useLargeButtons ? 32 : 24,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppConstants.spacingS),
                        Container(
                          padding: const EdgeInsets.all(AppConstants.spacingS),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(AppConstants.radiusS),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${currentMystery + 1}° Misterio ${todayMystery.substring(0, todayMystery.length - 1)}',
                                style: TextStyle(
                                  fontSize: AppConstants.fontSizeM * preferences.textScaleFactor,
                                  fontWeight: FontWeight.w600,
                                  color: AppConstants.primaryPurple,
                                ),
                              ),
                              const SizedBox(height: AppConstants.spacingXS),
                              Text(
                                currentMysteryTitle,
                                style: TextStyle(
                                  fontSize: AppConstants.fontSizeS * preferences.textScaleFactor,
                                  fontWeight: FontWeight.w500,
                                  color: AppConstants.primaryPurple.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppConstants.spacingS),
                        Expanded(
                          child: currentOracion.type == 'misterio'
                              ? Container(
                                  padding: const EdgeInsets.all(AppConstants.spacingM),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.shade100,
                                    borderRadius: BorderRadius.circular(AppConstants.radiusS),
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Medita en este Misterio',
                                          style: TextStyle(
                                            fontSize: AppConstants.fontSizeM * preferences.textScaleFactor,
                                            fontWeight: FontWeight.w600,
                                            color: AppConstants.primaryPurple,
                                          ),
                                        ),
                                        const SizedBox(height: AppConstants.spacingXS),
                                        Text(
                                          currentMysteryTitle,
                                          style: TextStyle(
                                            fontSize: AppConstants.fontSizeS * preferences.textScaleFactor,
                                            color: AppConstants.primaryPurple.withOpacity(0.8),
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : Container(
                                  padding: const EdgeInsets.all(AppConstants.spacingM),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(AppConstants.radiusS),
                                  ),
                                  child: SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.keyboard_arrow_down,
                                              color: AppConstants.secondaryPurple,
                                              size: 20,
                                            ),
                                            const SizedBox(width: AppConstants.spacingXS),
                                            Expanded(
                                              child: Text(
                                                currentOracion.type == 'avemaria' 
                                                    ? '${currentOracion.title} (${currentAveMaria + 1}°)'
                                                    : currentOracion.title,
                                                style: TextStyle(
                                                  fontSize: AppConstants.fontSizeM * preferences.textScaleFactor,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppConstants.textPrimary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (currentOracion.type == 'avemaria') ...[
                                          const SizedBox(height: AppConstants.spacingS),
                                          RosaryBeadsWidget(
                                            current: currentAveMaria,
                                            total: 10,
                                          ),
                                          const SizedBox(height: AppConstants.spacingXS),
                                          Center(
                                            child: Text(
                                              'Ave María ${currentAveMaria + 1} de 10',
                                              style: TextStyle(
                                                color: AppConstants.secondaryPurple,
                                                fontSize: AppConstants.fontSizeXS * preferences.textScaleFactor,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: AppConstants.spacingS),
                                        ] else ...[
                                          const SizedBox(height: AppConstants.spacingS),
                                        ],
                                        Text(
                                          currentOracion.text,
                                          style: TextStyle(
                                            fontSize: AppConstants.fontSizeS * preferences.textScaleFactor,
                                            height: 1.6,
                                            color: preferences.useHighContrast 
                                                ? Colors.black 
                                                : AppConstants.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                        ),
                        const SizedBox(height: AppConstants.spacingM),
                        Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: OutlinedButton(
                                onPressed: onPrevious,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppConstants.textSecondary,
                                  padding: EdgeInsets.symmetric(
                                    vertical: preferences.useLargeButtons 
                                        ? AppConstants.spacingL 
                                        : AppConstants.spacingS,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppConstants.radiusS),
                                  ),
                                  side: const BorderSide(color: Color(0xFFD1D5DB)),
                                ),
                                child: Text(
                                  'Atrás', 
                                  style: TextStyle(
                                    fontSize: AppConstants.fontSizeM * preferences.textScaleFactor, 
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppConstants.spacingS),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: onNext,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppConstants.secondaryPurple,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    vertical: preferences.useLargeButtons 
                                        ? AppConstants.spacingL 
                                        : AppConstants.spacingS,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppConstants.radiusS),
                                  ),
                                  elevation: 0,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text( 'Continuar',
                                      style: TextStyle(
                                        fontSize: AppConstants.fontSizeM * preferences.textScaleFactor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: AppConstants.spacingS),
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