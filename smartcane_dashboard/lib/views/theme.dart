import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';

class AppTheme {
  // Color System
  static const Color primary = Color(0xFF1A237E);
  static const Color primaryLight = Color(0xFF303F9F);
  static const Color sosRed = Color(0xFFD32F2F);
  static const Color helpOrange = Color(0xFFFF9800);
  static const Color normalGreen = Color(0xFF4CAF50);
  static const Color background = Color(0xFFF5F5F5);
  static const Color sidebarBg = Color(0xFF0D1B2A);
  static const Color sidebarActive = Color(0xFF1B3A5C);
  static const Color cardBg = Colors.white;

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: helpOrange,
        error: sosRed,
        surface: background,
      ),
      scaffoldBackgroundColor: background,
      textTheme: GoogleFonts.outfitTextTheme(),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: cardBg,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
      ),
    );
  }

  static String formatHealthInfo(String? raw) {
    if (raw == null || raw.isEmpty) return "N/A";
    if (!raw.trim().startsWith('{')) return raw;

    try {
      final data = jsonDecode(raw);
      final List<String> parts = [];

      if (data["groupe_sanguin"] != null && data["groupe_sanguin"] != "Inconnu") {
        parts.add("Groupe: ${data["groupe_sanguin"]}");
      }

      final List pathologies = data["pathologies"] ?? [];
      if (pathologies.isNotEmpty) {
        if (pathologies.contains("Aucune pathologie connue")) {
          parts.add("Aucune pathologie");
        } else {
          String pathStr = pathologies.join(", ");
          if (data["allergie_detail"]?.toString().isNotEmpty ?? false) {
            pathStr = pathStr.replaceAll("Allergies médicamenteuses", "Allergies (${data["allergie_detail"]})");
          }
          if (data["autre_detail"]?.toString().isNotEmpty ?? false) {
            pathStr = pathStr.replaceAll("Autre", "Autre (${data["autre_detail"]})");
          }
          parts.add("Pathologies: $pathStr");
        }
      }

      if (data["observations"]?.toString().isNotEmpty ?? false) {
        parts.add("Obs: ${data["observations"]}");
      }

      return parts.isEmpty ? "Stable" : parts.join(" | ");
    } catch (e) {
      return raw;
    }
  }
}
