import 'package:flutter/material.dart';

class ColorConstants {
  // Ana Renk: Enerjik bir Mor veya Mavi (Spotify yeşili veya Instagram gradienti gibi düşün)
  static const Color primaryColor = Color.fromARGB(255, 16, 225, 225);

  // İkincil Renk: Detaylar için (Turuncu gibi)
  static const Color secondaryColor = Color(0xFFFF6584);

  // Arka Planlar: Modern tasarımlarda bembeyaz (FFFFFF) yerine kırık beyaz kullanılır.
  static const Color backgroundColor = Color(0xFFF9F9F9);
  static const Color surfaceColor = Colors.white; // Kartların rengi

  // Yazı Renkleri: Simsiyah (000000) göz yorar. Koyu gri kullan.
  static const Color textPrimary = Color(0xFF2D3142);
  static const Color textSecondary = Color(0xFF9C9DB9);

  // Input Alanları
  static const Color inputFill = Color(0xFFF0F0F5);
}
