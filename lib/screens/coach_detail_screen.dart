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
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: ColorConstants.primaryColor,
                          ),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Text(
                            "Henüz yorum yapılmamış.",
                            style: GoogleFonts.poppins(color: Colors.white54),
                          ),
                        );
                      }
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
                          // --- YENİ HARİTA URL MANTIĞI ---
                          // Boşlukları ve Türkçe karakterleri + işaretine ve uygun formata çeviren güvenli yöntem
                          final String rawQuery =
                              "${location['addressTitle']} ${location['neighborhood']} ${location['district']} ${location['city']}";
                          final String encodedQuery = Uri.encodeComponent(
                            rawQuery,
                          );
                          // Universal Google Maps Search Linki
                          final Uri mapUrl = Uri.parse(
                            "https://www.google.com/maps/search/?api=1&query=$encodedQuery",
                          );

                          try {
                            // Doğrudan fırlat, sistem haritaları açsın
                            await launchUrl(
                              mapUrl,
                              mode: LaunchMode.externalApplication,
                            );
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "Harita uygulaması açılamadı. Hata: $e",
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
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
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
  DateTime? _selectedDay = DateTime.now();

  List<Map<String, dynamic>> _lessons = [];
  List<Map<String, dynamic>> _activities = [];
  List<Map<String, dynamic>> _routines = [];

  StreamSubscription? _lessonsSub, _activitiesSub, _routinesSub;

  String? _selectedSport; // SPORCUNUN SEÇECEĞİ ÖZEL DERS BRANŞI
  String? _selectedStartTime;
  String? _selectedEndTime;
  String _selectedLessonType = 'Online';
  bool _isSubmitting = false;

  late List<dynamic> _availableDays;
  late String _coachUid;

  @override
  void initState() {
    super.initState();
    _coachUid = widget.coachData['uid'] ?? '';
    _availableDays = widget.coachData['availableDays'] ?? [];
    if (widget.coachData['deliveryMode'] == 'Yüzyüze') {
      _selectedLessonType = 'Yüzyüze';
    }

    // VARSAYILAN BRANŞI AYARLA
    List<dynamic> specs = widget.coachData['specialties'] ?? [];
    if (specs.isNotEmpty) {
      _selectedSport = specs.first.toString();
    } else {
      _selectedSport = widget.coachData['lessonSport'] ?? 'Genel';
    }

    _setupStreams();
  }

  void _setupStreams() {
    final db = FirebaseFirestore.instance;
    _lessonsSub = db
        .collection('lessons')
        .where('coachId', isEqualTo: _coachUid)
        .where('status', isEqualTo: 'approved')
        .snapshots()
        .listen((snap) {
          if (mounted) {
            setState(() => _lessons = snap.docs.map((d) => d.data()).toList());
          }
        });
    _activitiesSub = db
        .collection('coach_manual_activities')
        .where('coachId', isEqualTo: _coachUid)
        .snapshots()
        .listen((snap) {
          if (mounted) {
            setState(
              () => _activities = snap.docs.map((d) => d.data()).toList(),
            );
          }
        });
    _routinesSub = db
        .collection('coach_routines')
        .where('coachId', isEqualTo: _coachUid)
        .snapshots()
        .listen((snap) {
          if (mounted) {
            setState(() => _routines = snap.docs.map((d) => d.data()).toList());
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

  List<String> _getValidHours() {
    List<dynamic> availableRanges = widget.coachData['availableHours'] ?? [];
    Set<int> hours = {};
    for (String range in availableRanges) {
      var parts = range.split('-');
      if (parts.length == 2) {
        int start = int.tryParse(parts[0].split(':')[0].trim()) ?? 0;
        int end = int.tryParse(parts[1].split(':')[0].trim()) ?? 0;
        if (end == 0) end = 24;
        for (int i = start; i <= end; i++) {
          hours.add(i);
        }
      }
    }
    if (hours.isEmpty) {
      for (int i = 8; i <= 22; i++) {
        hours.add(i);
      }
    }
    List<int> sorted = hours.toList()..sort();
    return sorted.map((h) => "${h.toString().padLeft(2, '0')}:00").toList();
  }

  Map<String, dynamic> _getDayData(DateTime day) {
    String dayName = _getWeekdayString(day.weekday);
    String dateStr = DateFormat('yyyy-MM-dd').format(day);

    bool isAvailDay = _availableDays.contains(dayName);
    bool hasUnavailable = false;
    List<String> busyHours = [];

    for (var l in _lessons) {
      if (l['lessonType'] != 'Grup Dersi' &&
          (l['days'] as List).contains(dayName)) {
        var h = (l['hours'] as List).map((e) => e.toString()).toList();
        busyHours.addAll(h);
      }
    }
    for (var r in _routines) {
      if ((r['days'] as List).contains(dayName)) {
        if (r['isUnavailable'] == true) hasUnavailable = true;
        if (r['hour'] != null && r['hour'] != '') busyHours.add(r['hour']);
      }
    }
    for (var a in _activities) {
      if (a['date'] == dateStr) {
        if (a['isUnavailable'] == true) hasUnavailable = true;
        if (a['hour'] != null && a['hour'] != '') busyHours.add(a['hour']);
      }
    }

    var allEvents = [
      ..._activities.where((a) => a['date'] == dateStr),
      ..._routines.where((r) => (r['days'] as List).contains(dayName)),
    ];
    for (var ev in allEvents) {
      if (ev['isGroupLesson'] == true) {
        int enrolled =
            (ev['currentEnrolled'] ?? 0) +
            _lessons
                .where(
                  (l) =>
                      l['lessonType'] == 'Grup Dersi' &&
                      (l['hours'] as List).contains(ev['hour']),
                )
                .length;
        if (enrolled >= (ev['maxCapacity'] ?? 10)) {
          if (ev['hour'] != null) busyHours.add(ev['hour']);
        }
      }
    }

    return {
      'isRed': hasUnavailable,
      'isYellow': !hasUnavailable && busyHours.isNotEmpty,
      'isGreen': isAvailDay && !hasUnavailable && busyHours.isEmpty,
      'busyHours': busyHours.toSet().toList()..sort(),
    };
  }

  Widget _buildDayCell(DateTime day, bool isSelected) {
    var data = _getDayData(day);
    bool isRed = data['isRed'];
    bool isYellow = data['isYellow'];
    bool isGreen = data['isGreen'];
    Color? bgColor;
    Color txtColor = Colors.white70;

    if (isRed) {
      bgColor = Colors.redAccent.withOpacity(isSelected ? 0.8 : 0.25);
      txtColor = isSelected ? Colors.white : Colors.redAccent;
    } else if (isYellow) {
      bgColor = Colors.amber.withOpacity(isSelected ? 0.8 : 0.25);
      txtColor = isSelected ? Colors.black : Colors.amber;
    } else if (isGreen) {
      bgColor = ColorConstants.primaryColor.withOpacity(
        isSelected ? 0.8 : 0.15,
      );
      txtColor = isSelected ? Colors.black : ColorConstants.primaryColor;
    } else if (isSelected) {
      bgColor = Colors.white24;
      txtColor = Colors.white;
    }

    return Container(
      margin: const EdgeInsets.all(4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: isSelected ? Border.all(color: Colors.white, width: 1.5) : null,
      ),
      child: Text(
        '${day.day}',
        style: GoogleFonts.poppins(
          color: txtColor,
          fontWeight: bgColor != null ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Future<void> _submitLessonRequest(
    bool isPreMeeting, {
    String? customHourRange,
    String? specificType,
    String? specificSport, // GRUP DERSİ VEYA ÖZEL SEÇİM İÇİN
  }) async {
    String finalHours =
        customHourRange ?? "$_selectedStartTime - $_selectedEndTime";
    String finalType = specificType ?? _selectedLessonType;
    String finalSport = isPreMeeting
        ? "Ön Görüşme (10 Dk)"
        : (specificSport ??
              _selectedSport ??
              widget.coachData['lessonSport'] ??
              "Genel");

    if (finalHours.contains('null')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Lütfen saat seçin.", style: GoogleFonts.poppins()),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
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
      final String? myImage = myDoc.data()?['profileImageUrl'];
      final String coachFullName =
          "${widget.coachData['name'] ?? ''} ${widget.coachData['surname'] ?? ''}"
              .trim();

      String dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay!);
      int price = isPreMeeting ? 0 : (widget.coachData['hourlyRate'] ?? 0);

      await FirebaseFirestore.instance.collection('lessons').add({
        'coachId': _coachUid,
        'coachName': coachFullName,
        'coachImage': widget.coachData['profileImageUrl'],
        'athleteId': currentUser.uid,
        'athleteName': myName.isEmpty ? "Öğrenci" : myName,
        'athleteImage': myImage,
        'sport': finalSport,
        'days': [_getWeekdayString(_selectedDay!.weekday)],
        'date': dateStr,
        'hours': [finalHours],
        'price': price,
        'status': 'pending',
        'lessonType': finalType,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isPreMeeting
                  ? "Ön görüşme talebi iletildi!"
                  : "Ders talebiniz başarıyla iletildi! Onaylandığında bildirim alacaksınız.",
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Hata: $e", style: GoogleFonts.poppins()),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              "Ders Saati Seçin",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: ColorConstants.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "Müsait",
                    style: GoogleFonts.poppins(
                      color: Colors.white54,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.amber,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "Kısmen Dolu",
                    style: GoogleFonts.poppins(
                      color: Colors.white54,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "Tamamen Dolu",
                    style: GoogleFonts.poppins(
                      color: Colors.white54,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          TableCalendar(
            locale: 'tr_TR',
            firstDay: DateTime.utc(2023, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (sel, foc) {
              setState(() {
                _selectedDay = sel;
                _focusedDay = foc;
                _selectedStartTime = null;
                _selectedEndTime = null;
              });
            },
            startingDayOfWeek: StartingDayOfWeek.monday,
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (ctx, day, foc) => _buildDayCell(day, false),
              todayBuilder: (ctx, day, foc) =>
                  _buildDayCell(day, isSameDay(day, _selectedDay)),
              selectedBuilder: (ctx, day, foc) => _buildDayCell(day, true),
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
          const SizedBox(height: 24),
          if (_selectedDay != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Builder(
                builder: (context) {
                  var data = _getDayData(_selectedDay!);
                  List<String> hours = data['busyHours'];
                  List<String> validHours = _getValidHours();

                  String dayName = _getWeekdayString(_selectedDay!.weekday);
                  String dateStr = DateFormat(
                    'yyyy-MM-dd',
                  ).format(_selectedDay!);
                  List<Map<String, dynamic>> todayGroupLessons = [
                    ..._activities.where(
                      (a) => a['date'] == dateStr && a['isGroupLesson'] == true,
                    ),
                    ..._routines.where(
                      (r) =>
                          (r['days'] as List).contains(dayName) &&
                          r['isGroupLesson'] == true,
                    ),
                  ];

                  if (data['isRed']) {
                    return Column(
                      children: [
                        const Icon(
                          Icons.block_rounded,
                          color: Colors.redAccent,
                          size: 30,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Antrenör bu günü kapattı.",
                          style: GoogleFonts.poppins(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Bu tarih için ders talebi oluşturulamaz.",
                          style: GoogleFonts.poppins(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    );
                  } else if (data['isYellow'] || data['isGreen']) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (todayGroupLessons.isNotEmpty) ...[
                          Row(
                            children: [
                              const Icon(
                                Icons.groups_rounded,
                                color: Colors.blueAccent,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Bugünün Grup Dersleri",
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
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
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
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
                                  Text(
                                    "Branş: ${gEvent['sport'] ?? widget.coachData['lessonSport'] ?? 'Genel'}",
                                    style: GoogleFonts.poppins(
                                      color: Colors.blueAccent,
                                      fontSize: 12,
                                    ),
                                  ),
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
                                              if (FirebaseAuth
                                                      .instance
                                                      .currentUser ==
                                                  null) {
                                                showGuestRegistrationPopup(
                                                  context,
                                                );
                                                return;
                                              }
                                              _submitLessonRequest(
                                                false,
                                                customHourRange: gEvent['hour'],
                                                specificType: 'Grup Dersi',
                                                specificSport: gEvent['sport'],
                                              );
                                            },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isFull
                                            ? Colors.white10
                                            : Colors.blueAccent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        isFull
                                            ? "Kontenjan Dolu"
                                            : "Hemen Katıl",
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
                          "Özel Ders Talep Et",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),

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
                          children:
                              widget.coachData['specialties'] != null &&
                                  (widget.coachData['specialties'] as List)
                                      .isNotEmpty
                              ? (widget.coachData['specialties'] as List).map((
                                  s,
                                ) {
                                  final isSelected =
                                      _selectedSport == s.toString();
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
                                      if (val) {
                                        setState(
                                          () => _selectedSport = s.toString(),
                                        );
                                      }
                                    },
                                  );
                                }).toList()
                              : [
                                  ChoiceChip(
                                    label: Text(
                                      widget.coachData['lessonSport'] ??
                                          'Genel',
                                    ),
                                    selected: true,
                                    selectedColor: ColorConstants.primaryColor,
                                    backgroundColor: Colors.white10,
                                    labelStyle: GoogleFonts.poppins(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    onSelected: (val) {},
                                  ),
                                ],
                        ),
                        const SizedBox(height: 16),

                        if (data['isYellow']) ...[
                          Text(
                            "Aşağıdaki dolu saatler dışındaki zamanları seçebilirsiniz:",
                            style: GoogleFonts.poppins(
                              color: Colors.amber,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: hours
                                .map(
                                  (h) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.amber.withOpacity(0.4),
                                      ),
                                    ),
                                    child: Text(
                                      h,
                                      style: GoogleFonts.poppins(
                                        color: Colors.amber,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 16),
                        ],
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedStartTime,
                                dropdownColor: const Color(0xFF1E1E1E),
                                icon: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: Colors.white54,
                                ),
                                decoration: InputDecoration(
                                  labelText: "Başlangıç",
                                  labelStyle: GoogleFonts.poppins(
                                    color: Colors.white54,
                                    fontSize: 13,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white10,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                items: validHours
                                    .map(
                                      (h) => DropdownMenuItem(
                                        value: h,
                                        child: Text(
                                          h,
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) =>
                                    setState(() => _selectedStartTime = val),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedEndTime,
                                dropdownColor: const Color(0xFF1E1E1E),
                                icon: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: Colors.white54,
                                ),
                                decoration: InputDecoration(
                                  labelText: "Bitiş",
                                  labelStyle: GoogleFonts.poppins(
                                    color: Colors.white54,
                                    fontSize: 13,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white10,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                items: validHours
                                    .map(
                                      (h) => DropdownMenuItem(
                                        value: h,
                                        child: Text(
                                          h,
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) =>
                                    setState(() => _selectedEndTime = val),
                              ),
                            ),
                          ],
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
                                  if (val) {
                                    setState(() => _selectedLessonType = type);
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: ScaleButton(
                                onPressed: () {
                                  if (FirebaseAuth.instance.currentUser ==
                                      null) {
                                    showGuestRegistrationPopup(context);
                                    return;
                                  }
                                  if (!_isSubmitting) {
                                    _submitLessonRequest(
                                      false,
                                      specificType: 'Özel Ders',
                                    );
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: ColorConstants.primaryColor,
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
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.bolt_rounded,
                                              color: Colors.black,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              "Dersi Al",
                                              style: GoogleFonts.poppins(
                                                color: Colors.black,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 4,
                              child: ScaleButton(
                                onPressed: () {
                                  if (FirebaseAuth.instance.currentUser ==
                                      null) {
                                    showGuestRegistrationPopup(context);
                                    return;
                                  }
                                  if (!_isSubmitting) {
                                    _submitLessonRequest(true);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
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
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.videocam_outlined,
                                              color: Colors.black,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 6),
                                            Flexible(
                                              child: Text(
                                                "Ön Görüşme Talep Et",
                                                style: GoogleFonts.poppins(
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
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
                      ],
                    );
                  } else {
                    return Center(
                      child: Text(
                        "Bu tarih antrenörün çalışma günleri arasında değildir.",
                        style: GoogleFonts.poppins(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
