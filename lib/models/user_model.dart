/// lib/models/user_model.dart
///
/// A typed representation of a user document stored in Firestore's
/// `users` collection. Using a dedicated model class instead of raw
/// `Map<String, dynamic>` provides:
///   - Compile-time safety (no more forgotten field-name typos).
///   - A single place to update if the Firestore schema changes.
///   - Easier reading for new teammates.

library;
class UserModel {
  /// Firestore document ID, same as Firebase Auth UID.
  final String uid;

  /// The user's first name.
  final String name;

  /// The user's last name.
  final String surname;

  /// Unique username chosen during registration (e.g. "john_doe").
  final String username;

  /// Email address used for Firebase Auth.
  final String email;

  /// Role in the app — either `'athlete'` or `'coach'`.
  final String userType;

  /// Whether this coach account has been approved by an admin.
  /// Always `false` for athletes.
  final bool isVerified;

  /// Whether the user has completed the onboarding form after registration.
  final bool isOnboardingCompleted;

  /// Optional URL to the user's profile picture stored in Firebase Storage.
  final String? profileImageUrl;

  /// Short biography text shown on the coach's public profile.
  final String? bio;

  const UserModel({
    required this.uid,
    required this.name,
    required this.surname,
    required this.username,
    required this.email,
    required this.userType,
    required this.isVerified,
    required this.isOnboardingCompleted,
    this.profileImageUrl,
    this.bio,
  });

  // ---------------------------------------------------------------------------
  // Factory constructors
  // ---------------------------------------------------------------------------

  /// Creates a [UserModel] from a Firestore document's data map.
  ///
  /// All nullable fields fall back to sensible defaults so callers never
  /// need to null-check individual fields after construction.
  factory UserModel.fromMap(String uid, Map<String, dynamic> map) {
    return UserModel(
      uid: uid,
      name: map['name'] as String? ?? '',
      surname: map['surname'] as String? ?? '',
      username: map['username'] as String? ?? '',
      email: map['email'] as String? ?? '',
      userType: map['userType'] as String? ?? 'athlete',
      isVerified: map['isApproved'] as bool? ?? map['isVerified'] as bool? ?? false,
      isOnboardingCompleted: map['isOnboardingCompleted'] as bool? ?? false,
      profileImageUrl: map['profileImageUrl'] as String?,
      bio: map['bio'] as String?,
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Returns `true` when this user's [userType] is `'coach'`.
  bool get isCoach => userType == 'coach';

  /// Returns the full display name (e.g. "Jane Doe").
  /// Falls back to `'Unnamed User'` if both parts are empty.
  String get fullName {
    final combined = '$name $surname'.trim();
    return combined.isEmpty ? 'Unnamed User' : combined;
  }

  /// Converts this model back to a map suitable for Firestore writes.
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'surname': surname,
      'username': username,
      'email': email,
      'userType': userType,
      'isVerified': isVerified,
      'isOnboardingCompleted': isOnboardingCompleted,
      if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
      if (bio != null) 'bio': bio,
    };
  }
}
