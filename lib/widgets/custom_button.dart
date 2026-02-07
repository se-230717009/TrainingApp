import 'package:flutter/material.dart';
import '../core/constants/color_constants.dart';
import 'package:google_fonts/google_fonts.dart';
import 'scale_button.dart'; // Yeni widget'ı ekle

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
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
