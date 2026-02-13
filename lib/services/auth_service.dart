import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  // Firebase'in yetkili servislerine erişim
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
      throw e;
    }
  }
}
