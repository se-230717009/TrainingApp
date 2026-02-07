import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/color_constants.dart';
import '../core/utils/validators.dart'; // Artık bunu aşağıda kullanıyoruz!
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/scale_button.dart';
import '../widgets/social_login_button.dart';

class UserRegisterScreen extends StatefulWidget {
  const UserRegisterScreen({super.key});

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
    // validate() çalıştığında aşağıdaki CustomTextField'lara verdiğimiz
    // validator fonksiyonları tek tek tetiklenir.
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Şifreler eşleşmiyor!')));
        return;
      }

      print("Validasyon Başarılı! Kayıt Başlıyor: ${_emailController.text}");

      setState(() => _isLoading = true);
      Future.delayed(const Duration(seconds: 2), () {
        setState(() => _isLoading = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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

                    const SizedBox(height: 30),

                    Text(
                      "Sporcu Hesabı\nOluştur.",
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Hemen başla, hedeflerine ulaş.",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),

                    const SizedBox(height: 30),

                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            label: "Ad",
                            icon: Icons.person_outline,
                            controller: _nameController,
                            maxLength: 30,
                            // İsim için özel bir validatör yazmadık ama boş olamaz diyelim
                            validator: (val) => val!.isEmpty ? 'Gerekli' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomTextField(
                            label: "Soyad",
                            icon: Icons.person_outline,
                            controller: _surnameController,
                            maxLength: 30,
                            validator: (val) => val!.isEmpty ? 'Gerekli' : null,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    CustomTextField(
                      label: "Kullanıcı Adı",
                      icon: Icons.alternate_email,
                      controller: _usernameController,
                      maxLength: 20,
                      // Kullanıcı adı validatörünü buraya bağlıyoruz
                      validator: Validators.validateUsername,
                    ),

                    const SizedBox(height: 16),

                    CustomTextField(
                      label: "E-posta",
                      icon: Icons.email_outlined,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      maxLength: 100,
                      // E-posta validatörünü buraya bağlıyoruz
                      validator: Validators.validateEmail,
                    ),

                    const SizedBox(height: 16),

                    CustomTextField(
                      label: "Şifre",
                      icon: Icons.lock_outline,
                      isPassword: true,
                      controller: _passwordController,
                      maxLength: 64,
                      // Şifre validatörünü buraya bağlıyoruz
                      validator: Validators.validatePassword,
                    ),

                    Padding(
                      padding: const EdgeInsets.only(left: 10, top: 5),
                      child: Text(
                        "En az 8 karakter, 1 büyük harf, 1 rakam, 1 özel karakter.",
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.white38,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    CustomTextField(
                      label: "Şifre Tekrar",
                      icon: Icons.lock_reset,
                      isPassword: true,
                      controller: _confirmPasswordController,
                      maxLength: 64,
                      // Basit bir eşleşme kontrolü (ya da boş kontrolü)
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Tekrar giriniz';
                        if (val != _passwordController.text)
                          return 'Eşleşmiyor';
                        return null;
                      },
                    ),

                    const SizedBox(height: 40),

                    _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: ColorConstants.primaryColor,
                            ),
                          )
                        : CustomButton(
                            text: "Hesap Oluştur",
                            onPressed: _register,
                          ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        const Expanded(child: Divider(color: Colors.white24)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            "veya",
                            style: GoogleFonts.poppins(color: Colors.white38),
                          ),
                        ),
                        const Expanded(child: Divider(color: Colors.white24)),
                      ],
                    ),

                    const SizedBox(height: 20),

                    SocialLoginButton(
                      text: "Google ile Kayıt Ol",
                      iconPath: 'assets/icons/google_logo.png',
                      onPressed: () {
                        print("Google Sign Up Tıklandı");
                      },
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
