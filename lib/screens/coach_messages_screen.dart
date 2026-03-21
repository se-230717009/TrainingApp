import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants/color_constants.dart';
import '../widgets/gradient_background.dart';
import 'chat_screen.dart';

class CoachMessagesScreen extends StatefulWidget {
  const CoachMessagesScreen({super.key});

  @override
  State<CoachMessagesScreen> createState() => _CoachMessagesScreenState();
}

class _CoachMessagesScreenState extends State<CoachMessagesScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final String currentUserId = _auth.currentUser!.uid;

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true, // PANELİM İLE AYNI YAPI
        appBar: AppBar(
          backgroundColor: Colors.black.withOpacity(0.6), // ŞEFFAF SİYAH
          elevation: 0,
          automaticallyImplyLeading: false, // GERİ TUŞU KALDIRILDI
          title: Text(
            "Mesajlarım",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 24, // Uyumlu başlık boyutu
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('chat_rooms')
              .where('participants', arrayContains: currentUserId)
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  "Hata: ${snapshot.error}",
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: ColorConstants.primaryColor,
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 60,
                      color: Colors.white.withOpacity(0.2),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Henüz bir mesajın yok.",
                      style: GoogleFonts.poppins(
                        color: Colors.white54,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              // APPBAR ALTINDA EZİLMEMESİ İÇİN DİNAMİK BOŞLUK
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + kToolbarHeight + 16,
                left: 16,
                right: 16,
                bottom: 16,
              ),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                var roomData =
                    snapshot.data!.docs[index].data() as Map<String, dynamic>;
                List<dynamic> participants = roomData['participants'] ?? [];
                if (participants.isEmpty ||
                    !participants.contains(currentUserId))
                  return const SizedBox();

                String otherUserId = participants.firstWhere(
                  (id) => id != currentUserId,
                  orElse: () => '',
                );
                if (otherUserId.isEmpty) return const SizedBox();

                String lastMessage =
                    roomData['lastMessage'] ?? 'Mesaj gönderildi';

                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(otherUserId)
                      .get(),
                  builder: (context, userSnapshot) {
                    if (!userSnapshot.hasData) return const SizedBox();
                    var userData =
                        userSnapshot.data!.data() as Map<String, dynamic>?;
                    if (userData == null) return const SizedBox();

                    String fullName =
                        "${userData['name'] ?? ''} ${userData['surname'] ?? ''}"
                            .trim();
                    String? profileImageUrl = userData['profileImageUrl'];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                receiverId: otherUserId,
                                receiverName: fullName.isEmpty
                                    ? "Öğrenci"
                                    : fullName,
                              ),
                            ),
                          );
                        },
                        tileColor: Colors.white.withOpacity(0.05),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.white10,
                          backgroundImage: profileImageUrl != null
                              ? NetworkImage(profileImageUrl)
                              : null,
                          child: profileImageUrl == null
                              ? const Icon(Icons.person, color: Colors.white38)
                              : null,
                        ),
                        title: Text(
                          fullName.isEmpty ? "İsimsiz Kullanıcı" : fullName,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          lastMessage,
                          style: GoogleFonts.poppins(
                            color: Colors.white54,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white24,
                          size: 14,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
