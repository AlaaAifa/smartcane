import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const CanneApp());
}

class CanneApp extends StatelessWidget {
  const CanneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Be My Eyes',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // follow system settings
      home: const LoginScreen(),
    );
  }
}
