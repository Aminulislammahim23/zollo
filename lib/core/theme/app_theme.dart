import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5B4BDB)),
      scaffoldBackgroundColor: const Color(0xFFF8F8FC),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: Color(0xFFF8F8FC),
        elevation: 0,
      ),
      cardTheme: const CardThemeData(elevation: 0, color: Colors.white),
    );
  }
}
