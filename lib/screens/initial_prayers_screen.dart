import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/rosary_state.dart';

final initialPrayers = [
  {
    'title': 'Señal de la Cruz',
    'text': 'Por la señal de la Santa Cruz...'
  },
  {
    'title': 'Acto de contrición',
    'text': 'Señor mío Jesucristo, Dios y hombre verdadero...'
  },
  {
    'title': 'Invocaciones',
    'text': 'Señor, ábreme los labios...'
  },
];

class InitialPrayersScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final rosaryState = Provider.of<RosaryState>(context);
    final index = rosaryState.currentPrayer;
    final prayer = initialPrayers[index];

    return Scaffold(
      appBar: AppBar(title: Text('Oraciones Iniciales')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('${index + 1}. ${prayer['title']}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Expanded(child: SingleChildScrollView(child: Text(prayer['text'] ?? ''))),
            ElevatedButton(
              onPressed: () => rosaryState.nextStep(),
              child: Text(index == initialPrayers.length - 1 ? "Comenzar Misterios" : "Siguiente"),
            )
          ],
        ),
      ),
    );
  }
}
