import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SentinelWatchApp());
}

class SentinelWatchApp extends StatelessWidget {
  const SentinelWatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SentinelWatch SOC Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF090D16),
        primaryColor: const Color(0xFF38BDF8),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF38BDF8),
          secondary: Color(0xFF0284C7),
          surface: Color(0xFF0F172A),
          background: Color(0xFF090D16),
          error: Color(0xFFEF4444),
        ),
        fontFamily: 'Roboto',
      ),
      home: const LoginScreen(),
    );
  }
}
