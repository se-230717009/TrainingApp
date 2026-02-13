import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/color_constants.dart';
import '../services/auth_service.dart';
import '../widgets/scale_button.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();

  // Şimdilik boş bir liste (Gerçek veritabanı bağlandığında burası dolacak)
  final List<dynamic> _coaches = [];

  // --- ÇIKIŞ YAP FONKSİYONU ---
  void _signOut() async {
    await _authService.signOut();
    if (mounted) {
      // Tüm geçmişi silip Login ekranına atar
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  // --- AYARLAR MENÜSÜ (ALTTAN AÇILAN) ---
  void _showSettingsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E), // Koyu gri menü
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min, // İçerik kadar yer kapla
              children: [
                // Tutamaç Çizgisi (Görsel detay)
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),

                // Menü Başlığı
                Text(
                  "Hesap & Ayarlar",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                // Menü Öğeleri
                _buildMenuItem(Icons.person_outline, "Profil Düzenle", () {}),
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

                const Divider(color: Colors.white10, height: 30), // Çizgi
                // Çıkış Yap Butonu (Kırmızı)
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
      backgroundColor: Colors.black, // Ana zemin siyah
      // --- ÜST BAR (APP BAR) ---
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        automaticallyImplyLeading: false, // Geri butonunu gizle
        title: Row(
          children: [
            Text(
              "Antrenörler",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            // Küçük bir nokta (Online hissi verir)
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
        actions: [
          // Sağ Üstteki Profil/Ayarlar Butonu
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
      body: _coaches.isEmpty
          ? _buildEmptyState() // Hoca yoksa bunu göster
          : _buildCoachList(), // Hoca varsa listeyi göster (Şu an çalışmayacak)
    );
  }

  // --- BOŞ DURUM TASARIMI (PROFESYONEL GÖRÜNÜM) ---
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // İkon Kutusu
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 60,
                color: Colors.white.withOpacity(0.3),
              ),
            ),
            const SizedBox(height: 24),

            // Başlık
            Text(
              "Henüz Eğitmen Yok",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            // Açıklama
            Text(
              "Şu an kriterlerine uygun aktif bir eğitmen bulunmuyor. Yeni eğitmenler katıldığında burada listelenecekler.",
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

  // --- LİSTE TASARIMI (İLERİDE KULLANACAĞIZ) ---
  Widget _buildCoachList() {
    return ListView.builder(
      itemCount: _coaches.length,
      itemBuilder: (context, index) {
        return const ListTile(title: Text("Hoca"));
      },
    );
  }

  // --- MENÜ ÖĞESİ TASARIMI (YARDIMCI) ---
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
        Navigator.pop(context); // Menüyü kapat
        onTap(); // İşlemi yap
      },
    );
  }
}
