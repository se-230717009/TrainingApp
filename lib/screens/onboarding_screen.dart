import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants/color_constants.dart';
import '../services/auth_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/scale_button.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final AuthService _authService = AuthService();
  int _currentIndex = 0;
  bool _isLoading = false;

  // --- VERİLER ---
  String? _selectedGoal;
  List<String> _selectedSports = [];
  String? _coachingType;
  String? _gender;
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  String? _experienceLevel;

  // YENİ EKLENEN TERCİHLER
  String? _preferredCoachGender;
  List<String> _selectedDays = [];
  List<String> _selectedHours = [];

  // FİYAT TAHMİNİ İÇİN
  int _minPrice = 0;
  int _maxPrice = 0;

  final List<String> _daysList = [
    "Pazartesi",
    "Salı",
    "Çarşamba",
    "Perşembe",
    "Cuma",
    "Cumartesi",
    "Pazar",
  ];
  final List<String> _hoursList = [
    "06:00 - 09:00",
    "09:00 - 12:00",
    "12:00 - 15:00",
    "15:00 - 18:00",
    "18:00 - 21:00",
    "21:00 - 00:00",
  ];
  final List<String> _goals = [
    "Kilo Vermek",
    "Kas Kazanmak",
    "Kondisyon",
    "Esneklik",
    "Yarışmaya Hazırlanmak",
  ];
  final List<String> _sports = [
    "Fitness",
    "Pilates",
    "Yoga",
    "Yüzme",
    "Futbol",
    "Basketbol",
    "Boks",
    "Kick Boks",
    "CrossFit",
    "Tenis",
  ];
  final List<String> _experienceLevels = [
    "Yeni Başlayan",
    "Orta Seviye",
    "İleri Seviye",
  ];

  // SEÇİLEN SPORLARA GÖRE VERİTABANINDAN FİYAT HESAPLAMA
  Future<void> _calculateEstimatedPrice() async {
    if (_selectedSports.isEmpty) {
      setState(() {
        _minPrice = 0;
        _maxPrice = 0;
      });
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('userType', isEqualTo: 'coach')
          .where('lessonSport', whereIn: _selectedSports)
          .get();

      if (snapshot.docs.isNotEmpty) {
        List<int> prices = snapshot.docs
            .map((d) => (d.data()['hourlyRate'] ?? 0) as int)
            .where((p) => p > 0)
            .toList();
        if (prices.isNotEmpty) {
          prices.sort();
          setState(() {
            _minPrice = prices.first;
            _maxPrice = prices.last;
          });
          return;
        }
      }
      // Antrenör yoksa standart piyasa fiyatı göster
      setState(() {
        _minPrice = 400;
        _maxPrice = 1500;
      });
    } catch (e) {
      setState(() {
        _minPrice = 400;
        _maxPrice = 1500;
      });
    }
  }

  void _nextPage() {
    // Validasyonları kısa tutuyorum, mevcut yapınla aynı
    if (_currentIndex == 0 && _selectedGoal == null)
      return _showError("Hedef seçin.");
    if (_currentIndex == 1 && _selectedSports.isEmpty)
      return _showError("Branş seçin.");
    if (_currentIndex == 2 && _coachingType == null)
      return _showError("Çalışma tipi seçin.");
    if (_currentIndex == 3 && (_gender == null || _ageController.text.isEmpty))
      return _showError("Bilgileri girin.");
    if (_currentIndex == 4 && _experienceLevel == null)
      return _showError("Deneyim seçin.");
    if (_currentIndex == 5 &&
        (_preferredCoachGender == null || _selectedDays.isEmpty))
      return _showError("Müsaitlik ve antrenör tercihini yapın.");

    if (_currentIndex < 5) {
      // 6 Adım oldu
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  void _finishOnboarding() async {
    setState(() => _isLoading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await _authService.updateUserProfile(
        uid: uid,
        data: {
          'goal': _selectedGoal,
          'interestedSports': _selectedSports,
          'coachingType': _coachingType,
          'gender': _gender,
          'age': _ageController.text,
          'height': _heightController.text,
          'weight': _weightController.text,
          'experienceLevel': _experienceLevel,
          'preferredCoachGender': _preferredCoachGender,
          'availableDays': _selectedDays,
          'availableHours': _selectedHours, // YENİ EKLENENLER
          'isOnboardingCompleted': true,
        },
      );
      if (mounted)
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
    } catch (e) {
      _showError("Hata: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color.fromARGB(255, 44, 43, 43), Color(0xFF0A0A0A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // FİYAT TAHMİNİ BARI (ARMUT TARZI)
                if (_minPrice > 0)
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 10,
                    ),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ColorConstants.primaryColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: ColorConstants.primaryColor.withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.insights_rounded,
                          color: ColorConstants.primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Ortalama Saatlik Ücret: $_minPrice ₺ - $_maxPrice ₺",
                          style: GoogleFonts.poppins(
                            color: ColorConstants.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                // İLERLEME ÇUBUĞU
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: (_currentIndex + 1) / 6,
                          backgroundColor: Colors.white10,
                          color: ColorConstants.primaryColor,
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Text(
                        "${_currentIndex + 1}/6",
                        style: GoogleFonts.poppins(
                          color: Colors.white54,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (index) =>
                        setState(() => _currentIndex = index),
                    children: [
                      _buildStep1Goal(),
                      _buildStep2Sports(),
                      _buildStep3CoachingType(),
                      _buildStep4Stats(),
                      _buildStep5Experience(),
                      _buildStep6Preferences(),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          color: ColorConstants.primaryColor,
                        )
                      : CustomButton(
                          text: _currentIndex == 5 ? "Tamamla" : "Devam Et",
                          onPressed: _nextPage,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS (Mevcutlar aynen kalıp 6. Adım eklendi) ---
  Widget _buildStep1Goal() {
    /* Mevcut kodunuzla aynı */
    return _buildStepContainer(
      title: "Hedefin Ne?",
      subtitle: "Seni motive eden asıl sebep nedir?",
      child: ListView.separated(
        itemCount: _goals.length,
        separatorBuilder: (c, i) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final goal = _goals[index];
          return _buildSelectableCard(
            text: goal,
            isSelected: _selectedGoal == goal,
            onTap: () => setState(() => _selectedGoal = goal),
          );
        },
      ),
    );
  }

  Widget _buildStep2Sports() {
    return _buildStepContainer(
      title: "İlgi Alanların",
      subtitle: "Hangi branşlarla ilgileniyorsun?",
      child: SingleChildScrollView(
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _sports.map((sport) {
            final isSelected = _selectedSports.contains(sport);
            return ChoiceChip(
              label: Text(sport),
              selected: isSelected,
              selectedColor: ColorConstants.primaryColor,
              backgroundColor: Colors.white10,
              onSelected: (selected) {
                setState(() {
                  selected
                      ? _selectedSports.add(sport)
                      : _selectedSports.remove(sport);
                  _calculateEstimatedPrice(); /* FİYATI GÜNCELLE */
                });
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStep3CoachingType() {
    return _buildStepContainer(
      title: "Nasıl Çalışmak İstersin?",
      subtitle: "Sana en uygun antrenörleri buna göre listeleyeceğiz.",
      child: Column(
        children: [
          _buildSelectableCardWithIcon(
            text: "Online Koçluk",
            subtext: "Uzaktan takip, program ve analiz.",
            icon: Icons.wifi,
            isSelected: _coachingType == "Online Koçluk",
            onTap: () => setState(() => _coachingType = "Online Koçluk"),
          ),
          const SizedBox(height: 16),
          _buildSelectableCardWithIcon(
            text: "Birebir (Yüzyüze)",
            subtext: "Spor salonunda veya dışarıda buluşarak.",
            icon: Icons.people_alt_outlined,
            isSelected: _coachingType == "Birebir (Yüzyüze)",
            onTap: () => setState(() => _coachingType = "Birebir (Yüzyüze)"),
          ),
        ],
      ),
    );
  }

  Widget _buildStep4Stats() {
    return _buildStepContainer(
      title: "Vücut Analizi",
      subtitle: "Sana en uygun programı hazırlıyoruz.",
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Cinsiyet", style: GoogleFonts.poppins(color: Colors.white70)),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildGenderButton(
                  "Erkek",
                  Icons.male,
                  () => setState(() => _gender = "Erkek"),
                  _gender == "Erkek",
                ),
                const SizedBox(width: 15),
                _buildGenderButton(
                  "Kadın",
                  Icons.female,
                  () => setState(() => _gender = "Kadın"),
                  _gender == "Kadın",
                ),
              ],
            ),
            const SizedBox(height: 25),
            _buildStatInput("Yaş", _ageController),
            const SizedBox(height: 15),
            _buildStatInput("Boy (cm)", _heightController),
            const SizedBox(height: 15),
            _buildStatInput("Kilo (kg)", _weightController),
          ],
        ),
      ),
    );
  }

  Widget _buildStep5Experience() {
    return _buildStepContainer(
      title: "Deneyim Seviyen",
      subtitle: "Daha önce bu sporu yaptın mı?",
      child: ListView.separated(
        itemCount: _experienceLevels.length,
        separatorBuilder: (c, i) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final level = _experienceLevels[index];
          return _buildSelectableCard(
            text: level,
            isSelected: _experienceLevel == level,
            onTap: () => setState(() => _experienceLevel = level),
          );
        },
      ),
    );
  }

  // YENİ EKLENEN 6. ADIM: Müsaitlik ve Antrenör Tercihi
  Widget _buildStep6Preferences() {
    return _buildStepContainer(
      title: "Zaman ve Tercih",
      subtitle: "Seni en doğru hocayla eşleştirelim.",
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Antrenör Tercihi",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildGenderButton(
                  "Erkek",
                  Icons.male,
                  () => setState(() => _preferredCoachGender = "Erkek"),
                  _preferredCoachGender == "Erkek",
                ),
                const SizedBox(width: 10),
                _buildGenderButton(
                  "Kadın",
                  Icons.female,
                  () => setState(() => _preferredCoachGender = "Kadın"),
                  _preferredCoachGender == "Kadın",
                ),
                const SizedBox(width: 10),
                _buildGenderButton(
                  "Farketmez",
                  Icons.people_outline,
                  () => setState(() => _preferredCoachGender = "Farketmez"),
                  _preferredCoachGender == "Farketmez",
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              "Müsait Günlerin",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _daysList
                  .map(
                    (day) => ChoiceChip(
                      label: Text(day),
                      selected: _selectedDays.contains(day),
                      selectedColor: ColorConstants.primaryColor,
                      backgroundColor: Colors.white10,
                      onSelected: (val) => setState(
                        () => val
                            ? _selectedDays.add(day)
                            : _selectedDays.remove(day),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),
            Text(
              "Müsait Saatlerin",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _hoursList
                  .map(
                    (hour) => ChoiceChip(
                      label: Text(hour),
                      selected: _selectedHours.contains(hour),
                      selectedColor: ColorConstants.primaryColor,
                      backgroundColor: Colors.white10,
                      onSelected: (val) => setState(
                        () => val
                            ? _selectedHours.add(hour)
                            : _selectedHours.remove(hour),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  // --- YARDIMCI WIDGET'LAR ---
  Widget _buildStepContainer({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.white54),
          ),
          const SizedBox(height: 30),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildSelectableCard({
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ScaleButton(
      onPressed: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? ColorConstants.primaryColor : Colors.white10,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: ColorConstants.primaryColor, width: 2)
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.black
                    : const Color.fromARGB(255, 0, 0, 0),
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: Colors.black),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectableCardWithIcon({
    required String text,
    required String subtext,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ScaleButton(
      onPressed: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? ColorConstants.primaryColor : Colors.white10,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.black.withOpacity(0.1)
                    : Colors.black26,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.black : Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.black : Colors.white,
                    ),
                  ),
                  Text(
                    subtext,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: isSelected ? Colors.black87 : Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: Colors.black),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderButton(
    String label,
    IconData icon,
    VoidCallback onTap,
    bool isSelected,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? ColorConstants.primaryColor : Colors.white10,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.black : Colors.white,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: isSelected ? Colors.black : Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatInput(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(3),
      ],
      style: GoogleFonts.poppins(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.white54),
        filled: true,
        fillColor: Colors.white10,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
      ),
    );
  }
}
