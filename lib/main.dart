import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'state/rosary_state.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => RosaryState(),
      child: RosaryApp(),
    ),
  );
}

class RosaryApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Santo Rosario',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomeScreen(),
    );
  }
}
