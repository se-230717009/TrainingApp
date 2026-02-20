import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants/color_constants.dart';
import '../services/auth_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/scale_button.dart';
import 'coach_home_screen.dart';

class CoachOnboardingScreen extends StatefulWidget {
  const CoachOnboardingScreen({super.key});

  @override
  State<CoachOnboardingScreen> createState() => _CoachOnboardingScreenState();
}

class _CoachOnboardingScreenState extends State<CoachOnboardingScreen> {
  final PageController _pageController = PageController();
  final AuthService _authService = AuthService();
  int _currentIndex = 0;
  bool _isLoading = false;

  // --- VERİLER ---
  List<String> _selectedSpecialties = [];
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _referenceController = TextEditingController();

  // YENİ: Dosya Yükleme Değişkenleri
  File? _selectedFile;
  String? _fileName;

  final List<String> _specialties = [
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
    "Beslenme",
    "Rehabilitasyon",
  ];

  // --- DOSYA SEÇME FONKSİYONU ---
  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'jpg',
          'jpeg',
          'png',
          'pdf',
        ], // İzin verilen formatlar
      );

      if (result != null) {
        setState(() {
          // Dosyayı alıyoruz
          _selectedFile = File(result.files.single.path!);
          _fileName = result.files.single.name;
        });
      }
    } catch (e) {
      _showError("Dosya seçilirken bir hata oluştu: $e");
    }
  }

  // --- VALIDATION VE İLERLEME MANTIĞI ---
  void _nextPage() {
    // 1. UZMANLIK ALANI KONTROLÜ
    if (_currentIndex == 0) {
      if (_selectedSpecialties.isEmpty) {
        _showError("Lütfen en az bir uzmanlık alanı seçin.");
        return;
      }
    }

    // 2. BIO KONTROLÜ
    if (_currentIndex == 1) {
      if (_bioController.text.trim().isEmpty) {
        _showError("Lütfen kendinizi kısaca tanıtın.");
        return;
      }
      if (_bioController.text.trim().length < 20) {
        _showError("Bio en az 20 karakter olmalıdır.");
        return;
      }
    }

    // 3. REFERANS VE DOSYA KONTROLÜ (BURAYI KİLİTLEDİK)
    if (_currentIndex == 2) {
      // Eğer ne link yazmış, ne de dosya seçmişse GEÇİŞE İZİN VERME
      if (_referenceController.text.trim().isEmpty && _selectedFile == null) {
        _showError("Lütfen bir referans linki girin VEYA bir belge yükleyin.");
        return;
      }
    }

    // İLERLE VEYA BİTİR
    if (_currentIndex < 2) {
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

      // Yazılı linkleri al (varsa)
      List<String> referenceLinks = _referenceController.text
          .trim()
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      // EĞER DOSYA SEÇİLMİŞSE FIREBASE STORAGE'A YÜKLE
      if (_selectedFile != null) {
        // Firebase Storage'da klasör yolu oluştur: verifications/uid/dosya_adi
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('verifications')
            .child(uid)
            .child(_fileName!);

        // Dosyayı yükle
        await storageRef.putFile(_selectedFile!);

        // Yüklenen dosyanın indirme linkini al
        final String fileUrl = await storageRef.getDownloadURL();

        // Linki listeye ekle
        referenceLinks.add(fileUrl);
      }

      // Veritabanını güncelle
      await _authService.updateUserProfile(
        uid: uid,
        data: {
          'specialties': _selectedSpecialties,
          'bio': _bioController.text.trim(),
          'referenceLinks':
              referenceLinks, // Hem yazılı linkler hem dosya linki burada
          'isOnboardingCompleted': true,
        },
      );

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const CoachHomeScreen()),
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
  void dispose() {
    _bioController.dispose();
    _referenceController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double progressValue = (_currentIndex + 1) / 3;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Arka Plan
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

          SafeArea(
            child: Column(
              children: [
                // İlerleme Çubuğu
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
                        "${_currentIndex + 1}/3",
                        style: GoogleFonts.poppins(
                          color: Colors.white54,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Sayfalar
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (index) =>
                        setState(() => _currentIndex = index),
                    children: [
                      _buildStep1Specialties(),
                      _buildStep2Bio(),
                      _buildStep3References(),
                    ],
                  ),
                ),

                // Buton
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          color: ColorConstants.primaryColor,
                        )
                      : CustomButton(
                          text: _currentIndex == 2 ? "Tamamla" : "Devam Et",
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

  // --- WIDGETS ---

  Widget _buildStep1Specialties() {
    return _buildStepContainer(
      title: "Uzmanlık Alanların",
      subtitle: "Hangi branşlarda eğitim veriyorsun?",
      child: SingleChildScrollView(
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _specialties.map((specialty) {
            final isSelected = _selectedSpecialties.contains(specialty);
            return ChoiceChip(
              label: Text(specialty),
              labelStyle: GoogleFonts.poppins(
                color: isSelected
                    ? Colors.black
                    : const Color.fromARGB(179, 1, 1, 1),
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
                      ? _selectedSpecialties.add(specialty)
                      : _selectedSpecialties.remove(specialty);
                });
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStep2Bio() {
    return _buildStepContainer(
      title: "Kendini Tanıt",
      subtitle: "Sporcuların seni daha iyi tanıması için kısa bir bio yaz.",
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: _bioController,
                maxLines: 6,
                maxLength: 300,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText:
                      "Örn: 5 yıllık fitness deneyimim ile yüzlerce sporcuya destek oldum...",
                  hintStyle: GoogleFonts.poppins(
                    color: Colors.white30,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(20),
                  counterStyle: GoogleFonts.poppins(
                    color: Colors.white38,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep3References() {
    return _buildStepContainer(
      title: "Referansların",
      subtitle:
          "Hesabını onaylamamız için Instagram linkini yazabilir VEYA sertifikanı yükleyebilirsin.",
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. SEÇENEK: Link Yazma
            Text(
              "Seçenek 1: Sosyal Medya / Web Linki",
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: _referenceController,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: "Örn: https://instagram.com/kullaniciadi",
                  hintStyle: GoogleFonts.poppins(
                    color: Colors.white30,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  prefixIcon: const Icon(
                    Icons.link_rounded,
                    color: Colors.white38,
                    size: 22,
                  ),
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Row(
                children: [
                  Expanded(child: Divider(color: Colors.white24)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      "VEYA",
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.white24)),
                ],
              ),
            ),

            // 2. SEÇENEK: Dosya Yükleme
            Text(
              "Seçenek 2: Belge Yükle (PDF, JPG, PNG)",
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            ScaleButton(
              onPressed: _pickFile,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  border: Border.all(
                    color: _selectedFile != null
                        ? ColorConstants.primaryColor
                        : Colors.white24,
                    style: BorderStyle.solid,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(
                      _selectedFile != null
                          ? Icons.check_circle_outline
                          : Icons.cloud_upload_outlined,
                      color: _selectedFile != null
                          ? ColorConstants.primaryColor
                          : Colors.white54,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedFile != null
                          ? _fileName!
                          : "Sertifika veya Kimlik Yükle",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: _selectedFile != null
                            ? ColorConstants.primaryColor
                            : Colors.white70,
                        fontWeight: _selectedFile != null
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
}
