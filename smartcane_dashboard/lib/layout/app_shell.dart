import 'package:flutter/material.dart';
import 'sidebar.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  final String currentRoute;
  final Function(String) onNavigate;

  const AppShell({
    super.key,
    required this.child,
    required this.currentRoute,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Sidebar(currentRoute: currentRoute, onNavigate: onNavigate),
          Expanded(
            child: Container(
              color: const Color(0xFFF5F5F5),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
