import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/rosary_state.dart';
import '../data/mysteries.dart';

final mysteryPrayers = [
  {'type': 'misterio', 'title': 'Misterio'},
  {'type': 'padrenuestro', 'title': 'Padre Nuestro', 'text': 'Padre nuestro...'},
  {'type': 'avemaria', 'title': 'Ave María', 'text': 'Dios te salve María...', 'count': 10},
  {'type': 'gloria', 'title': 'Gloria', 'text': 'Gloria al Padre...'},
  {'type': 'maria_madre', 'title': 'María Madre de Gracia', 'text': 'María, Madre de gracia...'},
  {'type': 'oh_jesus', 'title': 'Oh Jesús Mío', 'text': 'Oh Jesús mío...'}
];

class MysteriesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final rosaryState = Provider.of<RosaryState>(context);
    final currentPrayer = rosaryState.currentPrayer;
    final currentAveMaria = rosaryState.currentAveMaria;
    final currentMystery = rosaryState.currentMystery;
    final title = rosaryState.todayMystery;
    final text = mysteryData[title]?[currentMystery] ?? '';

    final prayer = mysteryPrayers[currentPrayer];

    return Scaffold(
      appBar: AppBar(title: Text('Misterios $title')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('${currentMystery + 1}° Misterio: $text', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Text(prayer['title'] ?? '', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            if (prayer['type'] == 'avemaria')
              Text('Ave María ${currentAveMaria + 1} de 10'),
            const SizedBox(height: 10),
            Expanded(child: SingleChildScrollView(child: Text(prayer['text'] ?? ''))),
            ElevatedButton(
              onPressed: () => rosaryState.nextStep(),
              child: Text("Continuar"),
            )
          ],
        ),
      ),
    );
  }
}
