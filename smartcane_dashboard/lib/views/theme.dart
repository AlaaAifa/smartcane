import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';

class AppTheme {
  // ── Corporate Premium Color System ──────────────────────────────────
  static const Color bgDeep     = Color(0xFFF3F4F6); // Light gray background
  static const Color bgCard     = Color(0xFFFFFFFF); // White cards
  static const Color sidebarBg  = Color(0xFF0F172A); // Deep Navy sidebar

  static const Color primary    = Color(0xFF1E293B); // Navy Blue
  static const Color accent     = Color(0xFFF59E0B); // Amber / Golden Orange
  static const Color sosRed     = Color(0xFFEF4444); // Modern Red
  static const Color neonGreen  = Color(0xFF10B981); // Emerald Green
  static const Color purple     = Color(0xFF6366F1); // Indigo
  static const Color cyan       = Color(0xFF0EA5E9); // Sky Blue

  // Legacy aliases for compatibility
  static const Color helpYellow = accent;
  static const Color helpOrange = accent;
  static const Color normalGreen = neonGreen;
  static const Color background = bgDeep;
  static const Color cardBg     = bgCard;

  // ── Premium Card Decoration (Shadow-based) ─────────────────────────
  static BoxDecoration glassCard({Color? borderColor, Color? shadowColor}) => BoxDecoration(
    color: bgCard,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: borderColor ?? Colors.grey.withOpacity(0.1), width: 1),
    boxShadow: [
      BoxShadow(
        color: (shadowColor ?? Colors.black).withOpacity(0.05),
        blurRadius: 15,
        offset: const Offset(0, 4),
        spreadRadius: 1,
      ),
    ],
  );

  static BoxDecoration gradientBtn({bool red = false, bool green = false}) => BoxDecoration(
    gradient: LinearGradient(
      colors: red
          ? [const Color(0xFFEF4444), const Color(0xFFB91C1C)]
          : green
              ? [const Color(0xFF10B981), const Color(0xFF047857)]
              : [const Color(0xFF1E293B), const Color(0xFF0F172A)],
    ),
    borderRadius: BorderRadius.circular(10),
    boxShadow: [
      BoxShadow(
        color: (red ? sosRed : green ? neonGreen : primary).withOpacity(0.2),
        blurRadius: 10,
        offset: const Offset(0, 3),
      )
    ],
  );

  static InputDecoration inputDecoration(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, size: 20, color: primary.withOpacity(0.4)),
    filled: true,
    fillColor: Color(0xFFF9FAFB),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    labelStyle: TextStyle(color: Colors.black.withOpacity(0.5), fontSize: 13, fontWeight: FontWeight.w500),
    hintStyle: TextStyle(color: Colors.black.withOpacity(0.3)),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: primary, width: 1.5),
    ),
  );

  // ── ThemeData (Premium Corporate) ──────────────────────────────────
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: bgDeep,
      primaryColor: primary,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: accent,
        error: sosRed,
        surface: bgCard,
        onSurface: Color(0xFF1E293B),
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: primary),
        headlineMedium: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: primary),
        titleLarge: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: primary),
      ).apply(
        bodyColor: const Color(0xFF334155),
        displayColor: primary,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.withOpacity(0.1))),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: 0.5),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: TextStyle(color: Colors.black.withOpacity(0.5)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: bgCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      dividerColor: Colors.grey.withOpacity(0.1),
      iconTheme: const IconThemeData(color: Color(0xFF64748B)),
    );
  }

  // ── Health info formatter (unchanged) ─────────────────────────────
  static String formatHealthInfo(String? raw) {
    if (raw == null || raw.isEmpty) return "Non renseign";
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

// ── Shared Reusable Gradient Button ──────────────────────────────────────────
class AppGradientButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool outlined;

  const AppGradientButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    this.onTap,
    this.outlined = false,
  });

  @override
  State<AppGradientButton> createState() => _AppGradientButtonState();
}

class _AppGradientButtonState extends State<AppGradientButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            gradient: widget.outlined ? null : LinearGradient(
              colors: [widget.color, widget.color.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            color: widget.outlined ? (_isHovered ? widget.color.withOpacity(0.1) : Colors.transparent) : null,
            borderRadius: BorderRadius.circular(12),
            border: widget.outlined ? Border.all(color: widget.color.withOpacity(0.5)) : null,
            boxShadow: [
              if (!widget.outlined && _isHovered)
                BoxShadow(color: widget.color.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 5)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: widget.outlined ? widget.color : Colors.white, size: 18),
              const SizedBox(width: 10),
              Text(
                widget.label.toUpperCase(),
                style: TextStyle(
                  color: widget.outlined ? widget.color : Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
