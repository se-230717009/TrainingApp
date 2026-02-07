import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/scale_button.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Controller'lar (Yazılanları yakalamak için)
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    return Scaffold(
      backgroundColor: Colors.black, // Tam siyah premium zemin
      body: Stack(
        children: [
          // Arka plan hafif gradyanı (Derinlik için)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1A1A1A), // Çok koyu gri
                    Colors.black,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. GERİ DÖN BUTONU
                  ScaleButton(
                    onPressed: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // 2. BAŞLIK
                  Text(
                    "Tekrar\nHoşgeldin.",
                    style: GoogleFonts.poppins(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Kaldığın yerden devam et.",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),

                  const SizedBox(height: 50),

                  // 3. INPUT ALANLARI
                  // E-posta
                  CustomTextField(
                    label: "E-posta Adresi",
                    icon: Icons.email_outlined,
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    maxLength: 100, // STANDART SINIR
                  ),

                  const SizedBox(height: 20),

                  // Şifre
                  CustomTextField(
                    label: "Şifre",
                    icon: Icons.lock_outline,
                    isPassword: true,
                    controller: passwordController,
                    maxLength: 64, // GÜVENLİK SINIRI (Buffer overflow önlemi)
                  ),

                  // Şifremi Unuttum
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        print("Şifremi unuttum");
                      },
                      child: Text(
                        "Şifremi Unuttum?",
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // 4. GİRİŞ YAP BUTONU
                  CustomButton(
                    text: "Giriş Yap",
                    onPressed: () {
                      print("Email: ${emailController.text}");
                      print("Şifre: ${passwordController.text}");
                      // İleride buraya Firebase Auth kodu gelecek
                    },
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
