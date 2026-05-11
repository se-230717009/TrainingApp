// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/color_constants.dart';
import '../core/utils/validators.dart';
import '../services/auth_service.dart';
import '../services/email_verification_service.dart';
import '../services/interfaces/i_auth_service.dart';
import '../services/interfaces/i_email_verification_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/scale_button.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final IAuthService authService;
  final IEmailVerificationService verificationService;

  OnboardingScreen({
    super.key,
    IAuthService? authService,
    IEmailVerificationService? verificationService,
  }) : authService = authService ?? AuthService(),
       verificationService = verificationService ?? EmailVerificationService();

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  bool _isLoading = false;
  bool _isEmailVerified = false;

  // Form verileri
  String? _selectedGoal;
  List<String> _selectedSports = [];
  String? _coachingType;
  String? _preferredLessonFormat;
  String? _gender;
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  String? _experienceLevel;
  String? _preferredCoachGender;
  List<String> _selectedDays = [];
  List<String> _selectedHours = [];

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

  @override
  void initState() {
    super.initState();
    _checkInitialEmailStatus();
  }

  void _checkInitialEmailStatus() async {
    await widget.verificationService.reloadUser();
    bool verified = await widget.verificationService.isEmailVerified();
    if (mounted) {
      setState(() => _isEmailVerified = verified);
      if (!verified) {
        await widget.verificationService.sendVerificationEmail();
      }
    }
  }

  void _checkVerificationManually() async {
    setState(() => _isLoading = true);
    await widget.verificationService.reloadUser();
    bool verified = await widget.verificationService.isEmailVerified();
    if (mounted) {
      setState(() {
        _isEmailVerified = verified;
        _isLoading = false;
      });
      if (verified) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      } else {
        _showError("E-posta henüz onaylanmamış görünüyor.");
      }
    }
  }

  void _nextPage() {
    if (_currentIndex == 0 && !_isEmailVerified)
      return _showError("Lütfen devam etmeden önce e-postanızı onaylayın.");
    if (_currentIndex == 1 && _selectedGoal == null)
      return _showError("Hedef seçin.");
    if (_currentIndex == 2 && _selectedSports.isEmpty)
      return _showError("Branş seçin.");
    if (_currentIndex == 3 && _coachingType == null)
      return _showError("Çalışma tipi seçin.");
    if (_currentIndex == 4 && _preferredLessonFormat == null)
      return _showError("Ders formatı seçin.");

    if (_currentIndex == 5) {
      if (_gender == null) return _showError("Cinsiyet seçin.");
      String? ageErr = Validators.validateAge(_ageController.text);
      if (ageErr != null) return _showError(ageErr);
      String? hErr = Validators.validateHeight(_heightController.text);
      if (hErr != null) return _showError(hErr);
      String? wErr = Validators.validateWeight(_weightController.text);
      if (wErr != null) return _showError(wErr);
    }

    if (_currentIndex == 6 && _experienceLevel == null)
      return _showError("Deneyim seçin.");

    if (_currentIndex < 7) {
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
      final String uid = FirebaseAuth.instance.currentUser!.uid;
      await widget.authService.updateUserProfile(
        uid: uid,
        data: {
          'goal': _selectedGoal,
          'interestedSports': _selectedSports,
          'coachingType': _coachingType,
          'preferredLessonFormat': _preferredLessonFormat,
          'gender': _gender,
          'age': _ageController.text,
          'height': _heightController.text,
          'weight': _weightController.text,
          'experienceLevel': _experienceLevel,
          'preferredCoachGender': _preferredCoachGender,
          'availableDays': _selectedDays,
          'availableHours': _selectedHours,
          'isOnboardingCompleted': true,
        },
      );
      if (mounted)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
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
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: (_currentIndex + 1) / 8,
                          backgroundColor: Colors.white10,
                          color: ColorConstants.primaryColor,
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Text(
                        "${_currentIndex + 1}/8",
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
                      _buildStep0EmailVerification(),
                      _buildStep1Goal(),
                      _buildStep2Sports(),
                      _buildStep3CoachingType(),
                      _buildStep4LessonFormat(),
                      _buildStep5Stats(),
                      _buildStep6Experience(),
                      _buildStep7Preferences(),
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
                          text: _currentIndex == 7 ? "Tamamla" : "Devam Et",
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

  Widget _buildStep0EmailVerification() {
    return _buildStepContainer(
      title: "E-posta Aktivasyonu",
      subtitle:
          "Kayıt işlemini bitirebilmeniz için e-postanızı onaylamanız gerekiyor.",
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: ColorConstants.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mark_email_read_rounded,
              color: ColorConstants.primaryColor,
              size: 64,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            "Lütfen e-posta adresinize gönderilen linke tıklayın. Ardından aşağıdaki butona basarak devam edebilirsiniz.",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 40),
          CustomButton(
            text: "Doğrulamayı Kontrol Et",
            onPressed: _checkVerificationManually,
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () => widget.verificationService.sendVerificationEmail(),
            child: Text(
              "Onay kodunu tekrar gönder",
              style: GoogleFonts.poppins(
                color: ColorConstants.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

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
                color: isSelected ? Colors.black : Colors.white,
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: Colors.black),
          ],
        ),
      ),
    );
  }

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
              selected: isSelected,
              selectedColor: ColorConstants.primaryColor,
              backgroundColor: Colors.white10,
              labelStyle: GoogleFonts.poppins(
                color: Colors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
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
          const SizedBox(height: 16),
          _buildSelectableCardWithIcon(
            text: "Farketmez",
            subtext: "Hem online hem yüzyüze.",
            icon: Icons.compare_arrows_rounded,
            isSelected: _coachingType == "Farketmez",
            onTap: () => setState(() => _coachingType = "Farketmez"),
          ),
        ],
      ),
    );
  }

  Widget _buildStep4LessonFormat() {
    return _buildStepContainer(
      title: "Ders Formatı",
      subtitle: "Eğitimlerini nasıl almak istiyorsun?",
      child: Column(
        children: [
          _buildSelectableCardWithIcon(
            text: "Özel Ders",
            subtext: "Eğitmen ile birebir.",
            icon: Icons.person,
            isSelected: _preferredLessonFormat == "Özel Ders",
            onTap: () => setState(() => _preferredLessonFormat = "Özel Ders"),
          ),
          const SizedBox(height: 16),
          _buildSelectableCardWithIcon(
            text: "Grup Dersi",
            subtext: "Küçük gruplar.",
            icon: Icons.groups,
            isSelected: _preferredLessonFormat == "Grup Dersi",
            onTap: () => setState(() => _preferredLessonFormat = "Grup Dersi"),
          ),
          const SizedBox(height: 16),
          _buildSelectableCardWithIcon(
            text: "İkisi de",
            subtext: "İki formata da açığım.",
            icon: Icons.all_inclusive_rounded,
            isSelected: _preferredLessonFormat == "İkisi de",
            onTap: () => setState(() => _preferredLessonFormat = "İkisi de"),
          ),
        ],
      ),
    );
  }

  Widget _buildStep5Stats() {
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

  Widget _buildStep6Experience() {
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

  Widget _buildStep7Preferences() {
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
                      labelStyle: const TextStyle(color: Colors.black),
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
                      labelStyle: const TextStyle(color: Colors.black),
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
