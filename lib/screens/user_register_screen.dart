/// lib/screens/user_register_screen.dart
///
/// Registration screen for both athletes and coaches.
///
/// The [userType] parameter (`'athlete'` or `'coach'`) is passed from
/// [RoleSelectionScreen] and controls both the UI copy and the role value
/// stored in Firestore.
///
/// After a successful registration this screen delegates all routing to
/// [AppRouter.navigateAfterAuth] — the same helper used by [LoginScreen] —
/// so the post-auth routing rules live in exactly one place.

// ignore_for_file: deprecated_member_use

library;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/color_constants.dart';
import '../core/navigation/app_router.dart';
import '../core/utils/validators.dart';
import '../services/auth_service.dart';
import '../services/interfaces/i_auth_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/scale_button.dart';
import '../widgets/social_login_button.dart';
import 'onboarding_screen.dart';
import 'coach_onboarding_screen.dart';

/// Registration form screen.
///
/// [userType] must be either `'athlete'` or `'coach'`.
class UserRegisterScreen extends StatefulWidget {
  /// The role that will be written to Firestore for this user.
  final String userType;

  /// [authService] is injectable for testing; defaults to [AuthService].
  final IAuthService authService;

  const UserRegisterScreen({
    super.key,
    required this.userType,
    IAuthService? authService,
  }) : authService = authService ?? const _DefaultAuth();

  @override
  State<UserRegisterScreen> createState() => _UserRegisterScreenState();
}

/// Const-compatible stand-in that resolves to the real [AuthService]
/// at runtime (needed because we cannot use `const AuthService()` in a
/// const constructor initialiser list).
class _DefaultAuth implements IAuthService {
  const _DefaultAuth();
  @override
  dynamic noSuchMethod(Invocation i) => AuthService();
}

class _UserRegisterScreenState extends State<UserRegisterScreen> {
  // ---------------------------------------------------------------------------
  // Form
  // ---------------------------------------------------------------------------

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  late final IAuthService _authService;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService is _DefaultAuth
        ? AuthService()
        : widget.authService;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Email / password registration
  // ---------------------------------------------------------------------------

  /// Validates the form, creates the account, then navigates to the
  /// appropriate onboarding screen.
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final String? error = await _authService.registerUser(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      name: _nameController.text.trim(),
      surname: _surnameController.text.trim(),
      username: _usernameController.text.trim(),
      userType: widget.userType,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error == null) {
      // Registration successful — direct the user to onboarding.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Kayıt Başarılı! Hadi profilini oluşturalım."),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => widget.userType == 'coach'
              ? const CoachOnboardingScreen()
              : const OnboardingScreen(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Google registration
  // ---------------------------------------------------------------------------

  /// Authenticates with Google (passing the known [userType] role) and
  /// navigates to onboarding on success.
  Future<void> _registerWithGoogle() async {
    setState(() => _isLoading = true);

    // Provide the role so AuthService can create the Firestore document for a
    // brand-new Google account.
    final String? error =
        await _authService.signInWithGoogle(role: widget.userType);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => widget.userType == 'coach'
              ? const CoachOnboardingScreen()
              : const OnboardingScreen(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final double spacing = screenHeight < 700 ? 10 : 16;

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
          // Background gradient
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
                      // Back button
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

                      // Dynamic heading based on user role
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

                      // Name / surname row
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              label: "Ad",
                              icon: Icons.person_outline,
                              controller: _nameController,
                              validator: (val) =>
                                  val!.isEmpty ? '' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomTextField(
                              label: "Soyad",
                              icon: Icons.person_outline,
                              controller: _surnameController,
                              validator: (val) =>
                                  val!.isEmpty ? '' : null,
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
                        // Passwords must match
                        validator: (val) =>
                            val != _passwordController.text ? '!' : null,
                      ),

                      SizedBox(height: spacing * 1.5),

                      // Registration button
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

                      // Divider
                      Row(
                        children: [
                          const Expanded(
                              child: Divider(color: Colors.white24)),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              "veya şununla devam et",
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.white38,
                              ),
                            ),
                          ),
                          const Expanded(
                              child: Divider(color: Colors.white24)),
                        ],
                      ),

                      SizedBox(height: spacing),

                      // Google registration button
                      SocialLoginButton(
                        text: "Google ile Devam Et",
                        iconPath: 'assets/icons/google.png',
                        onPressed: _registerWithGoogle,
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
