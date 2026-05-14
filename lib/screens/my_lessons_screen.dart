/// lib/screens/my_lessons_screen.dart
///
/// Displays all lessons booked by the currently signed-in athlete.
///
/// Each lesson card shows the status (pending / approved / rejected /
/// cancelled), lesson details, and context-sensitive action buttons:
///   - Online + approved → "Join Live Class" button (opens VideoCallScreen).
///   - Face-to-face + approved → location reminder text.
///   - Pending or approved → "Cancel Lesson" button.
///
/// Review submission logic is delegated to [ILessonService.submitReview] —
/// this screen never writes to Firestore directly.

// ignore_for_file: deprecated_member_use

library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants/color_constants.dart';
import '../services/lesson_service.dart';
import '../services/interfaces/i_lesson_service.dart';
import '../widgets/scale_button.dart';
import '../widgets/gradient_background.dart';
import 'video_call_screen.dart';
import 'welcome_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Athlete's lesson history and active lesson management screen.
class MyLessonsScreen extends StatefulWidget {
  /// Injectable lesson service — defaults to [LessonService].
  final ILessonService lessonService;

  const MyLessonsScreen({super.key, ILessonService? lessonService})
    : lessonService = lessonService ?? const _DefaultLesson();

  @override
  State<MyLessonsScreen> createState() => _MyLessonsScreenState();
}

class _DefaultLesson implements ILessonService {
  const _DefaultLesson();
  @override
  dynamic noSuchMethod(Invocation i) => LessonService();
}

class _MyLessonsScreenState extends State<MyLessonsScreen> {
  // ---------------------------------------------------------------------------
  // Dependencies
  // ---------------------------------------------------------------------------

  late final ILessonService _lessonService;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _lessonService = widget.lessonService is _DefaultLesson
        ? LessonService()
        : widget.lessonService;
  }

  // ---------------------------------------------------------------------------
  // Review modal
  // ---------------------------------------------------------------------------

  /// Opens a bottom sheet where the athlete can rate and comment on a coach
  /// after finishing a session.
  void _showAddReviewModal(String coachId) {
    int selectedStar = 5;
    final commentController = TextEditingController();
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
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
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
                    "Ders Nasıldı?",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Eğitmeni değerlendirerek topluluğa katkı sağla.",
                    style: GoogleFonts.poppins(
                      color: Colors.white54,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Star rating row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < selectedStar
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: Colors.amber,
                          size: 40,
                        ),
                        onPressed: () =>
                            setModalState(() => selectedStar = index + 1),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),

                  // Comment input
                  TextField(
                    controller: commentController,
                    maxLines: 4,
                    style: GoogleFonts.poppins(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Eğitmen hakkında ne düşünüyorsun?",
                      hintStyle: GoogleFonts.poppins(color: Colors.white30),
                      filled: true,
                      fillColor: Colors.black26,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              if (commentController.text.trim().isEmpty) return;
                              setModalState(() => isSubmitting = true);
                              await _submitReview(
                                coachId,
                                selectedStar,
                                commentController.text.trim(),
                              );
                              if (mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "Yorumunuz kaydedildi.",
                                      style: GoogleFonts.poppins(),
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorConstants.primaryColor,
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
                              "Yorumu Gönder",
                              style: GoogleFonts.poppins(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Delegates review submission to [ILessonService] after fetching the
  /// current athlete's display name and avatar from Firestore.
  Future<void> _submitReview(String coachId, int rating, String comment) async {
    final currentUser = _auth.currentUser!;

    // Fetch the athlete's own profile to denormalise their name into the review.
    final myDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();
    final String myName =
        "${myDoc.data()?['name'] ?? ''} ${myDoc.data()?['surname'] ?? ''}"
            .trim();
    final String? myImage = myDoc.data()?['profileImageUrl'] as String?;

    await _lessonService.submitReview(
      coachId: coachId,
      athleteId: currentUser.uid,
      athleteName: myName,
      athleteImage: myImage,
      rating: rating,
      comment: comment,
    );
  }

  // ---------------------------------------------------------------------------
  // Cancel dialog
  // ---------------------------------------------------------------------------

  /// Shows a confirmation dialog before cancelling a lesson.
  void _showCancelDialog(String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Emin misin?",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          "Bu dersi iptal etmek istediğine emin misin? "
          "Bu işlem geri alınamaz.",
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "Vazgeç",
              style: GoogleFonts.poppins(
                color: Colors.white54,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _lessonService.cancelLesson(docId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Ders başarıyla iptal edildi.",
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              "Dersi İptal Et",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // Guest user — show a prompt to sign in.
    if (_auth.currentUser == null) {
      return _buildGuestView();
    }

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.black.withOpacity(0.6),
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Text(
            "Derslerim",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: _lessonService.getLessonsForAthlete(_auth.currentUser!.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: ColorConstants.primaryColor,
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmptyState(context);
            }

            return ListView.builder(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + kToolbarHeight + 16,
                left: 16,
                right: 16,
                bottom: 16,
              ),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final docId = snapshot.data!.docs[index].id;
                final lesson =
                    snapshot.data!.docs[index].data() as Map<String, dynamic>;
                return _buildLessonCard(docId, lesson);
              },
            );
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Private builders
  // ---------------------------------------------------------------------------

  /// View shown to unauthenticated (guest) users.
  Widget _buildGuestView() {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          "Derslerim",
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
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  size: 80,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "CoachApp'e kaydol antrenmanlarına hemen başla 🔥",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
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

  /// Builds a card representing a single lesson booking.
  Widget _buildLessonCard(String docId, Map<String, dynamic> lesson) {
    final String status = lesson['status'] as String? ?? 'pending';
    final String type = lesson['lessonType'] as String? ?? 'Online';

    // Map status string to display values.
    Color statusColor = Colors.orange;
    String statusText = "Onay Bekliyor";
    IconData statusIcon = Icons.hourglass_empty_rounded;

    if (status == 'approved') {
      statusColor = Colors.green;
      statusText = "Aktif Ders";
      statusIcon = Icons.check_circle_rounded;
    } else if (status == 'rejected') {
      statusColor = Colors.redAccent;
      statusText = "Reddedildi";
      statusIcon = Icons.cancel_rounded;
    } else if (status == 'cancelled') {
      statusColor = Colors.grey;
      statusText = "İptal Edildi";
      statusIcon = Icons.block_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: status == 'approved'
              ? ColorConstants.primaryColor.withOpacity(0.3)
              : Colors.white10,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: coach avatar, name, status badge
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white10,
                backgroundImage: lesson['coachImage'] != null
                    ? CachedNetworkImageProvider(lesson['coachImage'] as String)
                    : null,
                child: lesson['coachImage'] == null
                    ? const Icon(Icons.person, color: Colors.white54)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson['coachName'] as String? ?? 'Eğitmen',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "${lesson['sport']} • $type",
                      style: GoogleFonts.poppins(
                        color: ColorConstants.primaryColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: GoogleFonts.poppins(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Day and time rows
          _detailRow(
            Icons.calendar_today_rounded,
            (lesson['days'] as List? ?? []).join(', '),
          ),
          const SizedBox(height: 8),
          _detailRow(
            Icons.access_time_rounded,
            (lesson['hours'] as List? ?? []).join(', '),
          ),

          // Online lesson: join button
          if (status == 'approved' && type == 'Online') ...[
            const SizedBox(height: 16),
            ScaleButton(
              onPressed: () async {
                final bool? isClassEnded = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VideoCallScreen(
                      roomName: "${lesson['sport']} Dersi",
                      remoteUserName:
                          lesson['coachName'] as String? ?? "Eğitmen",
                    ),
                  ),
                );
                if (isClassEnded == true) {
                  _showAddReviewModal(lesson['coachId'] as String);
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [ColorConstants.primaryColor, Color(0xFFB4FF4E)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: ColorConstants.primaryColor.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.videocam_rounded,
                      color: Colors.black,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Canlı Derse Katıl",
                      style: GoogleFonts.poppins(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ]
          // Face-to-face lesson: location reminder
          else if (status == 'approved' && type == 'Yüzyüze') ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    color: Colors.white54,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Yüzyüze Ders - Konum ve detaylar için "
                      "mesaj atabilirsiniz.",
                      style: GoogleFonts.poppins(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Cancel button for active or pending lessons
          if (status == 'pending' || status == 'approved') ...[
            const SizedBox(height: 12),
            ScaleButton(
              onPressed: () => _showCancelDialog(docId),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.cancel_outlined,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Dersi İptal Et",
                      style: GoogleFonts.poppins(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Small icon + label row used inside lesson cards for day/time info.
  Widget _detailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white54, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
          ),
        ),
      ],
    );
  }

  /// Shown when the athlete has no lessons yet.
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.play_lesson_outlined,
                size: 60,
                color: Colors.white.withOpacity(0.3),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Henüz Bir Ders Almadın",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Keşfet sayfasından sana en uygun eğitmeni bulup "
              "hemen antrenmanlara başlayabilirsin.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white54,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
