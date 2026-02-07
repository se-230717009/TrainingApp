import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Firebase Çekirdeği
import 'firebase_options.dart'; // Yapılandırma dosyası (Otomatik oluştu)
import 'screens/splash_screen.dart'; // Başlangıç ekranımız
import 'core/constants/color_constants.dart';

// Main artık "async" olmak zorunda çünkü Firebase'i bekleyeceğiz
void main() async {
  // 1. Flutter motorunu hazırla
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Firebase'i başlat (Platforma göre ayarları alarak)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 3. Uygulamayı çalıştır
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CoachApp',
      theme: ThemeData(
        primaryColor: ColorConstants.primaryColor,
        // Scaffold rengini siyah yaptık, dark mode premium havası bozulmasın
        scaffoldBackgroundColor: Colors.black,
        useMaterial3: true,
      ),
      // Yine Splash Screen ile başlıyoruz
      home: const SplashScreen(),
    );
  }
}
