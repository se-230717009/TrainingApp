import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/color_constants.dart';
import '../widgets/scale_button.dart';
import 'chat_screen.dart';

class CoachDetailScreen extends StatelessWidget {
  final Map<String, dynamic> coachData;

  const CoachDetailScreen({super.key, required this.coachData});

  @override
  Widget build(BuildContext context) {
    // Verileri güvenli çekelim
    final String name = coachData['name'] ?? '';
    final String surname = coachData['surname'] ?? '';
    final String fullName = "$name $surname".trim().isEmpty
        ? "Eğitmen"
        : "$name $surname";
    final String? profileImageUrl = coachData['profileImageUrl'];
    final String bio = coachData['bio'] ?? "Henüz biyografi eklenmemiş.";
    final String lessonSport = coachData['lessonSport'] ?? "Genel";
    final String character = coachData['coachCharacter'] ?? "Belirtilmemiş";
    final String coachUid = coachData['uid'] ?? '';
    final String deliveryMode =
        coachData['deliveryMode'] ?? "Online"; // Yeni veri
    final int price = coachData['hourlyRate'] ?? 0;
    final List<dynamic> specialties = coachData['specialties'] ?? [];

    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- ÜST KISIM (FOTOĞRAF & BACK BUTTON & KALP) ---
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // Arka Plan Resmi (Büyük Fotoğraf)
                Container(
                  height: 350,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    image: profileImageUrl != null
                        ? DecorationImage(
                            image: NetworkImage(profileImageUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: profileImageUrl == null
                      ? const Center(
                          child: Icon(
                            Icons.person,
                            size: 80,
                            color: Colors.white24,
                          ),
                        )
                      : null,
                ),
                // Gölge Efekti (Alttan yukarı siyahlık)
                Container(
                  height: 350,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.9),
                      ],
                      stops: const [0.6, 1.0],
                    ),
                  ),
                ),
                // Geri Butonu (Sol Üst)
                Positioned(
                  top: 50,
                  left: 20,
                  child: ScaleButton(
                    onPressed: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white12),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                // Kalp Butonu (Sağ Üst - Favori)
                Positioned(
                  top: 50,
                  right: 20,
                  child: ScaleButton(
                    onPressed: () {
                      // Favori işlemi sonra yapılacak
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white12),
                      ),
                      child: const Icon(
                        Icons.favorite_border_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- İSİM & KARAKTER ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fullName,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              character,
                              style: GoogleFonts.poppins(
                                color: ColorConstants.primaryColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Ücret Bilgisi (Köşede)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "$price ₺",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Saatlik",
                            style: GoogleFonts.poppins(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // --- BUTONLAR (MESAJ & ÖN GÖRÜŞME) ---
                  Row(
                    children: [
                      // Mesaj Gönder Butonu
                      Expanded(
                        child: ScaleButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(
                                  receiverId: coachUid,
                                  receiverName: fullName,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Mesaj Gönder",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Ön Görüşme Talep Et Butonu (Dolu Renk)
                      Expanded(
                        child: ScaleButton(
                          onPressed: () {}, // Aktif Değil
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: ColorConstants.primaryColor,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.calendar_today_rounded,
                                  color: Colors.black,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Ön Görüşme",
                                  style: GoogleFonts.poppins(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // --- PUAN VE YORUMLAR ---
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Colors.amber,
                              size: 28,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "5.0",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "(0 Yorum)",
                              style: GoogleFonts.poppins(
                                color: Colors.white54,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          "Tümünü Gör",
                          style: GoogleFonts.poppins(
                            color: Colors.white38,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- HAKKINDA (BİO) ---
                  Text(
                    "Hakkında",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    bio,
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- ÖZELLİKLER (UZMANLIK & DERS ŞEKLİ) ---
                  Text(
                    "Ders Detayları",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Branş (lessonSport burada kullanılıyor)
                  Row(
                    children: [
                      const Icon(
                        Icons.sports_gymnastics_rounded,
                        color: ColorConstants.primaryColor,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Branş: ",
                        style: GoogleFonts.poppins(color: Colors.white70),
                      ),
                      Text(
                        lessonSport,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Ders Verme Şekli
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: ColorConstants.primaryColor,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Eğitim Tipi: ",
                        style: GoogleFonts.poppins(color: Colors.white70),
                      ),
                      Text(
                        deliveryMode,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // --- UZMANLIK ALANLARI ---
                  if (specialties.isNotEmpty) ...[
                    Text(
                      "Tüm Uzmanlık Alanları",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: specialties.map<Widget>((s) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            s.toString(),
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 12),

                  // Uzmanlık Alanları Chip List
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: specialties.map<Widget>((s) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          s.toString(),
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
