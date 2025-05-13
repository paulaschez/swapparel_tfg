// lib/core/utils/responsive_utils.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

class ResponsiveUtils {
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 700.0;
  static const double desktopBreakpoint = 1024.0;

  static double fontSize(
    BuildContext context, {
    required double baseSize,
    double? tabletMultiplier,
    double? desktopMultiplier,
    double? minSize,
    double? maxSize,
  }) {
    final double screenWidth = MediaQuery.of(context).size.width;
    double calculatedSize = baseSize;

    if (screenWidth >= tabletBreakpoint &&
        screenWidth < desktopBreakpoint &&
        tabletMultiplier != null) {
      calculatedSize = baseSize * tabletMultiplier;
    } else if (screenWidth >= desktopBreakpoint && desktopMultiplier != null) {
      calculatedSize = baseSize * desktopMultiplier;
    }

    if (minSize != null) {
      calculatedSize = math.max(minSize, calculatedSize);
    }
    if (maxSize != null) {
      calculatedSize = math.min(maxSize, calculatedSize);
    }
    return calculatedSize;
  }


  static double horizontalPadding(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    return screenWidth * (screenWidth < tabletBreakpoint ? 0.05 : 0.1);
  }

  static double avatarRadius(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    return math.min(screenWidth * 0.12, 70.0);
  }

  static double verticalSpacing(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    // Considera si este espaciado debería depender también del ancho o solo del alto
    return screenHeight * 0.015;
  }

  static double largeVerticalSpacing(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    return screenHeight * 0.025;
  }

  static double gridPadding(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    // Si el breakpoint es el mismo que usas para horizontalPadding general,
    // podrías incluso combinar lógicas o crear un helper más genérico.
    return screenWidth * (screenWidth < mobileBreakpoint ? 0.035 : 0.02);
  }

  static double gridSpacing(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    return screenWidth * (screenWidth < mobileBreakpoint ? 0.025 : 0.015);
  }

  /* // --- AYUDANTE PARA NÚMERO DE COLUMNAS DEL GRID ---
  static int getCrossAxisCount(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth >= 1200) return 4;
    if (screenWidth >= tabletBreakpoint) return 3; // Usando el breakpoint definido arriba
    return 2;
  }

  // --- AYUDANTE PARA ASPECT RATIO DEL GRID (SI ES GENERALIZABLE) ---
  // Este es más complicado de generalizar si cada grid tiene un look muy distinto.
  // Podrías tener variantes o dejarlo específico en cada pantalla.
  // Por ahora, un ejemplo:
  static double getGridChildAspectRatio(BuildContext context, int crossAxisCount) {
    if (crossAxisCount == 4) return 0.85;
    if (crossAxisCount == 3) return 0.8;
    return 0.75; // Para 2 columnas (móvil) */
}
