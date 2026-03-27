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
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _referenceController = TextEditingController();
  File? _selectedFile;
  String? _fileName;

  String? _deliveryMode;
  String? _lessonFormat; // YENİ: Özel Ders / Grup Dersi
  String? _coachCharacter;

  Map<String, List<String>> _dayHoursMap = {};

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
      _deliveryMode == "Yüzyüze" ||
      _deliveryMode == "Farketmez" ||
      _deliveryMode == "Hibrit(İkisi de)";

  @override
  void initState() {
    super.initState();
    _fetchCities();
  }

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
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

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
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

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
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  List<Widget> get _pages {
    List<Widget> p = [
      _buildStep1SpecialtiesAndPrice(),
      _buildStep2Bio(),
      _buildStep3References(),
      _buildStep4DeliveryMode(),
      _buildStepLessonFormat(), // YENİ EKLENDİ
    ];
    if (_needsLocation) p.add(_buildStepLocation());
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
      if (result != null)
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _fileName = result.files.single.name;
        });
    } catch (e) {
      _showError("Dosya seçilirken bir hata oluştu.");
    }
  }

  void _nextPage() {
    final int totalPages = _pages.length;

    if (_currentIndex == 0 &&
        (_selectedSpecialties.isEmpty || _priceController.text.trim().isEmpty))
      return _showError(
        "Lütfen uzmanlık alanınızı ve saatlik ücretinizi girin.",
      );
    if (_currentIndex == 1 &&
        (_bioController.text.trim().isEmpty ||
            _bioController.text.trim().length < 20))
      return _showError("Hakkında kısmı en az 20 karakter olmalıdır.");
    if (_currentIndex == 2 &&
        _referenceController.text.trim().isEmpty &&
        _selectedFile == null)
      return _showError("Lütfen bir referans linki girin veya belge yükleyin.");
    if (_currentIndex == 3 && _deliveryMode == null)
      return _showError("Lütfen çalışma şeklini seçin.");
    if (_currentIndex == 4 && _lessonFormat == null)
      return _showError("Lütfen verdiğiniz ders tipini seçin.");

    if (_needsLocation) {
      if (_currentIndex == 5 &&
          (_selectedCity == null ||
              _selectedDistrict == null ||
              _selectedNeighborhood == null ||
              _addressTitleController.text.isEmpty ||
              _addressDetailController.text.isEmpty))
        return _showError(
          "Lütfen il, ilçe ve adres bilgilerini eksiksiz doldurun.",
        );
      if (_currentIndex == 6 && _dayHoursMap.isEmpty)
        return _showError("Lütfen en az bir gün için saat aralığı belirleyin.");
      if (_currentIndex == 7 && _coachCharacter == null)
        return _showError("Lütfen eğitmen karakterinizi seçin.");
    } else {
      if (_currentIndex == 5 && _dayHoursMap.isEmpty)
        return _showError("Lütfen en az bir gün için saat aralığı belirleyin.");
      if (_currentIndex == 6 && _coachCharacter == null)
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

      List<String> finalDays = _dayHoursMap.keys.toList();
      List<String> finalHours = _dayHoursMap.values
          .expand((h) => h)
          .toSet()
          .toList();

      Map<String, dynamic> updateData = {
        'specialties': _selectedSpecialties,
        'lessonSport': _selectedSpecialties.isNotEmpty
            ? _selectedSpecialties.first
            : "Genel",
        'hourlyRate': int.tryParse(_priceController.text) ?? 0,
        'bio': _bioController.text.trim(),
        'referenceLinks': referenceLinks,
        'deliveryMode': _deliveryMode,
        'lessonFormat': _lessonFormat, // Yeni
        'availableDays': finalDays,
        'availableHours': finalHours,
        'dayHoursMap': _dayHoursMap,
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
      if (mounted)
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const CoachHomeScreen()),
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

  Widget _buildStep1SpecialtiesAndPrice() {
    return _buildStepContainer(
      title: "Uzmanlık ve Ücret",
      subtitle: "Hangi branşlarda eğitim veriyorsun ve saatlik ücretin nedir?",
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
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
            const SizedBox(height: 32),
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

  Widget _buildStep2Bio() {
    return _buildStepContainer(
      title: "Hakkında",
      subtitle:
          "Sporcuların seni daha iyi tanıması için kısa bir profil yazısı yaz.",
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
      subtitle: "Sosyal medya linki veya antrenörlük belgesi yükleyebilirsin.",
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

  Widget _buildStep4DeliveryMode() {
    return _buildStepContainer(
      title: "Çalışma Şekli",
      subtitle: "Öğrencilerinle dersleri nasıl işleyeceksin?",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildModeButton("Online", Icons.wifi, true),
              const SizedBox(width: 10),
              _buildModeButton("Yüzyüze", Icons.people, true),
              const SizedBox(width: 10),
              _buildModeButton("Hibrit(İkisi de)", Icons.compare_arrows, true),
            ],
          ),
        ],
      ),
    );
  }

  // --- YENİ ADIM: DERS FORMATI ---
  Widget _buildStepLessonFormat() {
    return _buildStepContainer(
      title: "Ders Formatı",
      subtitle: "Nasıl dersler vereceksiniz?",
      child: Column(
        children: [
          Row(
            children: [
              _buildModeButton("Özel Ders", Icons.person, false),
              const SizedBox(width: 10),
              _buildModeButton("Grup Dersi", Icons.groups, false),
              const SizedBox(width: 10),
              _buildModeButton("İkisi de", Icons.all_inclusive_rounded, false),
            ],
          ),
        ],
      ),
    );
  }

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
                        val != "Seçenek bulunamadı")
                      setState(() => _selectedNeighborhood = val);
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
                  "Adres Başlığı",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildTextField(
                  _addressTitleController,
                  "Örn: MacFit, Moda Parkı",
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
      title: "Çalışma Saatleri",
      subtitle: "Müsait olduğunuz günleri ve saatleri belirleyin.",
      child: ListView.separated(
        itemCount: _daysList.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          String day = _daysList[index];
          List<String> selectedHours = _dayHoursMap[day] ?? [];
          bool isSelected = selectedHours.isNotEmpty;
          return ListTile(
            onTap: () => _showHoursPopup(day),
            tileColor: isSelected
                ? ColorConstants.primaryColor.withOpacity(0.1)
                : Colors.white10,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isSelected
                    ? ColorConstants.primaryColor.withOpacity(0.5)
                    : Colors.transparent,
              ),
            ),
            title: Text(
              day,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              isSelected
                  ? selectedHours.join(', ')
                  : "Saat seçmek için dokunun",
              style: GoogleFonts.poppins(
                color: isSelected
                    ? ColorConstants.primaryColor
                    : Colors.white54,
                fontSize: 12,
              ),
            ),
            trailing: Icon(
              Icons.timelapse_rounded,
              color: isSelected ? ColorConstants.primaryColor : Colors.white54,
            ),
          );
        },
      ),
    );
  }

  void _showHoursPopup(String day) {
    List<String> tempHours = List.from(_dayHoursMap[day] ?? []);
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                "$day Saatleri",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _hoursList.map((h) {
                    bool isSel = tempHours.contains(h);
                    return ChoiceChip(
                      label: Text(h),
                      selected: isSel,
                      selectedColor: ColorConstants.primaryColor,
                      backgroundColor: Colors.white10,
                      labelStyle: GoogleFonts.poppins(
                        color: Colors.black,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (val) {
                        setDialogState(() {
                          if (val)
                            tempHours.add(h);
                          else
                            tempHours.remove(h);
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "İptal",
                    style: GoogleFonts.poppins(color: Colors.white54),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      if (tempHours.isEmpty)
                        _dayHoursMap.remove(day);
                      else
                        _dayHoursMap[day] = tempHours;
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorConstants.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "Kaydet",
                    style: GoogleFonts.poppins(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
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
                  Expanded(
                    child: Text(
                      char,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.black : Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
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

  Widget _buildModeButton(String label, IconData icon, bool isDelivery) {
    final isSelected = isDelivery
        ? _deliveryMode == label
        : _lessonFormat == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          if (isDelivery)
            _deliveryMode = label;
          else
            _lessonFormat = label;
        }),
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
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    List<String> items,
    String? selectedValue,
    ValueChanged<String?> onChanged,
  ) {
    final uniqueItems = items.toSet().toList();
    if (uniqueItems.isEmpty) uniqueItems.add("Seçenek bulunamadı");
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
