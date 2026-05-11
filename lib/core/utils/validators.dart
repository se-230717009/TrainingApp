/// lib/core/utils/validators.dart
///
/// Pure, stateless form validation functions used by [CustomTextField].
/// Each function accepts a nullable [String] and returns `null` when valid
/// or a localised error string when validation fails.
///
/// All validators follow the same signature required by [TextFormField.validator].

/// Collection of reusable form field validators.
class Validators {
  // Private constructor — this class should never be instantiated.
  Validators._();

  /// Validates an email address using a basic RFC-compatible regex.
  ///
  /// Returns `null` when valid; an error string otherwise.
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'E-posta adresi gerekli';
    }
    // Basit regex ile e-posta formatı kontrolü
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Geçerli bir e-posta giriniz';
    }
    return null;
  }

  /// Validates a password against the app's strength policy:
  ///   - Minimum 8 characters.
  ///   - At least one uppercase letter.
  ///   - At least one digit.
  ///   - At least one special character.
  ///
  /// Returns `null` when valid; an error string otherwise.
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Şifre gerekli';
    }
    if (value.length < 8) {
      return 'Şifre en az 8 karakter olmalı';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Şifre en az bir büyük harf içermeli';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Şifre en az bir rakam içermeli';
    }
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Şifre en az bir özel karakter (!@#) içermeli';
    }
    return null;
  }

  /// Validates a username:
  ///   - 3–20 characters.
  ///   - Only letters, digits, and underscores (`_`).
  ///
  /// Returns `null` when valid; an error string otherwise.
  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Kullanıcı adı gerekli';
    }
    if (value.length < 3) {
      return 'En az 3 karakter olmalı';
    }
    if (value.length > 20) {
      return 'En fazla 20 karakter olabilir';
    }
    // Sadece harf, rakam ve alt çizgiye izin verelim
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return 'Sadece harf, rakam ve _ kullanılabilir';
    }
    return null;
  }

  /// Validates a user's age (must be between 12 and 100 inclusive).
  ///
  /// Returns `null` when valid; an error string otherwise.
  static String? validateAge(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Yaş bilgisi gerekli';
    }
    int? age = int.tryParse(value.trim());
    if (age == null) {
      return 'Lütfen geçerli bir yaş girin';
    }
    if (age < 12 || age > 100) {
      return 'Yaş 12 ile 100 arasında olmalıdır';
    }
    return null;
  }

  /// Validates height in centimetres (must be between 100 and 250 inclusive).
  ///
  /// Returns `null` when valid; an error string otherwise.
  static String? validateHeight(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Boy bilgisi gerekli';
    }
    int? height = int.tryParse(value.trim());
    if (height == null) {
      return 'Lütfen geçerli bir boy (cm) girin';
    }
    if (height < 100 || height > 250) {
      return 'Boy 100 ile 250 cm arasında olmalıdır';
    }
    return null;
  }

  /// Validates weight in kilograms (must be between 30 and 300 inclusive).
  ///
  /// Returns `null` when valid; an error string otherwise.
  static String? validateWeight(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Kilo bilgisi gerekli';
    }
    int? weight = int.tryParse(value.trim());
    if (weight == null) {
      return 'Lütfen geçerli bir kilo (kg) girin';
    }
    if (weight < 30 || weight > 300) {
      return 'Kilo 30 ile 300 kg arasında olmalıdır';
    }
    return null;
  }
}
