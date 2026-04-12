import 'package:flutter/material.dart';

/// Centralized color constants for the Siddhivinayak Garments app.
///
/// Uses a professional indigo + amber palette with gradient definitions
/// for cards and backgrounds.
class AppColors {
  AppColors._(); // Prevent instantiation

  // ─── Primary Palette ──────────────────────────────────────
  static const Color primary = Color(0xFF3949AB); // Indigo 600
  static const Color primaryDark = Color(0xFF283593); // Indigo 800
  static const Color primaryLight = Color(0xFF5C6BC0); // Indigo 400
  static const Color accent = Color(0xFFFFB300); // Amber 600

  // ─── Surface & Background ────────────────────────────────
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E2C);
  static const Color backgroundDark = Color(0xFF121212);

  // ─── Text Colors ──────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textLight = Color(0xFFFFFFFF);

  // ─── Status Colors ────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // ─── Role Badge Colors ────────────────────────────────────
  static const Color workerBadge = Color(0xFF3B82F6);
  static const Color helperBadge = Color(0xFFF97316);

  // ─── Card Gradients ───────────────────────────────────────
  static const LinearGradient cardGradient1 = LinearGradient(
    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient2 = LinearGradient(
    colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient3 = LinearGradient(
    colors: [Color(0xFFF093FB), Color(0xFFF5576C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient4 = LinearGradient(
    colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient loginGradient = LinearGradient(
    colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
