import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants/color_constants.dart';
import '../services/auth_service.dart';
import '../widgets/scale_button.dart';
import 'login_screen.dart';
import 'edit_profile_screen.dart';
import 'my_lessons_screen.dart';
import 'coach_detail_screen.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final String _uid = FirebaseAuth.instance.currentUser!.uid;

  // Sporcu Bilgileri
  String _athleteName = "Sporcu";
  String _athleteGoal = "";
  List<String> _interestedSports = [];
  String _preferredGender = "Farketmez";
  List<String> _availableDays = [];
  List<String> _availableHours = [];
  StreamSubscription<QuerySnapshot>? _lessonsSubscription;
  List<String> _bookedCoachIds = [];

  @override
  void initState() {
    super.initState();
    _loadAthleteData();
    _listenToBookedLessons();
  }

  void _listenToBookedLessons() {
    _lessonsSubscription = FirebaseFirestore.instance
        .collection('lessons')
        .where('athleteId', isEqualTo: _uid)
        .snapshots()
        .listen((snapshot) {
          if (mounted) {
            setState(() {
              // Sadece 'pending' (bekliyor) veya 'approved' (onaylandı) olanları alıyoruz
              _bookedCoachIds = snapshot.docs
                  .where(
                    (doc) =>
                        doc['status'] == 'pending' ||
                        doc['status'] == 'approved',
                  )
                  .map((doc) => doc['coachId'] as String)
                  .toList();
            });
          }
        });
  }

  @override
  void dispose() {
    _lessonsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadAthleteData() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .get();
    if (doc.exists && mounted) {
      final data = doc.data()!;
      setState(() {
        _athleteGoal = data['goal'] ?? "";
        _athleteName = data['name'] ?? "Sporcu";
        _interestedSports = List<String>.from(data['interestedSports'] ?? []);
        _preferredGender = data['preferredCoachGender'] ?? "Farketmez";
        _availableDays = List<String>.from(data['availableDays'] ?? []);
        _availableHours = List<String>.from(data['availableHours'] ?? []);
      });
    }
  }

  // ALGORİTMA: Antrenöre puan veriyoruz. Cinsiyet uyarsa +10 puan, her ortak gün/saat için +1 puan.
  // ALGORİTMA: Antrenöre puan veriyoruz.
  int _calculateMatchScore(Map<String, dynamic> coach) {
    int score = 0;

    // 1. KARAKTER VE HEDEF UYUMU (EN YÜKSEK PUAN: +20)
    String idealCoachCharacter = "";
    switch (_athleteGoal) {
      case "Kilo Vermek":
        idealCoachCharacter = "Motivatör & Enerjik";
        break;
      case "Kas Yapmak":
        idealCoachCharacter = "Disiplinli & Güç Odaklı";
        break;
      case "Kondisyon":
        idealCoachCharacter = "Dinamik & Dayanıklılık Odaklı";
        break;
      case "Esneklik":
        idealCoachCharacter = "Sakin & Beden Farkındalığı";
        break;
      case "Yarışmaya Hazırlanmak":
        idealCoachCharacter = "Sert & Hedef Odaklı (Pro)";
        break;
    }

    if (coach['coachCharacter'] == idealCoachCharacter) {
      score += 20; // Tam isabet!
    }

    // 2. Cinsiyet Uyumu (+10 Puan)
    if (_preferredGender != "Farketmez" &&
        coach['gender'] == _preferredGender) {
      score += 10;
    }

    // 3. Gün Uyumu (Ortak her gün için +1 Puan)
    List<String> coachDays = List<String>.from(coach['availableDays'] ?? []);
    score += coachDays.where((d) => _availableDays.contains(d)).length;

    // 4. Saat Uyumu (Ortak her saat için +1 Puan)
    List<String> coachHours = List<String>.from(coach['availableHours'] ?? []);
    score += coachHours.where((h) => _availableHours.contains(h)).length;

    return score;
  }

  void _signOut() async {
    await _authService.signOut();
    if (mounted)
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
  }

  // --- AYARLAR MENÜSÜ ---
  void _showSettingsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Hesap & Ayarlar",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                _buildMenuItem(Icons.person_outline, "Profil Düzenle", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditProfileScreen(),
                    ),
                  );
                }),
                _buildMenuItem(
                  Icons.settings_outlined,
                  "Uygulama Ayarları",
                  () {},
                ),
                const Divider(color: Colors.white10, height: 30),
                _buildMenuItem(
                  Icons.logout,
                  "Çıkış Yap",
                  _signOut,
                  isDestructive: true,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- MENÜ ÖĞESİ ---
  Widget _buildMenuItem(
    IconData icon,
    String text,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDestructive
              ? Colors.redAccent.withOpacity(0.1)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: isDestructive ? Colors.redAccent : Colors.white,
          size: 20,
        ),
      ),
      title: Text(
        text,
        style: GoogleFonts.poppins(
          color: isDestructive ? Colors.redAccent : Colors.white,
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios_rounded,
        color: Colors.white12,
        size: 14,
      ),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        /* Mevcut AppBar Kodların */
        backgroundColor: Colors.black,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: false,
        titleSpacing: 24,
        title: PopupMenuButton<String>(
          color: const Color(0xFF1E1E1E), // Açılan panelin arka plan rengi
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          offset: const Offset(0, 45), // Panelin biraz aşağıdan açılması için
          onSelected: (value) {
            if (value == 'derslerim') {
              // Derslerim'e tıklanırsa yeni sayfaya git
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MyLessonsScreen(),
                ),
              );
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'kesfet',
              child: Row(
                children: [
                  const Icon(
                    Icons.explore_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Keşfet",
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'derslerim',
              child: Row(
                children: [
                  const Icon(
                    Icons.play_lesson_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Derslerim",
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
          // Ana Ekranda Görünen Tıklanabilir Başlık Kısmı
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Keşfet",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.white54,
                size: 24,
              ), // OK İŞARETİ
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: ColorConstants.primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ScaleButton(
              onPressed: _showSettingsModal,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white12),
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 24),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Text(
              "Antrenmanlara Başla, $_athleteName 🔥",
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('userType', isEqualTo: 'coach')
                  .where('isApproved', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const Center(
                    child: CircularProgressIndicator(
                      color: ColorConstants.primaryColor,
                    ),
                  );
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                  return _buildEmptyState();

                List<Map<String, dynamic>> perfectMatches = [];
                List<Map<String, dynamic>> alternativeMatches = [];

                // EKRANI İKİYE BÖLME MANTIĞI
                for (var doc in snapshot.data!.docs) {
                  final coach = doc.data() as Map<String, dynamic>;
                  coach['uid'] = doc.id;
                  final lessonSport = coach['lessonSport'] ?? '';

                  if (_interestedSports.contains(lessonSport)) {
                    perfectMatches.add(coach);
                  } else {
                    alternativeMatches.add(coach);
                  }
                }

                // PERFECT MATCHES'İ ALGORİTMA PUANINA GÖRE BÜYÜKTEN KÜÇÜĞE SIRALA
                perfectMatches.sort(
                  (a, b) => _calculateMatchScore(
                    b,
                  ).compareTo(_calculateMatchScore(a)),
                );

                return ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  children: [
                    if (perfectMatches.isNotEmpty) ...[
                      Text(
                        "Sana En Uygun Eğitmenler",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...perfectMatches.map(
                        (coach) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildCoachCard(coach),
                        ),
                      ),
                    ],

                    if (alternativeMatches.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        "Farklı Deneyimler Arayanlara",
                        style: GoogleFonts.poppins(
                          color: Colors.white54,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...alternativeMatches.map(
                        (coach) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildCoachCard(coach),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- ANTRENÖR / DERS KARTI (Fiyat Eklenmiş Halde) ---
  // --- ANTRENÖR / DERS KARTI ---
  Widget _buildCoachCard(Map<String, dynamic> coachData) {
    final String name = coachData['name'] ?? '';
    final String surname = coachData['surname'] ?? '';
    final String fullName = "$name $surname".trim().isEmpty
        ? "İsimsiz Antrenör"
        : "$name $surname";
    final String? profileImageUrl = coachData['profileImageUrl'];
    final int hourlyRate = coachData['hourlyRate'] ?? 0;

    final String lessonSport = coachData['lessonSport'] ?? 'Genel Antrenman';
    final List<dynamic> daysList = coachData['availableDays'] ?? [];
    final List<dynamic> hoursList = coachData['availableHours'] ?? [];

    // HOCADAN DERS ALINMIŞ MI KONTROLÜ
    final bool isBooked = _bookedCoachIds.contains(coachData['uid']);

    return ScaleButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CoachDetailScreen(coachData: coachData),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isBooked
              ? Colors.green.withOpacity(0.05)
              : Colors.white.withOpacity(
                  0.05,
                ), // Alındıysa kart hafif yeşilimsi olur
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isBooked ? Colors.green.withOpacity(0.3) : Colors.white10,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white10,
                  backgroundImage: profileImageUrl != null
                      ? NetworkImage(profileImageUrl)
                      : null,
                  child: profileImageUrl == null
                      ? const Icon(Icons.person, color: Colors.white38)
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        coachData['coachCharacter'] ?? "Onaylı Eğitmen",
                        style: GoogleFonts.poppins(
                          color: ColorConstants.primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // SAĞ ÜST KÖŞE (ROZET VE FİYAT)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (isBooked)
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "✅ Alındı",
                          style: GoogleFonts.poppins(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    if (hourlyRate > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "$hourlyRate ₺ / Saat",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(color: Colors.white10, height: 1),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ColorConstants.primaryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.sports_gymnastics_rounded,
                    color: ColorConstants.primaryColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$lessonSport Dersi",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            color: Colors.white54,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              daysList.isEmpty
                                  ? "Gün belirtilmemiş"
                                  : daysList.join(', '),
                              style: GoogleFonts.poppins(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            color: Colors.white54,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              hoursList.isEmpty
                                  ? "Saat belirtilmemiş"
                                  : hoursList.join(', '),
                              style: GoogleFonts.poppins(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    /* Mevcut Kod */
    return const SizedBox();
  }
}
