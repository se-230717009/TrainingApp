import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../core/constants/color_constants.dart';
import 'welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Animasyon Ayarları (Süre: 2 saniye)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // Fade Efekti (Görünürlük 0'dan 1'e)
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    // Büyüme Efekti (Küçükten normale)
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    // Animasyonu Başlat
    _controller.forward();

    // 2. Sayfa Geçişi (6 saniye bekleyip WelcomeScreen'e git)
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Premium his için siyah arka plan
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // LOGO ALANI
                SizedBox(
                  height: 200, // Animasyonun boyutu (istediğin gibi oyna)
                  child: Lottie.asset(
                    'assets/animations/Progression.json', // json dosyasının yolu
                    fit: BoxFit.contain, // Kutuya sığdır
                    // repeat: true, // (Varsayılan olarak zaten tekrar eder)
                  ),
                ),
                const SizedBox(height: 20),

                // UYGULAMA İSMİ
                Text(
                  "CoachApp",
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2.0, // Harf aralığını açarak modern görünüm
                  ),
                ),

                const SizedBox(height: 10),

                // YÜKLENİYOR ÇUBUĞU (İsteğe bağlı, şık durur)
                const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      ColorConstants.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
