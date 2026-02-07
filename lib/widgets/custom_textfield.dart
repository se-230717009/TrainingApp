// lib/widgets/custom_textfield.dart GÜNCEL HALİ

import 'package:flutter/material.dart';
import '../core/constants/color_constants.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isPassword;
  final TextEditingController? controller;
  final int? maxLength;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator; // YENİ: Validator eklendi

  const CustomTextField({
    super.key,
    required this.label,
    required this.icon,
    this.isPassword = false,
    this.controller,
    this.maxLength,
    this.keyboardType,
    this.validator, // YENİ
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Container yüksekliği hataya göre değişsin diye sabit height vermiyoruz
      decoration: BoxDecoration(
        color: ColorConstants.inputFill,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextFormField(
        // TextField yerine TextFormField
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        maxLength: maxLength,
        validator: validator, // YENİ: Validasyonu buraya bağlıyoruz
        style: GoogleFonts.poppins(color: ColorConstants.textPrimary),
        buildCounter:
            (
              context, {
              required currentLength,
              required isFocused,
              maxLength,
            }) => null,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: ColorConstants.textSecondary),
          border: InputBorder.none,
          // Hata mesajı stili
          errorStyle: GoogleFonts.poppins(
            color: Colors.redAccent,
            fontSize: 12,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          hintText: label,
          hintStyle: GoogleFonts.poppins(color: ColorConstants.textSecondary),
          counterText: "",
        ),
      ),
    );
  }
}
