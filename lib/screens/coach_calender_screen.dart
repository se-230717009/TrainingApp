import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../core/constants/color_constants.dart';
import '../widgets/scale_button.dart';
import 'chat_screen.dart';
import 'video_call_screen.dart';
import '../widgets/gradient_background.dart';

class CoachCalendarScreen extends StatefulWidget {
  const CoachCalendarScreen({super.key});

  @override
  State<CoachCalendarScreen> createState() => _CoachCalendarScreenState();
}

class _CoachCalendarScreenState extends State<CoachCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- VERİLERİN TUTULACAĞI LİSTELER (Takvimdeki noktalar için) ---
  List<Map<String, dynamic>> _lessons = [];
  List<Map<String, dynamic>> _activities = [];
  List<Map<String, dynamic>> _routines = [];

  StreamSubscription<QuerySnapshot>? _lessonsSub;
  StreamSubscription<QuerySnapshot>? _activitiesSub;
  StreamSubscription<QuerySnapshot>? _routinesSub;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('tr_TR', null);
    _selectedDay = _focusedDay;
    _setupStreams();
  }

  void _setupStreams() {
    final String uid = _auth.currentUser!.uid;

    _lessonsSub = FirebaseFirestore.instance
        .collection('lessons')
        .where('coachId', isEqualTo: uid)
        .where('status', isEqualTo: 'approved')
        .snapshots()
        .listen((snap) {
          if (mounted) {
            setState(() => _lessons = snap.docs.map((d) => d.data()).toList());
          }
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

  String _getWeekdayString(int weekday) {
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

  // --- TAKVİMDEKİ NOKTALARI BELİRLEYEN FONKSİYON ---
  // --- TAKVİMDEKİ RENKLİ NOKTALARI BELİRLEYEN FONKSİYON ---
  List<dynamic> _getEventsForDay(DateTime day) {
    String dayName = _getWeekdayString(day.weekday);
    String dateStr = DateFormat('yyyy-MM-dd').format(day);

    bool hasBusy =
        _activities.any(
          (a) => a['date'] == dateStr && (a['isUnavailable'] == true),
        ) ||
        _routines.any(
          (r) =>
              (r['days'] as List).contains(dayName) &&
              (r['isUnavailable'] == true),
        );

    bool hasLesson = _lessons.any((l) => (l['days'] as List).contains(dayName));

    bool hasOther =
        _activities.any(
          (a) => a['date'] == dateStr && (a['isUnavailable'] != true),
        ) ||
        _routines.any(
          (r) =>
              (r['days'] as List).contains(dayName) &&
              (r['isUnavailable'] != true),
        );

    List<String> events = [];
    if (hasBusy) events.add('busy');
    if (hasLesson) events.add('lesson');
    if (hasOther) events.add('other');

    return events;
  }

  void _showLessonDetails(Map<String, dynamic> lesson) {
    String type = lesson['lessonType'] ?? 'Online';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
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
                  const SizedBox(height: 24),
                  Text(
                    "Ders Detayı",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.white10,
                          backgroundImage: lesson['athleteImage'] != null
                              ? NetworkImage(lesson['athleteImage'])
                              : null,
                          child: lesson['athleteImage'] == null
                              ? const Icon(Icons.person, color: Colors.white54)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lesson['athleteName'],
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "Öğrenci",
                                style: GoogleFonts.poppins(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(
                                  receiverId: lesson['athleteId'],
                                  receiverName: lesson['athleteName'],
                                ),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.chat_bubble_outline_rounded,
                            color: ColorConstants.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          Icons.access_time_rounded,
                          "Saatler",
                          (lesson['hours'] as List).join('\n'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildInfoCard(
                          Icons.sports_gymnastics_rounded,
                          "Branş / Tip",
                          "${lesson['sport']}\n$type",
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  if (type == 'Online') ...[
                    ScaleButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VideoCallScreen(
                              roomName: "${lesson['sport']} Dersi",
                              remoteUserName:
                                  lesson['athleteName'] ?? "Öğrenci",
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: ColorConstants.primaryColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.play_circle_fill_rounded,
                              color: Colors.black,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Dersi Başlat",
                              style: GoogleFonts.poppins(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        "Oda ders saatinden 10 dk önce açılır.",
                        style: GoogleFonts.poppins(
                          color: Colors.white30,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ] else ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.directions_run_rounded,
                            color: Colors.white54,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Yüzyüze Antrenman",
                            style: GoogleFonts.poppins(
                              color: Colors.white54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: ColorConstants.primaryColor, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // --- TEKİL AKTİVİTE EKLEME MODAL ---
  void _showAddActivityModal() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final hourController = TextEditingController();
    bool isSubmitting = false;
    bool isUnavailable = false; // YENİ: MEŞGUL İŞARETİ
    final selectedDate = _selectedDay ?? DateTime.now();

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
            return Padding(
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
                    Text(
                      "Tekil Aktivite Ekle",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      DateFormat(
                        'd MMMM yyyy, EEEE',
                        'tr_TR',
                      ).format(selectedDate),
                      style: GoogleFonts.poppins(
                        color: ColorConstants.primaryColor,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _activityTextField(titleController, "Başlık (zorunlu)"),
                    const SizedBox(height: 12),
                    _activityTextField(
                      hourController,
                      "Saat (örn: 10:00 - Boş bırakılabilir)",
                    ),
                    const SizedBox(height: 12),

                    // --- YENİ EKLENEN ŞIK MEŞGUL BUTONU ---
                    GestureDetector(
                      onTap: () =>
                          setModalState(() => isUnavailable = !isUnavailable),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: isUnavailable
                              ? Colors.redAccent.withOpacity(0.1)
                              : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isUnavailable
                                ? Colors.redAccent.withOpacity(0.5)
                                : Colors.white10,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.block_rounded,
                              color: isUnavailable
                                  ? Colors.redAccent
                                  : Colors.white54,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Dolu olarak işaretle",
                                    style: GoogleFonts.poppins(
                                      color: isUnavailable
                                          ? Colors.redAccent
                                          : Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    "Öğrenciler bu saate/güne ders alamaz.",
                                    style: GoogleFonts.poppins(
                                      color: Colors.white54,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: isUnavailable,
                              onChanged: (v) =>
                                  setModalState(() => isUnavailable = v),
                              activeColor: Colors.redAccent,
                              inactiveTrackColor: Colors.white10,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _activityTextField(
                      descController,
                      "Açıklama (isteğe bağlı)",
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            (isSubmitting ||
                                titleController.text.trim().isEmpty)
                            ? null
                            : () async {
                                setModalState(() => isSubmitting = true);
                                await FirebaseFirestore.instance
                                    .collection('coach_manual_activities')
                                    .add({
                                      'coachId': _auth.currentUser!.uid,
                                      'date': DateFormat(
                                        'yyyy-MM-dd',
                                      ).format(selectedDate),
                                      'title': titleController.text.trim(),
                                      'description': descController.text.trim(),
                                      'hour': hourController.text.trim(),
                                      'isUnavailable':
                                          isUnavailable, // YENİ VERİ TABANI ALANI
                                      'createdAt': FieldValue.serverTimestamp(),
                                    });
                                if (mounted) {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "Aktivite eklendi!",
                                        style: GoogleFonts.poppins(),
                                      ),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
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
                                  color: Colors.black,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                "Aktiviteyi Kaydet",
                                style: GoogleFonts.poppins(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- HAFTALIK RUTİN EKLEME MODAL ---
  void _showAddRoutineModal() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final hourController = TextEditingController();
    bool isSubmitting = false;
    bool isUnavailable = false; // YENİ: MEŞGUL İŞARETİ
    List<String> selectedDays = [];
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
            return Padding(
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
                    Text(
                      "Haftalık Rutin Ekle",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Hangi günler tekrarlanacak?",
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: daysList.map((day) {
                        final isSelected = selectedDays.contains(day);
                        return ChoiceChip(
                          label: Text(day),
                          selected: isSelected,
                          selectedColor: Colors.blueAccent,
                          backgroundColor: Colors.white,
                          labelStyle: GoogleFonts.poppins(
                            color: isSelected
                                ? Colors.white
                                : Colors.black, // Yazı simsiyah oldu
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w600,
                          ),
                          onSelected: (val) {
                            setModalState(() {
                              if (val)
                                selectedDays.add(day);
                              else
                                selectedDays.remove(day);
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    _activityTextField(titleController, "Başlık (zorunlu)"),
                    const SizedBox(height: 12),
                    _activityTextField(
                      hourController,
                      "Saat (örn: 10:00 - Boş bırakılabilir)",
                    ),
                    const SizedBox(height: 12),

                    // --- YENİ EKLENEN ŞIK MEŞGUL BUTONU ---
                    GestureDetector(
                      onTap: () =>
                          setModalState(() => isUnavailable = !isUnavailable),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: isUnavailable
                              ? Colors.redAccent.withOpacity(0.1)
                              : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isUnavailable
                                ? Colors.redAccent.withOpacity(0.5)
                                : Colors.white10,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.block_rounded,
                              color: isUnavailable
                                  ? Colors.redAccent
                                  : Colors.white54,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Zamanı Kapat (Dolu)",
                                    style: GoogleFonts.poppins(
                                      color: isUnavailable
                                          ? Colors.redAccent
                                          : Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    "Öğrenciler rutin günlerinde ders alamaz.",
                                    style: GoogleFonts.poppins(
                                      color: Colors.white54,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: isUnavailable,
                              onChanged: (v) =>
                                  setModalState(() => isUnavailable = v),
                              activeColor: Colors.redAccent,
                              inactiveTrackColor: Colors.white10,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _activityTextField(
                      descController,
                      "Açıklama (isteğe bağlı)",
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            (isSubmitting ||
                                titleController.text.trim().isEmpty ||
                                selectedDays.isEmpty)
                            ? null
                            : () async {
                                setModalState(() => isSubmitting = true);
                                await FirebaseFirestore.instance
                                    .collection('coach_routines')
                                    .add({
                                      'coachId': _auth.currentUser!.uid,
                                      'days': selectedDays,
                                      'title': titleController.text.trim(),
                                      'description': descController.text.trim(),
                                      'hour': hourController.text.trim(),
                                      'isUnavailable':
                                          isUnavailable, // YENİ VERİ TABANI ALANI
                                      'createdAt': FieldValue.serverTimestamp(),
                                    });
                                if (mounted) {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "Rutin eklendi!",
                                        style: GoogleFonts.poppins(),
                                      ),
                                      backgroundColor: Colors.blueAccent,
                                    ),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
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
                                "Rutini Kaydet",
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _activityTextField(
    TextEditingController ctrl,
    String hint, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
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
            "Takvimim",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ScaleButton(
              onPressed: _showAddRoutineModal,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueAccent.withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.repeat_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Rutin Ekle",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            ScaleButton(
              onPressed: _showAddActivityModal,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.event_note_rounded,
                      color: Colors.black,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Aktivite Ekle",
                      style: GoogleFonts.poppins(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        body: Column(
          children: [
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
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                eventLoader: _getEventsForDay, // YENİ: Anlık nokta okuyucu
                startingDayOfWeek: StartingDayOfWeek.monday,
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, day, events) {
                    if (events.isEmpty) return const SizedBox();
                    return Positioned(
                      bottom: 6,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: events.map((event) {
                          Color dotColor =
                              Colors.orange; // Default: Aktiviteler (Turuncu)
                          if (event == 'busy')
                            dotColor = Colors.redAccent; // Meşgul (Kırmızı)
                          if (event == 'lesson')
                            dotColor =
                                ColorConstants.primaryColor; // Ders (Yeşil)

                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1.5),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: dotColor,
                            ),
                          );
                        }).toList(),
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
            const SizedBox(height: 10),
            if (_selectedDay != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.date_range,
                      color: ColorConstants.primaryColor,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat(
                        'd MMMM yyyy, EEEE',
                        'tr_TR',
                      ).format(_selectedDay!),
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            Expanded(
              child: _selectedDay == null
                  ? Center(
                      child: Text(
                        "Dersleri görmek için bir gün seçin.",
                        style: GoogleFonts.poppins(color: Colors.white54),
                      ),
                    )
                  : _buildLessonListForDay(_selectedDay!),
            ),
          ],
        ),
      ),
    );
  }

  // YENİ: StreamBuilder kullanmak yerine hafızadaki (initState'de çekilen) verileri anında yansıtıyoruz
  Widget _buildLessonListForDay(DateTime day) {
    String dayName = _getWeekdayString(day.weekday);
    String dateStr = DateFormat('yyyy-MM-dd').format(day);

    final dayLessons = _lessons
        .where((l) => (l['days'] as List).contains(dayName))
        .toList();
    final dayActivities = _activities
        .where((a) => a['date'] == dateStr)
        .toList();
    final dayRoutines = _routines
        .where((r) => (r['days'] as List).contains(dayName))
        .toList();

    if (dayLessons.isEmpty && dayActivities.isEmpty && dayRoutines.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.event_busy_rounded,
              color: Colors.white24,
              size: 50,
            ),
            const SizedBox(height: 16),
            Text(
              "Bu tarihte etkinlik veya rutin bulunmuyor.",
              style: GoogleFonts.poppins(color: Colors.white54),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // 1. Alınan Dersler
        ...dayLessons.map((lesson) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              onTap: () => _showLessonDetails(lesson),
              tileColor: Colors.white.withOpacity(0.05),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: ColorConstants.primaryColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.fitness_center_rounded,
                  color: ColorConstants.primaryColor,
                  size: 20,
                ),
              ),
              title: Text(
                lesson['athleteName'],
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                "${(lesson['hours'] as List).join(', ')} • ${lesson['sport']}",
                style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white24,
                size: 14,
              ),
            ),
          );
        }),

        // 2. Haftalık Rutinler
        ...dayRoutines.map((routine) {
          final bool isUnavail = routine['isUnavailable'] ?? false;
          final Color tColor = isUnavail ? Colors.redAccent : Colors.blueAccent;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              tileColor: tColor.withOpacity(0.06),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: tColor.withOpacity(0.25)),
              ),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: tColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isUnavail ? Icons.block_rounded : Icons.repeat_rounded,
                  color: tColor,
                  size: 20,
                ),
              ),
              title: Text(
                routine['title'] ?? 'Rutin',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                [
                  if ((routine['hour'] as String? ?? '').isNotEmpty)
                    routine['hour'],
                  if ((routine['description'] as String? ?? '').isNotEmpty)
                    routine['description'],
                ].join(' • '),
                style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: tColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isUnavail ? "Meşgul" : "Rutin",
                  style: GoogleFonts.poppins(
                    color: tColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        }),

        // 3. Tekil Aktiviteler
        ...dayActivities.map((act) {
          final bool isUnavail = act['isUnavailable'] ?? false;
          final Color tColor = isUnavail ? Colors.redAccent : Colors.orange;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              tileColor: tColor.withOpacity(0.06),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: tColor.withOpacity(0.25)),
              ),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: tColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isUnavail ? Icons.block_rounded : Icons.event_note_rounded,
                  color: tColor,
                  size: 20,
                ),
              ),
              title: Text(
                act['title'] ?? 'Aktivite',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                [
                  if ((act['hour'] as String? ?? '').isNotEmpty) act['hour'],
                  if ((act['description'] as String? ?? '').isNotEmpty)
                    act['description'],
                ].join(' • '),
                style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: tColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isUnavail ? "Meşgul" : "Tekil",
                  style: GoogleFonts.poppins(
                    color: tColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
