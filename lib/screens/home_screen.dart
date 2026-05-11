/// lib/screens/home_screen.dart
///
/// Main shell screen for athletes (and unauthenticated guest users),
/// composed of five tabs:
///   0. Discover  — browse and search approved coaches.
///   1. Lessons   — the athlete's lesson history ([MyLessonsScreen]).
///   2. Messages  — conversations with coaches ([AthleteMessagesScreen]).
///   3. Profile   — profile editing ([EditProfileScreen]).
///   4. Settings  — app settings and sign-out.
///
/// Guest users (not signed in) can browse coaches but see prompts to
/// register when they try to access lessons or messages.
// ignore_for_file: unused_field, unused_element, deprecated_member_use, prefer_final_fields

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants/color_constants.dart';
import '../services/auth_service.dart';
import '../widgets/scale_button.dart';
import 'welcome_screen.dart';
import 'login_screen.dart';
import 'edit_profile_screen.dart';
import 'my_lessons_screen.dart';
import 'coach_detail_screen.dart';
import 'athlete_messages_screen.dart'; // YENİ EKLENDİ
import 'athlete_notifications_screen.dart';
import '../widgets/settings_menu_item.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  bool get _isGuest => _currentUser == null;

  int _selectedIndex = 0;

  String _athleteName = "Misafir Sporcu";
  String _athleteGoal = "";
  List<String> _interestedSports = [];
  String _preferredGender = "Farketmez";
  List<String> _availableDays = [];
  List<String> _availableHours = [];

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  RangeValues _priceRange = const RangeValues(0, 3000);
  String? _filterDeliveryMode;
  bool _sortByCheapest = false;

  @override
  void initState() {
    super.initState();
    if (!_isGuest) {
      _loadAthleteData();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAthleteData() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser!.uid)
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

  int _calculateMatchScore(Map<String, dynamic> coach) {
    if (_isGuest) return 0;
    int score = 0;
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
    if (coach['coachCharacter'] == idealCoachCharacter) score += 20;
    if (_preferredGender != "Farketmez" &&
        coach['gender'] == _preferredGender) {
      score += 10;
    }

    Map<String, dynamic>? dayHoursMap = coach['dayHoursMap'];
    if (dayHoursMap != null) {
      int timeScore = 0;
      for (String athDay in _availableDays) {
        if (dayHoursMap.containsKey(athDay)) {
          List<dynamic> coachHoursForDay = dayHoursMap[athDay] ?? [];
          for (String athHour in _availableHours) {
            if (coachHoursForDay.contains(athHour)) {
              timeScore += 5;
            }
          }
        }
      }
      score += timeScore;
    } else {
      List<String> coachDays = List<String>.from(coach['availableDays'] ?? []);
      score += coachDays.where((d) => _availableDays.contains(d)).length;
      List<String> coachHours = List<String>.from(
        coach['availableHours'] ?? [],
      );
      score += coachHours.where((h) => _availableHours.contains(h)).length;
    }

    return score;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildDiscoverTab(),
          const MyLessonsScreen(),
          // YENİ: MİSAFİR DEĞİLSE GERÇEK MESAJLAR EKRANINI GÖSTER
          _isGuest
              ? _buildGuestTab(
                  "Mesajlarım",
                  "Hocalarla iletişime geçip derslerinize başlamak için hemen kayıt ol.",
                  Icons.chat_bubble_outline_rounded,
                )
              : const AthleteMessagesScreen(),
          const EditProfileScreen(),
          _buildSettingsTab(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white10, width: 1)),
        ),
        child: BottomNavigationBar(
          backgroundColor: const Color(0xFF121212),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: ColorConstants.primaryColor,
          unselectedItemColor: Colors.white54,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          selectedLabelStyle: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: GoogleFonts.poppins(fontSize: 10),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore),
              label: "Keşfet",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.play_lesson_outlined),
              activeIcon: Icon(Icons.play_lesson),
              label: "Derslerim",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: "Mesajlar",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: "Profil",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: "Ayarlar",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoverTab() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.6),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          "Keşfet",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          _isGuest
              ? Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const WelcomeScreen(),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: ColorConstants.primaryColor.withOpacity(
                        0.15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: ColorConstants.primaryColor.withOpacity(0.5),
                        ),
                      ),
                    ),
                    child: Text(
                      "Kayıt Ol / Giriş Yap",
                      style: GoogleFonts.poppins(
                        color: ColorConstants.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                )
              : ScaleButton(
                  onPressed: () {
                    // YENİ: BİLDİRİMLER EKRANINA GİT
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AthleteNotificationsScreen(),
                      ),
                    );
                  },
                  child: Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(right: 16),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white12),
                        ),
                        child: const Icon(
                          Icons.notifications_none_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      // YENİ: OKUNMAMIŞ BİLDİRİM VARSA KIRMIZI NOKTA GÖSTER
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(_currentUser!.uid)
                            .collection('notifications')
                            .where('isRead', isEqualTo: false)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData &&
                              snapshot.data!.docs.isNotEmpty) {
                            return Positioned(
                              right: 18,
                              top: 2,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.black,
                                    width: 2,
                                  ),
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                ),
        ],
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1C1C1C), Color(0xFF0A0A0A)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: MediaQuery.of(context).padding.top + kToolbarHeight + 8,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _isGuest
                    ? "CoachApp'e Hoş Geldin"
                    : "Antrenmanlara Başla, $_athleteName",
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val.toLowerCase();
                          });
                        },
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: "Eğitmen, branş veya şehir ara...",
                          hintStyle: GoogleFonts.poppins(color: Colors.white38),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: Colors.white38,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  _buildQuickChip(
                    "Online",
                    _filterDeliveryMode == "Online",
                    () {
                      setState(() {
                        _filterDeliveryMode = "Online";
                      });
                    },
                  ),
                  _buildQuickChip(
                    "Yüzyüze",
                    _filterDeliveryMode == "Yüzyüze",
                    () {
                      setState(() {
                        _filterDeliveryMode = "Yüzyüze";
                      });
                    },
                  ),
                  _buildQuickChip("En Ucuz", _sortByCheapest, () {
                    setState(() {
                      _sortByCheapest = !_sortByCheapest;
                    });
                  }, icon: Icons.local_offer_rounded),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('userType', isEqualTo: 'coach')
                    .where('isApproved', isEqualTo: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: ColorConstants.primaryColor,
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        "Hata oluştu. Firebase kurallarını kontrol edin.",
                        style: GoogleFonts.poppins(color: Colors.white54),
                      ),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const SizedBox();
                  }

                  final filteredDocs = snapshot.data!.docs.where((doc) {
                    final coach = doc.data() as Map<String, dynamic>;
                    final name = "${coach['name']} ${coach['surname']}"
                        .toLowerCase();
                    final sport = (coach['lessonSport'] ?? "")
                        .toString()
                        .toLowerCase();
                    final city = coach['location'] != null
                        ? (coach['location']['city'] ?? "")
                              .toString()
                              .toLowerCase()
                        : "";
                    final mode = coach['deliveryMode'] ?? "";

                    bool matchesSearch =
                        _searchQuery.isEmpty ||
                        name.contains(_searchQuery) ||
                        sport.contains(_searchQuery) ||
                        city.contains(_searchQuery);
                    bool matchesMode = true;
                    if (_filterDeliveryMode != null) {
                      matchesMode =
                          (_filterDeliveryMode == "Online" &&
                              (mode == "Online" ||
                                  mode == "Hibrit(İkisi de)")) ||
                          (_filterDeliveryMode == "Yüzyüze" &&
                              (mode == "Yüzyüze" ||
                                  mode == "Hibrit(İkisi de)"));
                    }
                    return matchesSearch && matchesMode;
                  }).toList();

                  if (filteredDocs.isEmpty) {
                    return Center(
                      child: Text(
                        "Kriterlerine uygun eğitmen bulunamadı.",
                        style: GoogleFonts.poppins(color: Colors.white54),
                      ),
                    );
                  }

                  List<Map<String, dynamic>> perfectMatches = [];
                  List<Map<String, dynamic>> alternativeMatches = [];

                  for (var doc in filteredDocs) {
                    final coach = doc.data() as Map<String, dynamic>;
                    coach['uid'] = doc.id;
                    if (_isGuest || _interestedSports.isEmpty) {
                      alternativeMatches.add(coach);
                    } else {
                      final lessonSport = coach['lessonSport'] ?? '';
                      if (_interestedSports.contains(lessonSport)) {
                        perfectMatches.add(coach);
                      } else {
                        alternativeMatches.add(coach);
                      }
                    }
                  }

                  if (!_isGuest && !_sortByCheapest) {
                    perfectMatches.sort(
                      (a, b) => _calculateMatchScore(
                        b,
                      ).compareTo(_calculateMatchScore(a)),
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      if (perfectMatches.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                          child: Text(
                            "Sana En Uygun Eğitmenler",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 260,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.only(left: 24, right: 8),
                            itemCount: perfectMatches.length,
                            itemBuilder: (ctx, i) => Padding(
                              padding: const EdgeInsets.only(right: 16),
                              child: SizedBox(
                                width: 290,
                                child: _buildCoachCard(
                                  perfectMatches[i],
                                  isHorizontal: true,
                                  matchPercent: _isGuest ? 0 : 50,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (alternativeMatches.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                          child: Text(
                            _isGuest ? "Tüm Eğitmenler" : "Farklı Deneyimler",
                            style: GoogleFonts.poppins(
                              color: _isGuest ? Colors.white : Colors.white54,
                              fontSize: _isGuest ? 18 : 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 260,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.only(left: 24, right: 8),
                            itemCount: alternativeMatches.length,
                            itemBuilder: (ctx, i) => Padding(
                              padding: const EdgeInsets.only(right: 16),
                              child: SizedBox(
                                width: 290,
                                child: _buildCoachCard(alternativeMatches[i]),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestTab(String title, String message, IconData icon) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: ColorConstants.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 60, color: ColorConstants.primaryColor),
              ),
              const SizedBox(height: 24),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorConstants.primaryColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  "Kayıt Ol / Giriş Yap",
                  style: GoogleFonts.poppins(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the Settings tab.
  ///
  /// Authenticated users see a "Log Out" item; guests see "Log In".
  Widget _buildSettingsTab() {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          "Ayarlar",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        children: [
          SettingsMenuItem(
            icon: Icons.settings_outlined,
            label: "Uygulama Ayarları",
            onTap: () {},
          ),
          SettingsMenuItem(
            icon: Icons.privacy_tip_outlined,
            label: "Gizlilik Politikası",
            onTap: () {},
          ),
          SettingsMenuItem(
            icon: Icons.help_outline,
            label: "Yardım & Destek",
            onTap: () {},
          ),
          const Divider(color: Colors.white10, height: 30),
          if (!_isGuest)
            SettingsMenuItem(
              icon: Icons.logout,
              label: "Çıkış Yap",
              onTap: () async {
                await _authService.signOut();
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
              isDestructive: true,
            ),
          if (_isGuest)
            SettingsMenuItem(
              icon: Icons.login,
              label: "Giriş Yap",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                );
              },
            ),
        ],
      ),
    );
  }

  // _buildPlaceholderTab and _buildMenuItem have been removed.
  // Use the shared SettingsMenuItem widget for settings list items.

  Widget _buildQuickChip(
    String label,
    bool isSelected,
    VoidCallback onTap, {
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ActionChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: Colors.black),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
        backgroundColor: isSelected
            ? ColorConstants.primaryColor
            : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide.none,
        ),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildCoachCard(
    Map<String, dynamic> coachData, {
    bool isHorizontal = false,
    int matchPercent = 0,
  }) {
    final String fullName =
        "${coachData['name'] ?? ''} ${coachData['surname'] ?? ''}"
            .trim()
            .isEmpty
        ? "İsimsiz Antrenör"
        : "${coachData['name']} ${coachData['surname']}";
    final String? profileImageUrl = coachData['profileImageUrl'];
    final int hourlyRate = coachData['hourlyRate'] ?? 0;
    final String lessonSport = coachData['lessonSport'] ?? 'Genel Antrenman';
    final List<dynamic> daysList = coachData['availableDays'] ?? [];
    final List<dynamic> hoursList = coachData['availableHours'] ?? [];

    final bool isHighMatch = matchPercent >= 20;

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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isHighMatch
              ? ColorConstants.primaryColor.withOpacity(0.04)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isHighMatch
                ? ColorConstants.primaryColor.withOpacity(0.5)
                : Colors.white10,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white10,
                  backgroundImage: profileImageUrl != null
                      ? NetworkImage(profileImageUrl)
                      : null,
                  child: profileImageUrl == null
                      ? const Icon(Icons.person, color: Colors.white38)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        coachData['coachCharacter'] ?? "Onaylı Eğitmen",
                        style: GoogleFonts.poppins(
                          color: ColorConstants.primaryColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (isHighMatch)
                      _badge("Kriterlerine Uygun", ColorConstants.primaryColor),
                    if (hourlyRate > 0) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "$hourlyRate ₺ / Sa",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: Colors.white10, height: 1),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: ColorConstants.primaryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.sports_gymnastics_rounded,
                    color: ColorConstants.primaryColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$lessonSport Dersi",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            color: Colors.white54,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              daysList.isEmpty
                                  ? "Gün belirtilmemiş"
                                  : daysList.join(', '),
                              style: GoogleFonts.poppins(
                                color: Colors.white54,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            color: Colors.white54,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              hoursList.isEmpty
                                  ? "Saat belirtilmemiş"
                                  : hoursList.join(', '),
                              style: GoogleFonts.poppins(
                                color: Colors.white54,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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

  Widget _badge(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4), width: 0.8),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 9,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
