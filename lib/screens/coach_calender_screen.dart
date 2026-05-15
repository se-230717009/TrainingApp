// ignore_for_file: use_build_context_synchronously, unused_field

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../core/constants/color_constants.dart';
import '../widgets/scale_button.dart';
import '../widgets/gradient_background.dart';
import '../widgets/custom_tooltip_bubble.dart';

// --- GLOBAL YARDIMCI FONKSİYONLAR ---
String getWeekdayString(int weekday) {
  switch (weekday) {
    case 1:
      return "Pazartesi";
    case 2:
      return "Salı";
    case 3:
      return "Çarşamba";
    case 4:
      return "Perşembe";
    case 5:
      return "Cuma";
    case 6:
      return "Cumartesi";
    case 7:
      return "Pazar";
    default:
      return "";
  }
}

// Rutin bir dersin/etkinliğin seçili gün için geçerli (tarih aralığında) olup olmadığını kontrol eder
bool isRoutineValidForDay(Map<String, dynamic> r, DateTime day) {
  String dayName = getWeekdayString(day.weekday);
  if (!(r['days'] as List? ?? []).contains(dayName)) return false;

  DateTime dayDateOnly = DateTime(day.year, day.month, day.day);

  if (r['startDate'] != null) {
    DateTime start = DateFormat('yyyy-MM-dd').parse(r['startDate']);
    DateTime startDateOnly = DateTime(start.year, start.month, start.day);
    if (dayDateOnly.isBefore(startDateOnly)) return false;
  }

  if (r['endDate'] != null) {
    DateTime end = DateFormat('yyyy-MM-dd').parse(r['endDate']);
    DateTime endDateOnly = DateTime(end.year, end.month, end.day);
    if (dayDateOnly.isAfter(endDateOnly)) return false;
  }

  return true;
}

class CoachCalendarScreen extends StatefulWidget {
  const CoachCalendarScreen({super.key});

  @override
  State<CoachCalendarScreen> createState() => _CoachCalendarScreenState();
}

class _CoachCalendarScreenState extends State<CoachCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> _lessons = [];
  List<Map<String, dynamic>> _activities = [];
  List<Map<String, dynamic>> _routines = [];

  StreamSubscription<QuerySnapshot>? _lessonsSub;
  StreamSubscription<QuerySnapshot>? _activitiesSub;
  StreamSubscription<QuerySnapshot>? _routinesSub;

  bool _showDayDetailsTooltip = false;
  bool _showAddEventTooltip = false;

  List<String> _coachSpecialties = ['Genel'];
  int _defaultPrice = 0; // Hocanın varsayılan saatlik ücreti

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('tr_TR', null);
    _selectedDay = _focusedDay;
    _setupStreams();
    _fetchCoachData();
    _checkFirstTimeUser();
  }

  Future<void> _fetchCoachData() async {
    final uid = _auth.currentUser!.uid;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    if (doc.exists && mounted) {
      final data = doc.data() as Map<String, dynamic>;
      _defaultPrice = data['hourlyRate'] ?? 0;

      List<dynamic> specs = data['specialties'] ?? [];
      if (specs.isNotEmpty) {
        setState(() {
          _coachSpecialties = specs.map((e) => e.toString()).toList();
        });
      } else if (data['lessonSport'] != null) {
        setState(() {
          _coachSpecialties = [data['lessonSport']];
        });
      }
    }
  }

  Future<void> _checkFirstTimeUser() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .get();
    if (doc.exists) {
      bool isFirst = doc.data()?['isFirstTimeCalendar'] ?? true;
      if (isFirst && mounted) {
        setState(() => _showDayDetailsTooltip = true);
      }
    }
  }

  Future<void> _checkFirstTimeAddEvent() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .get();
    if (doc.exists) {
      bool isFirst = doc.data()?['isFirstTimeAddEvent'] ?? true;
      if (isFirst && mounted) {
        _showInstructionDialog();
      } else {
        _showAdvancedActivityModal();
      }
    }
  }

  void _showInstructionDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Etkinlik Tipleri Nelerdir?",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildInfoRow(
                Icons.bolt_rounded,
                Colors.greenAccent,
                "Özel Ders:",
                "Öğrencilerin sizden randevu alabileceği müsait saatlerinizdir.",
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.groups_rounded,
                Colors.blueAccent,
                "Grup Dersi:",
                "Kontenjanlı grup dersi sınıflarınızdır.",
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.block_rounded,
                Colors.redAccent,
                "Aktivite (Meşgul):",
                "Kişisel işlerinizdir. Bu saatlerde takviminiz kapanır.",
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(_auth.currentUser!.uid)
                        .set({
                          'isFirstTimeAddEvent': false,
                        }, SetOptions(merge: true));
                    Navigator.pop(ctx);
                    _showAdvancedActivityModal();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorConstants.primaryColor,
                  ),
                  child: Text(
                    "Anladım, Devam Et",
                    style: GoogleFonts.poppins(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, Color color, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 13,
                height: 1.5,
              ),
              children: [
                TextSpan(
                  text: "$title ",
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
                TextSpan(text: desc),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showAdvancedActivityModal() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final currentEnrolledCtrl = TextEditingController(text: "0");
    final maxCapacityCtrl = TextEditingController(text: "10");

    // Fiyat varsayılan olarak profilden gelir
    final priceCtrl = TextEditingController(text: _defaultPrice.toString());

    String selectedEventType = 'Özel Ders';
    String recurrenceType = 'Tek Seferlik';
    String startTime = "09:00";
    String endTime = "10:00";
    DateTime safeSelectedDay = _selectedDay ?? _focusedDay;
    List<String> selectedDays = [getWeekdayString(safeSelectedDay.weekday)];
    DateTime? endDate;
    bool isSubmitting = false;

    List<String> sportItems = _coachSpecialties.isNotEmpty
        ? _coachSpecialties
        : ['Genel'];
    String selectedSport = sportItems.first;

    final List<String> timeList = List.generate(
      24,
      (i) => "${i.toString().padLeft(2, '0')}:00",
    );
    final List<String> daysList = [
      "Pazartesi",
      "Salı",
      "Çarşamba",
      "Perşembe",
      "Cuma",
      "Cumartesi",
      "Pazar",
    ];

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
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom,
                  left: 24,
                  right: 24,
                  top: 24,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
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
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Etkinlik Ekle",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Text(
                        "Etkinlik Tipi",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            [
                              'Özel Ders',
                              'Grup Dersi',
                              'Aktivite (Meşgul)',
                            ].map((type) {
                              bool isSelected = selectedEventType == type;
                              Color chipColor = type == 'Aktivite (Meşgul)'
                                  ? Colors.redAccent
                                  : (type == 'Grup Dersi'
                                        ? Colors.blueAccent
                                        : Colors.greenAccent);
                              return ChoiceChip(
                                label: Text(type),
                                selected: isSelected,
                                selectedColor: chipColor,
                                backgroundColor: Colors.white10,
                                labelStyle: GoogleFonts.poppins(
                                  color: isSelected
                                      ? Colors.black
                                      : Colors.white,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                onSelected: (val) {
                                  if (val) {
                                    setModalState(() {
                                      selectedEventType = type;
                                      if (type == 'Grup Dersi')
                                        recurrenceType = 'Haftalık';
                                    });
                                  }
                                },
                              );
                            }).toList(),
                      ),
                      const SizedBox(height: 20),

                      _buildTextField(
                        titleController,
                        "Başlık (Örn: Sabah İdmanı)",
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        descController,
                        "Açıklama (İsteğe Bağlı)",
                      ),
                      const SizedBox(height: 12),

                      // --- YENİ: Saat Doğrulama Mantığı ---
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdown(
                              "Başlangıç",
                              startTime,
                              timeList,
                              (v) {
                                setModalState(() {
                                  startTime = v!;
                                  int sHour = int.parse(
                                    startTime.split(':')[0],
                                  );
                                  int eHour = int.parse(endTime.split(':')[0]);
                                  // Eğer bitiş saati, başlangıç saatinden geri veya eşitse otomatik ileri at
                                  if (eHour <= sHour && eHour != 0) {
                                    if (sHour < 23) {
                                      endTime =
                                          "${(sHour + 1).toString().padLeft(2, '0')}:00";
                                    } else {
                                      endTime = "00:00"; // Gece yarısı
                                    }
                                  }
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDropdown("Bitiş", endTime, timeList, (
                              v,
                            ) {
                              int sHour = int.parse(startTime.split(':')[0]);
                              int eHour = int.parse(v!.split(':')[0]);
                              if (eHour <= sHour && eHour != 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "Bitiş saati başlangıçtan ileri olmalıdır.",
                                      style: GoogleFonts.poppins(),
                                    ),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                              } else {
                                setModalState(() => endTime = v);
                              }
                            }),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Divider(color: Colors.white10),
                      const SizedBox(height: 12),

                      if (selectedEventType != 'Aktivite (Meşgul)') ...[
                        Row(
                          children: [
                            Expanded(
                              child: _buildDropdown(
                                "Branş",
                                selectedSport,
                                sportItems,
                                (v) => setModalState(() => selectedSport = v!),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                priceCtrl,
                                "Ücret (₺)",
                                isNumber: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],

                      if (selectedEventType == 'Grup Dersi') ...[
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: currentEnrolledCtrl,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                style: GoogleFonts.poppins(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: "Kayıtlı (Dışarıdan)",
                                  labelStyle: GoogleFonts.poppins(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white10,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: maxCapacityCtrl,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                style: GoogleFonts.poppins(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: "Toplam Kontenjan",
                                  labelStyle: GoogleFonts.poppins(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white10,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Not: Uygulama üzerinden onaylanan öğrenciler 'Kayıtlı Sayısı'na otomatik eklenir.",
                          style: GoogleFonts.poppins(
                            color: Colors.blueAccent,
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(color: Colors.white10),
                        const SizedBox(height: 12),
                      ],

                      Text(
                        "Tekrar Modeli",
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: ['Tek Seferlik', 'Haftalık'].map((type) {
                          bool isSelected = recurrenceType == type;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(type),
                              selected: isSelected,
                              selectedColor: ColorConstants.primaryColor,
                              backgroundColor: Colors.white10,
                              labelStyle: GoogleFonts.poppins(
                                color: Colors.black,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              onSelected: (val) =>
                                  setModalState(() => recurrenceType = type),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      if (recurrenceType == 'Haftalık') ...[
                        Text(
                          "Tekrar Günleri",
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: daysList.map((day) {
                            final isSelected = selectedDays.contains(day);
                            return ChoiceChip(
                              label: Text(day.substring(0, 3)),
                              selected: isSelected,
                              selectedColor: Colors.blueAccent,
                              backgroundColor: Colors.white10,
                              labelStyle: GoogleFonts.poppins(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.white70,
                              ),
                              onSelected: (val) => setModalState(() {
                                val
                                    ? selectedDays.add(day)
                                    : selectedDays.remove(day);
                              }),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Tekrar Bitiş Tarihi",
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ScaleButton(
                                onPressed: () async {
                                  final now = DateTime.now();
                                  final DateTime? picked = await showDatePicker(
                                    context: context,
                                    initialDate: now.add(
                                      const Duration(days: 30),
                                    ),
                                    firstDate: now,
                                    lastDate: DateTime(2030),
                                    // locale satırı kasıtlı olarak SİLİNDİ, kütüphane çökmesini önler.
                                    builder: (context, child) => Theme(
                                      data: ThemeData.dark().copyWith(
                                        colorScheme: const ColorScheme.dark(
                                          primary: ColorConstants.primaryColor,
                                          onPrimary: Colors.black,
                                          surface: Color(0xFF1E1E1E),
                                          onSurface: Colors.white,
                                        ),
                                      ),
                                      child: child!,
                                    ),
                                  );
                                  if (picked != null)
                                    setModalState(() => endDate = picked);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                    horizontal: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white10,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.date_range_rounded,
                                        color: Colors.white54,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        endDate == null
                                            ? "Tarih Seç"
                                            : DateFormat(
                                                'd MMM yyyy',
                                                'tr_TR',
                                              ).format(endDate!),
                                        style: GoogleFonts.poppins(
                                          color: endDate == null
                                              ? Colors.white54
                                              : Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: CheckboxListTile(
                                title: Text(
                                  "Süresiz",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                                value: endDate == null,
                                activeColor: ColorConstants.primaryColor,
                                checkColor: Colors.black,
                                contentPadding: EdgeInsets.zero,
                                onChanged: (val) => setModalState(
                                  () => endDate = val == true
                                      ? null
                                      : DateTime.now(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  // SON KAYDETME GÜVENLİK DOĞRULAMASI
                                  int sHour = int.parse(
                                    startTime.split(':')[0],
                                  );
                                  int eHour = int.parse(endTime.split(':')[0]);
                                  if (eHour <= sHour && eHour != 0) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          "Bitiş saati başlangıç saatinden ileri olmalıdır.",
                                          style: GoogleFonts.poppins(),
                                        ),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                    return;
                                  }

                                  setModalState(() => isSubmitting = true);
                                  try {
                                    String formattedHour =
                                        "$startTime - $endTime";
                                    bool isUnavailable =
                                        selectedEventType ==
                                        'Aktivite (Meşgul)';
                                    bool isGroupLesson =
                                        selectedEventType == 'Grup Dersi';
                                    bool isPrivateLesson =
                                        selectedEventType == 'Özel Ders';

                                    Map<String, dynamic> actData = {
                                      'coachId': _auth.currentUser!.uid,
                                      'title':
                                          titleController.text.trim().isEmpty
                                          ? selectedEventType
                                          : titleController.text.trim(),
                                      'description': descController.text.trim(),
                                      'hour': formattedHour,
                                      'isUnavailable': isUnavailable,
                                      'isGroupLesson': isGroupLesson,
                                      'isPrivateLesson': isPrivateLesson,
                                      if (!isUnavailable)
                                        'sport': selectedSport,
                                      if (!isUnavailable)
                                        'price':
                                            int.tryParse(priceCtrl.text) ??
                                            _defaultPrice,
                                      'currentEnrolled': isGroupLesson
                                          ? (int.tryParse(
                                                  currentEnrolledCtrl.text,
                                                ) ??
                                                0)
                                          : 0,
                                      'maxCapacity': isGroupLesson
                                          ? (int.tryParse(
                                                  maxCapacityCtrl.text,
                                                ) ??
                                                10)
                                          : 1,
                                      'createdAt': FieldValue.serverTimestamp(),
                                    };

                                    if (recurrenceType == 'Tek Seferlik') {
                                      actData['date'] = DateFormat(
                                        'yyyy-MM-dd',
                                      ).format(safeSelectedDay);
                                      await FirebaseFirestore.instance
                                          .collection('coach_manual_activities')
                                          .add(actData);
                                    } else {
                                      actData['days'] = selectedDays;
                                      actData['startDate'] = DateFormat(
                                        'yyyy-MM-dd',
                                      ).format(safeSelectedDay); // Sınır
                                      actData['endDate'] = endDate != null
                                          ? DateFormat(
                                              'yyyy-MM-dd',
                                            ).format(endDate!)
                                          : null; // Sınır
                                      await FirebaseFirestore.instance
                                          .collection('coach_routines')
                                          .add(actData);
                                    }
                                    if (mounted) {
                                      Navigator.pop(ctx);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            "Başarıyla kaydedildi!",
                                            style: GoogleFonts.poppins(),
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          "Hata oluştu.",
                                          style: GoogleFonts.poppins(),
                                        ),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  } finally {
                                    if (mounted)
                                      setModalState(() => isSubmitting = false);
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: recurrenceType == 'Haftalık'
                                ? Colors.blueAccent
                                : Colors.orange,
                            disabledBackgroundColor: Colors.white10,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: isSubmitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  "Kaydet",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String hint, {
    bool isNumber = false,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      inputFormatters: isNumber
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
      style: GoogleFonts.poppins(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: Colors.white38),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    List<String> uniqueItems = items.toSet().toList();
    if (uniqueItems.isEmpty) uniqueItems.add("Genel");
    String safeValue = uniqueItems.contains(value) ? value : uniqueItems.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(14),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: safeValue,
              isExpanded: true,
              dropdownColor: const Color(0xFF1E1E1E),
              icon: const Icon(
                Icons.access_time_rounded,
                color: Colors.white54,
                size: 18,
              ),
              style: GoogleFonts.poppins(color: Colors.white),
              items: uniqueItems
                  .map((i) => DropdownMenuItem(value: i, child: Text(i)))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  void _setupStreams() {
    final String uid = _auth.currentUser!.uid;
    _lessonsSub = FirebaseFirestore.instance
        .collection('lessons')
        .where('coachId', isEqualTo: uid)
        .where('status', isEqualTo: 'approved')
        .snapshots()
        .listen((snap) {
          if (mounted)
            setState(() => _lessons = snap.docs.map((d) => d.data()).toList());
        });
    _activitiesSub = FirebaseFirestore.instance
        .collection('coach_manual_activities')
        .where('coachId', isEqualTo: uid)
        .snapshots()
        .listen((snap) {
          if (mounted)
            setState(
              () => _activities = snap.docs.map((d) => d.data()).toList(),
            );
        });
    _routinesSub = FirebaseFirestore.instance
        .collection('coach_routines')
        .where('coachId', isEqualTo: uid)
        .snapshots()
        .listen((snap) {
          if (mounted)
            setState(() => _routines = snap.docs.map((d) => d.data()).toList());
        });
  }

  @override
  void dispose() {
    _lessonsSub?.cancel();
    _activitiesSub?.cancel();
    _routinesSub?.cancel();
    super.dispose();
  }

  // --- Takvim Üzerindeki Noktalar (Lejant) ---
  List<String> _getEventTypesForDay(DateTime day) {
    String dateStr = DateFormat('yyyy-MM-dd').format(day);
    List<String> types = [];

    bool hasGroup =
        _activities.any(
          (a) => a['date'] == dateStr && a['isGroupLesson'] == true,
        ) ||
        _routines.any(
          (r) => isRoutineValidForDay(r, day) && r['isGroupLesson'] == true,
        );
    if (hasGroup) types.add('group');

    bool hasPrivate =
        _activities.any(
          (a) => a['date'] == dateStr && a['isPrivateLesson'] == true,
        ) ||
        _routines.any(
          (r) => isRoutineValidForDay(r, day) && r['isPrivateLesson'] == true,
        );
    if (hasPrivate) types.add('private');

    bool hasBusy =
        _activities.any(
          (a) => a['date'] == dateStr && a['isUnavailable'] == true,
        ) ||
        _routines.any(
          (r) => isRoutineValidForDay(r, day) && r['isUnavailable'] == true,
        );

    // Onaylanmış dersleri de meşgul (Kırmızı) olarak ekliyoruz
    bool hasLesson = _lessons.any(
      (l) =>
          (l['days'] as List).contains(getWeekdayString(day.weekday)) ||
          l['date'] == dateStr,
    );

    if (hasBusy || hasLesson) types.add('busy');

    return types;
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildDot(Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1.5),
      width: 6,
      height: 6,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.black.withOpacity(0.6),
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Text(
            "Takvimim",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        floatingActionButton: _selectedDay != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  CustomTooltipBubble(
                    isVisible: _showAddEventTooltip,
                    message:
                        "Dilerseniz buradan da aktivite veya ders ekleyebilirsiniz.",
                    onClose: () {
                      setState(() => _showAddEventTooltip = false);
                      FirebaseFirestore.instance
                          .collection('users')
                          .doc(_auth.currentUser!.uid)
                          .set({
                            'isFirstTimeCalendar': false,
                          }, SetOptions(merge: true));
                    },
                    child: ScaleButton(
                      onPressed: () {
                        if (_showAddEventTooltip) {
                          setState(() => _showAddEventTooltip = false);
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(_auth.currentUser!.uid)
                              .set({
                                'isFirstTimeCalendar': false,
                              }, SetOptions(merge: true));
                        }
                        _checkFirstTimeAddEvent();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.add_circle_outline_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Etkinlik Ekle",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  CustomTooltipBubble(
                    isVisible: _showDayDetailsTooltip,
                    message:
                        "Burada günlerinizi planlayabilir, etkinlik ekleyebilir ve planlarınızı inceleyebilirsiniz.",
                    onClose: () {
                      setState(() {
                        _showDayDetailsTooltip = false;
                        _showAddEventTooltip = true;
                      });
                    },
                    child: ScaleButton(
                      onPressed: () {
                        if (_showDayDetailsTooltip) {
                          setState(() {
                            _showDayDetailsTooltip = false;
                            _showAddEventTooltip = true;
                          });
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CoachDayDetailsScreen(
                              selectedDate: _selectedDay!,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: ColorConstants.primaryColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: ColorConstants.primaryColor.withOpacity(
                                0.35,
                              ),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.view_day_rounded,
                              color: Colors.black,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Gün Detayları",
                              style: GoogleFonts.poppins(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : null,
        body: Column(
          children: [
            SizedBox(
              height: MediaQuery.of(context).padding.top + kToolbarHeight + 8,
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(Colors.greenAccent, "Özel Ders"),
                const SizedBox(width: 12),
                _buildLegendItem(Colors.blueAccent, "Grup Dersi"),
                const SizedBox(width: 12),
                _buildLegendItem(Colors.redAccent, "Meşgul"),
              ],
            ),
            const SizedBox(height: 8),

            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
              ),
              child: TableCalendar(
                locale: 'tr_TR',
                firstDay: DateTime.utc(2023, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) => setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                }),
                startingDayOfWeek: StartingDayOfWeek.monday,
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, day, focusedDay) {
                    final types = _getEventTypesForDay(day);
                    if (types.isEmpty) return const SizedBox();
                    List<Widget> dots = [];
                    if (types.contains('private'))
                      dots.add(_buildDot(Colors.greenAccent));
                    if (types.contains('group'))
                      dots.add(_buildDot(Colors.blueAccent));
                    if (types.contains('busy'))
                      dots.add(_buildDot(Colors.redAccent));
                    return Positioned(
                      bottom: 6,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: dots,
                      ),
                    );
                  },
                ),
                calendarStyle: CalendarStyle(
                  defaultTextStyle: GoogleFonts.poppins(color: Colors.white),
                  weekendTextStyle: GoogleFonts.poppins(
                    color: Colors.redAccent.withOpacity(0.8),
                  ),
                  outsideTextStyle: GoogleFonts.poppins(color: Colors.white24),
                  todayDecoration: const BoxDecoration(
                    color: Colors.white10,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: ColorConstants.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  selectedTextStyle: GoogleFonts.poppins(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                headerStyle: HeaderStyle(
                  titleCentered: true,
                  formatButtonVisible: false,
                  titleTextStyle: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  leftChevronIcon: const Icon(
                    Icons.chevron_left,
                    color: Colors.white,
                  ),
                  rightChevronIcon: const Icon(
                    Icons.chevron_right,
                    color: Colors.white,
                  ),
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: GoogleFonts.poppins(color: Colors.white70),
                  weekendStyle: GoogleFonts.poppins(
                    color: Colors.redAccent.withOpacity(0.5),
                  ),
                ),
              ),
            ),
            if (_selectedDay != null)
              Expanded(
                child: Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.start),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class CoachDayDetailsScreen extends StatefulWidget {
  final DateTime selectedDate;
  const CoachDayDetailsScreen({super.key, required this.selectedDate});
  @override
  State<CoachDayDetailsScreen> createState() => _CoachDayDetailsScreenState();
}

class _CoachDayDetailsScreenState extends State<CoachDayDetailsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> _lessons = [];
  List<Map<String, dynamic>> _activities = [];
  List<Map<String, dynamic>> _routines = [];
  StreamSubscription? _lessonsSub, _activitiesSub, _routinesSub;

  List<String> _coachSpecialties = ['Genel'];

  @override
  void initState() {
    super.initState();
    _setupStreams();
    _fetchCoachSpecialties();
  }

  Future<void> _fetchCoachSpecialties() async {
    final uid = _auth.currentUser!.uid;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    if (doc.exists && mounted) {
      final data = doc.data() as Map<String, dynamic>;
      List<dynamic> specs = data['specialties'] ?? [];
      if (specs.isNotEmpty) {
        setState(
          () => _coachSpecialties = specs.map((e) => e.toString()).toList(),
        );
      } else if (data['lessonSport'] != null) {
        setState(() => _coachSpecialties = [data['lessonSport']]);
      }
    }
  }

  void _setupStreams() {
    final String uid = _auth.currentUser!.uid;
    getWeekdayString(widget.selectedDate.weekday);
    String dateStr = DateFormat('yyyy-MM-dd').format(widget.selectedDate);
    _lessonsSub = FirebaseFirestore.instance
        .collection('lessons')
        .where('coachId', isEqualTo: uid)
        .where('status', isEqualTo: 'approved')
        .snapshots()
        .listen((snap) {
          if (mounted)
            setState(
              () => _lessons = snap.docs
                  .map((d) => <String, dynamic>{...d.data(), 'id': d.id})
                  .toList(),
            );
        });
    _activitiesSub = FirebaseFirestore.instance
        .collection('coach_manual_activities')
        .where('coachId', isEqualTo: uid)
        .where('date', isEqualTo: dateStr)
        .snapshots()
        .listen((snap) {
          if (mounted)
            setState(
              () => _activities = snap.docs
                  .map((d) => <String, dynamic>{...d.data(), 'id': d.id})
                  .toList(),
            );
        });
    _routinesSub = FirebaseFirestore.instance
        .collection('coach_routines')
        .where('coachId', isEqualTo: uid)
        .snapshots()
        .listen((snap) {
          if (mounted) {
            final allRoutines = snap.docs
                .map((d) => <String, dynamic>{...d.data(), 'id': d.id})
                .toList();
            setState(
              () => _routines = allRoutines
                  .where((r) => isRoutineValidForDay(r, widget.selectedDate))
                  .toList(),
            );
          }
        });
  }

  @override
  void dispose() {
    _lessonsSub?.cancel();
    _activitiesSub?.cancel();
    _routinesSub?.cancel();
    super.dispose();
  }

  List<Map<String, dynamic>> _getEventsForHour(int hour) {
    List<Map<String, dynamic>> events = [];
    String hourStr = hour.toString().padLeft(2, '0');
    for (var act in _activities) {
      if (act['hour'] != null && act['hour'].toString().startsWith(hourStr))
        events.add({...act, 'type': 'activity'});
    }
    for (var r in _routines) {
      if (r['hour'] != null && r['hour'].toString().startsWith(hourStr))
        events.add({...r, 'type': 'routine'});
    }
    for (var l in _lessons) {
      List<dynamic> hours = l['hours'] ?? [];
      for (String hRange in hours) {
        if (hRange.startsWith(hourStr)) events.add({...l, 'type': 'lesson'});
      }
    }
    return events;
  }

  void _showEventDetailsModal(Map<String, dynamic> event) {
    bool isLesson = event['type'] == 'lesson';
    bool isGroupLesson = event['isGroupLesson'] == true;
    bool isUnavail = event['isUnavailable'] == true;
    bool isPrivateLesson = event['isPrivateLesson'] == true;

    String title = event['title'] ?? event['athleteName'] ?? '';
    if (title.isEmpty)
      title = isLesson
          ? 'Ders'
          : (isGroupLesson
                ? 'Grup Dersi'
                : (isPrivateLesson ? 'Özel Ders' : 'Aktivite'));

    String time =
        event['hour'] ??
        (event['hours'] != null ? (event['hours'] as List).join(', ') : '');
    String desc = event['description'] ?? '';
    if (desc.isEmpty)
      desc = isLesson
          ? "${event['sport']} Dersi"
          : (isUnavail
                ? "Zaman Kapatıldı (Meşgul)"
                : (isGroupLesson
                      ? "Grup Dersi (Müsait)"
                      : "Özel Ders (Müsait)"));

    int currentEnrolled = event['currentEnrolled'] ?? 0;
    int totalEnrolled =
        currentEnrolled +
        _lessons
            .where(
              (l) =>
                  l['lessonType'] == 'Grup Dersi' &&
                  (l['hours'] as List).contains(event['hour']),
            )
            .length;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                const SizedBox(height: 20),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      color: Colors.white54,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      time,
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                if (desc.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    desc,
                    style: GoogleFonts.poppins(
                      color: Colors.white54,
                      fontSize: 13,
                    ),
                  ),
                ],
                if (event['price'] != null && event['price'] > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    "Ücret: ${event['price']} ₺",
                    style: GoogleFonts.poppins(
                      color: Colors.greenAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
                if (isGroupLesson) ...[
                  if (event['sport'] != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      "Branş: ${event['sport']}",
                      style: GoogleFonts.poppins(
                        color: Colors.blueAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.blueAccent.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.groups_rounded,
                          color: Colors.blueAccent,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Mevcut: $totalEnrolled / ${event['maxCapacity'] ?? '-'}",
                          style: GoogleFonts.poppins(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      String docId = event['id'];
                      try {
                        if (isLesson) {
                          await FirebaseFirestore.instance
                              .collection('lessons')
                              .doc(docId)
                              .update({'status': 'cancelled'});
                        } else if (event['type'] == 'activity') {
                          await FirebaseFirestore.instance
                              .collection('coach_manual_activities')
                              .doc(docId)
                              .delete();
                        } else if (event['type'] == 'routine') {
                          await FirebaseFirestore.instance
                              .collection('coach_routines')
                              .doc(docId)
                              .delete();
                        }
                        if (mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isLesson
                                    ? "Ders iptal edildi."
                                    : "Etkinlik kaldırıldı.",
                                style: GoogleFonts.poppins(),
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "Hata oluştu.",
                              style: GoogleFonts.poppins(),
                            ),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent.withOpacity(0.1),
                      elevation: 0,
                      side: BorderSide(
                        color: Colors.redAccent.withOpacity(0.5),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      isLesson ? "Bu Dersi İptal Et" : "Bu Etkinliği Kaldır",
                      style: GoogleFonts.poppins(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
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
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            "${widget.selectedDate.day} ${getWeekdayString(widget.selectedDate.weekday)} Planı",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(color: Colors.white10),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 40, top: 8),
                itemCount: 24,
                itemBuilder: (context, index) {
                  String timeLabel = "${index.toString().padLeft(2, '0')}:00";
                  List<Map<String, dynamic>> hourEvents = _getEventsForHour(
                    index,
                  );

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 55,
                          child: Text(
                            timeLabel,
                            style: GoogleFonts.poppins(
                              color: Colors.white54,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(color: Colors.white10),
                              ),
                            ),
                            padding: const EdgeInsets.only(top: 8, left: 8),
                            child: hourEvents.isEmpty
                                ? const SizedBox(height: 40)
                                : Column(
                                    children: hourEvents.map((event) {
                                      bool isGroupLesson =
                                          event['isGroupLesson'] == true;
                                      bool isUnavail =
                                          event['isUnavailable'] == true;
                                      bool isPrivateLesson =
                                          event['isPrivateLesson'] == true;

                                      Color cardColor = isUnavail
                                          ? Colors.redAccent
                                          : (isGroupLesson
                                                ? Colors.blueAccent
                                                : (isPrivateLesson
                                                      ? Colors.greenAccent
                                                      : ColorConstants
                                                            .primaryColor));

                                      int totalEnrolled =
                                          (event['currentEnrolled'] ?? 0) +
                                          _lessons
                                              .where(
                                                (l) =>
                                                    l['lessonType'] ==
                                                        'Grup Dersi' &&
                                                    (l['hours'] as List)
                                                        .contains(
                                                          event['hour'],
                                                        ),
                                              )
                                              .length;

                                      return ScaleButton(
                                        onPressed: () =>
                                            _showEventDetailsModal(event),
                                        child: Container(
                                          margin: const EdgeInsets.only(
                                            bottom: 8,
                                          ),
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: cardColor.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: cardColor.withOpacity(0.5),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                isGroupLesson
                                                    ? Icons.groups_rounded
                                                    : (isUnavail
                                                          ? Icons.block_rounded
                                                          : (isPrivateLesson
                                                                ? Icons
                                                                      .bolt_rounded
                                                                : Icons
                                                                      .fitness_center_rounded)),
                                                color: cardColor,
                                                size: 18,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      event['title'] ??
                                                          event['athleteName'] ??
                                                          'Etkinlik',
                                                      style:
                                                          GoogleFonts.poppins(
                                                            color: cardColor,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 13,
                                                          ),
                                                    ),
                                                    if (event['hour'] != null ||
                                                        event['hours'] != null)
                                                      Text(
                                                        event['hour'] ??
                                                            (event['hours']
                                                                    as List)
                                                                .join(', '),
                                                        style:
                                                            GoogleFonts.poppins(
                                                              color: Colors
                                                                  .white70,
                                                              fontSize: 11,
                                                            ),
                                                      ),
                                                    if (isGroupLesson &&
                                                        event['sport'] !=
                                                            null) ...[
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        "Branş: ${event['sport']}",
                                                        style:
                                                            GoogleFonts.poppins(
                                                              color: Colors
                                                                  .white70,
                                                              fontSize: 11,
                                                            ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 6,
                                                              vertical: 2,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: Colors
                                                              .blueAccent
                                                              .withOpacity(0.2),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                4,
                                                              ),
                                                        ),
                                                        child: Text(
                                                          "Mevcut: $totalEnrolled / ${event['maxCapacity'] ?? '-'}",
                                                          style:
                                                              GoogleFonts.poppins(
                                                                color: Colors
                                                                    .blueAccent,
                                                                fontSize: 10,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
