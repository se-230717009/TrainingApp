/// lib/services/auth_service.dart
///
/// Concrete implementation of [IAuthService] backed by Firebase Auth and
/// Cloud Firestore.
///
/// **Responsibilities (Single Responsibility Principle):**
///   - Firebase Auth sign-in / registration / sign-out.
///   - Writing the initial user document to Firestore on first sign-up.
///   - Reading the user's role and onboarding state from Firestore.
///
/// Screens must depend on the [IAuthService] abstraction, not this class
/// directly, to honour the Dependency Inversion Principle.

library;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'interfaces/i_auth_service.dart';

/// Firebase-backed implementation of [IAuthService].
class AuthService implements IAuthService {
  // ---------------------------------------------------------------------------
  // Dependencies
  // ---------------------------------------------------------------------------

  /// Firebase Auth instance — entry point for all auth operations.
  final FirebaseAuth _auth;

  /// Firestore instance — used to persist and read user profile documents.
  final FirebaseFirestore _firestore;

  /// Google Sign-In helper — must be initialised before the first call.
  final GoogleSignIn _googleSignIn;

  /// Guards against calling `_googleSignIn.initialize()` more than once per
  /// app session.
  bool _isGoogleInitialized = false;

  /// Creates an [AuthService].
  ///
  /// All three dependencies are optional and fall back to their Firebase
  /// singletons, making the class easy to unit-test with fakes.
  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Ensures the Google Sign-In SDK is ready before the first authentication
  /// attempt. Calling `initialize()` more than once causes an error, so we
  /// guard it with [_isGoogleInitialized].
  Future<void> _ensureGoogleInitialized() async {
    if (!_isGoogleInitialized) {
      await _googleSignIn.initialize();
      _isGoogleInitialized = true;
    }
  }

  /// Writes a new user document to Firestore using the provided fields.
  ///
  /// Called both from [registerUser] (email+password flow) and from
  /// [signInWithGoogle] when a brand-new Google account is being registered.
  Future<void> _createUserDocument({
    required String uid,
    required String email,
    required String name,
    required String surname,
    required String username,
    required String userType,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'uid': uid,
      'email': email,
      'name': name,
      'surname': surname,
      'username': username,
      'userType': userType,
      'createdAt': FieldValue.serverTimestamp(),
      'isVerified': false,
      'isOnboardingCompleted': false,
    });
  }

  // ---------------------------------------------------------------------------
  // IAuthService — Authentication
  // ---------------------------------------------------------------------------

  @override
  Future<String?> signInWithGoogle({String? role}) async {
    try {
      await _ensureGoogleInitialized();

      // Trigger the Google authentication flow.
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
      final GoogleSignInAuthentication googleAuth =
          googleUser.authentication;

      // Build a Firebase credential from the Google ID token.
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final String uid = userCredential.user!.uid;

      // Check whether this account already exists in Firestore.
      final DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();

      if (!doc.exists) {
        // --- New user ---
        if (role != null) {
          // Called from the registration screen: create the profile.
          final nameParts = (googleUser.displayName ?? '').split(' ');
          await _createUserDocument(
            uid: uid,
            email: googleUser.email,
            name: nameParts.first,
            surname: nameParts.skip(1).join(' '),
            username: googleUser.email.split('@').first,
            userType: role,
          );
          return null; // Registration successful.
        } else {
          // Called from the login screen but no account exists — reject.
          await userCredential.user!.delete();
          await _googleSignIn.signOut();
          return "Kayıtlı hesabınız yok. Lütfen 'Hesap Oluştur' adımından "
              "rolünüzü seçerek kayıt olun.";
        }
      }

      // --- Existing user — sign-in successful ---
      return null;
    } catch (e) {
      return "Google ile işlem başarısız: $e";
    }
  }

  @override
  Future<String?> registerUser({
    required String email,
    required String password,
    required String name,
    required String surname,
    required String username,
    required String userType,
  }) async {
    try {
      // 1. Create the Firebase Auth account.
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Persist the full profile to Firestore.
      await _createUserDocument(
        uid: userCredential.user!.uid,
        email: email,
        name: name,
        surname: surname,
        username: username,
        userType: userType,
      );

      return null; // Registration successful.
    } on FirebaseAuthException catch (e) {
      // Surface Firebase-specific error messages (e.g. email already in use).
      return e.message;
    } catch (e) {
      return "Bir hata oluştu: $e";
    }
  }

  @override
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; // Sign-in successful.
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return "Bir hata oluştu: $e";
    }
  }

  // ---------------------------------------------------------------------------
  // IAuthService — User data
  // ---------------------------------------------------------------------------

  @override
  Future<bool> checkOnboardingStatus(String uid) async {
    try {
      final DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        return data['isOnboardingCompleted'] == true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<String?> getUserType(String uid) async {
    try {
      final DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        return data['userType'] as String?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> updateUserProfile({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    // Re-throws so callers can show appropriate error UI.
    await _firestore.collection('users').doc(uid).update(data);
  }

  // ---------------------------------------------------------------------------
  // IAuthService — Sign out
  // ---------------------------------------------------------------------------

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    try {
      // Signing out of Google is a best-effort operation.
      // If it fails (e.g. Google was never used in this session), we ignore it.
      await _googleSignIn.signOut();
    } catch (_) {
      // Intentionally swallowed.
    }
  }
}
