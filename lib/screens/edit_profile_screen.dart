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

  // Yeni Eklenen Sporcu Alanları
  List<String> _selectedSports = [];
  String? _selectedLevel;
  String? _selectedGoal;

  // SİHİRBAZDAKİ LİSTELERLE BİREBİR AYNI YAPILDI
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
    _loadUserData();
  }

  // --- VERİLERİ ÇEK ---
  Future<void> _loadUserData() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
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

            // ANAHTAR KELİMELER SİHİRBAZA GÖRE DÜZELTİLDİ
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

        // KAYIT ANAHTARLARI SİHİRBAZA GÖRE DÜZELTİLDİ
        updateData['interestedSports'] = _selectedSports;
        updateData['experienceLevel'] = _selectedLevel;
        updateData['goal'] = _selectedGoal;
      } else if (_userType == 'coach') {
        updateData['bio'] = _bioController.text.trim();
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
                    // --- FOTOĞRAF ALANI ---
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

                    // --- ORTAK BİLGİLER ---
                    _buildTextField("Ad", _nameController),
                    const SizedBox(height: 16),
                    _buildTextField("Soyad", _surnameController),
                    const SizedBox(height: 16),

                    // --- SPORCU BİLGİLERİ ---
                    if (_userType == 'athlete') ...[
                      // Fiziksel Özellikler
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

                      // Hedef ve Seviye Seçimi (Dropdown)
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

                      // İlgilendiği Sporlar (Çoklu Seçim / ChoiceChip)
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

                    // --- ANTRENÖR BİLGİLERİ ---
                    if (_userType == 'coach') ...[
                      _buildTextField(
                        "Hakkımda (Bio)",
                        _bioController,
                        maxLines: 4,
                      ),
                    ],

                    const SizedBox(height: 40),

                    // --- KAYDET BUTONU ---
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

  // --- YARDIMCI WIDGET: Metin Kutusu ---
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

  // --- YARDIMCI WIDGET: Açılır Menü (Dropdown) ---
  Widget _buildDropdown(
    String label,
    List<String> items,
    String? selectedValue,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: selectedValue,
      isExpanded: true,
      dropdownColor: const Color(0xFF1E1E1E), // Açılan menünün arka planı
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
