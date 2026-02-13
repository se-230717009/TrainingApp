import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/color_constants.dart';
import '../services/auth_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/scale_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  String? _coachingType; // YENİ: Çalışma Tipi
  String? _gender;
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  String? _experienceLevel;

  // LİSTELER
  final List<String> _goals = [
    "Kilo Vermek",
    "Kas Yapmak",
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

  // --- VALIDATION VE İLERLEME MANTIĞI ---
  void _nextPage() {
    // 1. HEDEF KONTROLÜ (Index 0)
    if (_currentIndex == 0) {
      if (_selectedGoal == null) {
        _showError("Lütfen seni en iyi anlatan hedefi seç.");
        return;
      }
    }

    // 2. SPOR KONTROLÜ (Index 1)
    if (_currentIndex == 1) {
      if (_selectedSports.isEmpty) {
        _showError("Lütfen ilgilendiğin en az bir branşı seç.");
        return;
      }
    }

    // 3. ÇALIŞMA TİPİ KONTROLÜ (Index 2 - YENİ ADIM)
    if (_currentIndex == 2) {
      if (_coachingType == null) {
        _showError("Lütfen nasıl çalışmak istediğini seç.");
        return;
      }
    }

    // 4. VÜCUT ÖLÇÜLERİ KONTROLÜ (Index 3 - Kaydırıldı)
    if (_currentIndex == 3) {
      if (_gender == null) {
        _showError("Lütfen cinsiyetini seç.");
        return;
      }
      if (_ageController.text.isEmpty ||
          _heightController.text.isEmpty ||
          _weightController.text.isEmpty) {
        _showError("Lütfen yaş, boy ve kilo bilgilerini eksiksiz gir.");
        return;
      }

      int age = int.tryParse(_ageController.text) ?? 0;
      int height = int.tryParse(_heightController.text) ?? 0;
      int weight = int.tryParse(_weightController.text) ?? 0;

      if (age < 10 || age > 100) {
        _showError("Geçerli bir yaş giriniz (10-100).");
        return;
      }
      if (height < 100 || height > 250) {
        _showError("Geçerli bir boy giriniz (100-250 cm).");
        return;
      }
      if (weight < 30 || weight > 300) {
        _showError("Geçerli bir kilo giriniz (30-300 kg).");
        return;
      }
    }

    // 5. DENEYİM KONTROLÜ (Index 4 - Kaydırıldı)
    if (_currentIndex == 4) {
      if (_experienceLevel == null) {
        _showError("Lütfen tecrübe seviyeni seç.");
        return;
      }
    }

    // HER ŞEY TAMAMSA İLERLE (Toplam 5 Adım Oldu: 0,1,2,3,4)
    if (_currentIndex < 4) {
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
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // --- KAYDET VE BİTİR ---
  void _finishOnboarding() async {
    setState(() => _isLoading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      await _authService.updateUserProfile(
        uid: uid,
        data: {
          'goal': _selectedGoal,
          'interestedSports': _selectedSports,
          'coachingType': _coachingType, // YENİ VERİ EKLENDİ
          'gender': _gender,
          'age': _ageController.text,
          'height': _heightController.text,
          'weight': _weightController.text,
          'experienceLevel': _experienceLevel,
          'isOnboardingCompleted': true,
        },
      );

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      _showError("Bir hata oluştu: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Toplam adım sayısı 5 oldu
    final double progressValue = (_currentIndex + 1) / 5;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // --- 1. PREMIUM ARKA PLAN GRADYANI ---
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.fromARGB(255, 51, 48, 48),
                    Color.fromARGB(255, 10, 10, 10),
                  ],
                ),
              ),
            ),
          ),

          // --- 2. İÇERİK ---
          SafeArea(
            child: Column(
              children: [
                // İLERLEME ÇUBUĞU
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: progressValue,
                            backgroundColor: Colors.white10,
                            color: ColorConstants.primaryColor,
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Text(
                        "${_currentIndex + 1}/5", // 5 Adım oldu
                        style: GoogleFonts.poppins(
                          color: Colors.white54,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // SAYFALAR
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (index) =>
                        setState(() => _currentIndex = index),
                    children: [
                      _buildStep1Goal(),
                      _buildStep2Sports(),
                      _buildStep3CoachingType(), // YENİ EKRAN
                      _buildStep4Stats(), // Artık 4. sırada
                      _buildStep5Experience(), // Artık 5. sırada
                    ],
                  ),
                ),

                // BUTON
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          color: ColorConstants.primaryColor,
                        )
                      : CustomButton(
                          text: _currentIndex == 4 ? "Tamamla" : "Devam Et",
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

  // --- ADIM WIDGET'LARI ---

  Widget _buildStep1Goal() {
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
              labelStyle: GoogleFonts.poppins(
                color: isSelected
                    ? Colors.black
                    : const Color.fromARGB(255, 0, 0, 0),
                fontWeight: FontWeight.w600,
              ),
              selected: isSelected,
              selectedColor: ColorConstants.primaryColor,
              backgroundColor: Colors.white10,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
              ),
              side: BorderSide.none,
              onSelected: (selected) {
                setState(() {
                  selected
                      ? _selectedSports.add(sport)
                      : _selectedSports.remove(sport);
                });
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  // --- YENİ EKLENEN ADIM ---
  Widget _buildStep3CoachingType() {
    return _buildStepContainer(
      title: "Nasıl Çalışmak İstersin?",
      subtitle: "Sana en uygun antrenörleri buna göre listeleyeceğiz.",
      child: Column(
        children: [
          // ONLINE SEÇENEĞİ
          _buildSelectableCardWithIcon(
            text: "Online Koçluk",
            subtext: "Uzaktan takip, program ve analiz.",
            icon: Icons.wifi,
            isSelected: _coachingType == "Online Koçluk",
            onTap: () => setState(() => _coachingType = "Online Koçluk"),
          ),
          const SizedBox(height: 16),
          // YÜZYÜZE SEÇENEĞİ
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
                _buildGenderButton("Erkek", Icons.male),
                const SizedBox(width: 15),
                _buildGenderButton("Kadın", Icons.female),
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

  // Standart Kart (Sadece Metin)
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
                color: isSelected ? Colors.black : Colors.white,
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: Colors.black),
          ],
        ),
      ),
    );
  }

  // İkonlu ve Alt Metinli Kart (Online/Yüzyüze için özel)
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
          border: isSelected
              ? Border.all(color: ColorConstants.primaryColor, width: 2)
              : null,
        ),
        child: Row(
          children: [
            // İkon Kutusu
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
            // Metinler
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
                  const SizedBox(height: 4),
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

  Widget _buildGenderButton(String label, IconData icon) {
    final isSelected = _gender == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _gender = label),
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
