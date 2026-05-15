// ignore_for_file: unused_local_variable

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../core/constants/color_constants.dart';
import '../widgets/scale_button.dart';
import '../widgets/gradient_background.dart';
import 'chat_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'welcome_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

// --- YARDIMCI FONKSİYONLAR ---
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

void showGuestRegistrationPopup(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        "Kayıt Olmanız Gerekli",
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(
        "Ders alabilmek ve eğitmenlerle iletişime geçmek için giriş yapmanız veya kayıt olmanız gerekli.",
        style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            "İptal Et",
            style: GoogleFonts.poppins(
              color: Colors.white54,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const WelcomeScreen()),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorConstants.primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            "Kayıt Ol / Giriş Yap",
            style: GoogleFonts.poppins(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
}

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

  void _showCoachCalendarModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, controller) {
            return _AthleteCalendarModal(
              coachData: widget.coachData,
              scrollController: controller,
            );
          },
        );
      },
    );
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
                                          ? CachedNetworkImageProvider(
                                              review['userImage'],
                                            )
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
    final Map<String, dynamic>? location = widget.coachData['location'];
    final bool isFaceToFace =
        deliveryMode == "Yüzyüze" ||
        deliveryMode == "Farketmez" ||
        deliveryMode == "Hibrit(İkisi de)";

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
                              image: CachedNetworkImageProvider(
                                profileImageUrl,
                              ),
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
                              "Saatlik Ortalama",
                              style: GoogleFonts.poppins(
                                color: Colors.white54,
                                fontSize: 10,
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
                              if (_auth.currentUser == null) {
                                showGuestRegistrationPopup(context);
                                return;
                              }
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
                        Expanded(
                          flex: 2,
                          child: ScaleButton(
                            onPressed: _showCoachCalendarModal,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: ColorConstants.primaryColor,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.calendar_month_rounded,
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
                        ),
                      ],
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
                    ScaleButton(
                      onPressed: _showCoachCalendarModal,
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
                      ScaleButton(
                        onPressed: () async {
                          final String rawQuery =
                              "${location['addressTitle']} ${location['neighborhood']} ${location['district']} ${location['city']}";
                          final String encodedQuery = Uri.encodeComponent(
                            rawQuery,
                          );
                          final Uri mapUrl = Uri.parse(
                            "https://www.google.com/maps/search/?api=1&query=$encodedQuery",
                          );
                          try {
                            await launchUrl(
                              mapUrl,
                              mode: LaunchMode.externalApplication,
                            );
                          } catch (e) {
                            if (mounted)
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "Harita uygulaması açılamadı. Hata: $e",
                                  ),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
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

                    Text(
                      "Hoca Detayları",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                        Expanded(
                          child: Text(
                            specialties.isNotEmpty
                                ? specialties.join(', ')
                                : lessonSport,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
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

class _AthleteCalendarModal extends StatefulWidget {
  final Map<String, dynamic> coachData;
  final ScrollController scrollController;

  const _AthleteCalendarModal({
    required this.coachData,
    required this.scrollController,
  });

  @override
  State<_AthleteCalendarModal> createState() => _AthleteCalendarModalState();
}

class _AthleteCalendarModalState extends State<_AthleteCalendarModal> {
  DateTime _focusedDay = DateTime.now();

  final Set<DateTime> _selectedDays = {};
  final Map<DateTime, String> _selectedSlots = {};
  final Map<DateTime, bool> _selectedRecurring = {};

  bool _isMultiSelectMode = false;

  List<Map<String, dynamic>> _lessons = [];
  List<Map<String, dynamic>> _activities = [];
  List<Map<String, dynamic>> _routines = [];

  StreamSubscription? _lessonsSub, _activitiesSub, _routinesSub;

  String? _selectedSport;
  String _selectedLessonType = 'Online';
  bool _isSubmitting = false;

  late String _coachUid;
  late int _defaultPrice; // Hocanın profildeki ortalama fiyatı

  @override
  void initState() {
    super.initState();
    _coachUid = widget.coachData['uid'] ?? '';
    _defaultPrice = widget.coachData['hourlyRate'] ?? 0;

    _selectedDays.add(
      DateTime(_focusedDay.year, _focusedDay.month, _focusedDay.day),
    );

    if (widget.coachData['deliveryMode'] == 'Yüzyüze') {
      _selectedLessonType = 'Yüzyüze';
    }

    _setupStreams();
  }

  void _setupStreams() {
    final db = FirebaseFirestore.instance;
    // Onaylanan dersler çekiliyor ki müsaitlikten düşülebilsin
    _lessonsSub = db
        .collection('lessons')
        .where('coachId', isEqualTo: _coachUid)
        .where('status', isEqualTo: 'approved')
        .snapshots()
        .listen((snap) {
          if (mounted)
            setState(() => _lessons = snap.docs.map((d) => d.data()).toList());
        });
    _activitiesSub = db
        .collection('coach_manual_activities')
        .where('coachId', isEqualTo: _coachUid)
        .snapshots()
        .listen((snap) {
          if (mounted)
            setState(
              () => _activities = snap.docs.map((d) => d.data()).toList(),
            );
        });
    _routinesSub = db
        .collection('coach_routines')
        .where('coachId', isEqualTo: _coachUid)
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

  // Öğrenci sadece MÜSAİT olduğu Özel Ders ve Grup Derslerini yeşil/mavi noktalarla görecek. Meşgul veya Onaylı saatler nokta olarak basılmayacak.
  List<String> _getEventTypesForDay(DateTime day) {
    String dateStr = DateFormat('yyyy-MM-dd').format(day);
    if (day.isBefore(DateTime.now().subtract(const Duration(days: 1))))
      return [];

    List<String> types = [];

    // O gün için hocanın aktif ve müsait grup dersi var mı?
    bool hasAvailableGroup =
        _activities.any(
          (a) =>
              a['date'] == dateStr &&
              a['isGroupLesson'] == true &&
              a['isUnavailable'] != true,
        ) ||
        _routines.any(
          (r) =>
              isRoutineValidForDay(r, day) &&
              r['isGroupLesson'] == true &&
              r['isUnavailable'] != true,
        );
    if (hasAvailableGroup) types.add('group');

    // O gün için hocanın aktif ve müsait özel dersi var mı? (Ekstra olarak ders saatleriyle çakışmayan saat var mı diye tam fonksiyondan kontrol etmeliyiz)
    if (_getAvailablePrivateSlotsForDay(day).isNotEmpty) {
      types.add('private');
    }

    return types;
  }

  // Belirli bir gün için boş (alınmamış ve meşgul işaretlenmemiş) Özel Ders saatlerini getirir
  List<Map<String, dynamic>> _getAvailablePrivateSlotsForDay(DateTime day) {
    String dateStr = DateFormat('yyyy-MM-dd').format(day);
    List<Map<String, dynamic>> slots = [];

    for (var act in _activities) {
      if (act['date'] == dateStr &&
          act['isPrivateLesson'] == true &&
          act['isUnavailable'] != true) {
        slots.add({
          'hour': act['hour'],
          'isRoutine': false,
          'price': act['price'] ?? _defaultPrice,
          'sport': act['sport'],
        });
      }
    }
    for (var r in _routines) {
      if (isRoutineValidForDay(r, day) &&
          r['isPrivateLesson'] == true &&
          r['isUnavailable'] != true) {
        slots.add({
          'hour': r['hour'],
          'isRoutine': true,
          'price': r['price'] ?? _defaultPrice,
          'sport': r['sport'],
        });
      }
    }

    List<String> busyHours = [];
    for (var act in _activities) {
      if (act['date'] == dateStr && act['isUnavailable'] == true)
        busyHours.add(act['hour']);
    }
    for (var r in _routines) {
      if (isRoutineValidForDay(r, day) && r['isUnavailable'] == true)
        busyHours.add(r['hour']);
    }
    for (var l in _lessons) {
      if ((l['days'] as List).contains(getWeekdayString(day.weekday)) ||
          l['date'] == dateStr) {
        busyHours.addAll((l['hours'] as List).map((e) => e.toString()));
      }
    }

    slots.removeWhere((s) => busyHours.contains(s['hour']));

    var uniqueSlots = <String, Map<String, dynamic>>{};
    for (var s in slots) {
      uniqueSlots[s['hour']] = s;
    }

    var result = uniqueSlots.values.toList();
    result.sort((a, b) => (a['hour'] as String).compareTo(b['hour'] as String));
    return result;
  }

  Future<void> _submitMultiDayRequest() async {
    if (_selectedDays.isEmpty) return;
    if (_selectedSlots.length != _selectedDays.length)
      return; // Buton inaktif, yine de koruma

    setState(() => _isSubmitting = true);
    try {
      final currentUser = FirebaseAuth.instance.currentUser!;
      final myDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      final String myName =
          "${myDoc.data()?['name'] ?? ''} ${myDoc.data()?['surname'] ?? ''}"
              .trim();
      final String coachFullName =
          "${widget.coachData['name'] ?? ''} ${widget.coachData['surname'] ?? ''}"
              .trim();

      List<Map<String, dynamic>> requestedSlots = [];
      int totalPrice =
          0; // Çoklu talebin toplam veya ortalama fiyatını da tutabiliriz. Şimdilik sadece dinamik fiyatları atıyoruz.

      for (var day in _selectedDays) {
        String selectedHour = _selectedSlots[day]!;
        // Fiyatı ve branşı bul
        var slotsForDay = _getAvailablePrivateSlotsForDay(day);
        var selectedSlotData = slotsForDay.firstWhere(
          (element) => element['hour'] == selectedHour,
          orElse: () => {'price': _defaultPrice},
        );

        requestedSlots.add({
          'date': DateFormat('yyyy-MM-dd').format(day),
          'dayName': getWeekdayString(day.weekday),
          'hour': selectedHour,
          'isRecurringRequest': _selectedRecurring[day] == true,
          'price': selectedSlotData['price'],
        });
      }

      await FirebaseFirestore.instance.collection('lessons').add({
        'coachId': _coachUid,
        'coachName': coachFullName,
        'coachImage': widget.coachData['profileImageUrl'],
        'athleteId': currentUser.uid,
        'athleteName': myName.isEmpty ? "Öğrenci" : myName,
        'athleteImage': myDoc.data()?['profileImageUrl'],
        'sport': _selectedSport ?? widget.coachData['lessonSport'] ?? "Genel",
        'status': 'pending',
        'lessonType': _selectedLessonType,
        'isUnifiedRequest': true,
        'requestedSlots': requestedSlots,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Talebiniz başarıyla iletildi! Onaylandığında bildirim alacaksınız.",
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submitGroupLessonRequest(
    Map<String, dynamic> groupEvent,
    DateTime day,
  ) async {
    setState(() => _isSubmitting = true);
    try {
      final currentUser = FirebaseAuth.instance.currentUser!;
      final myDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      final String myName =
          "${myDoc.data()?['name'] ?? ''} ${myDoc.data()?['surname'] ?? ''}"
              .trim();
      final String coachFullName =
          "${widget.coachData['name'] ?? ''} ${widget.coachData['surname'] ?? ''}"
              .trim();

      bool isRoutine = groupEvent['isRoutine'] ?? false;

      await FirebaseFirestore.instance.collection('lessons').add({
        'coachId': _coachUid,
        'coachName': coachFullName,
        'coachImage': widget.coachData['profileImageUrl'],
        'athleteId': currentUser.uid,
        'athleteName': myName.isEmpty ? "Öğrenci" : myName,
        'athleteImage': myDoc.data()?['profileImageUrl'],
        'sport':
            groupEvent['sport'] ?? widget.coachData['lessonSport'] ?? "Genel",
        'status': 'pending',
        'lessonType': 'Grup Dersi',
        'isUnifiedRequest': true,
        'requestedSlots': [
          {
            'date': DateFormat('yyyy-MM-dd').format(day),
            'dayName': getWeekdayString(day.weekday),
            'hour': groupEvent['hour'],
            'isRecurringRequest': isRoutine,
            'price': groupEvent['price'] ?? _defaultPrice, // YENİ
          },
        ],
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Grup dersi talebi iletildi!",
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> todayGroupLessons = [];
    if (_selectedDays.length == 1) {
      DateTime day = _selectedDays.first;
      String dateStr = DateFormat('yyyy-MM-dd').format(day);
      todayGroupLessons = [
        ..._activities
            .where(
              (a) =>
                  a['date'] == dateStr &&
                  a['isGroupLesson'] == true &&
                  a['isUnavailable'] != true,
            )
            .map((e) => {...e, 'isRoutine': false}),
        ..._routines
            .where(
              (r) =>
                  isRoutineValidForDay(r, day) &&
                  r['isGroupLesson'] == true &&
                  r['isUnavailable'] != true,
            )
            .map((e) => {...e, 'isRoutine': true}),
      ];
    }

    // YENİ: Dersi Al Butonunun Aktif/İnaktif Durumu Kontrolü
    bool canSubmitRequest = false;
    int selectedTotalPrice = 0; // Dinamik Fiyatı Ekrana Basmak İçin

    if (_selectedDays.isNotEmpty &&
        _selectedSlots.length == _selectedDays.length) {
      canSubmitRequest = true;
      for (var day in _selectedDays) {
        var slots = _getAvailablePrivateSlotsForDay(day);
        var slotData = slots.firstWhere(
          (s) => s['hour'] == _selectedSlots[day],
          orElse: () => {},
        );
        if (slotData.isNotEmpty && slotData['price'] != null) {
          selectedTotalPrice += (slotData['price'] as num).toInt();
        } else {
          selectedTotalPrice += _defaultPrice;
        }
      }
    }

    // YENİ: Dinamik Branş Filtresi
    List<String> dynamicAvailableSports = [];
    if (_selectedDays.isNotEmpty) {
      for (var day in _selectedDays) {
        if (_selectedSlots[day] != null) {
          var slots = _getAvailablePrivateSlotsForDay(day);
          var slotData = slots.firstWhere(
            (s) => s['hour'] == _selectedSlots[day],
            orElse: () => {},
          );
          if (slotData.isNotEmpty &&
              slotData['sport'] != null &&
              !dynamicAvailableSports.contains(slotData['sport'])) {
            dynamicAvailableSports.add(slotData['sport']);
          }
        }
      }
    }
    // Eğer o saatler için özel branş girilmemişse hocanın genel branşlarını gösterelim
    if (dynamicAvailableSports.isEmpty) {
      dynamicAvailableSports = widget.coachData['specialties'] != null
          ? (widget.coachData['specialties'] as List)
                .map((e) => e.toString())
                .toList()
          : ['Genel'];
    }
    // Seçili branş eğer gelen dinamik listede yoksa ilk elemana eşitleyelim
    if (_selectedSport == null ||
        !dynamicAvailableSports.contains(_selectedSport)) {
      _selectedSport = dynamicAvailableSports.first;
    }

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: ListView(
        controller: widget.scrollController,
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
          Center(
            child: Text(
              "Takvim & Ders Seçimi",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              "Birden fazla gün seçmek için günlerin üzerine basılı tutun.",
              style: GoogleFonts.poppins(
                color: ColorConstants.primaryColor,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(Colors.greenAccent, "Özel Ders"),
              const SizedBox(width: 16),
              _buildLegendItem(Colors.blueAccent, "Grup Dersi"),
            ],
          ),
          const SizedBox(height: 12),

          TableCalendar(
            locale: 'tr_TR',
            firstDay: DateTime.now().subtract(const Duration(days: 30)),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) =>
                _selectedDays.any((d) => isSameDay(d, day)),
            onDaySelected: (sel, foc) {
              DateTime normalized = DateTime(sel.year, sel.month, sel.day);
              setState(() {
                if (_isMultiSelectMode) {
                  if (_selectedDays.any((d) => isSameDay(d, normalized))) {
                    _selectedDays.removeWhere((d) => isSameDay(d, normalized));
                    _selectedSlots.removeWhere(
                      (d, _) => isSameDay(d, normalized),
                    );
                    _selectedRecurring.removeWhere(
                      (d, _) => isSameDay(d, normalized),
                    );
                    if (_selectedDays.isEmpty) _isMultiSelectMode = false;
                  } else {
                    _selectedDays.add(normalized);
                  }
                } else {
                  _selectedDays.clear();
                  _selectedSlots.clear();
                  _selectedRecurring.clear();
                  _selectedDays.add(normalized);
                }
                _focusedDay = foc;
              });
            },
            onDayLongPressed: (sel, foc) {
              DateTime normalized = DateTime(sel.year, sel.month, sel.day);
              setState(() {
                _isMultiSelectMode = true;
                _selectedDays.add(normalized);
                _focusedDay = foc;
              });
            },
            startingDayOfWeek: StartingDayOfWeek.monday,
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, focusedDay) {
                final types = _getEventTypesForDay(day);
                if (types.isEmpty) return const SizedBox();
                List<Widget> dots = [];
                if (types.contains('private'))
                  dots.add(
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.greenAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                if (types.contains('group'))
                  dots.add(
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.blueAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                return Positioned(
                  bottom: 6,
                  child: Row(mainAxisSize: MainAxisSize.min, children: dots),
                );
              },
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
            calendarStyle: CalendarStyle(
              defaultTextStyle: GoogleFonts.poppins(color: Colors.white),
              weekendTextStyle: GoogleFonts.poppins(
                color: Colors.redAccent.withOpacity(0.8),
              ),
              selectedDecoration: const BoxDecoration(
                color: ColorConstants.primaryColor,
                shape: BoxShape.circle,
              ),
              selectedTextStyle: GoogleFonts.poppins(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
              todayDecoration: const BoxDecoration(
                color: Colors.white10,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(height: 24),

          if (_selectedDays.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_selectedDays.length == 1 &&
                      todayGroupLessons.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(
                          Icons.groups_rounded,
                          color: Colors.blueAccent,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Grup Dersleri (Bugün)",
                          style: GoogleFonts.poppins(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...todayGroupLessons.map((gEvent) {
                      int totalEnrolled =
                          (gEvent['currentEnrolled'] ?? 0) +
                          _lessons
                              .where(
                                (l) =>
                                    l['lessonType'] == 'Grup Dersi' &&
                                    (l['hours'] as List).contains(
                                      gEvent['hour'],
                                    ),
                              )
                              .length;
                      int maxCap = gEvent['maxCapacity'] ?? 10;
                      bool isFull = totalEnrolled >= maxCap;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.blueAccent.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    gEvent['title'] ?? 'Grup Dersi',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white10,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    gEvent['hour'] ?? '',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  "Branş: ${gEvent['sport'] ?? widget.coachData['lessonSport'] ?? 'Genel'}",
                                  style: GoogleFonts.poppins(
                                    color: Colors.blueAccent,
                                    fontSize: 12,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  "${gEvent['price'] ?? _defaultPrice} ₺",
                                  style: GoogleFonts.poppins(
                                    color: Colors.greenAccent,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ), // YENİ
                              ],
                            ),
                            if (gEvent['isRoutine'] == true) ...[
                              const SizedBox(height: 4),
                              Text(
                                "🔄 Her Hafta Tekrar Eden Ders",
                                style: GoogleFonts.poppins(
                                  color: Colors.amber,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.people_alt_rounded,
                                  color: Colors.blueAccent,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "Kayıtlı: $totalEnrolled / $maxCap Kişi",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: isFull
                                    ? null
                                    : () {
                                        if (FirebaseAuth.instance.currentUser ==
                                            null) {
                                          showGuestRegistrationPopup(context);
                                          return;
                                        }
                                        _submitGroupLessonRequest(
                                          gEvent,
                                          _selectedDays.first,
                                        );
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isFull
                                      ? Colors.white10
                                      : Colors.blueAccent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  isFull ? "Kontenjan Dolu" : "Hemen Katıl",
                                  style: GoogleFonts.poppins(
                                    color: isFull
                                        ? Colors.white38
                                        : Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 16),
                  ],

                  Text(
                    _selectedDays.length > 1
                        ? "Toplu Özel Ders Talep Et"
                        : "Özel Ders Talep Et",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 24),

                  ...(_selectedDays.toList()..sort()).map((day) {
                    List<Map<String, dynamic>> availableSlots =
                        _getAvailablePrivateSlotsForDay(day);
                    String dayStr = DateFormat(
                      'dd MMM, EEEE',
                      'tr_TR',
                    ).format(day);

                    bool isSelectedSlotRoutine = false;
                    int selectedSlotPrice = _defaultPrice;
                    if (_selectedSlots[day] != null) {
                      var sData = availableSlots.firstWhere(
                        (element) => element['hour'] == _selectedSlots[day],
                        orElse: () => {},
                      );
                      if (sData.isNotEmpty) {
                        if (sData['isRoutine'] == true)
                          isSelectedSlotRoutine = true;
                        if (sData['price'] != null)
                          selectedSlotPrice = sData['price'];
                      }
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                dayStr,
                                style: GoogleFonts.poppins(
                                  color: ColorConstants.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              if (_selectedSlots[day] != null)
                                Text(
                                  "$selectedSlotPrice ₺",
                                  style: GoogleFonts.poppins(
                                    color: Colors.greenAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          availableSlots.isEmpty
                              ? Text(
                                  "Bu gün için uygun saat bulunmamaktadır.",
                                  style: GoogleFonts.poppins(
                                    color: Colors.redAccent,
                                    fontSize: 12,
                                  ),
                                )
                              : Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: availableSlots.map((slotData) {
                                    String h = slotData['hour'];
                                    bool isSelected = _selectedSlots[day] == h;
                                    return ChoiceChip(
                                      label: Text(h),
                                      selected: isSelected,
                                      selectedColor:
                                          ColorConstants.primaryColor,
                                      backgroundColor: Colors.white10,
                                      labelStyle: GoogleFonts.poppins(
                                        color: Colors.black,
                                      ),
                                      onSelected: (val) {
                                        setState(() {
                                          if (val) {
                                            _selectedSlots[day] = h;
                                            _selectedRecurring[day] = false;
                                          }
                                        });
                                      },
                                    );
                                  }).toList(),
                                ),
                          if (isSelectedSlotRoutine) ...[
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.blueAccent.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.blueAccent.withOpacity(0.2),
                                ),
                              ),
                              child: CheckboxListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                activeColor: ColorConstants.primaryColor,
                                checkColor: Colors.black,
                                title: Text(
                                  "Bu dersi her hafta tekrarlı olarak talep et",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                                value: _selectedRecurring[day] ?? false,
                                onChanged: (val) => setState(
                                  () => _selectedRecurring[day] = val ?? false,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),

                  const Divider(color: Colors.white10),
                  const SizedBox(height: 16),

                  Text(
                    "Branş Seçin",
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: dynamicAvailableSports.map((s) {
                      final isSelected = _selectedSport == s.toString();
                      return ChoiceChip(
                        label: Text(s.toString()),
                        selected: isSelected,
                        selectedColor: ColorConstants.primaryColor,
                        backgroundColor: Colors.white10,
                        labelStyle: GoogleFonts.poppins(
                          color: Colors.black,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        onSelected: (val) {
                          if (val)
                            setState(() => _selectedSport = s.toString());
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    "Özel Ders Tipi",
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: ['Online', 'Yüzyüze'].map((type) {
                      final isSelected = _selectedLessonType == type;
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
                          onSelected: (val) {
                            if (val) setState(() => _selectedLessonType = type);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ScaleButton(
                          onPressed: () {
                            if (!canSubmitRequest) return;
                            if (FirebaseAuth.instance.currentUser == null) {
                              showGuestRegistrationPopup(context);
                              return;
                            }
                            if (!_isSubmitting) _submitMultiDayRequest();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: canSubmitRequest
                                  ? ColorConstants.primaryColor
                                  : Colors.redAccent.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: _isSubmitting
                                ? const Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.black,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        canSubmitRequest
                                            ? Icons.bolt_rounded
                                            : Icons.block_rounded,
                                        color: canSubmitRequest
                                            ? Colors.black
                                            : Colors.white54,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        canSubmitRequest
                                            ? (_selectedDays.length > 1
                                                  ? "Toplam: $selectedTotalPrice ₺ • Talebi Gönder"
                                                  : "Dersi Al ($selectedTotalPrice ₺)")
                                            : "Lütfen Saat Seçin",
                                        style: GoogleFonts.poppins(
                                          color: canSubmitRequest
                                              ? Colors.black
                                              : Colors.white54,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
