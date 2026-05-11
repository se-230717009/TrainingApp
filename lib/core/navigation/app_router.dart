/// lib/core/navigation/app_router.dart
///
/// Central routing helper for the application.
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
  static Future<void> navigateAfterAuth(
    BuildContext context,
    IAuthService authService,
  ) async {
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
      // 'const' ifadeleri kaldırıldı çünkü Onboarding sınıfları artık servis bağımlılığı alıyor.
      destination = isCoach ? CoachOnboardingScreen() : OnboardingScreen();
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
  static void goToWelcome(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }
}
