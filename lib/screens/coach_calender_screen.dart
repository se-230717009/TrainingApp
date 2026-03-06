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

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('tr_TR', null);
    _selectedDay = _focusedDay;
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

  List<Map<String, dynamic>> _getLessonsForDay(
    DateTime day,
    List<QueryDocumentSnapshot> allLessons,
  ) {
    String dayName = _getWeekdayString(day.weekday);
    List<Map<String, dynamic>> dayLessons = [];
    for (var doc in allLessons) {
      var data = doc.data() as Map<String, dynamic>;
      List<dynamic> days = data['days'] ?? [];
      if (days.contains(dayName)) dayLessons.add(data);
    }
    return dayLessons;
  }

  void _showLessonDetails(Map<String, dynamic> lesson) {
    String type = lesson['lessonType'] ?? 'Online'; // YENİ EKLENDİ

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
                      // YENİ: Branş kartının altına ders tipini de ekledik
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

                  // YENİ: SADECE ONLINE DERSLERDE BAŞLAT BUTONU ÇIKAR
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
                    // YÜZYÜZE İSE BİLGİ VER
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

  // --- MANUEL AKTİVİTE EKLEME MODAL ---
  void _showAddActivityModal() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final hourController = TextEditingController();
    bool isSubmitting = false;
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
                      "Aktivite Ekle",
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
                    _activityTextField(hourController, "Saat (orn: 10:00)"),
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
                                      backgroundColor:
                                          ColorConstants.primaryColor,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorConstants.primaryColor,
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
        floatingActionButton: ScaleButton(
          onPressed: _showAddActivityModal,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: ColorConstants.primaryColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: ColorConstants.primaryColor.withOpacity(0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_rounded, color: Colors.black, size: 20),
                const SizedBox(width: 6),
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
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('lessons')
              .where('coachId', isEqualTo: _auth.currentUser!.uid)
              .where('status', isEqualTo: 'approved')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: ColorConstants.primaryColor,
                ),
              );
            }
            List<QueryDocumentSnapshot> approvedLessons =
                snapshot.data?.docs ?? [];
            return Column(
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
                    eventLoader: (day) =>
                        _getLessonsForDay(day, approvedLessons),
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    calendarStyle: CalendarStyle(
                      defaultTextStyle: GoogleFonts.poppins(
                        color: Colors.white,
                      ),
                      weekendTextStyle: GoogleFonts.poppins(
                        color: Colors.redAccent.withOpacity(0.8),
                      ),
                      outsideTextStyle: GoogleFonts.poppins(
                        color: Colors.white24,
                      ),
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
                      markerDecoration: const BoxDecoration(
                        color: ColorConstants.primaryColor,
                        shape: BoxShape.circle,
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
                      : _buildLessonListForDay(_selectedDay!, approvedLessons),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLessonListForDay(
    DateTime day,
    List<QueryDocumentSnapshot> allLessons,
  ) {
    final lessons = _getLessonsForDay(day, allLessons);
    final String dateStr = DateFormat('yyyy-MM-dd').format(day);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('coach_manual_activities')
          .where('coachId', isEqualTo: _auth.currentUser!.uid)
          .where('date', isEqualTo: dateStr)
          .snapshots(),
      builder: (ctx, snap) {
        final activities = snap.hasData
            ? snap.data!.docs
                  .map((d) => d.data() as Map<String, dynamic>)
                  .toList()
            : <Map<String, dynamic>>[];

        if (lessons.isEmpty && activities.isEmpty) {
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
                  "Bu tarihte etkinlik bulunmuyor.",
                  style: GoogleFonts.poppins(color: Colors.white54),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            // Dersler
            ...lessons.asMap().entries.map((entry) {
              final lesson = entry.value;
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
                    style: GoogleFonts.poppins(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white24,
                    size: 14,
                  ),
                ),
              );
            }),

            // Manuel Aktiviteler
            ...activities.asMap().entries.map((entry) {
              final act = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  tileColor: Colors.orange.withOpacity(0.06),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.orange.withOpacity(0.25)),
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.event_note_rounded,
                      color: Colors.orange,
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
                      if ((act['hour'] as String? ?? '').isNotEmpty)
                        act['hour'],
                      if ((act['description'] as String? ?? '').isNotEmpty)
                        act['description'],
                    ].join(' • '),
                    style: GoogleFonts.poppins(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.calendar_today_outlined,
                    color: Colors.orange,
                    size: 14,
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
