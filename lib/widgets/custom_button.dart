/// lib/widgets/custom_button.dart
///
/// Application-wide primary action button.
/// Supports two visual modes: filled (primary) and outlined (secondary).
library;
import 'package:flutter/material.dart';
import '../core/constants/color_constants.dart';
import 'package:google_fonts/google_fonts.dart';
import 'scale_button.dart'; // Yeni widget'ı ekle

/// A full-width action button that adapts its visual style based on [isOutlined].
///
/// - **Filled** (default): solid [ColorConstants.primaryColor] background with
///   a matching glow shadow.
/// - **Outlined**: transparent background with a white border — suitable for
///   secondary actions on dark backgrounds.
///
/// All taps are wrapped in [ScaleButton] for a subtle press-down animation.
class CustomButton extends StatelessWidget {
  /// The label text displayed in the centre of the button.
  final String text;

  /// Callback invoked when the button is tapped.
  final VoidCallback onPressed;

  /// When `true`, renders as a white-bordered outline button instead of a
  /// filled button. Defaults to `false`.
  final bool isOutlined;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    // Tüm butonu ScaleButton ile sarıyoruz
    return ScaleButton(
      onPressed: onPressed,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          // Outlined ise şeffaf, değilse ana renk
          color: isOutlined ? Colors.transparent : ColorConstants.primaryColor,
          borderRadius: BorderRadius.circular(16),
          border: isOutlined
              ? Border.all(
                  color: Colors.white,
                  width: 2,
                ) // Dark modda beyaz çerçeve daha iyi
              : null,
          boxShadow: isOutlined
              ? null
              : [
                  BoxShadow(
                    color: ColorConstants.primaryColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white, // Dark modda her türlü beyaz yazı
            ),
          ),
        ),
      ),
    );
  }
}
