/// lib/services/interfaces/i_auth_service.dart
///
/// Abstract contract for authentication operations.
///
/// **Why an interface?**
/// Screens that depend on [IAuthService] (not on [AuthService] directly) can
/// be tested in isolation by swapping in a mock/fake implementation — without
/// touching Firebase. This follows the **Dependency Inversion Principle**.

library;
abstract class IAuthService {
  // ---------------------------------------------------------------------------
  // Authentication
  // ---------------------------------------------------------------------------

  /// Signs in an existing user with email and password.
  ///
  /// Returns `null` on success, or an error message string on failure.
  Future<String?> signIn({
    required String email,
    required String password,
  });

  /// Creates a new Firebase Auth account and writes the user profile to
  /// Firestore.
  ///
  /// Returns `null` on success, or an error message string on failure.
  Future<String?> registerUser({
    required String email,
    required String password,
    required String name,
    required String surname,
    required String username,
    required String userType,
  });

  /// Authenticates the user via the Google Sign-In flow.
  ///
  /// [role] should be provided when called from the registration screen
  /// (`'athlete'` or `'coach'`), and left `null` when called from the
  /// login screen (existing accounts only).
  ///
  /// Returns `null` on success, or an error/info message string on failure.
  Future<String?> signInWithGoogle({String? role});

  // ---------------------------------------------------------------------------
  // User data
  // ---------------------------------------------------------------------------

  /// Fetches the user's onboarding completion flag from Firestore.
  ///
  /// Returns `true` if the user has already completed the onboarding form.
  Future<bool> checkOnboardingStatus(String uid);

  /// Fetches the user's role from Firestore (`'athlete'` or `'coach'`).
  ///
  /// Returns `null` if the document does not exist or on error.
  Future<String?> getUserType(String uid);

  /// Partially updates the user's Firestore profile document.
  ///
  /// [data] should be a map of only the fields that need to change
  /// (e.g. `{'bio': 'New bio', 'isOnboardingCompleted': true}`).
  Future<void> updateUserProfile({
    required String uid,
    required Map<String, dynamic> data,
  });

  // ---------------------------------------------------------------------------
  // Sign out
  // ---------------------------------------------------------------------------

  /// Signs out from both Firebase Auth and Google Sign-In.
  Future<void> signOut();
}
