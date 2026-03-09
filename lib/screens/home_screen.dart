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
  StreamSubscription<QuerySnapshot>? _allLessonsSubscription;
  List<String> _bookedCoachIds = [];
  Set<String> _anyoneBookedCoachIds = {};

  // --- ARAMA VE DETAYLI FİLTRELEME DEĞİŞKENLERİ ---
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  RangeValues _priceRange = const RangeValues(0, 3000);
  String? _filterDeliveryMode; // null: Hepsi, "Online", "Yüzyüze"
  bool _sortByCheapest = false;

  // YENİ FİLTRELER
  String? _filterSport;
  String? _filterGender;
  String? _filterCity;
  List<String> _filterDays = [];
  final List<String> _cities = [
    "Adana",
    "Adıyaman",
    "Afyonkarahisar",
    "Ağrı",
    "Aksaray",
    "Amasya",
    "Ankara",
    "Antalya",
    "Ardahan",
    "Artvin",
    "Aydın",
    "Balıkesir",
    "Bartın",
    "Batman",
    "Bayburt",
    "Bilecik",
    "Bingöl",
    "Bitlis",
    "Bolu",
    "Burdur",
    "Bursa",
    "Çanakkale",
    "Çankırı",
    "Çorum",
    "Denizli",
    "Diyarbakır",
    "Düzce",
    "Edirne",
    "Elazığ",
    "Erzincan",
    "Erzurum",
    "Eskişehir",
    "Gaziantep",
    "Giresun",
    "Gümüşhane",
    "Hakkâri",
    "Hatay",
    "Iğdır",
    "Isparta",
    "İstanbul",
    "İzmir",
    "Kahramanmaraş",
    "Karabük",
    "Karaman",
    "Kars",
    "Kastamonu",
    "Kayseri",
    "Kırıkkale",
    "Kırklareli",
    "Kırşehir",
    "Kilis",
    "Kocaeli",
    "Konya",
    "Kütahya",
    "Malatya",
    "Manisa",
    "Mardin",
    "Mersin",
    "Muğla",
    "Muş",
    "Nevşehir",
    "Niğde",
    "Ordu",
    "Osmaniye",
    "Rize",
    "Sakarya",
    "Samsun",
    "Siirt",
    "Sinop",
    "Sivas",
    "Şanlıurfa",
    "Şırnak",
    "Tekirdağ",
    "Tokat",
    "Trabzon",
    "Tunceli",
    "Uşak",
    "Van",
    "Yalova",
    "Yozgat",
    "Zonguldak",
  ];
  List<String> _filterHours = [];

  final List<String> _allSports = [
    "Fitness",
    "Pilates",
    "Yoga",
    "Yüzme",
    "Boks",
    "Kick Boks",
    "CrossFit",
    "Tenis",
    "Futbol",
    "Basketbol",
  ];
  final List<String> _allDays = [
    "Pazartesi",
    "Salı",
    "Çarşamba",
    "Perşembe",
    "Cuma",
    "Cumartesi",
    "Pazar",
  ];
  final List<String> _allHours = [
    "06:00 - 09:00",
    "09:00 - 12:00",
    "12:00 - 15:00",
    "15:00 - 18:00",
    "18:00 - 21:00",
    "21:00 - 00:00",
  ];

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

    _allLessonsSubscription = FirebaseFirestore.instance
        .collection('lessons')
        .snapshots()
        .listen((snapshot) {
          if (mounted) {
            setState(() {
              _anyoneBookedCoachIds = snapshot.docs
                  .where(
                    (doc) =>
                        doc['status'] == 'pending' ||
                        doc['status'] == 'approved',
                  )
                  .map((doc) => doc['coachId'] as String)
                  .toSet();
            });
          }
        });
  }

  @override
  void dispose() {
    _lessonsSubscription?.cancel();
    _allLessonsSubscription?.cancel();
    _searchController.dispose();
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

  int _calculateMatchScore(Map<String, dynamic> coach) {
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
    if (_preferredGender != "Farketmez" && coach['gender'] == _preferredGender)
      score += 10;

    List<String> coachDays = List<String>.from(coach['availableDays'] ?? []);
    score += coachDays.where((d) => _availableDays.contains(d)).length;

    List<String> coachHours = List<String>.from(coach['availableHours'] ?? []);
    score += coachHours.where((h) => _availableHours.contains(h)).length;

    return score;
  }

  int _calculateMaxScore() => 37;

  void _signOut() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  // --- KAPSAMLI FİLTRELEME MODALI (Bottom Sheet) ---
  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors
          .transparent, // Arka planı Draggable yapısına uyması için şeffaf yaptık
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.85, // Ekranın %85'ini kaplar
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (_, controller) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: ListView(
                    controller: controller, // Kaydırılabilir olması için
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
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Detaylı Arama",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                _priceRange = const RangeValues(0, 3000);
                                _filterDeliveryMode = null;
                                _filterSport = null;
                                _filterGender = null;
                                _filterCity = "";
                                _filterDays.clear();
                                _filterHours.clear();
                              });
                            },
                            child: Text(
                              "Temizle",
                              style: GoogleFonts.poppins(
                                color: Colors.redAccent,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // 1. DERS ŞEKLİ
                      Text(
                        "Ders Şekli",
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing:
                            10, // Taşma hatasını önlemek için Wrap kullanıldı
                        children: ["Hepsi", "Online", "Yüzyüze"].map((mode) {
                          final isSelected =
                              (_filterDeliveryMode ?? "Hepsi") == mode;
                          return ChoiceChip(
                            label: Text(mode),
                            selected: isSelected,
                            selectedColor: ColorConstants.primaryColor,
                            backgroundColor: Colors.white10,
                            labelStyle: GoogleFonts.poppins(
                              color: Colors.black, // Yazı her zaman simsiyah
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                            ),
                            onSelected: (val) {
                              setModalState(
                                () => _filterDeliveryMode = mode == "Hepsi"
                                    ? null
                                    : mode,
                              );
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // 2. KONUM (Sadece Yüzyüze veya Hepsi seçiliyse göster)
                      // 2. KONUM (Sadece Yüzyüze veya Hepsi seçiliyse göster)
                      if (_filterDeliveryMode == null ||
                          _filterDeliveryMode == "Yüzyüze") ...[
                        Text(
                          "Konum (Şehir)",
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: _filterCity,
                          dropdownColor: const Color(0xFF1E1E1E),
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Colors.white54,
                          ),
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: "Şehir Seçin",
                            hintStyle: GoogleFonts.poppins(
                              color: Colors.white54,
                            ),
                            filled: true,
                            fillColor: Colors.white10,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          items: _cities
                              .map(
                                (c) =>
                                    DropdownMenuItem(value: c, child: Text(c)),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setModalState(() => _filterCity = val),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // 3. BRANŞ
                      Text(
                        "Branş Seçimi",
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _allSports.map((sport) {
                          final isSelected = _filterSport == sport;
                          return ChoiceChip(
                            label: Text(sport),
                            selected: isSelected,
                            selectedColor: ColorConstants.primaryColor,
                            backgroundColor: Colors.white10,
                            labelStyle: GoogleFonts.poppins(
                              color: Colors.black, // Yazı her zaman simsiyah
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                            ),
                            onSelected: (val) => setModalState(
                              () => _filterSport = val ? sport : null,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // 4. CİNSİYET
                      Text(
                        "Eğitmen Cinsiyeti",
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ["Farketmez", "Erkek", "Kadın"].map((gender) {
                          final isSelected =
                              (_filterGender ?? "Farketmez") == gender;
                          return ChoiceChip(
                            label: Text(gender),
                            selected: isSelected,
                            selectedColor: ColorConstants.primaryColor,
                            backgroundColor: Colors.white10,
                            labelStyle: GoogleFonts.poppins(
                              color: Colors.black, // Yazı her zaman simsiyah
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                            ),
                            onSelected: (val) => setModalState(
                              () => _filterGender = gender == "Farketmez"
                                  ? null
                                  : gender,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // 5. MÜSAİTLİK GÜNLERİ
                      Text(
                        "Uygun Günler",
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _allDays.map((day) {
                          final isSelected = _filterDays.contains(day);
                          return ChoiceChip(
                            label: Text(day),
                            selected: isSelected,
                            selectedColor: ColorConstants.primaryColor,
                            backgroundColor: Colors.white10,
                            labelStyle: GoogleFonts.poppins(
                              color: Colors.black, // Yazı her zaman simsiyah
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                            ),
                            onSelected: (val) => setModalState(
                              () => val
                                  ? _filterDays.add(day)
                                  : _filterDays.remove(day),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // 6. MÜSAİTLİK SAATLERİ
                      Text(
                        "Uygun Saatler",
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _allHours.map((hour) {
                          final isSelected = _filterHours.contains(hour);
                          return ChoiceChip(
                            label: Text(hour),
                            selected: isSelected,
                            selectedColor: ColorConstants.primaryColor,
                            backgroundColor: Colors.white10,
                            labelStyle: GoogleFonts.poppins(
                              color: Colors.black, // Yazı her zaman simsiyah
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                            ),
                            onSelected: (val) => setModalState(
                              () => val
                                  ? _filterHours.add(hour)
                                  : _filterHours.remove(hour),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // 7. FİYAT ARALIĞI
                      Text(
                        "Saatlik Ücret Aralığı",
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      RangeSlider(
                        values: _priceRange,
                        min: 0,
                        max: 3000,
                        divisions: 30,
                        activeColor: ColorConstants.primaryColor,
                        inactiveColor: Colors.white10,
                        labels: RangeLabels(
                          "${_priceRange.start.round()} ₺",
                          "${_priceRange.end.round()} ₺",
                        ),
                        onChanged: (val) =>
                            setModalState(() => _priceRange = val),
                      ),

                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(
                              () {},
                            ); // Modal kapanırken ana ekranı güncelle
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorConstants.primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            "Filtreleri Uygula",
                            style: GoogleFonts.poppins(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.6),
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: false,
        titleSpacing: 24,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1A1A1A), Colors.transparent],
            ),
          ),
        ),
        title: PopupMenuButton<String>(
          color: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          offset: const Offset(0, 45),
          onSelected: (value) {
            if (value == 'derslerim') {
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
              ),
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

            // SELAMLAMA METNİ GERİ GELDİ 🔥
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                "Antrenmanlara Başla, $_athleteName 🔥",
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),

            // ARAMA ÇUBUĞU VE FİLTRE BUTONU
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

            // HIZLI FİLTRE ÇİPLERİ (Yazılar siyah yapıldı, kontrast artırıldı)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  _buildQuickChip(
                    "Online",
                    _filterDeliveryMode == "Online",
                    () {
                      setState(() => _filterDeliveryMode = "Online");
                    },
                  ),
                  _buildQuickChip(
                    "Yüzyüze",
                    _filterDeliveryMode == "Yüzyüze",
                    () {
                      setState(() => _filterDeliveryMode = "Yüzyüze");
                    },
                  ),
                  _buildQuickChip("En Ucuz", _sortByCheapest, () {
                    setState(() => _sortByCheapest = !_sortByCheapest);
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
                  if (snapshot.connectionState == ConnectionState.waiting)
                    return const Center(
                      child: CircularProgressIndicator(
                        color: ColorConstants.primaryColor,
                      ),
                    );
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                    return _buildEmptyState();

                  // KAPSAMLI FİLTRELEME MANTIĞI
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
                    final price = coach['hourlyRate'] ?? 0;
                    final mode = coach['deliveryMode'] ?? "";
                    final gender = coach['gender'] ?? "";
                    final List<dynamic> days = coach['availableDays'] ?? [];
                    final List<dynamic> hours = coach['availableHours'] ?? [];

                    // 1. Arama Çubuğu (Kelime eşleşmesi)
                    bool matchesSearch =
                        _searchQuery.isEmpty ||
                        name.contains(_searchQuery) ||
                        sport.contains(_searchQuery) ||
                        city.contains(_searchQuery);

                    // 2. Fiyat Kontrolü
                    bool matchesPrice =
                        price >= _priceRange.start && price <= _priceRange.end;

                    // 3. Ders Şekli (Hibrit uyumlu)
                    bool matchesMode = true;
                    if (_filterDeliveryMode != null) {
                      if (_filterDeliveryMode == "Online") {
                        matchesMode =
                            mode == "Online" || mode == "Hibrit(İkisi de)";
                      } else if (_filterDeliveryMode == "Yüzyüze") {
                        matchesMode =
                            mode == "Yüzyüze" || mode == "Hibrit(İkisi de)";
                      }
                    }

                    // 4. Branş Kontrolü
                    bool matchesSport =
                        _filterSport == null ||
                        sport == _filterSport!.toLowerCase();

                    // 5. Cinsiyet Kontrolü
                    bool matchesGender =
                        _filterGender == null || gender == _filterGender;

                    // 6. Şehir Kontrolü (Dropdown'dan seçildiyse)
                    bool matchesCity =
                        _filterCity == null ||
                        city == _filterCity!.toLowerCase();
                    // 7. Gün ve Saat Kontrolü (Seçili günlerden/saatlerden EN AZ BİRİ uyuşuyorsa gösterir)
                    bool matchesDays =
                        _filterDays.isEmpty ||
                        _filterDays.any((d) => days.contains(d));
                    bool matchesHours =
                        _filterHours.isEmpty ||
                        _filterHours.any((h) => hours.contains(h));

                    return matchesSearch &&
                        matchesPrice &&
                        matchesMode &&
                        matchesSport &&
                        matchesGender &&
                        matchesCity &&
                        matchesDays &&
                        matchesHours;
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

                  // İLGİ ALANINA GÖRE AYIR
                  for (var doc in filteredDocs) {
                    final coach = doc.data() as Map<String, dynamic>;
                    coach['uid'] = doc.id;
                    final lessonSport = coach['lessonSport'] ?? '';

                    if (_interestedSports.contains(lessonSport)) {
                      perfectMatches.add(coach);
                    } else {
                      alternativeMatches.add(coach);
                    }
                  }

                  // SIRALAMA
                  if (_sortByCheapest) {
                    perfectMatches.sort(
                      (a, b) => (a['hourlyRate'] ?? 0).compareTo(
                        b['hourlyRate'] ?? 0,
                      ),
                    );
                    alternativeMatches.sort(
                      (a, b) => (a['hourlyRate'] ?? 0).compareTo(
                        b['hourlyRate'] ?? 0,
                      ),
                    );
                  } else {
                    perfectMatches.sort(
                      (a, b) => _calculateMatchScore(
                        b,
                      ).compareTo(_calculateMatchScore(a)),
                    );
                  }

                  final int maxScore = _calculateMaxScore();

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
                            itemBuilder: (ctx, i) {
                              final coach = perfectMatches[i];
                              final score = _calculateMatchScore(coach);
                              final matchPct = maxScore > 0
                                  ? (score / maxScore * 100).round()
                                  : 0;
                              return Padding(
                                padding: const EdgeInsets.only(right: 16),
                                child: SizedBox(
                                  width: 290,
                                  child: _buildCoachCard(
                                    coach,
                                    isHorizontal: true,
                                    matchPercent: matchPct,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      if (alternativeMatches.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                          child: Text(
                            "Farklı Deneyimler Arayanlara",
                            style: GoogleFonts.poppins(
                              color: Colors.white54,
                              fontSize: 16,
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
                            itemBuilder: (ctx, i) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 16),
                                child: SizedBox(
                                  width: 290,
                                  child: _buildCoachCard(alternativeMatches[i]),
                                ),
                              );
                            },
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

  // --- HIZLI FİLTRE ÇİPİ (RENK VE OKUNABİLİRLİK DÜZELTİLDİ) ---
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
                color: Colors.black, // YAZILAR ARTIK SİMSİYAH VE ÇOK NET!
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
        // Seçiliyse fosforlu yeşil, seçili değilse düz beyaz
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

  // --- ANTRENÖR / DERS KARTI ---
  Widget _buildCoachCard(
    Map<String, dynamic> coachData, {
    bool isHorizontal = false,
    int matchPercent = 0,
  }) {
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
    final String coachUid = coachData['uid'] ?? '';

    final bool isMyBooking = _bookedCoachIds.contains(coachUid);
    final bool isAnyoneBooked =
        _anyoneBookedCoachIds.contains(coachUid) && !isMyBooking;
    final bool isHighMatch = matchPercent >= 20;

    Color borderColor = Colors.white10;
    Color bgColor = Colors.white.withOpacity(0.05);
    List<BoxShadow> shadows = [];

    if (isMyBooking) {
      borderColor = Colors.green.withOpacity(0.3);
      bgColor = Colors.green.withOpacity(0.05);
    } else if (isAnyoneBooked) {
      borderColor = Colors.redAccent.withOpacity(0.6);
      bgColor = Colors.redAccent.withOpacity(0.04);
    } else if (isHighMatch) {
      borderColor = ColorConstants.primaryColor.withOpacity(0.5);
      bgColor = ColorConstants.primaryColor.withOpacity(0.04);
      shadows = [
        BoxShadow(
          color: ColorConstants.primaryColor.withOpacity(0.25),
          blurRadius: 18,
          spreadRadius: 2,
        ),
      ];
    }

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
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: borderColor,
            width: isAnyoneBooked ? 1.2 : 1,
          ),
          boxShadow: shadows,
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
                    if (isMyBooking)
                      _badge("✅ Alındı", Colors.green)
                    else if (isAnyoneBooked)
                      _badge("Ders Alındı", Colors.redAccent)
                    else if (isHighMatch)
                      _badge(
                        "Kriterlerine Çok Uygun 🔥",
                        ColorConstants.primaryColor,
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

  Widget _buildEmptyState() {
    return const SizedBox();
  }
}
