/// lib/widgets/custom_textfield.dart
///
/// A styled input field used consistently across all form screens.
/// Wraps [TextFormField] so it participates in [Form] validation.
library;
// lib/widgets/custom_textfield.dart GÜNCEL HALİ

import 'package:flutter/material.dart';
import '../core/constants/color_constants.dart';
import 'package:google_fonts/google_fonts.dart';

/// A styled text input field backed by [TextFormField].
///
/// Uses [ColorConstants.inputFill] as the background and [GoogleFonts.poppins]
/// for consistent typography. Supports optional password masking, keyboard
/// type hints, character limits, and [Form] validation.
class CustomTextField extends StatelessWidget {
  /// Hint text shown inside the empty field.
  final String label;

  /// Leading icon rendered as a prefix inside the field.
  final IconData icon;

  /// When `true`, input is obscured (password mode). Defaults to `false`.
  final bool isPassword;

  /// Optional controller for reading or pre-filling the field value.
  final TextEditingController? controller;

  /// Optional character limit; hides the default Flutter counter text.
  final int? maxLength;

  /// Keyboard type hint (e.g. [TextInputType.emailAddress]).
  final TextInputType? keyboardType;

  /// Optional [Form] validator function that returns an error string or `null`.
  final String? Function(String?)? validator;

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
