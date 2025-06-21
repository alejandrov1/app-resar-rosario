import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../services/preferences_service.dart';

/// Widget especializado para mostrar las Letanías de la Santísima Virgen
/// 
/// Características:
/// - Formato estructurado para mejor legibilidad
/// - Resalta las respuestas en cursiva
/// - Agrupa las invocaciones por secciones
/// - Scroll suave para textos largos
class LetaniasWidget extends StatelessWidget {
  final String text;
  final PreferencesService preferences;
  
  const LetaniasWidget({
    super.key,
    required this.text,
    required this.preferences,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(AppConstants.radiusS),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _buildLetaniasContent(context),
        ),
      ),
    );
  }

  List<Widget> _buildLetaniasContent(BuildContext context) {
    final lines = text.split('\n');
    final widgets = <Widget>[];
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) {
        widgets.add(const SizedBox(height: AppConstants.spacingS));
        continue;
      }
      
      // Detectar diferentes tipos de líneas
      if (_isResponse(line)) {
        // Respuestas en cursiva y color diferente
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _getInvocation(line),
                    style: TextStyle(
                      fontSize: AppConstants.fontSizeS * preferences.textScaleFactor,
                      height: 1.6,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: AppConstants.spacingS),
                Text(
                  _getResponse(line),
                  style: TextStyle(
                    fontSize: AppConstants.fontSizeS * preferences.textScaleFactor,
                    height: 1.6,
                    color: AppConstants.primaryGreen,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (_isSectionHeader(line)) {
        // Encabezados de sección
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(
              top: AppConstants.spacingS,
              bottom: AppConstants.spacingXS,
            ),
            child: Text(
              line,
              style: TextStyle(
                fontSize: (AppConstants.fontSizeS + 2) * preferences.textScaleFactor,
                fontWeight: FontWeight.bold,
                color: AppConstants.primaryGreen,
              ),
            ),
          ),
        );
      } else {
        // Líneas normales
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              line,
              style: TextStyle(
                fontSize: AppConstants.fontSizeS * preferences.textScaleFactor,
                height: 1.6,
                color: AppConstants.textPrimary,
                fontWeight: _isKyrie(line) ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }
    }
    
    return widgets;
  }
  
  bool _isResponse(String line) {
    return line.contains('Ten misericordia de nosotros') ||
           line.contains('Ruega por nosotros');
  }
  
  bool _isSectionHeader(String line) {
    return line.startsWith('Santa María,') ||
           line.startsWith('Madre de Cristo,') ||
           line.startsWith('Virgen prudentísima,') ||
           line.startsWith('Espejo de justicia,') ||
           line.startsWith('Salud de los enfermos,') ||
           line.startsWith('Reina de los Ángeles,');
  }
  
  bool _isKyrie(String line) {
    return line.contains('Señor, ten piedad') ||
           line.contains('Cristo, ten piedad') ||
           line.contains('Cristo, óyenos') ||
           line.contains('Cristo, escúchanos');
  }
  
  String _getInvocation(String line) {
    if (line.contains('Ten misericordia de nosotros')) {
      return line.replaceAll('Ten misericordia de nosotros', '').trim();
    } else if (line.contains('Ruega por nosotros')) {
      return line.replaceAll('Ruega por nosotros', '').trim();
    }
    return line;
  }
  
  String _getResponse(String line) {
    if (line.contains('Ten misericordia de nosotros')) {
      return 'Ten misericordia de nosotros.';
    } else if (line.contains('Ruega por nosotros')) {
      return 'Ruega por nosotros';
    }
    return '';
  }
}

/// Widget alternativo con diseño de lista para las letanías
class LetaniasListWidget extends StatelessWidget {
  final String text;
  final PreferencesService preferences;
  
  const LetaniasListWidget({
    super.key,
    required this.text,
    required this.preferences,
  });

  @override
  Widget build(BuildContext context) {
    final sections = _parseLetanias();
    
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(AppConstants.radiusS),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: sections.length,
        itemBuilder: (context, index) {
          final section = sections[index];
          return _buildSection(context, section);
        },
      ),
    );
  }
  
  List<LetaniaSection> _parseLetanias() {
    final sections = <LetaniaSection>[];
    
    // Sección inicial (Kyrie)
    sections.add(LetaniaSection(
      title: 'Invocación inicial',
      items: [
        LetaniaItem('Señor, ten piedad', '', false),
        LetaniaItem('Cristo, ten piedad', '', false),
        LetaniaItem('Señor, ten piedad', '', false),
        LetaniaItem('Cristo, óyenos', '', false),
        LetaniaItem('Cristo, escúchanos', '', false),
      ],
    ));
    
    // Trinidad
    sections.add(LetaniaSection(
      title: 'Invocaciones a la Trinidad',
      items: [
        LetaniaItem('Dios Padre celestial,', 'Ten misericordia de nosotros.', true),
        LetaniaItem('Dios Hijo, Redentor del mundo,', 'Ten misericordia de nosotros.', true),
        LetaniaItem('Dios Espíritu Santo,', 'Ten misericordia de nosotros.', true),
        LetaniaItem('Trinidad Santa, un solo Dios,', 'Ten misericordia de nosotros.', true),
      ],
    ));
    
    // Invocaciones a María - Títulos fundamentales
    sections.add(LetaniaSection(
      title: 'Títulos fundamentales de María',
      items: [
        LetaniaItem('Santa María,', 'Ruega por nosotros', true),
        LetaniaItem('Santa Madre de Dios,', 'Ruega por nosotros', true),
        LetaniaItem('Santa Virgen de las Vírgenes,', 'Ruega por nosotros', true),
      ],
    ));
    
    // Madre
    sections.add(LetaniaSection(
      title: 'María como Madre',
      items: [
        LetaniaItem('Madre de Cristo,', 'Ruega por nosotros', true),
        LetaniaItem('Madre de la Iglesia,', 'Ruega por nosotros', true),
        LetaniaItem('Madre de la Misericordia,', 'Ruega por nosotros', true),
        LetaniaItem('Madre de la divina gracia,', 'Ruega por nosotros', true),
        LetaniaItem('Madre de la Esperanza,', 'Ruega por nosotros', true),
        LetaniaItem('Madre purísima,', 'Ruega por nosotros', true),
        LetaniaItem('Madre castísima,', 'Ruega por nosotros', true),
        LetaniaItem('Madre siempre virgen,', 'Ruega por nosotros', true),
        LetaniaItem('Madre inmaculada,', 'Ruega por nosotros', true),
        LetaniaItem('Madre amable,', 'Ruega por nosotros', true),
        LetaniaItem('Madre admirable,', 'Ruega por nosotros', true),
        LetaniaItem('Madre del buen consejo,', 'Ruega por nosotros', true),
        LetaniaItem('Madre del Creador,', 'Ruega por nosotros', true),
        LetaniaItem('Madre del Salvador,', 'Ruega por nosotros', true),
      ],
    ));
    
    // Virgen
    sections.add(LetaniaSection(
      title: 'María como Virgen',
      items: [
        LetaniaItem('Virgen prudentísima,', 'Ruega por nosotros', true),
        LetaniaItem('Virgen digna de veneración,', 'Ruega por nosotros', true),
        LetaniaItem('Virgen digna de alabanza,', 'Ruega por nosotros', true),
        LetaniaItem('Virgen poderosa,', 'Ruega por nosotros', true),
        LetaniaItem('Virgen clemente,', 'Ruega por nosotros', true),
        LetaniaItem('Virgen fiel,', 'Ruega por nosotros', true),
      ],
    ));
    
    // Símbolos
    sections.add(LetaniaSection(
      title: 'Símbolos marianos',
      items: [
        LetaniaItem('Espejo de justicia,', 'Ruega por nosotros', true),
        LetaniaItem('Trono de la sabiduría,', 'Ruega por nosotros', true),
        LetaniaItem('Causa de nuestra alegría,', 'Ruega por nosotros', true),
        LetaniaItem('Vaso espiritual,', 'Ruega por nosotros', true),
        LetaniaItem('Vaso digno de honor,', 'Ruega por nosotros', true),
        LetaniaItem('Vaso insigne de devoción,', 'Ruega por nosotros', true),
        LetaniaItem('Rosa mística,', 'Ruega por nosotros', true),
        LetaniaItem('Torre de David,', 'Ruega por nosotros', true),
        LetaniaItem('Torre de marfil,', 'Ruega por nosotros', true),
        LetaniaItem('Casa de oro,', 'Ruega por nosotros', true),
        LetaniaItem('Arca de la Alianza,', 'Ruega por nosotros', true),
        LetaniaItem('Puerta del cielo,', 'Ruega por nosotros', true),
        LetaniaItem('Estrella de la mañana,', 'Ruega por nosotros', true),
      ],
    ));
    
    // Auxilio
    sections.add(LetaniaSection(
      title: 'María como auxilio',
      items: [
        LetaniaItem('Salud de los enfermos,', 'Ruega por nosotros', true),
        LetaniaItem('Refugio de los pecadores,', 'Ruega por nosotros', true),
        LetaniaItem('Consuelo de los migrantes,', 'Ruega por nosotros', true),
        LetaniaItem('Consoladora de los afligidos,', 'Ruega por nosotros', true),
        LetaniaItem('Auxilio de los cristianos,', 'Ruega por nosotros', true),
      ],
    ));
    
    // Reina
    sections.add(LetaniaSection(
      title: 'María como Reina',
      items: [
        LetaniaItem('Reina de los Ángeles,', 'Ruega por nosotros', true),
        LetaniaItem('Reina de los Patriarcas,', 'Ruega por nosotros', true),
        LetaniaItem('Reina de los Profetas,', 'Ruega por nosotros', true),
        LetaniaItem('Reina de los Apóstoles,', 'Ruega por nosotros', true),
        LetaniaItem('Reina de los Mártires,', 'Ruega por nosotros', true),
        LetaniaItem('Reina de los Confesores,', 'Ruega por nosotros', true),
        LetaniaItem('Reina de las Vírgenes,', 'Ruega por nosotros', true),
        LetaniaItem('Reina de todos los Santos,', 'Ruega por nosotros', true),
        LetaniaItem('Reina concebida sin pecado original,', 'Ruega por nosotros', true),
        LetaniaItem('Reina asunta a los Cielos,', 'Ruega por nosotros', true),
        LetaniaItem('Reina del Santo Rosario,', 'Ruega por nosotros', true),
        LetaniaItem('Reina de la familia,', 'Ruega por nosotros', true),
        LetaniaItem('Reina de la paz,', 'Ruega por nosotros', true),
      ],
    ));
    
    return sections;
  }
  
  Widget _buildSection(BuildContext context, LetaniaSection section) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingS),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (section.title.isNotEmpty) ...[
            Text(
              section.title,
              style: TextStyle(
                fontSize: (AppConstants.fontSizeS + 2) * preferences.textScaleFactor,
                fontWeight: FontWeight.bold,
                color: AppConstants.primaryGreen,
              ),
            ),
            const SizedBox(height: AppConstants.spacingXS),
          ],
          ...section.items.map((item) => _buildItem(context, item)),
        ],
      ),
    );
  }
  
  Widget _buildItem(BuildContext context, LetaniaItem item) {
    if (!item.hasResponse) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(
          item.invocation,
          style: TextStyle(
            fontSize: AppConstants.fontSizeS * preferences.textScaleFactor,
            height: 1.6,
            color: AppConstants.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item.invocation,
              style: TextStyle(
                fontSize: AppConstants.fontSizeS * preferences.textScaleFactor,
                height: 1.6,
                color: AppConstants.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: AppConstants.spacingS),
          Text(
            item.response,
            style: TextStyle(
              fontSize: AppConstants.fontSizeS * preferences.textScaleFactor,
              height: 1.6,
              color: AppConstants.primaryGreen,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class LetaniaSection {
  final String title;
  final List<LetaniaItem> items;
  
  LetaniaSection({
    required this.title,
    required this.items,
  });
}

class LetaniaItem {
  final String invocation;
  final String response;
  final bool hasResponse;
  
  LetaniaItem(this.invocation, this.response, this.hasResponse);
}