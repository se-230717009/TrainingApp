// lib/widgets/social_login_button.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'scale_button.dart'; // Animasyonlu tıklama için

class SocialLoginButton extends StatelessWidget {
  final String text;
  final String iconPath; // Google logosunun yolu (Asset)
  final VoidCallback onPressed;

  const SocialLoginButton({
    super.key,
    required this.text,
    required this.iconPath,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleButton(
      onPressed: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white, // Google butonu genelde beyaz olur
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo (Asset olarak eklemen gerekecek)
            Image.asset(iconPath, height: 24, width: 24),
            const SizedBox(width: 12),
            Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
