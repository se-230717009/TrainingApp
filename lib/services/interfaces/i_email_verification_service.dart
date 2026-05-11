/// lib/services/interfaces/i_email_verification_service.dart
library;

abstract class IEmailVerificationService {
  /// Kullanıcının e-postasının onaylı olup olmadığını döner.
  Future<bool> isEmailVerified();

  /// Kullanıcıya bir doğrulama e-postası gönderir.
  Future<void> sendVerificationEmail();

  /// Kullanıcının Firebase üzerindeki anlık durumunu (onaylanıp onaylanmadığını) yeniler.
  Future<void> reloadUser();
}
