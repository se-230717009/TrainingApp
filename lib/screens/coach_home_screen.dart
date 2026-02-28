import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants/color_constants.dart';
import '../services/auth_service.dart';
import '../widgets/scale_button.dart';
import 'login_screen.dart';
import 'edit_profile_screen.dart';
import 'coach_calender_screen.dart';
import 'coach_messages_screen.dart';
import 'coach_notification_screen.dart';

class CoachHomeScreen extends StatefulWidget {
  const CoachHomeScreen({super.key});

  @override
  State<CoachHomeScreen> createState() => _CoachHomeScreenState();
}

class _CoachHomeScreenState extends State<CoachHomeScreen> {
  final AuthService _authService = AuthService();
  final String _uid = FirebaseAuth.instance.currentUser!.uid;

  // --- ÇIKIŞ YAP ---
  void _signOut() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  // --- AYARLAR MENÜSÜ ---
  void _showSettingsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Hesap & Ayarlar",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                _buildMenuItem(Icons.person_outline, "Profil Düzenle", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditProfileScreen(),
                    ),
                  );
                }),
                _buildMenuItem(
                  Icons.settings_outlined,
                  "Uygulama Ayarları",
                  () {},
                ),
                _buildMenuItem(
                  Icons.privacy_tip_outlined,
                  "Gizlilik Politikası",
                  () {},
                ),
                _buildMenuItem(Icons.help_outline, "Yardım & Destek", () {}),
                const Divider(color: Colors.white10, height: 30),
                _buildMenuItem(
                  Icons.logout,
                  "Çıkış Yap",
                  _signOut,
                  isDestructive: true,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // --- ÜST BAR ---
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: false,
        titleSpacing: 24,
        title: PopupMenuButton<String>(
          color: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          offset: const Offset(0, 45),
          onSelected: (value) {
            if (value == 'takvimim') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CoachCalendarScreen(),
                ),
              );
            } else if (value == 'mesajlarim') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CoachMessagesScreen(),
                ),
              );
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'panelim',
              child: Row(
                children: [
                  const Icon(
                    Icons.dashboard_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Panelim",
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'takvimim',
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_month_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Takvimim",
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'mesajlarim',
              child: Row(
                children: [
                  const Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Mesajlarım",
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Panelim",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.white54,
                size: 24,
              ),
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: ColorConstants.primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
        actions: [
          ScaleButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CoachNotificationsScreen(),
                ),
              );
            },
            child: Stack(
              alignment: Alignment.topRight,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white12),
                  ),
                  child: const Icon(
                    Icons.notifications_none_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                // Küçük kırmızı bildirim noktası
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ScaleButton(
              onPressed: _showSettingsModal,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white12),
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 24),
              ),
            ),
          ),
        ],
      ),

      // --- GÖVDE ---
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(_uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: ColorConstants.primaryColor,
              ),
            );
          }

          if (snapshot.hasError ||
              !snapshot.hasData ||
              !snapshot.data!.exists) {
            return _buildErrorState();
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          // isApproved veya isVerified alanlarından birini kontrol et
          final bool isVerified =
              data['isApproved'] ?? data['isVerified'] ?? false;
          final String userName = data['name'] ?? 'Antrenör';
          final String? lessonSport = data['lessonSport'];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hoşgeldin Mesajı
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: Text(
                  "Merhaba, $userName 👋",
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Henüz onaylanmamışsa Banner'ı göster
              if (!isVerified) _buildVerificationBanner(),

              // ANA İÇERİK: Ders varsa vitrini göster, yoksa boş durumu göster
              Expanded(
                child: lessonSport == null
                    ? _buildEmptyState(isVerified)
                    : SingleChildScrollView(child: _buildProfilePreview(data)),
              ),
            ],
          );
        },
      ),

      // --- FAB: Sadece Onaylıysa Aktif ---
      floatingActionButton: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(_uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists)
            return const SizedBox.shrink();

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final bool isVerified =
              data['isApproved'] ?? data['isVerified'] ?? false;

          if (!isVerified) return const SizedBox.shrink();

          return ScaleButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "Ders ekleme ekranı yakında gelecek!",
                    style: GoogleFonts.poppins(),
                  ),
                  backgroundColor: ColorConstants.primaryColor,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: ColorConstants.primaryColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: ColorConstants.primaryColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    "Yeni Ders Ekle",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- KULLANICI GÖZÜNDEN PROFİL VİTRİNİ ---
  Widget _buildProfilePreview(Map<String, dynamic> data) {
    final String name = data['name'] ?? '';
    final String surname = data['surname'] ?? '';
    final String fullName = "$name $surname".trim().isEmpty
        ? "İsimsiz Antrenör"
        : "$name $surname";
    final String? profileImageUrl = data['profileImageUrl'];
    final String bio = data['bio'] ?? 'Henüz biyografi eklenmemiş.';

    final String lessonSport = data['lessonSport'] ?? 'Belirtilmemiş';
    final List<dynamic> days = data['availableDays'] ?? [];
    final List<dynamic> hours = data['availableHours'] ?? [];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.visibility_outlined,
                color: Colors.white54,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                "Kullanıcı Gözünden Profilin",
                style: GoogleFonts.poppins(
                  color: Colors.white54,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profil Üst Kısım (Fotoğraf ve İsim)
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white10,
                      backgroundImage: profileImageUrl != null
                          ? NetworkImage(profileImageUrl)
                          : null,
                      child: profileImageUrl == null
                          ? const Icon(
                              Icons.person,
                              color: Colors.white38,
                              size: 30,
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fullName,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Eğitmen",
                            style: GoogleFonts.poppins(
                              color: ColorConstants.primaryColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Biyografi
                Text(
                  bio,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(color: Colors.white10),
                const SizedBox(height: 16),

                // Ders Bilgileri
                Text(
                  "Aktif Dersin",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // Branş Chip'i
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: ColorConstants.primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    lessonSport,
                    style: GoogleFonts.poppins(
                      color: ColorConstants.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Günler ve Saatler
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      color: Colors.white54,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        days.isEmpty ? "Gün belirtilmedi" : days.join(', '),
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      color: Colors.white54,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        hours.isEmpty ? "Saat belirtilmedi" : hours.join(', '),
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- ONAY BEKLENİYOR BANNER ---
  Widget _buildVerificationBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.amber.withOpacity(0.12),
              Colors.orange.withOpacity(0.06),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.amber.withOpacity(0.25)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.hourglass_top_rounded,
                color: Colors.amber,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Profiliniz İnceleniyor",
                    style: GoogleFonts.poppins(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Güvenli bir topluluk oluşturmak için referanslarınızı inceliyoruz. Hesabınız onaylandıktan sonra profiliniz ve dersiniz sporculara görünür olacaktır.",
                    style: GoogleFonts.poppins(
                      color: Colors.white54,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- BOŞ DURUM (Empty State) ---
  Widget _buildEmptyState(bool isVerified) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isVerified ? Icons.school_outlined : Icons.lock_clock_outlined,
                size: 60,
                color: Colors.white.withOpacity(0.3),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isVerified ? "Henüz Ders Eklemediniz" : "Onay Bekleniyor",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isVerified
                  ? "İlk dersinizi ekleyin ve öğrencilerle buluşmaya başlayın! Sağ alttaki butona dokunarak başlayabilirsiniz."
                  : "Profiliniz onaylandıktan sonra burada ders ve paketlerinizi yönetebileceksiniz.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white54,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- HATA DURUMU ---
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 60,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              "Bir hata oluştu",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Verileriniz yüklenirken bir sorun oluştu. Lütfen tekrar deneyin.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  // --- MENÜ ÖĞESİ ---
  Widget _buildMenuItem(
    IconData icon,
    String text,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDestructive
              ? Colors.redAccent.withOpacity(0.1)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: isDestructive ? Colors.redAccent : Colors.white,
          size: 20,
        ),
      ),
      title: Text(
        text,
        style: GoogleFonts.poppins(
          color: isDestructive ? Colors.redAccent : Colors.white,
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios_rounded,
        color: Colors.white12,
        size: 14,
      ),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }
}
