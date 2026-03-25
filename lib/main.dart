import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EfFortApp());
}

class EfFortApp extends StatelessWidget {
  const EfFortApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EF-FORT.BF',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
