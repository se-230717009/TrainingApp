/// lib/models/lesson_model.dart
///
/// A typed representation of a lesson document stored in Firestore's
/// `lessons` collection. Centralising field-name strings here means that
/// if the schema changes, only this file needs updating.

/// Represents the lifecycle state of a lesson booking.
library;
enum LessonStatus {
  /// The athlete has requested the lesson; the coach has not responded yet.
  pending,

  /// The coach accepted the lesson request.
  approved,

  /// The coach declined the lesson request.
  rejected,

  /// Either party cancelled the lesson after it was accepted.
  cancelled,
}

/// Possible delivery formats for a lesson.
enum LessonType {
  /// Conducted via video call (Jitsi Meet).
  online,

  /// Conducted in person at an agreed location.
  faceToFace,
}

class LessonModel {
  /// Firestore document ID of this lesson.
  final String docId;

  /// Firebase Auth UID of the athlete who booked this lesson.
  final String athleteId;

  /// Display name of the athlete (denormalised for quick reads).
  final String athleteName;

  /// Optional URL to the athlete's profile picture.
  final String? athleteImage;

  /// Firebase Auth UID of the coach.
  final String coachId;

  /// Display name of the coach (denormalised for quick reads).
  final String coachName;

  /// Optional URL to the coach's profile picture.
  final String? coachImage;

  /// The sport/discipline this lesson covers (e.g. "Yüzme").
  final String sport;

  /// Current lifecycle state of this lesson.
  final LessonStatus status;

  /// Whether the lesson is online or face-to-face.
  final LessonType lessonType;

  /// Days of the week selected for recurring sessions (e.g. ["Pazartesi"]).
  final List<String> days;

  /// Time slots selected for recurring sessions (e.g. ["09:00", "11:00"]).
  final List<String> hours;

  const LessonModel({
    required this.docId,
    required this.athleteId,
    required this.athleteName,
    this.athleteImage,
    required this.coachId,
    required this.coachName,
    this.coachImage,
    required this.sport,
    required this.status,
    required this.lessonType,
    required this.days,
    required this.hours,
  });

  // ---------------------------------------------------------------------------
  // Factory constructors
  // ---------------------------------------------------------------------------

  /// Creates a [LessonModel] from a Firestore document.
  factory LessonModel.fromMap(String docId, Map<String, dynamic> map) {
    return LessonModel(
      docId: docId,
      athleteId: map['athleteId'] as String? ?? '',
      athleteName: map['athleteName'] as String? ?? 'Unnamed Athlete',
      athleteImage: map['athleteImage'] as String?,
      coachId: map['coachId'] as String? ?? '',
      coachName: map['coachName'] as String? ?? 'Unnamed Coach',
      coachImage: map['coachImage'] as String?,
      sport: map['sport'] as String? ?? '',
      status: _parseStatus(map['status'] as String?),
      lessonType: _parseType(map['lessonType'] as String?),
      days: List<String>.from(map['days'] as List? ?? []),
      hours: List<String>.from(map['hours'] as List? ?? []),
    );
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  static LessonStatus _parseStatus(String? raw) {
    switch (raw) {
      case 'approved':
        return LessonStatus.approved;
      case 'rejected':
        return LessonStatus.rejected;
      case 'cancelled':
        return LessonStatus.cancelled;
      default:
        return LessonStatus.pending;
    }
  }

  static LessonType _parseType(String? raw) {
    if (raw == 'Yüzyüze') return LessonType.faceToFace;
    return LessonType.online;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Returns the Firestore-compatible string for the current [status].
  String get statusString {
    switch (status) {
      case LessonStatus.approved:
        return 'approved';
      case LessonStatus.rejected:
        return 'rejected';
      case LessonStatus.cancelled:
        return 'cancelled';
      case LessonStatus.pending:
        return 'pending';
    }
  }
}
