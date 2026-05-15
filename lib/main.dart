import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Firebase Çekirdeği
// YENİ EKLENEN İMPORT (Yerelleştirme için)
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart'; // Yapılandırma dosyası (Otomatik oluştu)
import 'core/constants/color_constants.dart';
import 'widgets/auth_wrapper.dart';

// Main artık "async" olmak zorunda çünkü Firebase'i bekleyeceğiz
void main() async {
  // 1. Flutter motorunu hazırla
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Firebase'i başlat (Platforma göre ayarları alarak)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 3. Uygulamayı çalıştır
  runApp(const MyApp());
}

/// Root widget of the application.
///
/// Configures [MaterialApp] with the app theme and sets [AuthWrapper] as the
/// home widget, which decides which screen to show based on auth state.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CoachApp',

      // --- YENİ EKLENEN DİL AYARLARI ---
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr', 'TR'), // Türkçe desteği
        Locale('en', 'US'), // İngilizce fallback
      ],
      locale: const Locale('tr', 'TR'), // Uygulamayı zorunlu Türkçe başlat

      // --------------------------------
      theme: ThemeData(
        primaryColor: ColorConstants.primaryColor,
        // Keep the scaffold background black for the premium dark-mode look.
        scaffoldBackgroundColor: Colors.black,
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}
