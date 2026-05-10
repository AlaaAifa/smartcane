import 'package:flutter/material.dart';
import '../theme.dart';
import '../layout/sirius_logo.dart';
import 'dart:async';

class SiriusTransitionScreen extends StatefulWidget {
  final VoidCallback onFinished;
  const SiriusTransitionScreen({super.key, required this.onFinished});

  @override
  State<SiriusTransitionScreen> createState() => _SiriusTransitionScreenState();
}

class _SiriusTransitionScreenState extends State<SiriusTransitionScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _fadeAnim = CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeIn));
    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.8, curve: Curves.elasticOut)));

    _controller.forward();

    Timer(const Duration(milliseconds: 2800), () {
      widget.onFinished();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070c18),
      body: Stack(
        children: [
          // Background Glow
          Center(
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF5A623).withOpacity(0.05),
                    blurRadius: 100,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _scaleAnim,
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: const SiriusLogo(size: 140),
                  ),
                ),
                const SizedBox(height: 48),
                FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(
                    children: [
                      const Text(
                        "SIRIUS",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "INITIALISATION DU SYSTÈME",
                        style: TextStyle(
                          color: const Color(0xFFF5A623).withOpacity(0.8),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 80),
                FadeTransition(
                  opacity: _fadeAnim,
                  child: Container(
                    width: 240,
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                      child: LinearProgressIndicator(
                        backgroundColor: Colors.transparent,
                        color: Color(0xFFF5A623),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
