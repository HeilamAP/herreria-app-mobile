import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'paleta.dart';

class AppTheme {
  static const Color primaryCyan = Color(0xFF06B6D4);
  static const Color primaryBlue = Color(0xFF0284C7);
  static const Color accentTeal = Color(0xFF2DD4BF);
  static const Color successGreen = Color(0xFF10B981);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color infoPurple = Color(0xFF8B5CF6);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: GoogleFonts.inter().fontFamily,
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      colorScheme: const ColorScheme.dark(
        primary: primaryCyan,
        secondary: accentTeal,
        surface: Color(0xFF1E293B),
        error: dangerRed,
        onPrimary: Colors.white,
        onSurface: Color(0xFFF8FAFC),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E293B),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF334155), width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF334155), width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0F172A),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryCyan, width: 2),
        ),
        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
        hintStyle: const TextStyle(color: Color(0xFF64748B)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryCyan,
          foregroundColor: const Color(0xFF0F172A),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// Tema de toda la app: alto contraste y letra grande, en claro u oscuro según la
  /// paleta activa (ver [EC]). Lo usan los encargados y el administrador.
  static ThemeData get encargadoTheme {
    final oscuro = EC.oscuro;
    final base = oscuro ? darkTheme : lightTheme;
    OutlineInputBorder linea(Color color, [double ancho = 1]) =>
        OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: color, width: ancho));
    return base.copyWith(
      scaffoldBackgroundColor: EC.fondo,
      canvasColor: EC.fondo,
      cardColor: EC.superficie,
      colorScheme: base.colorScheme.copyWith(
        primary: EC.acento,
        onPrimary: Colors.white,
        surface: EC.fondo,
        onSurface: EC.texto,
        error: EC.peligro,
      ),
      // englishLike2021 trae los tamaños definidos, que es lo que necesita fontSizeFactor.
      textTheme: Typography.englishLike2021.merge(base.textTheme).apply(
        fontSizeFactor: 1.15,
        bodyColor: EC.texto,
        displayColor: EC.texto,
      ),
      iconTheme: IconThemeData(color: EC.texto),
      appBarTheme: AppBarTheme(backgroundColor: EC.fondo, foregroundColor: EC.texto, surfaceTintColor: EC.fondo),
      cardTheme: CardThemeData(
        color: EC.superficie,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: EC.borde)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: EC.fondo,
        surfaceTintColor: EC.fondo,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: EC.borde)),
      ),
      bottomSheetTheme: BottomSheetThemeData(backgroundColor: EC.fondo, surfaceTintColor: EC.fondo),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: oscuro ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
        contentTextStyle: TextStyle(color: oscuro ? const Color(0xFF0F172A) : Colors.white, fontSize: 17),
      ),
      textSelectionTheme: TextSelectionThemeData(cursorColor: EC.acento, selectionHandleColor: EC.acento),
      dividerColor: EC.borde,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: EC.superficie,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: linea(EC.borde),
        enabledBorder: linea(EC.borde),
        focusedBorder: linea(EC.acento, 2),
        labelStyle: TextStyle(color: EC.textoSuave),
        hintStyle: TextStyle(fontSize: 20, color: EC.textoTenue),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: GoogleFonts.inter().fontFamily,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      colorScheme: const ColorScheme.light(
        primary: primaryBlue,
        secondary: primaryCyan,
        surface: Colors.white,
        error: dangerRed,
        onPrimary: Colors.white,
        onSurface: Color(0xFF0F172A),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
