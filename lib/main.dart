import 'package:flutter/material.dart';
import 'screens/splash_screen.dart'; // SplashScreen'i ekledik
import 'core/constants/color_constants.dart';

void main() {
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
        scaffoldBackgroundColor: ColorConstants.backgroundColor,
        useMaterial3: true,
      ),
      // ARTIK İLK EKRANIMIZ SPLASH SCREEN
      home: const SplashScreen(),
    );
  }
}
