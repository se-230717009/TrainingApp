import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
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

  final List<String> _selectedSpecialties = [];
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _referenceController = TextEditingController();
  File? _selectedFile;
  String? _fileName;

  String? _selectedLessonSport;
  final TextEditingController _priceController = TextEditingController();
  final List<String> _selectedDays = [];
  final List<String> _selectedHours = [];
  String? _coachCharacter;
  String? _deliveryMode;

  // --- API KONUM DEĞİŞKENLERİ ---
  String? _selectedCity;
  String? _selectedDistrict;
  String? _selectedNeighborhood;

  List<dynamic> _citiesData = [];
  List<dynamic> _districtsData = [];
  List<dynamic> _neighborhoodsData = [];
  bool _isLoadingLocation = false;

  final TextEditingController _addressDetailController =
      TextEditingController();
  final TextEditingController _addressTitleController = TextEditingController();

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
  ];
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
  final List<String> _characterList = [
    "Motivatör & Enerjik",
    "Disiplinli & Güç Odaklı",
    "Dinamik & Dayanıklılık Odaklı",
    "Sakin & Beden Farkındalığı",
    "Sert & Hedef Odaklı (Pro)",
  ];

  bool get _needsLocation =>
      _deliveryMode == "Yüzyüze" || _deliveryMode == "Hibrit(İkisi de)";

  @override
  void initState() {
    super.initState();
    _fetchCities();
  }

  // --- API: İLLERİ ÇEK ---
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
    } catch (e) {
      _showError("İller yüklenirken hata oluştu.");
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  // --- API: İLÇELERİ ÇEK ---
  Future<void> _fetchDistricts(int provinceId) async {
    setState(() {
      _isLoadingLocation = true;
      _districtsData = [];
      _neighborhoodsData = [];
      _selectedDistrict = null;
      _selectedNeighborhood = null;
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
    } catch (e) {
      _showError("İlçeler yüklenirken hata oluştu.");
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  // --- API: MAHALLELERİ ÇEK ---
  Future<void> _fetchNeighborhoods(int districtId) async {
    setState(() {
      _isLoadingLocation = true;
      _neighborhoodsData = [];
      _selectedNeighborhood = null;
    });
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.turkiyeapi.dev/v1/neighborhoods?districtId=$districtId&limit=1000',
        ),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _neighborhoodsData = data['data'];
          _neighborhoodsData.sort(
            (a, b) => a['name'].toString().compareTo(b['name'].toString()),
          );
        });
      }
    } catch (e) {
      _showError("Mahalleler yüklenirken hata oluştu.");
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  // --- DİNAMİK SAYFA LİSTESİ ---
  List<Widget> get _pages {
    List<Widget> p = [
      _buildStep1Specialties(),
      _buildStep2Bio(),
      _buildStep3References(),
      _buildStep4LessonSport(),
    ];
    if (_needsLocation) {
      p.add(_buildStepLocation());
    }
    p.add(_buildStep5Availability());
    p.add(_buildStep6Character());
    return p;
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      );
      if (result != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _fileName = result.files.single.name;
        });
      }
    } catch (e) {
      _showError("Dosya seçilirken bir hata oluştu: $e");
    }
  }

  void _nextPage() {
    final int totalPages = _pages.length;

    if (_currentIndex == 0 && _selectedSpecialties.isEmpty)
      return _showError("Lütfen en az bir uzmanlık alanı seçin.");
    if (_currentIndex == 1 &&
        (_bioController.text.trim().isEmpty ||
            _bioController.text.trim().length < 20))
      return _showError("Bio en az 20 karakter olmalıdır.");
    if (_currentIndex == 2 &&
        _referenceController.text.trim().isEmpty &&
        _selectedFile == null)
      return _showError("Lütfen bir referans linki girin veya belge yükleyin.");
    if (_currentIndex == 3 &&
        (_selectedLessonSport == null ||
            _priceController.text.isEmpty ||
            _deliveryMode == null))
      return _showError("Lütfen branş, ders şekli ve ücret belirleyin.");

    if (_needsLocation) {
      if (_currentIndex == 4 &&
          (_selectedCity == null ||
              _selectedDistrict == null ||
              _selectedNeighborhood == null ||
              _addressTitleController.text.isEmpty ||
              _addressDetailController.text.isEmpty)) {
        return _showError(
          "Lütfen il, ilçe ve adres bilgilerini eksiksiz doldurun.",
        );
      }
      if (_currentIndex == 5 &&
          (_selectedDays.isEmpty || _selectedHours.isEmpty))
        return _showError("Lütfen en az bir gün ve saat aralığı seçin.");
      if (_currentIndex == 6 && _coachCharacter == null)
        return _showError("Lütfen eğitmen karakterinizi seçin.");
    } else {
      if (_currentIndex == 4 &&
          (_selectedDays.isEmpty || _selectedHours.isEmpty))
        return _showError("Lütfen en az bir gün ve saat aralığı seçin.");
      if (_currentIndex == 5 && _coachCharacter == null)
        return _showError("Lütfen eğitmen karakterinizi seçin.");
    }

    if (_currentIndex < totalPages - 1) {
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
      ),
    );
  }

  void _finishOnboarding() async {
    setState(() => _isLoading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      List<String> referenceLinks = _referenceController.text
          .trim()
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      if (_selectedFile != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('verifications')
            .child(uid)
            .child(_fileName!);
        await storageRef.putFile(_selectedFile!);
        referenceLinks.add(await storageRef.getDownloadURL());
      }

      Map<String, dynamic> updateData = {
        'specialties': _selectedSpecialties,
        'bio': _bioController.text.trim(),
        'referenceLinks': referenceLinks,
        'lessonSport': _selectedLessonSport,
        'hourlyRate': int.tryParse(_priceController.text) ?? 0,
        'availableDays': _selectedDays,
        'availableHours': _selectedHours,
        'deliveryMode': _deliveryMode,
        'coachCharacter': _coachCharacter,
        'isApproved': false,
        'isOnboardingCompleted': true,
      };

      if (_needsLocation) {
        updateData['location'] = {
          'city': _selectedCity,
          'district': _selectedDistrict,
          'neighborhood': _selectedNeighborhood,
          'addressDetail': _addressDetailController.text.trim(),
          'addressTitle': _addressTitleController.text.trim(),
        };
      }

      await _authService.updateUserProfile(uid: uid, data: updateData);

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const CoachHomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      _showError("Hata: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPages = _pages;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
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
                            value: (_currentIndex + 1) / currentPages.length,
                            backgroundColor: Colors.white10,
                            color: ColorConstants.primaryColor,
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Text(
                        "${_currentIndex + 1}/${currentPages.length}",
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
                    children: currentPages,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          color: ColorConstants.primaryColor,
                        )
                      : CustomButton(
                          text: _currentIndex == currentPages.length - 1
                              ? "Tamamla"
                              : "Devam Et",
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
                    : const Color.fromARGB(179, 9, 9, 9),
              ),
              selected: isSelected,
              selectedColor: ColorConstants.primaryColor,
              backgroundColor: Colors.white10,
              onSelected: (selected) => setState(
                () => selected
                    ? _selectedSpecialties.add(specialty)
                    : _selectedSpecialties.remove(specialty),
              ),
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
      child: TextField(
        controller: _bioController,
        maxLines: 6,
        maxLength: 300,
        style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: "Örn: 5 yıllık fitness deneyimim ile...",
          hintStyle: GoogleFonts.poppins(color: Colors.white30, fontSize: 14),
          filled: true,
          fillColor: Colors.white10,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildStep3References() {
    return _buildStepContainer(
      title: "Referansların",
      subtitle: "Sosyal medya linki veya sertifika yükleyebilirsin.",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _referenceController,
            style: GoogleFonts.poppins(color: Colors.white),
            decoration: InputDecoration(
              hintText: "https://instagram.com/kullaniciadi",
              filled: true,
              fillColor: Colors.white10,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "VEYA Belge Yükle",
            style: GoogleFonts.poppins(color: Colors.white70),
          ),
          const SizedBox(height: 10),
          ScaleButton(
            onPressed: _pickFile,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _selectedFile != null
                      ? ColorConstants.primaryColor
                      : Colors.white24,
                ),
              ),
              child: Text(
                _selectedFile != null ? _fileName! : "Sertifika Seç",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: _selectedFile != null
                      ? ColorConstants.primaryColor
                      : Colors.white70,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep4LessonSport() {
    return _buildStepContainer(
      title: "Ders Detayları",
      subtitle: "Branşını, ücretini ve ders verme şeklini belirle.",
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Branş",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _specialties.map((sport) {
                final isSelected = _selectedLessonSport == sport;
                return ChoiceChip(
                  label: Text(sport),
                  labelStyle: GoogleFonts.poppins(
                    color: isSelected
                        ? Colors.black
                        : const Color.fromARGB(179, 0, 0, 0),
                  ),
                  selected: isSelected,
                  selectedColor: ColorConstants.primaryColor,
                  backgroundColor: Colors.white10,
                  onSelected: (selected) => setState(
                    () => _selectedLessonSport = selected ? sport : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Text(
              "Nasıl Ders Veriyorsun?",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildModeButton("Online", Icons.wifi),
                const SizedBox(width: 10),
                _buildModeButton("Yüzyüze", Icons.people),
                const SizedBox(width: 10),
                _buildModeButton("Hibrit(İkisi de)", Icons.compare_arrows),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              "Saatlik Ücret (TL)",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              style: GoogleFonts.poppins(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Örn: 500",
                hintStyle: GoogleFonts.poppins(color: Colors.white30),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(
                  Icons.attach_money_rounded,
                  color: Colors.white54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- GÜÇLENDİRİLMİŞ KONUM ADIMI ---
  Widget _buildStepLocation() {
    return _buildStepContainer(
      title: "Konum Bilgileri",
      subtitle: "Öğrencilerinle nerede buluşacaksın?",
      child: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDropdown(
                  "İl",
                  _citiesData.isEmpty
                      ? ["Yükleniyor..."]
                      : _citiesData.map((c) => c['name'].toString()).toList(),
                  _selectedCity,
                  (val) {
                    if (val != null &&
                        val != "Yükleniyor..." &&
                        val != "Seçenek bulunamadı") {
                      setState(() {
                        _selectedCity = val;
                        _selectedDistrict = null;
                        _selectedNeighborhood = null;
                      });
                      final cityObj = _citiesData.firstWhere(
                        (c) => c['name'] == val,
                      );
                      _fetchDistricts(cityObj['id']);
                    }
                  },
                ),
                const SizedBox(height: 16),

                _buildDropdown(
                  "İlçe",
                  _selectedCity == null
                      ? ["Önce İl Seçin"]
                      : _districtsData
                            .map((d) => d['name'].toString())
                            .toList(),
                  _selectedDistrict,
                  (val) {
                    if (val != null &&
                        val != "Önce İl Seçin" &&
                        val != "Seçenek bulunamadı") {
                      setState(() {
                        _selectedDistrict = val;
                        _selectedNeighborhood = null;
                      });
                      final districtObj = _districtsData.firstWhere(
                        (d) => d['name'] == val,
                      );
                      _fetchNeighborhoods(districtObj['id']);
                    }
                  },
                ),
                const SizedBox(height: 16),

                _buildDropdown(
                  "Semt / Mahalle",
                  _selectedDistrict == null
                      ? ["Önce İlçe Seçin"]
                      : _neighborhoodsData
                            .map((n) => n['name'].toString())
                            .toList(),
                  _selectedNeighborhood,
                  (val) {
                    if (val != null &&
                        val != "Önce İlçe Seçin" &&
                        val != "Seçenek bulunamadı") {
                      setState(() => _selectedNeighborhood = val);
                    }
                  },
                ),

                const SizedBox(height: 24),
                Text(
                  "Adres Tarifi",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildTextField(
                  _addressDetailController,
                  "Örn: Metronun arka çıkışındaki parkın girişi...",
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                Text(
                  "Adres Başlığı(Doğru yazdığınızdan emin olun!!)",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildTextField(
                  _addressTitleController,
                  "Örn: MacFit Spor Salonu, Moda Parkı, X Yüzme Havuzu",
                  maxLines: 1,
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),

          if (_isLoadingLocation)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: ColorConstants.primaryColor,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStep5Availability() {
    return _buildStepContainer(
      title: "Müsaitlik Durumu",
      subtitle: "Hangi gün ve saatlerde ders verebilirsin?",
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Günler",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _daysList.map((day) {
                final isSelected = _selectedDays.contains(day);
                return ChoiceChip(
                  label: Text(day),
                  selected: isSelected,
                  selectedColor: ColorConstants.primaryColor,
                  backgroundColor: Colors.white10,
                  onSelected: (val) => setState(
                    () => val
                        ? _selectedDays.add(day)
                        : _selectedDays.remove(day),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Text(
              "Saat Aralıkları",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _hoursList.map((hour) {
                final isSelected = _selectedHours.contains(hour);
                return ChoiceChip(
                  label: Text(hour),
                  selected: isSelected,
                  selectedColor: ColorConstants.primaryColor,
                  backgroundColor: Colors.white10,
                  onSelected: (val) => setState(
                    () => val
                        ? _selectedHours.add(hour)
                        : _selectedHours.remove(hour),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep6Character() {
    return _buildStepContainer(
      title: "Eğitmen Karakterin",
      subtitle: "Tarzını seç, sana en uygun öğrencilerle eşleşmeni sağlayalım.",
      child: ListView.separated(
        itemCount: _characterList.length,
        separatorBuilder: (c, i) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final char = _characterList[index];
          final isSelected = _coachCharacter == char;
          return ScaleButton(
            onPressed: () => setState(() => _coachCharacter = char),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isSelected
                    ? ColorConstants.primaryColor
                    : Colors.white10,
                borderRadius: BorderRadius.circular(16),
                border: isSelected
                    ? Border.all(color: ColorConstants.primaryColor, width: 2)
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    char,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.black : Colors.white,
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check_circle, color: Colors.black),
                ],
              ),
            ),
          );
        },
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

  Widget _buildModeButton(String label, IconData icon) {
    final isSelected = _deliveryMode == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _deliveryMode = label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? ColorConstants.primaryColor : Colors.white10,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: ColorConstants.primaryColor)
                : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.black : Colors.white,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 11,
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

  // --- KİLİTLENMEYE KARŞI GÜÇLENDİRİLMİŞ DROPDOWN ---
  Widget _buildDropdown(
    String label,
    List<String> items,
    String? selectedValue,
    ValueChanged<String?> onChanged,
  ) {
    // 1. Tekrarlanan verileri engeller (Örn: İki tane Merkez Mah. varsa Flutter çökerdi)
    final uniqueItems = items.toSet().toList();

    // 2. Liste tamamen boşsa tıkanmasını önlemek için sahte bir öğe koyar
    if (uniqueItems.isEmpty) {
      uniqueItems.add("Seçenek bulunamadı");
    }

    final safeValue = uniqueItems.contains(selectedValue)
        ? selectedValue
        : null;

    return DropdownButtonFormField<String>(
      value: safeValue,
      isExpanded: true,
      dropdownColor: const Color(0xFF1E1E1E),
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: Colors.white54,
      ),
      style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.white54, fontSize: 13),
        filled: true,
        fillColor: Colors.white10,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      items: uniqueItems
          .map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text(item, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: Colors.white30, fontSize: 13),
        filled: true,
        fillColor: Colors.white10,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}
