/// lib/widgets/auth_wrapper.dart
///
/// Root widget that listens to Firebase Auth state changes and routes the
/// user to the correct screen on app start.
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
        // Bağlantı bekletiliyor...
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

        // 2. Kullanıcı giriş yapmamışsa direkt ana sayfaya (misafir modu) gönder
        if (!snapshot.hasData || snapshot.data == null) {
          return const HomeScreen();
        }

        // 3. Kullanıcı giriş yapmışsa Firestore'dan profilini kontrol et
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
              // Veritabanında belge yoksa yeni kullanıcıdır, Onboarding'e yönlendir.
              // 'const' kaldırıldı çünkü Onboarding artık servis bağımlılığı alıyor.
              return OnboardingScreen();
            }

            final userData = userSnapshot.data!.data() as Map<String, dynamic>;
            final bool isCoach = userData['userType'] == 'coach';

            // Onboarding tamamlanma durumu kontrol ediliyor.
            final bool isOnboardingCompleted =
                userData['isOnboardingCompleted'] == true;

            // 4. Duruma göre yönlendirme
            if (isOnboardingCompleted) {
              return isCoach ? const CoachHomeScreen() : const HomeScreen();
            } else {
              // 'const' ifadeleri kaldırıldı.
              return isCoach ? CoachOnboardingScreen() : OnboardingScreen();
            }
          },
        );
      },
    );
  }
}
