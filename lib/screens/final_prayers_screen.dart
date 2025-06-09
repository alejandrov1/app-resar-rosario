import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/rosary_state.dart';

final finalPrayers = [
  {'title': 'Letanías', 'text': 'Señor, ten piedad...'},
  {'title': 'Cordero de Dios', 'text': 'Cordero de Dios...'},
  {'title': 'Oración Final', 'text': 'Te pedimos, Señor...'},
  {'title': 'Por las intenciones del Papa', 'text': 'Padre Nuestro...'},
  {'title': 'Ave María', 'text': 'Dios te salve, María...'},
  {'title': 'Gloria', 'text': 'Gloria al Padre...'},
  {'title': 'Una Salve', 'text': 'Dios te salve, Reina y Madre...'},
  {'title': 'Jaculatoria', 'text': 'Ave María Purísima...'}
];

class FinalPrayersScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final rosaryState = Provider.of<RosaryState>(context);
    final index = rosaryState.currentPrayer;
    final prayer = finalPrayers[index];

    return Scaffold(
      appBar: AppBar(title: Text('Oraciones Finales')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(prayer['title'] ?? '', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Expanded(child: SingleChildScrollView(child: Text(prayer['text'] ?? ''))),
            ElevatedButton(
              onPressed: () => rosaryState.nextStep(),
              child: Text(index == finalPrayers.length - 1 ? "Terminar Rosario" : "Siguiente"),
            )
          ],
        ),
      ),
    );
  }
}
