import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../core/constants/color_constants.dart';
import '../widgets/scale_button.dart';
import '../widgets/gradient_background.dart';
import 'chat_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class CoachDetailScreen extends StatefulWidget {
  final Map<String, dynamic> coachData;

  const CoachDetailScreen({super.key, required this.coachData});

  @override
  State<CoachDetailScreen> createState() => _CoachDetailScreenState();
}

class _CoachDetailScreenState extends State<CoachDetailScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late String coachUid;

  @override
  void initState() {
    super.initState();
    coachUid = widget.coachData['uid'] ?? '';
    initializeDateFormatting('tr_TR', null);
  }

  void _showCoachCalendarModal(List<dynamic> availableDays) {
    DateTime focusedDay = DateTime.now();
    DateTime? selectedDay = DateTime.now();

    final Map<String, int> dayNameToWeekday = {
      'Pazartesi': 1,
      'Salı': 2,
      'Çarşamba': 3,
      'Perşembe': 4,
      'Cuma': 5,
      'Cumartesi': 6,
      'Pazar': 7,
    };
    final Set<int> availableWeekdays = availableDays
        .map((d) => dayNameToWeekday[d.toString()] ?? 0)
        .where((w) => w > 0)
        .toSet();

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
            return DraggableScrollableSheet(
              initialChildSize: 0.75,
              minChildSize: 0.5,
              maxChildSize: 0.92,
              expand: false,
              builder: (context, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
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
                        const SizedBox(height: 16),
                        Text(
                          "Eğitmenin Takvimi",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _legendDot(ColorConstants.primaryColor),
                            const SizedBox(width: 6),
                            Text(
                              'Müsait Gün',
                              style: GoogleFonts.poppins(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 16),
                            _legendDot(Colors.red.shade400),
                            const SizedBox(width: 6),
                            Text(
                              'Ders Var',
                              style: GoogleFonts.poppins(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        StreamBuilder<QuerySnapshot>(
                          stream: _firestore
                              .collection('lessons')
                              .where('coachId', isEqualTo: coachUid)
                              .where('status', isEqualTo: 'approved')
                              .snapshots(),
                          builder: (ctx, snap) {
                            Set<int> bookedWeekdays = {};
                            if (snap.hasData) {
                              for (var doc in snap.data!.docs) {
                                final data = doc.data() as Map<String, dynamic>;
                                final List<dynamic> days = data['days'] ?? [];
                                for (var d in days) {
                                  final wd = dayNameToWeekday[d.toString()];
                                  if (wd != null) bookedWeekdays.add(wd);
                                }
                              }
                            }
                            return TableCalendar(
                              locale: 'tr_TR',
                              firstDay: DateTime.utc(2023, 1, 1),
                              lastDay: DateTime.utc(2030, 12, 31),
                              focusedDay: focusedDay,
                              selectedDayPredicate: (day) =>
                                  isSameDay(selectedDay, day),
                              onDaySelected: (sel, foc) {
                                setModalState(() {
                                  selectedDay = sel;
                                  focusedDay = foc;
                                });
                              },
                              startingDayOfWeek: StartingDayOfWeek.monday,
                              calendarBuilders: CalendarBuilders(
                                defaultBuilder: (ctx, day, focDay) {
                                  final wd = day.weekday;
                                  final isAvail = availableWeekdays.contains(
                                    wd,
                                  );
                                  final isBooked = bookedWeekdays.contains(wd);
                                  Color? bg;
                                  if (isBooked)
                                    bg = Colors.red.shade900.withOpacity(0.5);
                                  else if (isAvail)
                                    bg = ColorConstants.primaryColor
                                        .withOpacity(0.2);
                                  return Container(
                                    margin: const EdgeInsets.all(4),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: bg,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '${day.day}',
                                      style: GoogleFonts.poppins(
                                        color: isBooked
                                            ? Colors.red.shade300
                                            : isAvail
                                            ? ColorConstants.primaryColor
                                            : Colors.white70,
                                        fontWeight: isAvail || isBooked
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        fontSize: 13,
                                      ),
                                    ),
                                  );
                                },
                              ),
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
                                weekdayStyle: GoogleFonts.poppins(
                                  color: Colors.white70,
                                ),
                                weekendStyle: GoogleFonts.poppins(
                                  color: Colors.redAccent.withOpacity(0.5),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        if (availableDays.isNotEmpty) ...[
                          Text(
                            'Müsait Günler',
                            style: GoogleFonts.poppins(
                              color: Colors.white54,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: availableDays
                                .map(
                                  (d) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: ColorConstants.primaryColor
                                          .withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: ColorConstants.primaryColor
                                            .withOpacity(0.4),
                                      ),
                                    ),
                                    child: Text(
                                      d.toString(),
                                      style: GoogleFonts.poppins(
                                        color: ColorConstants.primaryColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _legendDot(Color color) => Container(
    width: 10,
    height: 10,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );

  void _showBookingModal(
    List<dynamic> days,
    List<dynamic> hours,
    String lessonSport,
    int price,
  ) {
    List<String> selectedDays = [];
    List<String> selectedHours = [];
    String selectedType = 'Online';
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                        "Ders Talebi Oluştur",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Ders Tipi",
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: ['Online', 'Yüzyüze'].map((type) {
                          final isSelected = selectedType == type;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(type),
                              selected: isSelected,
                              selectedColor: ColorConstants.primaryColor,
                              backgroundColor: Colors.white10,
                              labelStyle: GoogleFonts.poppins(
                                color: isSelected ? Colors.black : Colors.white,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              onSelected: (val) {
                                if (val) {
                                  setModalState(() => selectedType = type);
                                }
                              },
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Gün Seçin (Birden fazla seçebilirsiniz)",
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: days.map((day) {
                          final isSelected = selectedDays.contains(
                            day.toString(),
                          );
                          return ChoiceChip(
                            label: Text(day.toString()),
                            selected: isSelected,
                            selectedColor: ColorConstants.primaryColor,
                            backgroundColor: Colors.white10,
                            onSelected: (val) {
                              setModalState(() {
                                if (val) {
                                  selectedDays.add(day.toString());
                                } else {
                                  selectedDays.remove(day.toString());
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Saat Seçin (Birden fazla seçebilirsiniz)",
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: hours.map((hour) {
                          final isSelected = selectedHours.contains(
                            hour.toString(),
                          );
                          return ChoiceChip(
                            label: Text(hour.toString()),
                            selected: isSelected,
                            selectedColor: ColorConstants.primaryColor,
                            backgroundColor: Colors.white10,
                            onSelected: (val) {
                              setModalState(() {
                                if (val) {
                                  selectedHours.add(hour.toString());
                                } else {
                                  selectedHours.remove(hour.toString());
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              (selectedDays.isEmpty ||
                                  selectedHours.isEmpty ||
                                  isSubmitting)
                              ? null
                              : () async {
                                  setModalState(() => isSubmitting = true);
                                  await _submitLessonRequest(
                                    selectedDays,
                                    selectedHours,
                                    lessonSport,
                                    price,
                                    selectedType,
                                  );
                                  if (mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          "Ders talebi eğitmenine iletildi!",
                                          style: GoogleFonts.poppins(),
                                        ),
                                        backgroundColor: Colors.green,
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
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.black,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  "Talebi Gönder",
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
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _submitLessonRequest(
    List<String> selectedDays,
    List<String> selectedHours,
    String sport,
    int price,
    String lessonType,
  ) async {
    final currentUser = _auth.currentUser!;
    final myDoc = await _firestore
        .collection('users')
        .doc(currentUser.uid)
        .get();
    final String myName =
        "${myDoc.data()?['name'] ?? ''} ${myDoc.data()?['surname'] ?? ''}"
            .trim();
    final String? myImage = myDoc.data()?['profileImageUrl'];
    final String coachFullName =
        "${widget.coachData['name'] ?? ''} ${widget.coachData['surname'] ?? ''}"
            .trim();

    await _firestore.collection('lessons').add({
      'coachId': coachUid,
      'coachName': coachFullName,
      'coachImage': widget.coachData['profileImageUrl'],
      'athleteId': currentUser.uid,
      'athleteName': myName.isEmpty ? "Öğrenci" : myName,
      'athleteImage': myImage,
      'sport': sport,
      'days': selectedDays,
      'hours': selectedHours,
      'price': price,
      'status': 'pending',
      'lessonType': lessonType,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  void _showAllReviewsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 16),
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
                const SizedBox(height: 16),
                Text(
                  "Tüm Yorumlar",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('users')
                        .doc(coachUid)
                        .collection('reviews')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting)
                        return const Center(
                          child: CircularProgressIndicator(
                            color: ColorConstants.primaryColor,
                          ),
                        );
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                        return Center(
                          child: Text(
                            "Henüz yorum yapılmamış.",
                            style: GoogleFonts.poppins(color: Colors.white54),
                          ),
                        );
                      return ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          var review =
                              snapshot.data!.docs[index].data()
                                  as Map<String, dynamic>;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: Colors.white10,
                                      backgroundImage:
                                          review['userImage'] != null
                                          ? NetworkImage(review['userImage'])
                                          : null,
                                      child: review['userImage'] == null
                                          ? const Icon(
                                              Icons.person,
                                              color: Colors.white54,
                                              size: 20,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            review['userName'] ?? "Öğrenci",
                                            style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          Row(
                                            children: List.generate(
                                              5,
                                              (starIndex) => Icon(
                                                starIndex <
                                                        (review['rating'] ?? 5)
                                                    ? Icons.star_rounded
                                                    : Icons.star_border_rounded,
                                                color: Colors.amber,
                                                size: 14,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  review['comment'] ?? "",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
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
    final String fullName =
        "${widget.coachData['name'] ?? ''} ${widget.coachData['surname'] ?? ''}"
            .trim()
            .isEmpty
        ? "Eğitmen"
        : "${widget.coachData['name']} ${widget.coachData['surname']}";
    final String? profileImageUrl = widget.coachData['profileImageUrl'];
    final String bio = widget.coachData['bio'] ?? "Henüz biyografi eklenmemiş.";
    final String lessonSport = widget.coachData['lessonSport'] ?? "Genel";
    final String character =
        widget.coachData['coachCharacter'] ?? "Belirtilmemiş";
    final String deliveryMode =
        widget.coachData['deliveryMode'] ?? "Online/Yüzyüze";
    final int price = widget.coachData['hourlyRate'] ?? 0;
    final List<dynamic> specialties = widget.coachData['specialties'] ?? [];
    final List<dynamic> days = widget.coachData['availableDays'] ?? [];
    final List<dynamic> hours = widget.coachData['availableHours'] ?? [];

    // --- YENİ KONUM BİLGİLERİ ---
    final Map<String, dynamic>? location = widget.coachData['location'];
    final bool isFaceToFace =
        deliveryMode == "Yüzyüze" || deliveryMode == "Hibrit(İkisi de)";

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Container(
                    height: 350,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      image: profileImageUrl != null
                          ? DecorationImage(
                              image: NetworkImage(profileImageUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: profileImageUrl == null
                        ? const Center(
                            child: Icon(
                              Icons.person,
                              size: 80,
                              color: Colors.white24,
                            ),
                          )
                        : null,
                  ),
                  Container(
                    height: 350,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.9),
                        ],
                        stops: const [0.6, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 50,
                    left: 20,
                    child: ScaleButton(
                      onPressed: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white12),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 50,
                    right: 20,
                    child: ScaleButton(
                      onPressed: () {},
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white12),
                        ),
                        child: const Icon(
                          Icons.favorite_border_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fullName,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                character,
                                style: GoogleFonts.poppins(
                                  color: ColorConstants.primaryColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "$price ₺",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "Saatlik",
                              style: GoogleFonts.poppins(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ScaleButton(
                            onPressed: () {
                              if (coachUid.isNotEmpty) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatScreen(
                                      receiverId: coachUid,
                                      receiverName: fullName,
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.white10,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Mesaj",
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        StreamBuilder<QuerySnapshot>(
                          stream: _firestore
                              .collection('lessons')
                              .where('coachId', isEqualTo: coachUid)
                              .snapshots(),
                          builder: (context, snapshot) {
                            bool isBookedByMe = false;
                            bool isBookedBySomeoneElse = false;
                            if (snapshot.hasData) {
                              for (var doc in snapshot.data!.docs) {
                                if (doc['status'] == 'pending' ||
                                    doc['status'] == 'approved') {
                                  if (doc['athleteId'] ==
                                      _auth.currentUser!.uid) {
                                    isBookedByMe = true;
                                  } else {
                                    isBookedBySomeoneElse = true;
                                  }
                                }
                              }
                            }
                            if (isBookedByMe) {
                              return Expanded(
                                flex: 2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                    horizontal: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: Colors.green.withOpacity(0.5),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        color: Colors.green,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          "Ders Alındı",
                                          style: GoogleFonts.poppins(
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            } else if (isBookedBySomeoneElse) {
                              return Expanded(
                                flex: 2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                    horizontal: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: Colors.redAccent.withOpacity(0.5),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.lock_outline_rounded,
                                        color: Colors.redAccent,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          "Bu Ders Zaten Alındı",
                                          style: GoogleFonts.poppins(
                                            color: Colors.redAccent,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            } else {
                              return Expanded(
                                flex: 2,
                                child: ScaleButton(
                                  onPressed: () => _showBookingModal(
                                    days,
                                    hours,
                                    lessonSport,
                                    price,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: ColorConstants.primaryColor,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.bolt_rounded,
                                          color: Colors.black,
                                          size: 22,
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            "Dersi Al",
                                            style: GoogleFonts.poppins(
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ScaleButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "Görüntülü ön görüşme özelliği yakında aktif edilecek!",
                              style: GoogleFonts.poppins(),
                            ),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.videocam_outlined,
                              color: Colors.white70,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Ön Görüşme Talep Et (10 Dk)",
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    StreamBuilder<DocumentSnapshot>(
                      stream: _firestore
                          .collection('users')
                          .doc(coachUid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        double avgRating = 5.0;
                        int revCount = 0;
                        if (snapshot.hasData && snapshot.data!.exists) {
                          var data =
                              snapshot.data!.data() as Map<String, dynamic>;
                          avgRating = (data['rating'] ?? 5.0).toDouble();
                          revCount = data['reviewCount'] ?? 0;
                        }
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    color: Colors.amber,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    avgRating.toStringAsFixed(1),
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "($revCount Yorum)",
                                    style: GoogleFonts.poppins(
                                      color: Colors.white54,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: revCount > 0
                                    ? _showAllReviewsModal
                                    : null,
                                child: Text(
                                  "Tümünü Gör",
                                  style: GoogleFonts.poppins(
                                    color: revCount > 0
                                        ? Colors.white70
                                        : Colors.white24,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // ŞIK TAKVİM BUTONU
                    ScaleButton(
                      onPressed: () => _showCoachCalendarModal(days),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 20,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              ColorConstants.primaryColor.withOpacity(0.15),
                              Colors.transparent,
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: ColorConstants.primaryColor.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: ColorConstants.primaryColor.withOpacity(
                                  0.2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.calendar_month_rounded,
                                color: ColorConstants.primaryColor,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Eğitmenin Takvimi",
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Müsait günleri ve ders programı",
                                    style: GoogleFonts.poppins(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Colors.white38,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      "Hakkında",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      bio,
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- YENİ EKLENEN KONUM BİLGİSİ WIDGET'I ---
                    if (isFaceToFace && location != null) ...[
                      Text(
                        "Konum Bilgisi",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // TIKLANABİLİR YAPTIK
                      ScaleButton(
                        onPressed: () async {
                          // Adresi birleştirip bir arama sorgusu oluşturuyoruz
                          final String query =
                              "${location['addressTitle']} ${location['neighborhood']} ${location['district']} ${location['city']}";
                          // Google Haritalar evrensel arama linki (iOS ve Android'de harita uygulamasını tetikler)
                          final Uri mapUrl = Uri.parse(
                            "https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}",
                          );

                          if (await canLaunchUrl(mapUrl)) {
                            await launchUrl(
                              mapUrl,
                              mode: LaunchMode.externalApplication,
                            );
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "Harita açılamadı.",
                                    style: GoogleFonts.poppins(),
                                  ),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: ColorConstants.primaryColor
                                          .withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.location_on_rounded,
                                      color: ColorConstants.primaryColor,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          location['addressTitle'] ?? "Adres",
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          "${location['district'] ?? ''}, ${location['city'] ?? ''}",
                                          style: GoogleFonts.poppins(
                                            color: Colors.white54,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // KULLANICIYA TIKLANABİLİR OLDUĞUNU GÖSTERMEK İÇİN YÖN İKONU
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white10,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.navigation_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ],
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Divider(
                                  color: Colors.white10,
                                  height: 1,
                                ),
                              ),
                              Text(
                                "${location['neighborhood'] ?? ''} - ${location['addressDetail'] ?? ''}",
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    // ------------------------------------------

                    // ------------------------------------------
                    Text(
                      "Ders Detayları",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.sports_gymnastics_rounded,
                          color: ColorConstants.primaryColor,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Branş: ",
                          style: GoogleFonts.poppins(color: Colors.white70),
                        ),
                        Text(
                          lessonSport,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: ColorConstants.primaryColor,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Eğitim Tipi: ",
                          style: GoogleFonts.poppins(color: Colors.white70),
                        ),
                        Text(
                          deliveryMode,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (specialties.isNotEmpty) ...[
                      Text(
                        "Tüm Uzmanlık Alanları",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: specialties
                            .map<Widget>(
                              (s) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white10,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  s.toString(),
                                  style: GoogleFonts.poppins(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
