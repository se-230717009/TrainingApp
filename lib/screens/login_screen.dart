import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/scale_button.dart';
import 'onboarding_screen.dart';
import 'home_screen.dart';
import '../widgets/social_login_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controller'lar
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Servis ve Durum
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  void _login() async {
    // 1. Basit Kontrol
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen tüm alanları doldurun")),
      );
      return;
    }

    // 2. Yükleniyor Başlat
    setState(() => _isLoading = true);

    // 3. Giriş Yap
    final message = await _authService.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (message == null) {
      // --- GİRİŞ BAŞARILI ---
      // Şimdi kullanıcının durumunu kontrol edelim
      if (mounted) {
        String uid = FirebaseAuth.instance.currentUser!.uid;
        bool isOnboarded = await _authService.checkOnboardingStatus(uid);

        if (mounted) {
          // Yönlendirme Kararı
          if (isOnboarded) {
            // Eğer profil tamamsa -> Ana Sayfaya
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false,
            );
          } else {
            // Eğer eksikse -> Onboarding Ekranına (Kaldığı yerden devam etsin)
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const OnboardingScreen()),
              (route) => false,
            );
          }
        }
      }
    } else {
      // --- HATA VAR ---
      if (mounted) {
        setState(() => _isLoading = false); // Animasyonu durdur
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- GOOGLE İLE GİRİŞ FONKSİYONU ---
  void _loginWithGoogle() async {
    setState(() => _isLoading = true);

    // DİKKAT: Login ekranında olduğumuz için role: null gönderiyoruz.
    final message = await _authService.signInWithGoogle();

    if (message == null) {
      // Giriş Başarılı, Onboarding kontrolü yap
      if (mounted) {
        String uid = FirebaseAuth.instance.currentUser!.uid;
        bool isOnboarded = await _authService.checkOnboardingStatus(uid);

        if (mounted) {
          if (isOnboarded) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
            );
          } else {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const OnboardingScreen()),
              (route) => false,
            );
          }
        }
      }
    } else {
      // Hata veya Uyarı Var
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Arka Plan
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1A1A1A), Colors.black],
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
                  // Geri Dön Butonu
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

                  // Başlık
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

                  // Inputlar
                  CustomTextField(
                    label: "E-posta Adresi",
                    icon: Icons.email_outlined,
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 20),

                  CustomTextField(
                    label: "Şifre",
                    icon: Icons.lock_outline,
                    isPassword: true,
                    controller: _passwordController,
                  ),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        /* Şifremi unuttum */
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

                  // Giriş Butonu (Loading Kontrollü)
                  _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : CustomButton(text: "Giriş Yap", onPressed: _login),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      const Expanded(child: Divider(color: Colors.white24)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          "veya şununla devam et",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white38,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider(color: Colors.white24)),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // GOOGLE BUTONU (Yeni eklendi, dosyada import ettiğinden emin ol)
                  SocialLoginButton(
                    text: "Google ile Giriş Yap",
                    iconPath: 'assets/icons/google.png',
                    onPressed: _loginWithGoogle,
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
