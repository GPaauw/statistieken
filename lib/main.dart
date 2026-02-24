// lib/main.dart
import 'package:flutter/material.dart';
import 'pages/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ScoreApp());
}

class ScoreApp extends StatelessWidget {
  const ScoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(seedColor: Colors.indigo);

    return MaterialApp(
      title: 'Statistieken',
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}
