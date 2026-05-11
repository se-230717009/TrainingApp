/// lib/services/email_verification_service.dart
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'interfaces/i_email_verification_service.dart';

/// Firebase kullanarak e-posta doğrulama işlemlerini yöneten servis.
/// Single Responsibility (Tek Sorumluluk) prensibi gereği Auth işlemlerinden ayrılmıştır.
class EmailVerificationService implements IEmailVerificationService {
  final FirebaseAuth _auth;

  // Test edilebilirlik (Dependency Injection) için opsiyonel auth parametresi
  EmailVerificationService({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;

  @override
  Future<bool> isEmailVerified() async {
    return _auth.currentUser?.emailVerified ?? false;
  }

  @override
  Future<void> sendVerificationEmail() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  @override
  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }
}
