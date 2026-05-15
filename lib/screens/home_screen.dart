/// lib/screens/home_screen.dart
///
/// Main shell screen for athletes (and unauthenticated guest users),
/// composed of five tabs:
///   0. Discover  — browse and search approved coaches.
///   1. Lessons   — the athlete's lesson history ([MyLessonsScreen]).
///   2. Messages  — conversations with coaches ([AthleteMessagesScreen]).
///   3. Profile   — profile editing ([EditProfileScreen]).
///   4. Settings  — app settings and sign-out.
// ignore_for_file: unused_field, unused_element, deprecated_member_use, prefer_final_fields

import 'dart:convert';
import 'package:http/http.dart' as http;
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
import 'athlete_messages_screen.dart';
import 'athlete_notifications_screen.dart';
import '../widgets/settings_menu_item.dart';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';

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

  // --- ÖĞRENCİ VERİLERİ ---
  String _athleteName = "Misafir Sporcu";
  String _athleteGoal = "";
  List<String> _interestedSports = [];
  String _preferredGender = "Farketmez";
  Map<String, dynamic> _athleteDayHoursMap =
      {}; // YENİ: Öğrencinin nokta atışı müsaitlikleri

  // --- ARAMA VE FİLTRELEME ---
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  bool _sortByCheapest = false;

  double _maxPrice = 3000;
  String? _filterDeliveryMode;
  String? _filterCharacter;
  String? _filterAvailability;

  String? _selectedCity;
  String? _selectedDistrict;
  List<dynamic> _citiesData = [];
  List<dynamic> _districtsData = [];
  bool _isLoadingLocation = false;

  final List<String> _characterList = [
    "Motivatör & Enerjik",
    "Disiplinli & Güç Odaklı",
    "Dinamik & Dayanıklılık Odaklı",
    "Sakin & Beden Farkındalığı",
    "Sert & Hedef Odaklı (Pro)",
  ];

  // --- YENİ: ARKA PLAN VERİ HARİTALARI (TÜM HOCALAR İÇİN) ---
  final Map<String, List<Map<String, dynamic>>> _allCoachRoutines = {};
  final Map<String, List<Map<String, dynamic>>> _allCoachActivities = {};

  @override
  void initState() {
    super.initState();
    if (!_isGuest) {
      _loadAthleteData();
    }
    _fetchCities();
    _preloadAllCoachesCalendarData(); // YENİ: Tüm hocaların takvimini önbelleğe al
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- 1. ARKA PLAN VERİ ÇEKİMİ ---
  // Uygulama açıldığında tüm onaylı hocaların takvimlerini çeker ve eşleştirme için hazırlar.
  Future<void> _preloadAllCoachesCalendarData() async {
    try {
      // Sadece müsaitlik yaratan (Özel veya Grup) ve kapatılmamış (isUnavailable: false) rutinleri çek
      final routinesSnap = await FirebaseFirestore.instance
          .collection('coach_routines')
          .where('isUnavailable', isEqualTo: false)
          .get();

      for (var doc in routinesSnap.docs) {
        final data = doc.data();
        String cId = data['coachId'];
        if (!_allCoachRoutines.containsKey(cId)) _allCoachRoutines[cId] = [];
        _allCoachRoutines[cId]!.add(data);
      }

      final activitiesSnap = await FirebaseFirestore.instance
          .collection('coach_manual_activities')
          .where('isUnavailable', isEqualTo: false)
          .get();

      for (var doc in activitiesSnap.docs) {
        final data = doc.data();
        String cId = data['coachId'];
        if (!_allCoachActivities.containsKey(cId))
          _allCoachActivities[cId] = [];
        _allCoachActivities[cId]!.add(data);
      }
    } catch (e) {
      debugPrint("Takvim verileri önyüklenirken hata: $e");
    }
  }

  // --- 2. ÖĞRENCİ VERİSİNİ ÇEKME ---
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
        _athleteDayHoursMap = data['dayHoursMap'] ?? {}; // YENİ EKLENDİ
      });
    }
  }

  // --- 3. AKILLI EŞLEŞTİRME ALGORİTMASI ---
  int _calculateMatchScore(Map<String, dynamic> coach) {
    if (_isGuest) return 0;
    int score = 0;
    String idealCoachCharacter = "";

    // 1. Hedef ve Karakter Uyum Puanı
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

    // 2. YENİ: Dinamik Takvim Eşleşmesi (En Önemlisi)
    String coachId = coach['uid'];
    List<Map<String, dynamic>> cRoutines = _allCoachRoutines[coachId] ?? [];

    if (_athleteDayHoursMap.isNotEmpty) {
      int timeScore = 0;

      // Öğrencinin seçtiği her bir günü ve saatleri kontrol et
      _athleteDayHoursMap.forEach((athleteDay, athHoursList) {
        List<dynamic> athHours = athHoursList as List<dynamic>;

        // Hocanın o gün için rutini var mı?
        var matchingRoutines = cRoutines.where(
          (r) => (r['days'] as List).contains(athleteDay),
        );
        for (var r in matchingRoutines) {
          if (athHours.contains(r['hour'])) {
            timeScore += 10; // Kesişen her saat için +10 puan!
          }
        }
      });
      score += timeScore;
    }

    return score;
  }

  // Filtre: Hoca şu an takvimde müsait slot barındırıyor mu?
  bool _isCoachAvailable(String coachUid) {
    return (_allCoachRoutines[coachUid]?.isNotEmpty ?? false) ||
        (_allCoachActivities[coachUid]?.isNotEmpty ?? false);
  }

  // --- API KONUM METOTLARI ---
  Future<void> _fetchCities() async {
    setState(() => _isLoadingLocation = true);
    try {
      final response = await http.get(
        Uri.parse('https://api.turkiyeapi.dev/v1/provinces?limit=100'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _citiesData = data['data'];
          _citiesData.sort(
            (a, b) => a['name'].toString().compareTo(b['name'].toString()),
          );
        });
      }
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _fetchDistricts(int provinceId) async {
    setState(() {
      _isLoadingLocation = true;
      _districtsData = [];
      _selectedDistrict = null;
    });
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.turkiyeapi.dev/v1/districts?provinceId=$provinceId&limit=1000',
        ),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _districtsData = data['data'];
          _districtsData.sort(
            (a, b) => a['name'].toString().compareTo(b['name'].toString()),
          );
        });
      }
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  // --- GELİŞMİŞ FİLTRELEME MODALI ---
  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom,
                  left: 24,
                  right: 24,
                  top: 24,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[700],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Detaylı Filtreleme",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                _maxPrice = 3000;
                                _filterDeliveryMode = null;
                                _filterCharacter = null;
                                _filterAvailability = null;
                                _selectedCity = null;
                                _selectedDistrict = null;
                              });
                              setState(() {});
                            },
                            child: Text(
                              "Temizle",
                              style: GoogleFonts.poppins(
                                color: Colors.redAccent,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Text(
                        "Maksimum Saatlik Ücret",
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      Slider(
                        value: _maxPrice,
                        min: 0,
                        max: 3000,
                        divisions: 30,
                        activeColor: ColorConstants.primaryColor,
                        inactiveColor: Colors.white10,
                        label: "${_maxPrice.toInt()} ₺",
                        onChanged: (val) =>
                            setModalState(() => _maxPrice = val),
                      ),
                      Center(
                        child: Text(
                          "${_maxPrice.toInt()} ₺",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                      Text(
                        "Çalışma Şekli",
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ['Online', 'Yüzyüze', 'Hibrit(İkisi de)'].map(
                          (mode) {
                            bool isSelected = _filterDeliveryMode == mode;
                            return ChoiceChip(
                              label: Text(mode),
                              selected: isSelected,
                              selectedColor: ColorConstants.primaryColor,
                              backgroundColor: Colors.white10,
                              labelStyle: GoogleFonts.poppins(
                                color: Colors.black,
                              ),
                              onSelected: (val) => setModalState(
                                () => _filterDeliveryMode = val ? mode : null,
                              ),
                            );
                          },
                        ).toList(),
                      ),

                      if (_filterDeliveryMode == 'Yüzyüze' ||
                          _filterDeliveryMode == 'Hibrit(İkisi de)') ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDropdown(
                                "İl",
                                _citiesData
                                    .map((c) => c['name'].toString())
                                    .toList(),
                                _selectedCity,
                                (val) {
                                  if (val != null) {
                                    setModalState(() {
                                      _selectedCity = val;
                                      _selectedDistrict = null;
                                    });
                                    final cityObj = _citiesData.firstWhere(
                                      (c) => c['name'] == val,
                                      orElse: () => null,
                                    );
                                    if (cityObj != null)
                                      _fetchDistricts(cityObj['id']);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDropdown(
                                "İlçe",
                                _districtsData
                                    .map((d) => d['name'].toString())
                                    .toList(),
                                _selectedDistrict,
                                (val) {
                                  if (val != null)
                                    setModalState(
                                      () => _selectedDistrict = val,
                                    );
                                },
                                disabled: _selectedCity == null,
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 16),
                      Text(
                        "Eğitmen Karakteri",
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _filterCharacter,
                            isExpanded: true,
                            dropdownColor: const Color(0xFF1E1E1E),
                            hint: Text(
                              "Farketmez",
                              style: GoogleFonts.poppins(color: Colors.white54),
                            ),
                            style: GoogleFonts.poppins(color: Colors.white),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text("Farketmez"),
                              ),
                              ..._characterList.map(
                                (c) =>
                                    DropdownMenuItem(value: c, child: Text(c)),
                              ),
                            ],
                            onChanged: (val) =>
                                setModalState(() => _filterCharacter = val),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                      Text(
                        "Müsaitlik Durumu",
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ['Tüm Eğitmenler', 'Müsait Olanlar'].map((
                          avail,
                        ) {
                          bool isSelected =
                              _filterAvailability == avail ||
                              (_filterAvailability == null &&
                                  avail == 'Tüm Eğitmenler');
                          return ChoiceChip(
                            label: Text(avail),
                            selected: isSelected,
                            selectedColor: ColorConstants.primaryColor,
                            backgroundColor: Colors.white10,
                            labelStyle: GoogleFonts.poppins(
                              color: Colors.black,
                            ),
                            onSelected: (val) => setModalState(
                              () => _filterAvailability = val ? avail : null,
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {}); // Ana ekranı filtrelerle tetikle
                            Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorConstants.primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            "Sonuçları Göster",
                            style: GoogleFonts.poppins(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDropdown(
    String label,
    List<String> items,
    String? selectedValue,
    ValueChanged<String?> onChanged, {
    bool disabled = false,
  }) {
    List<String> uniqueItems = items.toSet().toList();
    if (uniqueItems.isEmpty) uniqueItems.add("Seçenek Yok");
    String? safeValue = uniqueItems.contains(selectedValue)
        ? selectedValue
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(disabled ? 0.02 : 0.05),
            borderRadius: BorderRadius.circular(14),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: safeValue,
              isExpanded: true,
              dropdownColor: const Color(0xFF1E1E1E),
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.white54,
                size: 18,
              ),
              style: GoogleFonts.poppins(color: Colors.white),
              items: uniqueItems
                  .map(
                    (i) => DropdownMenuItem(
                      value: i,
                      child: Text(i, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: disabled ? null : onChanged,
            ),
          ),
        ),
      ],
    );
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
          onTap: (index) => setState(() => _selectedIndex = index),
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
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                    ),
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
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AthleteNotificationsScreen(),
                    ),
                  ),
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
                        onChanged: (val) =>
                            setState(() => _searchQuery = val.toLowerCase()),
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
                  const SizedBox(width: 12),
                  ScaleButton(
                    onPressed: _showFilterModal,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: ColorConstants.primaryColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: ColorConstants.primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.tune_rounded,
                        color: Colors.black,
                        size: 22,
                      ),
                    ),
                  ),
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
                  if (snapshot.connectionState == ConnectionState.waiting)
                    return const Center(
                      child: CircularProgressIndicator(
                        color: ColorConstants.primaryColor,
                      ),
                    );
                  if (snapshot.hasError)
                    return Center(
                      child: Text(
                        "Hata oluştu.",
                        style: GoogleFonts.poppins(color: Colors.white54),
                      ),
                    );
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                    return const SizedBox();

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
                    final dist = coach['location'] != null
                        ? (coach['location']['district'] ?? "")
                              .toString()
                              .toLowerCase()
                        : "";
                    final mode = coach['deliveryMode'] ?? "";
                    final char = coach['coachCharacter'] ?? "";
                    final price = coach['hourlyRate'] ?? 0;

                    bool matchesSearch =
                        _searchQuery.isEmpty ||
                        name.contains(_searchQuery) ||
                        sport.contains(_searchQuery) ||
                        city.contains(_searchQuery) ||
                        dist.contains(_searchQuery);
                    bool matchesPrice = price <= _maxPrice;

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

                    bool matchesLocation = true;
                    if ((_filterDeliveryMode == 'Yüzyüze' ||
                        _filterDeliveryMode == 'Hibrit(İkisi de)')) {
                      if (_selectedCity != null &&
                          coach['location']?['city'] != _selectedCity)
                        matchesLocation = false;
                      if (_selectedDistrict != null &&
                          coach['location']?['district'] != _selectedDistrict)
                        matchesLocation = false;
                    }

                    bool matchesChar =
                        _filterCharacter == null || char == _filterCharacter;

                    return matchesSearch &&
                        matchesPrice &&
                        matchesMode &&
                        matchesLocation &&
                        matchesChar;
                  }).toList();

                  if (filteredDocs.isEmpty) {
                    return Center(
                      child: Text(
                        "Aramanıza uygun eğitmen bulunamadı.",
                        style: GoogleFonts.poppins(color: Colors.white54),
                      ),
                    );
                  }

                  // Validasyonları geçip filtreleri atlayan hocalar
                  List<Map<String, dynamic>> validCoaches = [];
                  for (var doc in filteredDocs) {
                    final coach = doc.data() as Map<String, dynamic>;
                    coach['uid'] = doc.id;

                    if (_filterAvailability == 'Müsait Olanlar') {
                      if (!_isCoachAvailable(doc.id)) continue;
                    }
                    validCoaches.add(coach);
                  }

                  if (validCoaches.isEmpty) {
                    return Center(
                      child: Text(
                        "Şu an müsait olan eğitmen bulunamadı.",
                        style: GoogleFonts.poppins(color: Colors.white54),
                      ),
                    );
                  }

                  List<Map<String, dynamic>> perfectMatches = [];
                  List<Map<String, dynamic>> alternativeMatches = [];

                  for (var coach in validCoaches) {
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
                          height: 250,
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
                                  isHighMatch: !_isGuest,
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
                          height: 250,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.only(left: 24, right: 8),
                            itemCount: alternativeMatches.length,
                            itemBuilder: (ctx, i) => Padding(
                              padding: const EdgeInsets.only(right: 16),
                              child: SizedBox(
                                width: 290,
                                child: _buildCoachCard(
                                  alternativeMatches[i],
                                  isHighMatch: false,
                                ),
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
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                ),
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
              isDestructive: true,
              onTap: () async {
                await _authService.signOut();
                if (mounted)
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
              },
            ),
          if (_isGuest)
            SettingsMenuItem(
              icon: Icons.login,
              label: "Giriş Yap",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WelcomeScreen()),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCoachCard(
    Map<String, dynamic> coachData, {
    bool isHighMatch = false,
  }) {
    final String fullName =
        "${coachData['name'] ?? ''} ${coachData['surname'] ?? ''}"
            .trim()
            .isEmpty
        ? "İsimsiz Antrenör"
        : "${coachData['name']} ${coachData['surname']}";
    final String? profileImageUrl = coachData['profileImageUrl'];
    final int hourlyRate = coachData['hourlyRate'] ?? 0;

    String bio = coachData['bio'] ?? "Henüz biyografi eklenmemiş.";
    if (bio.length > 80) bio = "${bio.substring(0, 80)}...";

    final List<dynamic> specialties = coachData['specialties'] ?? [];
    String formattedSpecialties = specialties.isEmpty
        ? (coachData['lessonSport'] ?? 'Genel')
        : specialties.take(2).join(', ');
    if (specialties.length > 2)
      formattedSpecialties += " +${specialties.length - 2}";

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
                      ? CachedNetworkImageProvider(profileImageUrl)
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
                      Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: ColorConstants.primaryColor.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: ColorConstants.primaryColor.withOpacity(0.4),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          "Sana Uygun",
                          style: GoogleFonts.poppins(
                            color: ColorConstants.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 9,
                          ),
                        ),
                      ),
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
                          "Ort. $hourlyRate ₺",
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            formattedSpecialties,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            coachData['deliveryMode'] ?? 'Farketmez',
                            style: GoogleFonts.poppins(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        bio,
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 11,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
}
