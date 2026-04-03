import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'services/securite_service.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Charger la session précédente si disponible
  await ApiService.loadToken();
  
  // Appliquer la sécurité selon le rôle de l'utilisateur
  // Admin : captures d'écran autorisées
  // Utilisateur : captures d'écran bloquées sur Android
  await SecuriteService.appliquerSecurite();
  
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
