/// lib/screens/coach_notification_screen.dart
///
/// Displays pending lesson requests sent to the currently signed-in coach.
///
/// The coach can approve or reject each request from this screen.
/// Approving a request automatically sends a notification to the athlete via
/// [INotificationService] — the screen itself never writes to Firestore
/// directly (Single Responsibility Principle).

library;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants/color_constants.dart';
import '../services/lesson_service.dart';
import '../services/notification_service.dart';
import '../services/interfaces/i_lesson_service.dart';
import '../services/interfaces/i_notification_service.dart';

/// Coach-facing screen that lists unanswered lesson booking requests.
class CoachNotificationsScreen extends StatefulWidget {
  /// Injectable lesson service — defaults to [LessonService].
  final ILessonService lessonService;

  /// Injectable notification service — defaults to [NotificationService].
  final INotificationService notificationService;

  const CoachNotificationsScreen({
    super.key,
    ILessonService? lessonService,
    INotificationService? notificationService,
  })  : lessonService = lessonService ?? const _DefaultLesson(),
        notificationService =
            notificationService ?? const _DefaultNotification();

  @override
  State<CoachNotificationsScreen> createState() =>
      _CoachNotificationsScreenState();
}

class _DefaultLesson implements ILessonService {
  const _DefaultLesson();
  @override
  dynamic noSuchMethod(Invocation i) => LessonService();
}

class _DefaultNotification implements INotificationService {
  const _DefaultNotification();
  @override
  dynamic noSuchMethod(Invocation i) => NotificationService();
}

class _CoachNotificationsScreenState
    extends State<CoachNotificationsScreen> {
  // ---------------------------------------------------------------------------
  // Dependencies
  // ---------------------------------------------------------------------------

  late final ILessonService _lessonService;
  late final INotificationService _notificationService;
  late final String _currentUserId;

  @override
  void initState() {
    super.initState();
    _lessonService = widget.lessonService is _DefaultLesson
        ? LessonService()
        : widget.lessonService;
    _notificationService = widget.notificationService is _DefaultNotification
        ? NotificationService()
        : widget.notificationService;
    _currentUserId = FirebaseAuth.instance.currentUser!.uid;
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  /// Updates the lesson [status] (approved / rejected) and, if approved,
  /// sends a notification to the athlete.
  ///
  /// [lessonData] is the raw Firestore map needed to build the notification
  /// body (coach name, sport, athlete ID).
  Future<void> _updateLessonStatus(
    String docId,
    String status,
    Map<String, dynamic> lessonData,
  ) async {
    // 1. Persist the new status.
    await _lessonService.updateLessonStatus(docId, status);

    // 2. If the lesson was approved, notify the athlete.
    if (status == 'approved') {
      await _notificationService.sendLessonApprovedNotification(
        athleteId: lessonData['athleteId'] as String,
        coachName: lessonData['coachName'] as String? ?? 'Coach',
        sport: lessonData['sport'] as String? ?? '',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
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
          "Bildirimler",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Stream of pending lesson requests for this coach.
        stream: _lessonService.getPendingLessonsForCoach(_currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: ColorConstants.primaryColor,
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final lessonData = doc.data() as Map<String, dynamic>;

              // Safely read the first day/hour from list fields.
              final String lessonDay =
                  (lessonData['days'] as List?)?.first as String? ??
                      'Gün belirtilmedi';
              final String lessonHour =
                  (lessonData['hours'] as List?)?.first as String? ??
                      'Saat belirtilmedi';

              return _buildRequestCard(
                doc.id,
                lessonData,
                lessonDay,
                lessonHour,
              );
            },
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Private builders
  // ---------------------------------------------------------------------------

  /// Empty state shown when there are no pending requests.
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ignore: deprecated_member_use
          Icon(
            Icons.notifications_off_outlined,
            size: 60,
            color: Colors.white.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            "Yeni bildiriminiz yok.",
            style: GoogleFonts.poppins(
              color: Colors.white54,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  /// Card showing a single lesson request with approve / reject actions.
  Widget _buildRequestCard(
    String docId,
    Map<String, dynamic> lessonData,
    String lessonDay,
    String lessonHour,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          // ignore: deprecated_member_use
          color: ColorConstants.primaryColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Athlete info row
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white10,
                backgroundImage: lessonData['athleteImage'] != null
                    ? NetworkImage(lessonData['athleteImage'] as String)
                    : null,
                child: lessonData['athleteImage'] == null
                    ? const Icon(Icons.person, color: Colors.white38)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lessonData['athleteName'] as String? ??
                          'İsimsiz Öğrenci',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      "Yeni Ders Talebi "
                      "(${lessonData['lessonType'] ?? 'Online'})",
                      style: GoogleFonts.poppins(
                        color: ColorConstants.primaryColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Lesson day/time
          _infoRow(Icons.event, "$lessonDay • $lessonHour"),
          const SizedBox(height: 6),
          _infoRow(Icons.sports_gymnastics,
              "${lessonData['sport']} Dersi"),

          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () =>
                      _updateLessonStatus(docId, 'rejected', lessonData),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "Reddet",
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () =>
                      _updateLessonStatus(docId, 'approved', lessonData),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorConstants.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "Onayla",
                    style: GoogleFonts.poppins(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Small icon + text info row used inside the request card.
  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white54, size: 16),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}
