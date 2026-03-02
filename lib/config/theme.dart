import 'package:flutter/material.dart';

class AppColors {
  static const Color teal = Color(0xFF00BCD4);
  static const Color tealDark = Color(0xFF00838F);
  static const Color tealLight = Color(0xFFB2EBF2);
  static const Color blue = Color(0xFF1565C0);
  static const Color blueDark = Color(0xFF0D47A1);
  static const Color blueLight = Color(0xFFBBDEFB);
  static const Color orange = Color(0xFFF57C00);
  static const Color orangeLight = Color(0xFFFFE0B2);
  static const Color green = Color(0xFF43A047);
  static const Color greenLight = Color(0xFFC8E6C9);
  static const Color red = Color(0xFFE53935);
  static const Color redLight = Color(0xFFFFCDD2);
  static const Color gold = Color(0xFFFFB300);
  static const Color goldLight = Color(0xFFFFF8E1);
  static const Color bg = Color(0xFFF5F7FA);
  static const Color card = Colors.white;
  static const Color text = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);

  static const LinearGradient tealGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0097A7), Color(0xFF00BCD4), Color(0xFF00ACC1)],
  );

  static const LinearGradient tealBlueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [teal, blue],
  );
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.teal,
        primary: AppColors.teal,
        secondary: AppColors.blue,
        tertiary: AppColors.orange,
        surface: Colors.white,
        background: AppColors.bg,
      ),
      scaffoldBackgroundColor: AppColors.bg,
      fontFamily: 'Outfit',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.text,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: AppColors.text,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.teal,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.teal,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(fontFamily: 'Outfit', fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontFamily: 'Outfit', fontSize: 11, fontWeight: FontWeight.w500),
      ),
    );
  }
}
