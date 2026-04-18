// ignore_for_file: unused_field

import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import '../core/constants/color_constants.dart';
import '../core/utils/validators.dart';
import '../widgets/custom_button.dart';
import '../widgets/scale_button.dart';
import '../widgets/gradient_background.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final String _uid = FirebaseAuth.instance.currentUser!.uid;
  bool _isLoading = true;
  bool _isSaving = false;

  String _userType = '';
  String? _profileImageUrl;
  File? _selectedImage;

  // --- ORTAK ALANLAR ---
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();

  // --- SPORCU (ATHLETE) ALANLARI ---
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  List<String> _selectedSports = [];
  String? _selectedLevel;
  String? _selectedGoal;

  final List<String> _sportsList = [
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
  final List<String> _levelList = [
    "Yeni Başlayan",
    "Orta Seviye",
    "İleri Seviye",
  ];
  final List<String> _goalList = [
    "Kilo Vermek",
    "Kas Yapmak",
    "Kondisyon",
    "Esneklik",
    "Yarışmaya Hazırlanmak",
  ];

  // --- ANTRENÖR (COACH) ALANLARI ---
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  List<String> _selectedSpecialties = [];
  String? _deliveryMode;
  String? _lessonFormat;
  String? _coachCharacter;
  Map<String, List<String>> _dayHoursMap = {};

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

  // --- ANTRENÖR KONUM ALANLARI ---
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

  bool get _needsLocation =>
      _deliveryMode == "Yüzyüze" ||
      _deliveryMode == "Farketmez" ||
      _deliveryMode == "Hibrit(İkisi de)";

  @override
  void initState() {
    super.initState();
    _loadUserData();
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
        _citiesData = data['data'];
        _citiesData.sort(
          (a, b) => a['name'].toString().compareTo(b['name'].toString()),
        );
      }
    } catch (e) {
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _fetchDistricts(int provinceId) async {
    setState(() {
      _isLoadingLocation = true;
      _districtsData = [];
      _neighborhoodsData = [];
    });
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.turkiyeapi.dev/v1/districts?provinceId=$provinceId&limit=1000',
        ),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        _districtsData = data['data'];
        _districtsData.sort(
          (a, b) => a['name'].toString().compareTo(b['name'].toString()),
        );
      }
    } catch (e) {
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _fetchNeighborhoods(int districtId) async {
    setState(() {
      _isLoadingLocation = true;
      _neighborhoodsData = [];
    });
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.turkiyeapi.dev/v1/neighborhoods?districtId=$districtId&limit=1000',
        ),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        _neighborhoodsData = data['data'];
        _neighborhoodsData.sort(
          (a, b) => a['name'].toString().compareTo(b['name'].toString()),
        );
      }
    } catch (e) {
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _loadUserData() async {
    try {
      await _fetchCities(); // Önce şehirleri yükle ki konum eşleşebilsin
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _userType = data['userType'] ?? 'athlete';
        _nameController.text = data['name'] ?? '';
        _surnameController.text = data['surname'] ?? '';
        _profileImageUrl = data['profileImageUrl'];

        if (_userType == 'athlete') {
          _ageController.text = data['age']?.toString() ?? '';
          _heightController.text = data['height']?.toString() ?? '';
          _weightController.text = data['weight']?.toString() ?? '';
          _selectedSports = List<String>.from(data['interestedSports'] ?? []);
          String? fetchedLevel = data['experienceLevel'];
          _selectedLevel = _levelList.contains(fetchedLevel)
              ? fetchedLevel
              : null;
          String? fetchedGoal = data['goal'];
          _selectedGoal = _goalList.contains(fetchedGoal) ? fetchedGoal : null;
        } else if (_userType == 'coach') {
          _bioController.text = data['bio'] ?? '';
          _priceController.text = (data['hourlyRate'] ?? '').toString();
          _selectedSpecialties = List<String>.from(data['specialties'] ?? []);
          _deliveryMode = data['deliveryMode'];
          _lessonFormat = data['lessonFormat'];
          _coachCharacter = data['coachCharacter'];

          if (data['dayHoursMap'] != null) {
            _dayHoursMap = (data['dayHoursMap'] as Map<String, dynamic>).map(
              (key, value) => MapEntry(key, List<String>.from(value)),
            );
          }

          if (data['location'] != null) {
            _selectedCity = data['location']['city'];
            _selectedDistrict = data['location']['district'];
            _selectedNeighborhood = data['location']['neighborhood'];
            _addressTitleController.text =
                data['location']['addressTitle'] ?? '';
            _addressDetailController.text =
                data['location']['addressDetail'] ?? '';

            if (_selectedCity != null) {
              var cityObj = _citiesData.firstWhere(
                (c) => c['name'] == _selectedCity,
                orElse: () => null,
              );
              if (cityObj != null) {
                await _fetchDistricts(cityObj['id']);
                if (_selectedDistrict != null) {
                  var distObj = _districtsData.firstWhere(
                    (d) => d['name'] == _selectedDistrict,
                    orElse: () => null,
                  );
                  if (distObj != null) {
                    await _fetchNeighborhoods(distObj['id']);
                  }
                }
              }
            }
          }
        }
      }
    } catch (e) {
      _showError("Veriler yüklenirken hata oluştu.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );
      if (result != null)
        setState(() => _selectedImage = File(result.files.single.path!));
    } catch (e) {
      _showError("Fotoğraf seçilemedi: $e");
    }
  }

  Future<void> _saveProfile() async {
    if (_userType == 'athlete') {
      String? ageError = Validators.validateAge(_ageController.text);
      if (ageError != null) return _showError(ageError);
      String? heightError = Validators.validateHeight(_heightController.text);
      if (heightError != null) return _showError(heightError);
      String? weightError = Validators.validateWeight(_weightController.text);
      if (weightError != null) return _showError(weightError);
    } else if (_userType == 'coach') {
      if (_selectedSpecialties.isEmpty)
        return _showError("Lütfen en az bir uzmanlık alanı seçin.");
      if (_priceController.text.trim().isEmpty)
        return _showError("Saatlik ücret boş olamaz.");
      if (_deliveryMode == null) return _showError("Çalışma şeklini seçin.");
      if (_lessonFormat == null) return _showError("Ders formatını seçin.");
      if (_coachCharacter == null)
        return _showError("Eğitmen karakterinizi seçin.");
      if (_dayHoursMap.isEmpty)
        return _showError("Lütfen müsaitlik durumunuzu belirleyin.");
      if (_needsLocation &&
          (_selectedCity == null ||
              _selectedDistrict == null ||
              _selectedNeighborhood == null ||
              _addressTitleController.text.isEmpty ||
              _addressDetailController.text.isEmpty)) {
        return _showError("Lütfen adres bilgilerinizi eksiksiz girin.");
      }
    }

    setState(() => _isSaving = true);
    try {
      String? newImageUrl = _profileImageUrl;
      if (_selectedImage != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_pictures')
            .child('$_uid.jpg');
        await storageRef.putFile(_selectedImage!);
        newImageUrl = await storageRef.getDownloadURL();
      }

      Map<String, dynamic> updateData = {
        'name': _nameController.text.trim(),
        'surname': _surnameController.text.trim(),
        if (newImageUrl != null) 'profileImageUrl': newImageUrl,
      };

      if (_userType == 'athlete') {
        updateData.addAll({
          'age': _ageController.text.trim(),
          'height': _heightController.text.trim(),
          'weight': _weightController.text.trim(),
          'interestedSports': _selectedSports,
          'experienceLevel': _selectedLevel,
          'goal': _selectedGoal,
        });
      } else if (_userType == 'coach') {
        List<String> finalDays = _dayHoursMap.keys.toList();
        List<String> finalHours = _dayHoursMap.values
            .expand((h) => h)
            .toSet()
            .toList();

        updateData.addAll({
          'bio': _bioController.text.trim(),
          'specialties': _selectedSpecialties,
          'lessonSport': _selectedSpecialties.isNotEmpty
              ? _selectedSpecialties.first
              : "Genel",
          'hourlyRate': int.tryParse(_priceController.text) ?? 0,
          'deliveryMode': _deliveryMode,
          'lessonFormat': _lessonFormat,
          'coachCharacter': _coachCharacter,
          'availableDays': finalDays,
          'availableHours': finalHours,
          'dayHoursMap': _dayHoursMap,
        });

        if (_needsLocation) {
          updateData['location'] = {
            'city': _selectedCity,
            'district': _selectedDistrict,
            'neighborhood': _selectedNeighborhood,
            'addressDetail': _addressDetailController.text.trim(),
            'addressTitle': _addressTitleController.text.trim(),
          };
        }
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .update(updateData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Profil başarıyla güncellendi! ✅",
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _showError("Profil kaydedilirken bir hata oluştu: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
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

  // --- ANTRENÖR: MÜSAİTLİK DÜZENLEME MODALI ---
  void _showAvailabilityModal() {
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
            return FractionallySizedBox(
              heightFactor: 0.85,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
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
                    const SizedBox(height: 24),
                    Text(
                      "Müsaitlik Durumu",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Müsait olduğunuz günleri ve saatleri belirleyin.",
                      style: GoogleFonts.poppins(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: ListView.separated(
                        itemCount: _daysList.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          String day = _daysList[index];
                          List<String> selectedHours = _dayHoursMap[day] ?? [];
                          bool isSelected = selectedHours.isNotEmpty;

                          return ListTile(
                            onTap: () => _showHoursPopup(day, setModalState),
                            tileColor: isSelected
                                ? ColorConstants.primaryColor.withOpacity(0.1)
                                : Colors.white10,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: isSelected
                                    ? ColorConstants.primaryColor.withOpacity(
                                        0.5,
                                      )
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
                              Icons.timelapse,
                              color: isSelected
                                  ? ColorConstants.primaryColor
                                  : Colors.white54,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorConstants.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          "Bitti",
                          style: GoogleFonts.poppins(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showHoursPopup(String day, StateSetter setModalState) {
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
                        color: isSel ? Colors.black : Colors.white,
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
                    // Hem Ana Ekranı Hem de BottomSheet'i Güncelle
                    setState(() {
                      if (tempHours.isEmpty)
                        _dayHoursMap.remove(day);
                      else
                        _dayHoursMap[day] = tempHours;
                    });
                    setModalState(() {});
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

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            "Profili Düzenle",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: ColorConstants.primaryColor,
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.white10,
                            backgroundImage: _selectedImage != null
                                ? FileImage(_selectedImage!) as ImageProvider
                                : (_profileImageUrl != null
                                      ? NetworkImage(_profileImageUrl!)
                                      : null),
                            child:
                                (_selectedImage == null &&
                                    _profileImageUrl == null)
                                ? const Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.white38,
                                  )
                                : null,
                          ),
                          GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                color: ColorConstants.primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    _buildTextField("Ad", _nameController),
                    const SizedBox(height: 16),
                    _buildTextField("Soyad", _surnameController),
                    const SizedBox(height: 16),

                    // ==========================================
                    // SPORCU ÖZEL ALANLARI
                    // ==========================================
                    if (_userType == 'athlete') ...[
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              "Yaş",
                              _ageController,
                              isNumber: true,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              "Boy (cm)",
                              _heightController,
                              isNumber: true,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              "Kilo",
                              _weightController,
                              isNumber: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdown(
                              "Spor Seviyesi",
                              _levelList,
                              _selectedLevel,
                              (val) => setState(() => _selectedLevel = val),
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: _buildDropdown(
                              "Ana Hedef",
                              _goalList,
                              _selectedGoal,
                              (val) => setState(() => _selectedGoal = val),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      Text(
                        "İlgilendiğin Sporlar",
                        style: GoogleFonts.poppins(
                          color: Colors.white54,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _sportsList.map((sport) {
                          final isSelected = _selectedSports.contains(sport);
                          return ChoiceChip(
                            label: Text(sport),
                            labelStyle: GoogleFonts.poppins(
                              color: isSelected ? Colors.black : Colors.white,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                            ),
                            selected: isSelected,
                            selectedColor: ColorConstants.primaryColor,
                            backgroundColor: Colors.white10,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                            ),
                            side: BorderSide.none,
                            onSelected: (selected) => setState(() {
                              selected
                                  ? _selectedSports.add(sport)
                                  : _selectedSports.remove(sport);
                            }),
                          );
                        }).toList(),
                      ),
                    ],

                    // ==========================================
                    // ANTRENÖR ÖZEL ALANLARI
                    // ==========================================
                    if (_userType == 'coach') ...[
                      Text(
                        "Uzmanlık Alanları",
                        style: GoogleFonts.poppins(
                          color: Colors.white54,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _sportsList.map((specialty) {
                          final isSelected = _selectedSpecialties.contains(
                            specialty,
                          );
                          return ChoiceChip(
                            label: Text(specialty),
                            labelStyle: GoogleFonts.poppins(
                              color: Colors.black,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
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
                      const SizedBox(height: 24),

                      Text(
                        "Çalışma Şekli",
                        style: GoogleFonts.poppins(
                          color: Colors.white54,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: ['Online', 'Yüzyüze', 'Hibrit'].map((mode) {
                          final isSelected = _deliveryMode == mode;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(mode),
                              labelStyle: GoogleFonts.poppins(
                                color: Colors.black,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              selected: isSelected,
                              selectedColor: ColorConstants.primaryColor,
                              backgroundColor: Colors.white10,
                              onSelected: (val) {
                                if (val) setState(() => _deliveryMode = mode);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      Text(
                        "Ders Formatı",
                        style: GoogleFonts.poppins(
                          color: Colors.white54,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: ['Özel Ders', 'Grup Dersi', 'İkisi de'].map((
                          format,
                        ) {
                          final isSelected = _lessonFormat == format;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(format),
                              labelStyle: GoogleFonts.poppins(
                                color: Colors.black,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              selected: isSelected,
                              selectedColor: ColorConstants.primaryColor,
                              backgroundColor: Colors.white10,
                              onSelected: (val) {
                                if (val) setState(() => _lessonFormat = format);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      _buildTextField(
                        "Saatlik Ücret (TL)",
                        _priceController,
                        isNumber: true,
                      ),
                      const SizedBox(height: 16),
                      _buildDropdown(
                        "Eğitmen Karakterin",
                        _characterList,
                        _coachCharacter,
                        (val) => setState(() => _coachCharacter = val),
                      ),
                      const SizedBox(height: 24),

                      Text(
                        "Çalışma Gün ve Saatleri",
                        style: GoogleFonts.poppins(
                          color: Colors.white54,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ScaleButton(
                        onPressed: _showAvailabilityModal,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 20,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _dayHoursMap.isEmpty
                                  ? Colors.redAccent.withOpacity(0.5)
                                  : Colors.white24,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _dayHoursMap.isEmpty
                                    ? "Müsaitlik Seçilmedi"
                                    : "${_dayHoursMap.length} Gün Ayarlandı",
                                style: GoogleFonts.poppins(
                                  color: _dayHoursMap.isEmpty
                                      ? Colors.redAccent
                                      : Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Icon(
                                Icons.edit_calendar_rounded,
                                color: _dayHoursMap.isEmpty
                                    ? Colors.redAccent
                                    : Colors.white54,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      if (_needsLocation) ...[
                        Text(
                          "Konum Bilgileri",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildDropdown(
                          "İl",
                          _citiesData.isEmpty
                              ? ["Yükleniyor..."]
                              : _citiesData
                                    .map((c) => c['name'].toString())
                                    .toList(),
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
                        const SizedBox(height: 16),
                        _buildTextField(
                          "Adres Başlığı (Örn: MacFit Moda)",
                          _addressTitleController,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          "Adres Tarifi",
                          _addressDetailController,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 24),
                      ],

                      _buildTextField(
                        "Hakkımda (Bio)",
                        _bioController,
                        maxLines: 4,
                      ),
                    ],

                    const SizedBox(height: 40),
                    _isSaving
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: ColorConstants.primaryColor,
                            ),
                          )
                        : CustomButton(
                            text: "Değişiklikleri Kaydet",
                            onPressed: _saveProfile,
                          ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
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
          vertical: 18,
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
}
