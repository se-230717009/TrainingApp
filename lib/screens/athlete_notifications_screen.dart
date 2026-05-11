/// lib/screens/athlete_notifications_screen.dart
///
/// Displays all notifications for the currently signed-in athlete.
///
/// Notifications are written to Firestore by [NotificationService] (e.g.
/// when a coach approves a lesson) and read here via [INotificationService].
/// Tapping an unread notification marks it as read — the screen never writes
/// to Firestore directly (Single Responsibility Principle).

// ignore_for_file: deprecated_member_use

library;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants/color_constants.dart';
import '../widgets/gradient_background.dart';
import '../services/notification_service.dart';
import '../services/interfaces/i_notification_service.dart';

/// Notification inbox for athletes.
class AthleteNotificationsScreen extends StatefulWidget {
  /// Injectable notification service — defaults to [NotificationService].
  final INotificationService notificationService;

  const AthleteNotificationsScreen({
    super.key,
    INotificationService? notificationService,
  }) : notificationService =
            notificationService ?? const _DefaultNotification();

  @override
  State<AthleteNotificationsScreen> createState() =>
      _AthleteNotificationsScreenState();
}

class _DefaultNotification implements INotificationService {
  const _DefaultNotification();
  @override
  dynamic noSuchMethod(Invocation i) => NotificationService();
}

class _AthleteNotificationsScreenState
    extends State<AthleteNotificationsScreen> {
  // ---------------------------------------------------------------------------
  // Dependencies
  // ---------------------------------------------------------------------------

  late final INotificationService _notificationService;
  late final String _uid;

  @override
  void initState() {
    super.initState();
    _notificationService =
        widget.notificationService is _DefaultNotification
            ? NotificationService()
            : widget.notificationService;
    _uid = FirebaseAuth.instance.currentUser!.uid;
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  /// Marks a notification as read when the user taps it.
  Future<void> _markAsRead(String docId) async {
    await _notificationService.markAsRead(_uid, docId);
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

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
            "Bildirimler",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: _notificationService.getNotificationsForUser(_uid),
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
              padding: const EdgeInsets.all(16),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final doc = snapshot.data!.docs[index];
                final notif = doc.data() as Map<String, dynamic>;
                final bool isRead = notif['isRead'] as bool? ?? false;

                return GestureDetector(
                  // Mark as read on tap if not already read.
                  onTap: () {
                    if (!isRead) _markAsRead(doc.id);
                  },
                  child: _buildNotificationCard(notif, isRead),
                );
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 60,
            color: Colors.white.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            "Henüz bir bildiriminiz yok.",
            style: GoogleFonts.poppins(
              color: Colors.white54,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a single notification card.
  ///
  /// Unread notifications are highlighted with a coloured border and
  /// background, plus a dot indicator in the top-right corner.
  Widget _buildNotificationCard(
      Map<String, dynamic> notif, bool isRead) {
    final bool isApproved = notif['type'] == 'lesson_approved';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isRead
            ? Colors.white.withOpacity(0.05)
            : ColorConstants.primaryColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRead
              ? Colors.white10
              : ColorConstants.primaryColor.withOpacity(0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Notification type icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isRead
                  ? Colors.white10
                  : ColorConstants.primaryColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isApproved
                  ? Icons.check_circle_outline_rounded
                  : Icons.notifications_active_rounded,
              color: isRead
                  ? Colors.white54
                  : ColorConstants.primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),

          // Title and body
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notif['title'] as String? ?? 'Bildirim',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight:
                        isRead ? FontWeight.w500 : FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  notif['body'] as String? ?? '',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          // Unread dot indicator
          if (!isRead)
            Container(
              margin: const EdgeInsets.only(top: 6),
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: ColorConstants.primaryColor,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}
