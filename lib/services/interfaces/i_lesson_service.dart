/// lib/services/interfaces/i_lesson_service.dart
///
/// Abstract contract for lesson CRUD operations.
///
/// Extracts all `lessons` collection reads/writes from the UI layer into a
/// dedicated service, following the **Single Responsibility Principle**.
/// Screens subscribe to streams or call methods here; they never touch
/// Firestore directly.

library;
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class ILessonService {
  // ---------------------------------------------------------------------------
  // Streams (real-time listeners)
  // ---------------------------------------------------------------------------

  /// Returns a real-time stream of all lessons booked by [athleteId],
  /// ordered by most recent first.
  Stream<QuerySnapshot> getLessonsForAthlete(String athleteId);

  /// Returns a real-time stream of lesson requests that are in `pending`
  /// state and addressed to [coachId], ordered by most recent first.
  Stream<QuerySnapshot> getPendingLessonsForCoach(String coachId);

  // ---------------------------------------------------------------------------
  // Mutations
  // ---------------------------------------------------------------------------

  /// Updates the `status` field of the lesson document identified by [docId].
  ///
  /// Valid [status] values: `'approved'`, `'rejected'`, `'cancelled'`.
  Future<void> updateLessonStatus(String docId, String status);

  /// Cancels the lesson identified by [docId] (sets status to `'cancelled'`).
  Future<void> cancelLesson(String docId);

  // ---------------------------------------------------------------------------
  // Reviews
  // ---------------------------------------------------------------------------

  /// Submits a [rating] (1–5) and [comment] for coach [coachId] by the
  /// currently signed-in athlete, then recalculates and persists the
  /// coach's average rating in their profile document.
  Future<void> submitReview({
    required String coachId,
    required String athleteId,
    required String athleteName,
    required String? athleteImage,
    required int rating,
    required String comment,
  });
}
