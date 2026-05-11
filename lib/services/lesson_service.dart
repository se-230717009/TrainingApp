/// lib/services/lesson_service.dart
///
/// Concrete implementation of [ILessonService] backed by Firebase Firestore.
///
/// **Why this file exists:**
/// Previously, every screen that dealt with lessons (`MyLessonsScreen`,
/// `CoachNotificationsScreen`, `CoachCalendarScreen`) was calling
/// `FirebaseFirestore.instance.collection('lessons')` directly inside widget
/// methods. That mixed business logic with UI and made the code very hard to
/// change or test. Now all lesson-related Firestore operations live here.

library;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'interfaces/i_lesson_service.dart';

/// Provides all CRUD operations for the `lessons` Firestore collection.
class LessonService implements ILessonService {
  /// Injected Firestore instance — defaults to the singleton but can be
  /// replaced with a fake in tests.
  final FirebaseFirestore _firestore;

  /// Creates a [LessonService].
  ///
  /// The [firestore] parameter is optional and defaults to the Firebase
  /// singleton, so existing code doesn't need to change its call-sites.
  LessonService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // Streams
  // ---------------------------------------------------------------------------

  @override
  Stream<QuerySnapshot> getLessonsForAthlete(String athleteId) {
    // Fetch all lessons where the athlete is the booking party, newest first.
    return _firestore
        .collection('lessons')
        .where('athleteId', isEqualTo: athleteId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  @override
  Stream<QuerySnapshot> getPendingLessonsForCoach(String coachId) {
    // Only surface unanswered (pending) requests so the coach's notification
    // screen stays actionable and uncluttered.
    return _firestore
        .collection('lessons')
        .where('coachId', isEqualTo: coachId)
        .where('status', isEqualTo: 'pending')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // ---------------------------------------------------------------------------
  // Mutations
  // ---------------------------------------------------------------------------

  @override
  Future<void> updateLessonStatus(String docId, String status) async {
    await _firestore.collection('lessons').doc(docId).update({
      'status': status,
    });
  }

  @override
  Future<void> cancelLesson(String docId) async {
    await updateLessonStatus(docId, 'cancelled');
  }

  // ---------------------------------------------------------------------------
  // Reviews
  // ---------------------------------------------------------------------------

  @override
  Future<void> submitReview({
    required String coachId,
    required String athleteId,
    required String athleteName,
    required String? athleteImage,
    required int rating,
    required String comment,
  }) async {
    // 1. Write (or overwrite) the review document.
    //    Using the athlete's UID as the document ID prevents duplicate reviews.
    await _firestore
        .collection('users')
        .doc(coachId)
        .collection('reviews')
        .doc(athleteId)
        .set({
      'userId': athleteId,
      'userName': athleteName.isEmpty ? 'Student' : athleteName,
      'userImage': athleteImage,
      'rating': rating,
      'comment': comment,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // 2. Recalculate the coach's average rating from all reviews so the
    //    discovery screen always shows an accurate score.
    final reviewsSnapshot = await _firestore
        .collection('users')
        .doc(coachId)
        .collection('reviews')
        .get();

    double totalScore = 0;
    for (final doc in reviewsSnapshot.docs) {
      totalScore += (doc.data()['rating'] as num? ?? 0);
    }

    final double newAverage = totalScore / reviewsSnapshot.docs.length;
    await _firestore.collection('users').doc(coachId).update({
      'rating': newAverage,
      'reviewCount': reviewsSnapshot.docs.length,
    });
  }
}
