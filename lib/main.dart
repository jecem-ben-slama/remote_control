import 'package:flutter/material.dart';
import 'screens/main_navigation_shell.dart';

void main() => runApp(const SlartTVApp());

/// Root application widget
/// Configures Material 3 theme and app navigation
class SlartTVApp extends StatelessWidget {
  const SlartTVApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Slart SMASNUG Hub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00C853),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        useMaterial3: true,
      ),
      home: const MainNavigationShell(),
    );
  }
}
