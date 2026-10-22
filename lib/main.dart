import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const MedEaseApp());
}

class MedEaseApp extends StatelessWidget {
  const MedEaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'MedEase',
        debugShowCheckedModeBanner: false,
        theme: MedEaseTheme.light(),
        home: const SplashScreen(),
      ),
    );
  }
}
