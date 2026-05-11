/// lib/services/notification_service.dart
///
/// Concrete implementation of [INotificationService] backed by Firebase Firestore.
///
/// **Why this file exists:**
/// Notification reads and writes were scattered across `AthleteNotificationsScreen`
/// and `CoachNotificationsScreen` as raw Firestore calls embedded inside widget
/// methods. Extracting them here keeps the UI layer free of data-access code
/// (Single Responsibility Principle) and makes the notification schema
/// change-safe — only this file needs updating if the collection structure evolves.

library;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'interfaces/i_notification_service.dart';

/// Provides all read/write operations for the per-user `notifications`
/// subcollection in Firestore.
class NotificationService implements INotificationService {
  /// Injected Firestore instance — defaults to the singleton but can be
  /// replaced with a fake in tests.
  final FirebaseFirestore _firestore;

  /// Creates a [NotificationService].
  NotificationService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // Streams
  // ---------------------------------------------------------------------------

  @override
  Stream<QuerySnapshot> getNotificationsForUser(String uid) {
    // Fetch all notifications for the user, newest first.
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  @override
  Stream<QuerySnapshot> getUnreadNotificationsForUser(String uid) {
    // Only count unread items — used to decide whether to show the red dot
    // badge on the notification bell icon.
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots();
  }

  // ---------------------------------------------------------------------------
  // Mutations
  // ---------------------------------------------------------------------------

  @override
  Future<void> markAsRead(String uid, String docId) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc(docId)
        .update({'isRead': true});
  }

  @override
  Future<void> sendLessonApprovedNotification({
    required String athleteId,
    required String coachName,
    required String sport,
  }) async {
    // Write a new notification document into the athlete's notifications
    // subcollection. The athlete's screen listens to this collection in
    // real-time, so the notification appears immediately.
    await _firestore
        .collection('users')
        .doc(athleteId)
        .collection('notifications')
        .add({
      'title': 'Dersiniz Onaylandı! 🎉',
      'body':
          '$coachName ile olan $sport dersiniz onaylandı. '
          'Derslerim sekmesinden detayları ve takvimi kontrol edebilirsiniz.',
      'isRead': false,
      'timestamp': FieldValue.serverTimestamp(),
      // The athlete's screen uses this type to pick the right icon.
      'type': 'lesson_approved',
    });
  }
}
