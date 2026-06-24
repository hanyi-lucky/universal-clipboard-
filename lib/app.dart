import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/unlock_screen.dart';

class UniversalClipboardApp extends StatelessWidget {
  const UniversalClipboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '通用剪切板',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      initialRoute: '/unlock',
      routes: {
        '/unlock': (context) => const UnlockScreen(),
        '/home': (context) => const HomeScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}
