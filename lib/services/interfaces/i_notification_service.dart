/// lib/services/interfaces/i_notification_service.dart
///
/// Abstract contract for notification read/write operations.
///
/// Both the coach side (sending notifications to athletes) and the athlete
/// side (reading and marking notifications as read) go through this
/// interface, keeping notification logic out of the widget layer.

library;
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class INotificationService {
  // ---------------------------------------------------------------------------
  // Streams
  // ---------------------------------------------------------------------------

  /// Returns a real-time stream of all notifications for [uid], ordered
  /// by most recent first.
  Stream<QuerySnapshot> getNotificationsForUser(String uid);

  /// Returns a real-time stream of **unread** notifications for [uid].
  /// Used to drive the badge counter on the notification bell icon.
  Stream<QuerySnapshot> getUnreadNotificationsForUser(String uid);

  // ---------------------------------------------------------------------------
  // Mutations
  // ---------------------------------------------------------------------------

  /// Marks the notification document [docId] (belonging to user [uid])
  /// as read by setting its `isRead` field to `true`.
  Future<void> markAsRead(String uid, String docId);

  /// Sends a "lesson approved" push notification to [athleteId].
  ///
  /// [coachName] and [sport] are included in the notification body so the
  /// athlete knows which lesson was approved.
  Future<void> sendLessonApprovedNotification({
    required String athleteId,
    required String coachName,
    required String sport,
  });
}
