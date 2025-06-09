import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/rosary_state.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final rosaryState = Provider.of<RosaryState>(context);
    final todayMystery = rosaryState.todayMystery;
    final todayDay = rosaryState.todayDay;

    return Scaffold(
      backgroundColor: Colors.blue.shade900,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.brightness_5, size: 100, color: Colors.white),
              const SizedBox(height: 20),
              Text("Santo Rosario",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
              Text("Misterios $todayMystery • $todayDay", style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                icon: Icon(Icons.play_arrow),
                label: Text("Comenzar Rosario"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () {
                  rosaryState.nextStep();
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
