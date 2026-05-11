/// lib/screens/welcome_screen.dart
///
/// The first screen shown to unauthenticated users who open the app.
/// Displays a hero background image with two action buttons:
///   - "Log In"  → navigates to [LoginScreen].
///   - "Create Account" → navigates to [RoleSelectionScreen].
library;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/color_constants.dart';
import '../widgets/custom_button.dart';
import 'role_selection_screen.dart';
import 'login_screen.dart';

/// Landing / splash screen for unauthenticated users.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Stack: Üst üste katmanlar koymamızı sağlar
      body: Stack(
        children: [
          // KATMAN 1: ARKA PLAN GÖRSELİ
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1476480862126-209bfaa8edc8?q=80&w=1920&auto=format&fit=crop',
              fit: BoxFit.cover, // Resmi ekrana yayar, keserek doldurur
            ),
          ),

          // KATMAN 2: KARANLIK GRADIENT (ÖRTÜ)
          // Resmin üzerine siyah bir perde çekiyoruz ki yazılar okunsun.
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.1), // Üst kısım daha aydınlık
                    Colors.black.withOpacity(
                      0.8,
                    ), // Alt kısım (butonların olduğu yer) karanlık
                    Colors.black, // En alt simsiyah
                  ],
                  stops: const [0.0, 0.6, 1.0], // Renklerin geçiş noktaları
                ),
              ),
            ),
          ),

          // KATMAN 3: İÇERİK (Yazılar ve Butonlar)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 30.0,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start, // Yazıları sola yasla
                children: [
                  // Üstteki küçük logo (Opsiyonel)
                  Row(
                    children: [
                      Icon(
                        Icons.fitness_center_sharp,
                        color: ColorConstants.primaryColor,
                        size: 35,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "CoachApp",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(), // İçeriği aşağı iter
                  // Vurucu Başlık
                  Text(
                    "Sınırlarını\nZorlamaya Başla.",
                    textAlign: TextAlign.start,
                    style: GoogleFonts.poppins(
                      fontSize: 38, // Daha büyük font
                      fontWeight: FontWeight.w800, // Daha kalın
                      color: Colors.white, // Beyaz yazı
                      height: 1.1, // Satır arası sıkı
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Alt Açıklama
                  Text(
                    "Hedeflerine ulaşmak için profesyonel antrenörlerle birebir çalış veya online derslere katıl.",
                    textAlign: TextAlign.start,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white.withOpacity(
                        0.8,
                      ), // Hafif şeffaf beyaz
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // BUTONLAR
                  CustomButton(
                    text: "Giriş Yap",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Outlined butonun bu karanlık temada iyi durması için
                  // CustomButton'a küçük bir renk ayarı gerekebilir ama
                  // eğer primary rengin parlaksa (mor/mavi gibi) güzel duracaktır.
                  CustomButton(
                    text: "Hesap Oluştur",
                    isOutlined: true,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RoleSelectionScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
