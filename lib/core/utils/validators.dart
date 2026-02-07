// lib/core/utils/validators.dart

class Validators {
  // E-posta kontrolü
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

  // Güçlü şifre kontrolü
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

  // Kullanıcı adı kontrolü
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
}
