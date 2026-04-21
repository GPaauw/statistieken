// lib/main.dart
import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'services/theme_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await ThemeService.instance.init();

  // Forceer: altijd light bij opstarten (negeert systeem-stand)
  ThemeService.instance.modeNotifier.value = ThemeMode.light;

  runApp(const ScoreApp());
}

class ScoreApp extends StatelessWidget {
  const ScoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(seedColor: Colors.indigo);
    final darkColorScheme = ColorScheme.fromSeed(
      seedColor: Colors.indigo,
      brightness: Brightness.dark,
    );

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.instance.modeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'Statistieken',
          theme: ThemeData(
            colorScheme: colorScheme,
            useMaterial3: true,
            fontFamily: 'Roboto',
          ),
          darkTheme: ThemeData(
            colorScheme: darkColorScheme,
            useMaterial3: true,
            fontFamily: 'Roboto',
          ),
          themeMode: themeMode, // nu altijd light bij start
          debugShowCheckedModeBanner: false,
          home: const HomePage(),
        );
      },
    );
  }
}
