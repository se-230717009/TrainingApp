import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  // Firebase'in yetkili servislerine erişim
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. DEĞİŞİKLİK: Artık 'GoogleSignIn.instance' kullanmak zorundayız (v7 kuralı)
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  bool _isGoogleInitialized = false;

  // 2. DEĞİŞİKLİK: Google servisini kullanmadan önce uyandırmamız (initialize) gerekiyor
  Future<void> _ensureGoogleInitialized() async {
    if (!_isGoogleInitialized) {
      await _googleSignIn.initialize();
      _isGoogleInitialized = true;
    }
  }

  // --- GOOGLE İLE GİRİŞ / KAYIT ---
  Future<String?> signInWithGoogle({String? role}) async {
    try {
      // Önce servisi uyandırıyoruz
      await _ensureGoogleInitialized();

      // 3. DEĞİŞİKLİK: signIn() yerine authenticate() kullanıyoruz
      final GoogleSignInAccount? googleUser = await _googleSignIn
          .authenticate();
      if (googleUser == null) return "Google girişi iptal edildi.";

      // Kimlik Doğrulama Bilgilerini Al
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 4. DEĞİŞİKLİK: Yeni sürümde accessToken ayrı bir yere taşındı,
      // Firebase'e giriş yapmak için sadece idToken vermemiz yeterli.
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // Firebase'e Giriş Yap
      UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      String uid = userCredential.user!.uid;

      // Kullanıcı Veritabanında Var Mı Kontrol Et
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();

      if (!doc.exists) {
        // --- YENİ KULLANICI DURUMU ---
        if (role != null) {
          // Eğer Register ekranından geldiyse veritabanına kaydet
          await _firestore.collection('users').doc(uid).set({
            'uid': uid,
            'email': googleUser.email,
            'name': googleUser.displayName?.split(' ').first ?? '',
            'surname':
                googleUser.displayName?.split(' ').skip(1).join(' ') ?? '',
            'username': googleUser.email.split('@').first,
            'userType': role,
            'createdAt': FieldValue.serverTimestamp(),
            'isVerified': false,
            'isOnboardingCompleted': false,
          });
          return null; // Kayıt başarılı
        } else {
          // Eğer Login ekranından geldiyse ve hesabı yoksa, auth'u silip uyarı ver
          await userCredential.user!.delete();
          await _googleSignIn.signOut(); // Google'dan da çıkış yap
          return "Kayıtlı hesabınız yok. Lütfen 'Hesap Oluştur' adımından rolünüzü seçerek kayıt olun.";
        }
      } else {
        // --- ESKİ KULLANICI DURUMU ---
        return null; // Zaten hesabı var, giriş başarılı
      }
    } catch (e) {
      return "Google ile işlem başarısız: $e";
    }
  }

  // --- KAYIT OL (REGISTER) ---
  Future<String?> registerUser({
    required String email,
    required String password,
    required String name,
    required String surname,
    required String username,
    required String userType, // 'athlete' veya 'coach'
  }) async {
    try {
      // 1. Firebase Auth'ta kullanıcı oluştur (E-posta ve Şifre ile)
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // 2. Oluşan kullanıcının ID'sini (UID) al
      String uid = userCredential.user!.uid;

      // 3. Firestore veritabanına kullanıcının detaylarını kaydet
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'name': name,
        'surname': surname,
        'username': username,
        'userType': userType, // Rolü burada kaydediyoruz
        'createdAt': FieldValue.serverTimestamp(), // Kayıt tarihi
        'isVerified': false, // Henüz onaylı değil (Antrenörler için önemli)
        'isOnboardingCompleted':
            false, // EKLENDİ: Klasik kayıtta da onboarding false olmalı
      });

      return null; // Hata yok, işlem başarılı
    } on FirebaseAuthException catch (e) {
      // Firebase'den özel bir hata gelirse (Örn: E-posta zaten kayıtlı)
      return e.message;
    } catch (e) {
      // Beklenmedik bir hata olursa
      return "Bir hata oluştu: $e";
    }
  }

  // --- GİRİŞ YAP (LOGIN) ---
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; // Hata yok, giriş başarılı
    } on FirebaseAuthException catch (e) {
      return e.message; // Hata mesajını döndür
    } catch (e) {
      return "Bir hata oluştu: $e";
    }
  }

  // --- ONBOARDING TAMAMLANDI MI KONTROL ET ---
  Future<bool> checkOnboardingStatus(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        // 'isOnboardingCompleted' true mu diye bakıyoruz
        return data['isOnboardingCompleted'] == true;
      }
      return false; // Kullanıcı yoksa veya alan yoksa false
    } catch (e) {
      return false;
    }
  }

  // --- ÇIKIŞ YAP (LOGOUT) ---
  Future<void> signOut() async {
    await _auth.signOut();
    try {
      await _googleSignIn
          .signOut(); // Temiz bir çıkış için Google oturumunu da sonlandıralım
    } catch (e) {
      // Hata verirse yoksayabiliriz
    }
  }

  // --- KULLANICI ROLÜNÜ GETİR (COACH / ATHLETE) ---
  Future<String?> getUserType(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        return data['userType'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // --- KULLANICI PROFİLİNİ GÜNCELLE (ONBOARDING İÇİN) ---
  Future<void> updateUserProfile({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      print("Profil güncelleme hatası: $e");
      throw e; // Hatayı yukarı fırlat
    }
  }
}
