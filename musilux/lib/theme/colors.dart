import 'package:flutter/material.dart';

class AppColors {
  // Marca principal
  static const Color primaryPurple    = Color(0xFF6366F1); // Indigo 500
  static const Color primaryDark      = Color(0xFF4F46E5); // Indigo 600 (hover/pressed)
  static const Color primaryLight     = Color(0xFFE0E7FF); // Indigo 100 (fondos sutiles)

  // Superficies
  static const Color headerBg         = Color(0xFF1E1B2E); // Más profundo, premium
  static const Color background       = Color(0xFFF3F4F6); // Gris neutro suave
  static const Color surface          = Color(0xFFFFFFFF);
  static const Color surfaceVariant   = Color(0xFFF9FAFB); // Cards alternadas

  // Texto
  static const Color textPrimary      = Color(0xFF111827);
  static const Color textSecondary    = Color(0xFF6B7280);
  static const Color textDisabled     = Color(0xFF9CA3AF);

  // Estados
  static const Color success          = Color(0xFF10B981);
  static const Color warning          = Color(0xFFF59E0B);
  static const Color error            = Color(0xFFEF4444);
  static const Color priceSale        = Color(0xFFF59E0B);

  // Tags / Chips
  static const Color tagBg            = Color(0xFFEDE9FE); // Violeta muy suave
  static const Color tagText          = Color(0xFF6366F1);

  // Compatibilidad con código anterior
  static const Color primaryPurpleHover = primaryDark;
  static const Color priceText          = primaryPurple;

  // Gradiente de marca (banner hero)
  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
