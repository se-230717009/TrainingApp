import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/color_constants.dart';
import '../core/utils/validators.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/scale_button.dart';
import '../widgets/social_login_button.dart';

class UserRegisterScreen extends StatefulWidget {
  // Bu ekranı kimin için açıyoruz? 'athlete' veya 'coach'
  final String userType;

  const UserRegisterScreen({
    super.key,
    required this.userType, // Zorunlu yaptık
  });

  @override
  State<UserRegisterScreen> createState() => _UserRegisterScreenState();
}

class _UserRegisterScreenState extends State<UserRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  void _register() {
    if (_formKey.currentState!.validate()) {
      // Backend'e gönderirken widget.userType bilgisini de göndereceğiz
      print("Kayıt Tipi: ${widget.userType}");
      print("İsim: ${_nameController.text}");

      // Simülasyon
      setState(() => _isLoading = true);
      Future.delayed(const Duration(seconds: 2), () {
        setState(() => _isLoading = false);
        // Kayıt başarılı -> Ana Sayfaya veya Onay Ekranına yönlendir
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final double spacing = screenHeight < 700 ? 10 : 16;

    // Rol'e göre metinleri belirle
    final bool isCoach = widget.userType == 'coach';
    final String title = isCoach ? "Antrenör Hesabı" : "Sporcu Hesabı";
    final String subtitle = isCoach
        ? "Öğrencilerini bekleme, hemen başla."
        : "Hemen başla, hedeflerine ulaş.";

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
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
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Geri Dön Butonu
                      Row(
                        children: [
                          ScaleButton(
                            onPressed: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: spacing),

                      // Dinamik Başlık
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),

                      SizedBox(height: spacing * 1.5),

                      // Ad - Soyad
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              label: "Ad",
                              icon: Icons.person_outline,
                              controller: _nameController,
                              validator: (val) => val!.isEmpty ? '' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomTextField(
                              label: "Soyad",
                              icon: Icons.person_outline,
                              controller: _surnameController,
                              validator: (val) => val!.isEmpty ? '' : null,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: spacing),

                      CustomTextField(
                        label: "Kullanıcı Adı",
                        icon: Icons.alternate_email,
                        controller: _usernameController,
                        validator: Validators.validateUsername,
                      ),

                      SizedBox(height: spacing),

                      CustomTextField(
                        label: "E-posta",
                        icon: Icons.email_outlined,
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: Validators.validateEmail,
                      ),

                      SizedBox(height: spacing),

                      CustomTextField(
                        label: "Şifre",
                        icon: Icons.lock_outline,
                        isPassword: true,
                        controller: _passwordController,
                        validator: Validators.validatePassword,
                      ),

                      SizedBox(height: spacing),

                      CustomTextField(
                        label: "Şifre Tekrar",
                        icon: Icons.lock_reset,
                        isPassword: true,
                        controller: _confirmPasswordController,
                        validator: (val) =>
                            val != _passwordController.text ? '!' : null,
                      ),

                      SizedBox(height: spacing * 1.5),

                      // Kayıt Butonu
                      _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: ColorConstants.primaryColor,
                              ),
                            )
                          : CustomButton(
                              text: "Kayıt Ol",
                              onPressed: _register,
                            ),

                      SizedBox(height: spacing),

                      // VEYA ÇİZGİSİ
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

                      SizedBox(height: spacing),

                      // Google Butonu
                      SocialLoginButton(
                        text: "Google ile Devam Et",
                        iconPath: 'assets/icons/google.png',
                        onPressed: () {
                          // Google Login de rolü bilmeli
                          print(
                            "Google Login Tıklandı - Rol: ${widget.userType}",
                          );
                        },
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
