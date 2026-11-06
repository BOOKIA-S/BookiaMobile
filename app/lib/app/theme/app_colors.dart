import 'package:flutter/material.dart';

/// BOOKIA color tokens, sampled from the approved mockups (propuesta_movil).
abstract final class AppColors {
  // Brand
  static const primary = Color(0xFF8F4F22);
  static const primaryDark = Color(0xFF6F3C1C);
  static const brown = Color(0xFF4F2B16);
  static const espresso = Color(0xFF331C0F);
  static const gold = Color(0xFFD9A066);

  // Surfaces
  static const background = Color(0xFFFBF7F0);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceTint = Color(0xFFFBF3EA);
  static const sand = Color(0xFFF7E8D7);
  static const border = Color(0xFFF4E2CC);

  // Text
  static const textPrimary = Color(0xFF2B2118);
  static const textSecondary = Color(0xFF78716C);
  static const textMuted = Color(0xFFA8A29E);

  // Availability badges: available, low stock, sold out
  static const success = Color(0xFF3D6139);
  static const successContainer = Color(0xFFE3ECE1);
  static const warning = Color(0xFFB45309);
  static const warningContainer = Color(0xFFFEF3C7);
  static const error = Color(0xFFB91C1C);
  static const errorContainer = Color(0xFFFEF2F2);
}
