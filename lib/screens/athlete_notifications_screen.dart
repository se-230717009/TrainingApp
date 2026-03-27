import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants/color_constants.dart';
import '../widgets/gradient_background.dart';

class AthleteNotificationsScreen extends StatefulWidget {
  const AthleteNotificationsScreen({super.key});

  @override
  State<AthleteNotificationsScreen> createState() =>
      _AthleteNotificationsScreenState();
}

class _AthleteNotificationsScreenState
    extends State<AthleteNotificationsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _markAsRead(String docId) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .collection('notifications')
        .doc(docId)
        .update({'isRead': true});
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            "Bildirimler",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(_auth.currentUser!.uid)
              .collection('notifications')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
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
                      Icons.notifications_off_outlined,
                      size: 60,
                      color: Colors.white.withOpacity(0.2),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Henüz bir bildiriminiz yok.",
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
              padding: const EdgeInsets.all(16),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                var notifDoc = snapshot.data!.docs[index];
                var notif = notifDoc.data() as Map<String, dynamic>;
                bool isRead = notif['isRead'] ?? false;

                return GestureDetector(
                  onTap: () {
                    if (!isRead) _markAsRead(notifDoc.id);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isRead
                          ? Colors.white.withOpacity(0.05)
                          : ColorConstants.primaryColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isRead
                            ? Colors.white10
                            : ColorConstants.primaryColor.withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isRead
                                ? Colors.white10
                                : ColorConstants.primaryColor.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            notif['type'] == 'lesson_approved'
                                ? Icons.check_circle_outline_rounded
                                : Icons.notifications_active_rounded,
                            color: isRead
                                ? Colors.white54
                                : ColorConstants.primaryColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notif['title'] ?? 'Bildirim',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: isRead
                                      ? FontWeight.w500
                                      : FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                notif['body'] ?? '',
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isRead)
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: ColorConstants.primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
