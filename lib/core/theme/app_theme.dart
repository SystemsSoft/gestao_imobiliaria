import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta do app: a padrão do sistema (azul-marinho + dourado) até a
/// imobiliária ser identificada; depois, a dela (cadastrada no painel da
/// plataforma), aplicada com [aplicarPaleta] antes de desenhar as telas.
class AppColors {
  static const _navyDark = Color.fromARGB(255, 38, 49, 79);
  static const _navy = Color.fromARGB(152, 48, 54, 75);
  static const _blue = Color(0xFF244888);
  static const _blueGlow = Color(0xFF2661AB);
  static const _gold = Color(0xFFDCBC5C);
  static const _goldLight = Color(0xFFD0B864);
  static const _goldDark = Color(0xFFB29043);
  static const _fundoMenu = Color(0xFF071430);

  static Color navyDark = _navyDark;
  static Color navy = _navy;
  static Color blue = _blue;
  static Color blueGlow = _blueGlow;
  static Color gold = _gold;
  static Color goldLight = _goldLight;
  static Color goldDark = _goldDark;

  /// Fundo mais escuro (topo do menu lateral).
  static Color fundoMenu = _fundoMenu;

  /// Paleta da imobiliária a partir das duas cores do cadastro; sem uma
  /// delas, aquela parte segue a padrão.
  static void aplicarPaleta({Color? primaria, Color? destaque}) {
    restaurarPaleta();
    if (primaria != null) {
      navyDark = Color.lerp(primaria, Colors.black, 0.35)!;
      navy = Color.lerp(primaria, Colors.black, 0.2)!.withValues(alpha: 0.6);
      blue = Color.lerp(primaria, Colors.white, 0.12)!;
      blueGlow = Color.lerp(primaria, Colors.white, 0.3)!;
      fundoMenu = Color.lerp(primaria, Colors.black, 0.6)!;
    }
    if (destaque != null) {
      gold = destaque;
      goldLight = Color.lerp(destaque, Colors.white, 0.2)!;
      goldDark = Color.lerp(destaque, Colors.black, 0.2)!;
    }
  }

  static void restaurarPaleta() {
    navyDark = _navyDark;
    navy = _navy;
    blue = _blue;
    blueGlow = _blueGlow;
    gold = _gold;
    goldLight = _goldLight;
    goldDark = _goldDark;
    fundoMenu = _fundoMenu;
  }
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
    // Diálogos aproveitam a largura do celular (no computador cada um já
    // limita a própria largura).
    dialogTheme: const DialogThemeData(
      insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.navy,
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.gold.withValues(alpha: 0.4)),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
    ),
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
        borderSide: BorderSide(color: AppColors.gold, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color.fromARGB(255, 250, 98, 98)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color.fromARGB(255, 241, 105, 105),
          width: 1.6,
        ),
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
TextStyle estiloManuscrito({double tamanho = 24, Color? cor}) =>
    GoogleFonts.dancingScript(
      fontSize: tamanho,
      fontWeight: FontWeight.w700,
      color: cor ?? AppColors.gold,
      height: 1.1,
    );
