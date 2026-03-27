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

  // --- YENİ: YAŞ KONTROLÜ (12-100 Arası) ---
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

  // --- YENİ: BOY KONTROLÜ (100-250 cm Arası) ---
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

  // --- YENİ: KİLO KONTROLÜ (30-300 kg Arası) ---
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
