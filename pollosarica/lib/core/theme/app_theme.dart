
import 'package:flutter/material.dart';

class AppTheme {
  // ==========================================
  // COLORES OFICIALES DE POLLOS ARICA
  // ==========================================

  static const Color naranja = Color(0xFFE87522);
  static const Color naranjaClaro = Color(0xFFF6A94A);
  static const Color crema = Color(0xFFFFF5E9);
  static const Color marron = Color(0xFF432B20);
  static const Color textoSecundario = Color(0xFF765D4B);

  // ==========================================
  // TEMA GENERAL DE LA APLICACIÓN
  // ==========================================

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Roboto',
      scaffoldBackgroundColor: crema,

      colorScheme: ColorScheme.fromSeed(
        seedColor: naranja,
        primary: naranja,
        secondary: naranjaClaro,
        surface: crema,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: naranja,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
