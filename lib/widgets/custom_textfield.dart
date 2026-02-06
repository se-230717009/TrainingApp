import 'package:flutter/material.dart';
import '../core/constants/color_constants.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isPassword;
  final TextEditingController? controller;

  const CustomTextField({
    super.key,
    required this.label,
    required this.icon,
    this.isPassword = false,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ColorConstants.inputFill,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: GoogleFonts.poppins(color: ColorConstants.textPrimary),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: ColorConstants.textSecondary),
          border: InputBorder.none, // Çizgileri kaldırdık, modern kutu görünümü
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          hintText: label,
          hintStyle: GoogleFonts.poppins(color: ColorConstants.textSecondary),
        ),
      ),
    );
  }
}
