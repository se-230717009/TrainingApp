/// lib/screens/login_screen.dart
///
/// Allows existing users to sign in with email/password or Google.
///
/// After a successful sign-in this screen delegates all routing decisions to
/// [AppRouter.navigateAfterAuth], which checks the user's role and onboarding
/// state and pushes the appropriate home or onboarding screen. This avoids
/// duplicating routing logic here and in [UserRegisterScreen].

// ignore_for_file: deprecated_member_use

library;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/interfaces/i_auth_service.dart';
import '../core/navigation/app_router.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/scale_button.dart';
import '../widgets/social_login_button.dart';
import 'welcome_screen.dart';

/// Sign-in screen for returning users.
class LoginScreen extends StatefulWidget {
  /// [authService] is injected to support testing with a fake implementation.
  /// Defaults to the real [AuthService] when omitted.
  const LoginScreen({super.key, IAuthService? authService})
      : _authService = authService ?? const _DefaultAuth();

  final IAuthService _authService;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

/// Workaround: const default that resolves at runtime because we can't
/// write `const AuthService()` in a const constructor.
class _DefaultAuth implements IAuthService {
  const _DefaultAuth();

  // All calls are forwarded to the real AuthService singleton.
  @override
  dynamic noSuchMethod(Invocation i) => AuthService();
}

class _LoginScreenState extends State<LoginScreen> {
  // ---------------------------------------------------------------------------
  // Form controllers
  // ---------------------------------------------------------------------------

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  /// Late-bound real service — built once so it isn't re-created on rebuild.
  late final IAuthService _authService;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // If the widget received an injected service (e.g. from a test), use it.
    // Otherwise fall back to the real AuthService singleton.
    _authService = widget._authService is _DefaultAuth
        ? AuthService()
        : widget._authService;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Email / password sign-in
  // ---------------------------------------------------------------------------

  /// Validates form fields, calls [IAuthService.signIn], and navigates on
  /// success. Shows a [SnackBar] on failure.
  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen tüm alanları doldurun")),
      );
      return;
    }

    setState(() => _isLoading = true);

    final String? error = await _authService.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (error == null) {
      // Sign-in successful — let AppRouter decide where to go.
      await AppRouter.navigateAfterAuth(context, _authService);
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Google sign-in
  // ---------------------------------------------------------------------------

  /// Initiates the Google OAuth flow and navigates on success.
  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);

    // Pass no role — we are on the login screen (existing accounts only).
    final String? error = await _authService.signInWithGoogle();

    if (error == null) {
      await AppRouter.navigateAfterAuth(context, _authService);
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 20,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom -
                      40,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back button — returns to WelcomeScreen
                      ScaleButton(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const WelcomeScreen(),
                            ),
                            (route) => false,
                          );
                        },
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

                      // Heading
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

                      // Email field
                      CustomTextField(
                        label: "E-posta Adresi",
                        icon: Icons.email_outlined,
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                      ),

                      const SizedBox(height: 20),

                      // Password field
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
                            // TODO: Implement forgot-password flow.
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

                      // Primary action button
                      _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            )
                          : CustomButton(
                              text: "Giriş Yap",
                              onPressed: _login,
                            ),

                      const SizedBox(height: 20),

                      // Divider row
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

                      const SizedBox(height: 24),

                      // Google sign-in button
                      SocialLoginButton(
                        text: "Google ile Giriş Yap",
                        iconPath: 'assets/icons/google.png',
                        onPressed: _loginWithGoogle,
                      ),
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
