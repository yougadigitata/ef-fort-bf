import 'package:flutter/material.dart';

/// Palette de couleurs EF-FORT.BF — Style e-learning moderne (inspiré Coursera)
class AppColors {
  // ── Couleur principale : Bleu Coursera ─────────────────────────────
  static const primary = Color(0xFF0056D2);        // Bleu Coursera
  static const primaryDark = Color(0xFF003FA3);    // Bleu foncé
  static const primaryLight = Color(0xFF4A90E2);   // Bleu clair
  static const primarySurface = Color(0xFFEEF4FF); // Surface bleue légère

  // ── Couleur secondaire : Vert Burkina ───────────────────────────────
  static const secondary = Color(0xFF009E49);      // Vert drapeau BF
  static const secondaryDark = Color(0xFF007A38);
  static const secondaryLight = Color(0xFF00C85A);
  static const secondarySurface = Color(0xFFE6F9EF);

  // ── Accent : Or Burkina ─────────────────────────────────────────────
  static const accent = Color(0xFFFCD116);         // Jaune drapeau BF
  static const accentDark = Color(0xFFE6B800);
  static const accentSurface = Color(0xFFFFFBE6);

  // ── Fond et surfaces ────────────────────────────────────────────────
  static const background = Color(0xFFF8FAFF);     // Blanc bleuté léger
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFF0F4F8);
  static const cardBackground = Color(0xFFFFFFFF);

  // ── Textes ──────────────────────────────────────────────────────────
  static const textDark = Color(0xFF1A1D23);       // Noir très foncé
  static const textMedium = Color(0xFF404553);     // Gris moyen
  static const textLight = Color(0xFF6B7280);      // Gris clair
  static const textSubtle = Color(0xFF9CA3AF);     // Gris subtil

  // ── États ───────────────────────────────────────────────────────────
  static const success = Color(0xFF059669);
  static const successSurface = Color(0xFFECFDF5);
  static const error = Color(0xFFDC2626);
  static const errorSurface = Color(0xFFFEF2F2);
  static const warning = Color(0xFFD97706);
  static const warningSurface = Color(0xFFFFFBEB);
  static const info = Color(0xFF0284C7);
  static const infoSurface = Color(0xFFF0F9FF);

  // ── Utilitaires ─────────────────────────────────────────────────────
  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF000000);
  static const divider = Color(0xFFE5E7EB);
  static const shadow = Color(0x1A000000);

  // ── Couleurs drapeau BF ─────────────────────────────────────────────
  static const bfRed = Color(0xFFEF2B2D);
  static const bfGreen = Color(0xFF009E49);
  static const bfYellow = Color(0xFFFCD116);

  // ── Couleurs domaines (palette Coursera) ────────────────────────────
  static const domaineColors = [
    Color(0xFF0056D2), // Bleu
    Color(0xFF009E49), // Vert
    Color(0xFF8B1A1A), // Rouge foncé
    Color(0xFF7C3AED), // Violet
    Color(0xFF0891B2), // Cyan
    Color(0xFFD97706), // Orange
    Color(0xFF059669), // Vert émeraude
    Color(0xFFDB2777), // Rose
    Color(0xFF2563EB), // Bleu électrique
    Color(0xFF16A34A), // Vert forêt
    Color(0xFF9333EA), // Violet vif
    Color(0xFF0D9488), // Teal
  ];
}
