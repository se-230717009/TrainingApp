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
            ? ScaleButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CoachDayDetailsScreen(selectedDate: _selectedDay!),
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
                        color: ColorConstants.primaryColor.withOpacity(0.35),
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
              )
            : null,
        body: Column(
          children: [
            SizedBox(
              height: MediaQuery.of(context).padding.top + kToolbarHeight + 8,
            ),
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
                eventLoader: _getEventsForDay,
                startingDayOfWeek: StartingDayOfWeek.monday,
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, day, events) {
                    if (events.isEmpty) return const SizedBox();
                    return Positioned(
                      bottom: 6,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: events.map((event) {
                          Color dotColor = Colors.orange;
                          if (event == 'busy') dotColor = Colors.redAccent;
                          if (event == 'lesson')
                            dotColor = ColorConstants.primaryColor;
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
            if (_selectedDay != null)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      const Icon(
                        Icons.touch_app_rounded,
                        color: Colors.white24,
                        size: 50,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Saatlik planı görmek ve aktivite eklemek için\n'Gün Detayları' butonuna tıklayın.",
                        style: GoogleFonts.poppins(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
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

  // Hocanın uzmanlık alanları (Branş seçimi için)
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

  void _setupStreams() {
    final String uid = _auth.currentUser!.uid;
    String dayName = _getWeekdayString(widget.selectedDate.weekday);
    String dateStr = DateFormat('yyyy-MM-dd').format(widget.selectedDate);
    _lessonsSub = FirebaseFirestore.instance
        .collection('lessons')
        .where('coachId', isEqualTo: uid)
        .where('status', isEqualTo: 'approved')
        .where('days', arrayContains: dayName)
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
        .where('days', arrayContains: dayName)
        .snapshots()
        .listen((snap) {
          if (mounted)
            setState(
              () => _routines = snap.docs
                  .map((d) => <String, dynamic>{...d.data(), 'id': d.id})
                  .toList(),
            );
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
    String title = event['title'] ?? event['athleteName'] ?? 'Etkinlik';
    String time =
        event['hour'] ??
        (event['hours'] != null ? (event['hours'] as List).join(', ') : '');
    String desc =
        event['description'] ??
        (isLesson
            ? "${event['sport']} Dersi"
            : (isUnavail ? "Zaman Kapatıldı" : ""));

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

  void _showAdvancedActivityModal() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final currentEnrolledCtrl = TextEditingController(text: "0");
    final maxCapacityCtrl = TextEditingController(text: "10");

    String recurrenceType = 'Tek Seferlik';
    String startTime = "09:00";
    String endTime = "10:00";
    List<String> selectedDays = [
      _getWeekdayString(widget.selectedDate.weekday),
    ];
    bool isUnavailable = false;
    bool isGroupLesson = false;
    DateTime? endDate;
    bool isSubmitting = false;

    // Güvenli Branş Seçimi
    List<String> sportItems = _coachSpecialties.isNotEmpty
        ? _coachSpecialties
        : ['Genel'];
    String selectedSport = sportItems.first;

    final List<String> daysList = [
      "Pazartesi",
      "Salı",
      "Çarşamba",
      "Perşembe",
      "Cuma",
      "Cumartesi",
      "Pazar",
    ];
    final List<String> timeList = List.generate(
      24,
      (i) => "${i.toString().padLeft(2, '0')}:00",
    );

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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Aktivite Ayarları",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close, color: Colors.white54),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      titleController,
                      "Başlık (Örn: Özel Antrenman)",
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdown(
                            "Başlangıç",
                            startTime,
                            timeList,
                            (v) => setModalState(() => startTime = v!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDropdown(
                            "Bitiş",
                            endTime,
                            timeList,
                            (v) => setModalState(() => endTime = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 12),

                    // --- YENİ: GRUP DERSİ SEÇENEĞİ ---
                    SwitchListTile(
                      title: Text(
                        "Bu bir Grup Dersi mi?",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        "Birden fazla öğrencinin katılabileceği kontenjanlı sınıf.",
                        style: GoogleFonts.poppins(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                      value: isGroupLesson,
                      activeColor: Colors.blueAccent,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) => setModalState(() {
                        isGroupLesson = val;
                        if (val) isUnavailable = false;
                      }),
                    ),
                    if (isGroupLesson) ...[
                      const SizedBox(height: 12),
                      _buildDropdown(
                        "Branş",
                        selectedSport,
                        sportItems,
                        (v) => setModalState(() => selectedSport = v!),
                      ),
                      const SizedBox(height: 12),
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
                                labelText: "Kayıtlı Sayısı (Dışarıdan)",
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
                                labelText: "Toplam Mevcut",
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
                        "Not: Uygulama üzerinden onayladığınız öğrenciler 'Kayıtlı Sayısı'na otomatik olarak eklenecektir.",
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
                              color: isSelected ? Colors.white : Colors.white70,
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
                                final DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now().add(
                                    const Duration(days: 30),
                                  ),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime(2030),
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

                    if (!isGroupLesson) ...[
                      const Divider(color: Colors.white10),
                      const SizedBox(height: 12),
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
                                      "Zamanı Kapat (Meşgul)",
                                      style: GoogleFonts.poppins(
                                        color: isUnavailable
                                            ? Colors.redAccent
                                            : Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      "Öğrenciler bu saatlere ders alamaz.",
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
                      const SizedBox(height: 24),
                    ],

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            (isSubmitting ||
                                titleController.text.trim().isEmpty)
                            ? null
                            : () async {
                                setModalState(() => isSubmitting = true);
                                try {
                                  String formattedHour =
                                      "$startTime - $endTime";
                                  Map<String, dynamic> actData = {
                                    'coachId': _auth.currentUser!.uid,
                                    'title': titleController.text.trim(),
                                    'description': descController.text.trim(),
                                    'hour': formattedHour,
                                    'isUnavailable': isUnavailable,
                                    'isGroupLesson': isGroupLesson,
                                    if (isGroupLesson) 'sport': selectedSport,
                                    'currentEnrolled':
                                        int.tryParse(
                                          currentEnrolledCtrl.text,
                                        ) ??
                                        0,
                                    'maxCapacity':
                                        int.tryParse(maxCapacityCtrl.text) ??
                                        10,
                                    'createdAt': FieldValue.serverTimestamp(),
                                  };

                                  if (recurrenceType == 'Tek Seferlik') {
                                    actData['date'] = DateFormat(
                                      'yyyy-MM-dd',
                                    ).format(widget.selectedDate);
                                    await FirebaseFirestore.instance
                                        .collection('coach_manual_activities')
                                        .add(actData);
                                  } else {
                                    actData['days'] = selectedDays;
                                    actData['endDate'] = endDate != null
                                        ? DateFormat(
                                            'yyyy-MM-dd',
                                          ).format(endDate!)
                                        : null;
                                    await FirebaseFirestore.instance
                                        .collection('coach_routines')
                                        .add(actData);
                                  }
                                  if (mounted) {
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context).showSnackBar(
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
            );
          },
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
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
            "${widget.selectedDate.day} ${_getWeekdayString(widget.selectedDate.weekday)} Planı",
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: ScaleButton(
                onPressed: _showAdvancedActivityModal,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
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
                        "Aktivite / Grup Dersi Ekle",
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
            ),
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
                                      Color cardColor = isGroupLesson
                                          ? Colors.blueAccent
                                          : (event['type'] == 'lesson'
                                                ? ColorConstants.primaryColor
                                                : (isUnavail
                                                      ? Colors.redAccent
                                                      : Colors.orange));

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
                                                          : (event['type'] ==
                                                                    'lesson'
                                                                ? Icons
                                                                      .fitness_center_rounded
                                                                : Icons
                                                                      .event_note_rounded)),
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
                                                    if (isGroupLesson) ...[
                                                      if (event['sport'] !=
                                                          null) ...[
                                                        const SizedBox(
                                                          height: 4,
                                                        ),
                                                        Text(
                                                          "Branş: ${event['sport']}",
                                                          style:
                                                              GoogleFonts.poppins(
                                                                color: Colors
                                                                    .white70,
                                                                fontSize: 11,
                                                              ),
                                                        ),
                                                      ],
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
