import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import '../core/constants/color_constants.dart';
import '../widgets/custom_button.dart';
import '../widgets/gradient_background.dart';
import 'welcome_screen.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // YENİ: KULLANICI ID'SİNİ GÜVENLİ (NULLABLE) HALE GETİRDİK
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

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

  @override
  void initState() {
    super.initState();
    // YENİ: EĞER MİSAFİR DEĞİLSE VERİLERİ YÜKLE
    if (FirebaseAuth.instance.currentUser != null) {
      _loadUserData();
    } else {
      setState(() => _isLoading = false);
    }
  }

  // --- VERİLERİ ÇEK ---
  Future<void> _loadUserData() async {
    if (_uid == null) return; // Güvenlik kontrolü

    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_uid!)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
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
            _selectedGoal = _goalList.contains(fetchedGoal)
                ? fetchedGoal
                : null;
          } else if (_userType == 'coach') {
            _bioController.text = data['bio'] ?? '';
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      _showError("Veriler yüklenirken hata oluştu.");
      setState(() => _isLoading = false);
    }
  }

  // --- FOTOĞRAF SEÇ ---
  Future<void> _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result != null) {
        setState(() {
          _selectedImage = File(result.files.single.path!);
        });
      }
    } catch (e) {
      _showError("Fotoğraf seçilemedi: $e");
    }
  }

  // --- PROFİLİ KAYDET ---
  Future<void> _saveProfile() async {
    if (_uid == null) return; // Güvenlik kontrolü

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
        updateData['age'] = _ageController.text.trim();
        updateData['height'] = _heightController.text.trim();
        updateData['weight'] = _weightController.text.trim();
        updateData['interestedSports'] = _selectedSports;
        updateData['experienceLevel'] = _selectedLevel;
        updateData['goal'] = _selectedGoal;
      } else if (_userType == 'coach') {
        updateData['bio'] = _bioController.text.trim();
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_uid!)
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

  @override
  Widget build(BuildContext context) {
    // 1. EĞER MİSAFİR İSE PROFİL OLUŞTURMA EKRANINI GÖSTER
    if (FirebaseAuth.instance.currentUser == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Text(
            "Profilim",
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
                  child: const Icon(
                    Icons.person_add_alt_1_rounded,
                    size: 80,
                    color: ColorConstants.primaryColor,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "Kendi profilini oluştur ve hedeflerine ulaşmak için ilk adımı at!",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
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
                    "Giriş Yap / Kayıt Ol",
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

    // 2. MİSAFİR DEĞİLSE NORMAL PROFİL DÜZENLEME EKRANINI ÇİZ
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.black.withOpacity(0.6),
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Text(
            "Profilim",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 24,
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
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + kToolbarHeight + 24,
                  left: 24,
                  right: 24,
                  bottom: 24,
                ),
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
                              color: isSelected
                                  ? Colors.black
                                  : const Color.fromARGB(179, 2, 2, 2),
                              fontWeight: FontWeight.w600,
                            ),
                            selected: isSelected,
                            selectedColor: ColorConstants.primaryColor,
                            backgroundColor: Colors.white10,
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
                    ],

                    if (_userType == 'coach') ...[
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
    return DropdownButtonFormField<String>(
      value: selectedValue,
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
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}
