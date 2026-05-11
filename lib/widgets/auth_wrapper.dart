/// lib/widgets/auth_wrapper.dart
///
/// Root widget that listens to Firebase Auth state changes and routes the
/// user to the correct screen on app start.
///
/// Decision tree:
///   1. Auth state loading  → show a loading spinner.
///   2. No authenticated user → show [HomeScreen] (guest mode).
///   3. Authenticated user:
///        a. Fetch Firestore profile.
///        b. Profile missing → [OnboardingScreen] (new user).
///        c. Onboarding complete + coach  → [CoachHomeScreen].
///        d. Onboarding complete + athlete → [HomeScreen].
///        e. Onboarding incomplete + coach  → [CoachOnboardingScreen].
///        f. Onboarding incomplete + athlete → [OnboardingScreen].
library;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/color_constants.dart';
import '../screens/home_screen.dart';
import '../screens/coach_home_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/coach_onboarding_screen.dart';

/// Listens to [FirebaseAuth.authStateChanges] and renders the appropriate
/// screen based on the user's authentication status and profile state.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Firebase'de aktif bir oturum var mı diye dinleniyor
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: CircularProgressIndicator(
                color: ColorConstants.primaryColor,
              ),
            ),
          );
        }

        // 2. Kullanıcı çıkış yapmışsa veya hiç girmemişse Welcome ekranına yönlendir
        // 2. Kullanıcı çıkış yapmışsa veya hiç girmemişse Ana Ekrana (Misafir) yönlendir
        if (!snapshot.hasData || snapshot.data == null) {
          return const HomeScreen();
        }

        // 3. Kullanıcı oturum açmış. Firestore'dan doğrudan rol ve form durumunu çek.
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(snapshot.data!.uid)
              .get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: Colors.black,
                body: Center(
                  child: CircularProgressIndicator(
                    color: ColorConstants.primaryColor,
                  ),
                ),
              );
            }

            if (userSnapshot.hasError ||
                !userSnapshot.hasData ||
                !userSnapshot.data!.exists) {
              // Veritabanında belge yoksa yeni kullanıcıdır, standart Onboarding'e yönlendir.
              return const OnboardingScreen();
            }

            final userData = userSnapshot.data!.data() as Map<String, dynamic>;
            final bool isCoach = userData['userType'] == 'coach';

            // Onboarding ekranlarında kaydedilen doğru anahtar kontrol ediliyor.
            final bool isOnboardingCompleted =
                userData['isOnboardingCompleted'] == true;

            // 4. Duruma göre yönlendirme
            if (isOnboardingCompleted) {
              return isCoach ? const CoachHomeScreen() : const HomeScreen();
            } else {
              return isCoach
                  ? const CoachOnboardingScreen()
                  : const OnboardingScreen();
            }
          },
        );
      },
    );
  }
}
