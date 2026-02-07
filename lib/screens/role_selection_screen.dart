import 'package:coachingapp/screens/user_register_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/color_constants.dart';
import '../widgets/scale_button.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. ARKA PLAN GÖRSELİ
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?q=80&w=1920&auto=format&fit=crop',
              fit: BoxFit.cover,
            ),
          ),

          // 2. KARANLIK GRADYAN
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color.fromARGB(255, 12, 12, 12).withOpacity(0.4),
                    const Color.fromARGB(255, 19, 19, 19).withOpacity(0.85),
                    const Color.fromARGB(255, 16, 16, 16),
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),
          ),

          // 3. İÇERİK
          SafeArea(
            child: Column(
              children: [
                // Geri Dön Butonu
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      ScaleButton(
                        onPressed: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15), // Buzlu cam
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
                    ],
                  ),
                ),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      // mainAxisAlignment: MainAxisAlignment.center, // BUNU KALDIRDIK
                      children: [
                        // YENİ AYAR:
                        // Üstte 3 birim boşluk, altta 4 birim boşluk olacak.
                        // Bu, içeriği hafifçe yukarı iter.
                        const Spacer(flex: 3),

                        // BAŞLIK
                        Text(
                          "Kimsin?",
                          style: GoogleFonts.poppins(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Sana en uygun deneyimi sunabilmemiz için\nlütfen kim olduğunu seç.",
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            color: Colors.white70,
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 40),

                        // KART 1: ANTRENÖR
                        _buildAnimatedCard(
                          title: "Antrenörüm",
                          subtitle: "Ders ver, program hazırla, kazan.",
                          icon: Icons.sports,
                          color: Colors.blueAccent,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    UserRegisterScreen(userType: 'coach'),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 20),

                        // KART 2: SPORCU
                        _buildAnimatedCard(
                          title: "Sporcuyum",
                          subtitle: "Hoca bul, antrenman yap, geliş.",
                          icon: Icons.directions_run,
                          color: ColorConstants.primaryColor,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const UserRegisterScreen(
                                  userType: 'athlete',
                                ),
                              ),
                            );
                          },
                        ),

                        // ALT BOŞLUK (Üstten daha fazla olduğu için yukarı iter)
                        const Spacer(flex: 4),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // KART TASARIMI (Aynı kaldı)
  Widget _buildAnimatedCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ScaleButton(
      onPressed: onPressed,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E).withOpacity(0.9),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 20),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white30,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
