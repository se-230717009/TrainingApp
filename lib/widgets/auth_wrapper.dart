import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../core/constants/color_constants.dart';
import '../screens/welcome_screen.dart'; // Eğer uygulaman ilk Welcome'dan başlıyorsa
import '../screens/home_screen.dart';
import '../screens/coach_home_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/coach_onboarding_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Future<Map<String, dynamic>> _getUserData(String uid) async {
    final AuthService authService = AuthService();
    bool isOnboarded = await authService.checkOnboardingStatus(uid);
    String? userType = await authService.getUserType(uid);

    return {
      'isOnboarded': isOnboarded,
      'userType': userType ?? 'athlete', // Varsayılan athlete
    };
  }

  @override
  Widget build(BuildContext context) {
    // 1. Firebase'de aktif bir oturum var mı diye dinliyoruz
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Firebase henüz kontrol ediyorsa siyah bir ekranda loading göster
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

        // 2. Kullanıcı çıkış yapmışsa veya hiç girmemişse doğrudan Login/Welcome'a at
        if (!snapshot.hasData || snapshot.data == null) {
          return const WelcomeScreen(); // Kendi başlangıç ekranın neyse onu yaz
        }

        // 3. Kullanıcı giriş yapmış, şimdi rolünü ve form (onboarding) durumunu öğrenelim
        return FutureBuilder<Map<String, dynamic>>(
          future: _getUserData(snapshot.data!.uid),
          builder: (context, userSnapshot) {
            // Veritabanından rolü çekene kadar loading
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

            if (userSnapshot.hasError || !userSnapshot.hasData) {
              return const WelcomeScreen(); // Hata olursa güvenli limana dön
            }

            final userData = userSnapshot.data!;
            final bool isCoach = userData['userType'] == 'coach';
            final bool isOnboarded = userData['isOnboarded'] == true;

            // 4. BÜYÜK YÖNLENDİRME (Vibe Routing)
            if (isOnboarded) {
              // Formu doldurmuş, direkt ana ekrana at
              return isCoach ? const CoachHomeScreen() : const HomeScreen();
            } else {
              // Formu eksik kalmış, kaldığı yerden formu doldurtsun
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
