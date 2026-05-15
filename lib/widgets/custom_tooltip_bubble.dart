import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/color_constants.dart';

class CustomTooltipBubble extends StatelessWidget {
  final Widget child;
  final String message;
  final bool isVisible;
  final VoidCallback? onClose;
  final double bottomOffset;

  const CustomTooltipBubble({
    super.key,
    required this.child,
    required this.message,
    required this.isVisible,
    this.onClose,
    this.bottomOffset =
        65.0, // Altındaki widget'ın boyutuna göre yüksekliği ayarlar
  });

  @override
  Widget build(BuildContext context) {
    // Eğer görünür değilse sadece widget'ın kendisini döndür (Baloncuk yok)
    if (!isVisible) return child;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        child, // Hedeflenen asıl widget (Örn: Buton)
        Positioned(
          bottom: bottomOffset,
          child: Material(
            color: Colors.transparent,
            elevation: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Baloncuk Gövdesi
                Container(
                  constraints: const BoxConstraints(maxWidth: 240),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: ColorConstants.primaryColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: ColorConstants.primaryColor.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          message,
                          style: GoogleFonts.poppins(
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      if (onClose != null) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: onClose,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.black,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Aşağı Bakan Küçük Ok (Kuyruk)
                CustomPaint(
                  size: const Size(16, 10),
                  painter: _TrianglePainter(color: ColorConstants.primaryColor),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Baloncuğun altındaki küçük oku çizen ressam sınıfı
class _TrianglePainter extends CustomPainter {
  final Color color;

  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    var path = Path();
    path.moveTo(0, 0); // Sol üst
    path.lineTo(size.width / 2, size.height); // Alt orta
    path.lineTo(size.width, 0); // Sağ üst
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
