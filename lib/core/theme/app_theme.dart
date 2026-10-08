import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Identidade visual Marcelo Bonifácio: azul-marinho profundo + dourado.
class AppColors {
  static const navyDark = Color(0xFF020B22);
  static const navy = Color(0xFF061A48);
  static const blue = Color(0xFF0D3A8C);
  static const blueGlow = Color(0xFF2F7DE8);
  static const gold = Color(0xFFF5C432);
  static const goldLight = Color(0xFFEECD59);
  static const goldDark = Color(0xFFC8921A);
}

ThemeData buildAppTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.gold,
        brightness: Brightness.dark,
      ).copyWith(
        primary: AppColors.gold,
        onPrimary: AppColors.navyDark,
        surface: AppColors.navy,
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.navyDark,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.06),
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIconColor: AppColors.gold,
      suffixIconColor: Colors.white60,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.gold.withValues(alpha: 0.35)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.gold.withValues(alpha: 0.35)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.gold, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.6),
      ),
    ),
  );
}

/// Fonte serifada dos títulos de módulo (identidade elegante da marca).
TextStyle estiloTitulo({double tamanho = 30, Color cor = Colors.white}) =>
    GoogleFonts.playfairDisplay(
      fontSize: tamanho,
      fontWeight: FontWeight.w700,
      color: cor,
      letterSpacing: 0.2,
    );

/// Fonte manuscrita para frases de destaque.
TextStyle estiloManuscrito({double tamanho = 24, Color cor = AppColors.gold}) =>
    GoogleFonts.dancingScript(
      fontSize: tamanho,
      fontWeight: FontWeight.w700,
      color: cor,
      height: 1.1,
    );
