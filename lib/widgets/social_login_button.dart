/// lib/widgets/social_login_button.dart
///
/// A white pill-shaped button used for OAuth provider sign-in flows.
/// Currently used for Google sign-in on [LoginScreen] and [UserRegisterScreen].
library;
// lib/widgets/social_login_button.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'scale_button.dart'; // Animasyonlu tıklama için

/// A button styled for social / OAuth provider authentication.
///
/// Wraps a [ScaleButton] to provide a subtle press animation.
class SocialLoginButton extends StatelessWidget {
  /// The label displayed next to the provider icon (e.g. "Sign in with Google").
  final String text;

  /// Asset path to the provider's logo image (e.g. `'assets/icons/google.png'`).
  final String iconPath;

  /// Callback invoked when the button is tapped.
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
            Flexible(
              child: Text(
                text,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
