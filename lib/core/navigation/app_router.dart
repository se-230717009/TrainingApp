/// lib/core/navigation/app_router.dart
///
/// Central routing helper for the application.
///
/// **Why this file exists:**
/// The logic "after a successful login, check the user's role and onboarding
/// state, then push the correct screen" was copy-pasted verbatim in three
/// different places:
///   - `LoginScreen._login()`
///   - `LoginScreen._loginWithGoogle()`
///   - `UserRegisterScreen._registerWithGoogle()`
///
/// Any change to the routing rules had to be made in all three spots — a
/// classic Open/Closed violation. [AppRouter] is the single source of truth.

library;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../screens/home_screen.dart';
import '../../screens/coach_home_screen.dart';
import '../../screens/onboarding_screen.dart';
import '../../screens/coach_onboarding_screen.dart';
import '../../screens/welcome_screen.dart';
import '../../services/interfaces/i_auth_service.dart';

/// Provides static navigation methods used after authentication events.
class AppRouter {
  // Prevent instantiation — this is a utility class.
  AppRouter._();

  // ---------------------------------------------------------------------------
  // Post-auth routing
  // ---------------------------------------------------------------------------

  /// Determines the correct destination screen after a successful sign-in or
  /// registration, then navigates to it by clearing the entire back stack.
  ///
  /// Decision logic:
  ///   1. Fetch the user's [onboarding status] and [role] from [authService].
  ///   2. If onboarding is complete → go to the appropriate home screen.
  ///   3. If onboarding is not complete → go to the appropriate onboarding screen.
  ///
  /// [context] must still be mounted when this method is called.
  /// Returns early without navigating if the widget is unmounted.
  static Future<void> navigateAfterAuth(
    BuildContext context,
    IAuthService authService,
  ) async {
    // Guard: do nothing if the widget that triggered auth is gone.
    if (!context.mounted) return;

    final String uid = FirebaseAuth.instance.currentUser!.uid;

    // Parallel fetch — both are independent Firestore reads.
    final results = await Future.wait([
      authService.checkOnboardingStatus(uid),
      authService.getUserType(uid),
    ]);

    // Guard: check mount again after the async gap.
    if (!context.mounted) return;

    final bool isOnboarded = results[0] as bool;
    final bool isCoach = (results[1] as String?) == 'coach';

    final Widget destination;
    if (isOnboarded) {
      destination = isCoach ? const CoachHomeScreen() : const HomeScreen();
    } else {
      destination =
          isCoach ? const CoachOnboardingScreen() : const OnboardingScreen();
    }

    // Replace the entire navigation stack so the user cannot press Back
    // to return to the login/register screen.
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => destination),
      (route) => false,
    );
  }

  // ---------------------------------------------------------------------------
  // Convenience navigators
  // ---------------------------------------------------------------------------

  /// Navigates to [WelcomeScreen], clearing the back stack.
  ///
  /// Used by the Settings tab "Logout" action so the user cannot navigate
  /// back to a protected screen after signing out.
  static void goToWelcome(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }
}
