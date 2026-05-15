/// lib/screens/coach_notification_screen.dart
///
/// Displays pending lesson requests sent to the currently signed-in coach.
///
/// The coach can approve or reject each request from this screen.
/// Approving a request automatically sends a notification to the athlete via
/// [INotificationService] — the screen itself never writes to Firestore
/// directly (Single Responsibility Principle).

library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../core/constants/color_constants.dart';
import '../services/lesson_service.dart';
import '../services/notification_service.dart';
import '../services/interfaces/i_lesson_service.dart';
import '../services/interfaces/i_notification_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/scale_button.dart';
import 'chat_screen.dart'; // YENİ: Mesajlaşma ekranı için

/// Coach-facing screen that lists unanswered lesson booking requests.
class CoachNotificationsScreen extends StatefulWidget {
  /// Injectable lesson service — defaults to [LessonService].
  final ILessonService lessonService;

  /// Injectable notification service — defaults to [NotificationService].
  final INotificationService notificationService;

  const CoachNotificationsScreen({
    super.key,
    ILessonService? lessonService,
    INotificationService? notificationService,
  }) : lessonService = lessonService ?? const _DefaultLesson(),
       notificationService =
           notificationService ?? const _DefaultNotification();

  @override
  State<CoachNotificationsScreen> createState() =>
      _CoachNotificationsScreenState();
}

class _DefaultLesson implements ILessonService {
  const _DefaultLesson();
  @override
  dynamic noSuchMethod(Invocation i) => LessonService();
}

class _DefaultNotification implements INotificationService {
  const _DefaultNotification();
  @override
  dynamic noSuchMethod(Invocation i) => NotificationService();
}

class _CoachNotificationsScreenState extends State<CoachNotificationsScreen> {
  late final ILessonService _lessonService;
  late final INotificationService _notificationService;
  late final String _currentUserId;

  @override
  void initState() {
    super.initState();
    _lessonService = widget.lessonService is _DefaultLesson
        ? LessonService()
        : widget.lessonService;
    _notificationService = widget.notificationService is _DefaultNotification
        ? NotificationService()
        : widget.notificationService;
    _currentUserId = FirebaseAuth.instance.currentUser!.uid;
  }

  /// Updates the lesson [status] (approved / rejected) and, if approved,
  /// sends a notification to the athlete.
  Future<void> _updateLessonStatus(
    String docId,
    String status,
    Map<String, dynamic> lessonData,
  ) async {
    // 1. Ana durumu güncelle
    await _lessonService.updateLessonStatus(docId, status);

    // 2. Eğer onaylandıysa ve bu toplu bir istekse (Unified Request),
    // Takvimin (CoachCalendarScreen) bu saatleri meşgul olarak okuyabilmesi için
    // days ve hours dizilerini yama (patch) yapıyoruz.
    if (status == 'approved' && lessonData['isUnifiedRequest'] == true) {
      List<dynamic> slots = lessonData['requestedSlots'] ?? [];
      Set<String> daysSet = {};
      Set<String> hoursSet = {};

      for (var s in slots) {
        if (s['dayName'] != null) daysSet.add(s['dayName']);
        if (s['hour'] != null) hoursSet.add(s['hour']);
      }

      Map<String, dynamic> calendarPatch = {
        'days': daysSet.toList(),
        'hours': hoursSet.toList(),
      };

      if (slots.isNotEmpty && slots.first['date'] != null) {
        calendarPatch['date'] = slots.first['date'];
      }

      await FirebaseFirestore.instance
          .collection('lessons')
          .doc(docId)
          .update(calendarPatch);
    }

    // 3. Öğrenciye bildirim gönder
    if (status == 'approved') {
      await _notificationService.sendLessonApprovedNotification(
        athleteId: lessonData['athleteId'] as String,
        coachName: lessonData['coachName'] as String? ?? 'Antrenör',
        sport: lessonData['sport'] as String? ?? '',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Gelen Talepler",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _lessonService.getPendingLessonsForCoach(_currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: ColorConstants.primaryColor,
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final lessonData = doc.data() as Map<String, dynamic>;
              return _buildUnifiedRequestCard(doc.id, lessonData);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
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
            "Yeni ders talebiniz yok.",
            style: GoogleFonts.poppins(color: Colors.white54, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildUnifiedRequestCard(
    String docId,
    Map<String, dynamic> lessonData,
  ) {
    final bool isUnified = lessonData['isUnifiedRequest'] == true;
    final List<dynamic> requestedSlots = lessonData['requestedSlots'] ?? [];

    // Ders tipini belirle (Toplu mu, Tekrarlı mı, Tekli mi?)
    bool isRecurring = false;
    if (isUnified && requestedSlots.isNotEmpty) {
      isRecurring = requestedSlots.any(
        (slot) => slot['isRecurringRequest'] == true,
      );
    }

    String requestTypeTitle = "Yeni Ders Talebi";
    if (isRecurring) {
      requestTypeTitle = "🔄 Tekrarlı Ders Talebi";
    } else if (requestedSlots.length > 1) {
      requestTypeTitle = "📅 Toplu Ders Talebi (${requestedSlots.length} Gün)";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ColorConstants.primaryColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ÜST KISIM: Öğrenci Bilgisi ve Mesaj Butonu
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white10,
                backgroundImage: lessonData['athleteImage'] != null
                    ? CachedNetworkImageProvider(lessonData['athleteImage'])
                    : null,
                child: lessonData['athleteImage'] == null
                    ? const Icon(Icons.person, color: Colors.white38)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lessonData['athleteName'] as String? ?? 'İsimsiz Öğrenci',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      requestTypeTitle,
                      style: GoogleFonts.poppins(
                        color: ColorConstants.primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // Mesaj Gönder Butonu
              ScaleButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        receiverId: lessonData['athleteId'],
                        receiverName: lessonData['athleteName'] ?? 'Öğrenci',
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 12),

          // ORTA KISIM: Ders Detayları
          Row(
            children: [
              const Icon(
                Icons.sports_gymnastics,
                color: Colors.white54,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                "${lessonData['sport']} • ${lessonData['lessonType'] ?? 'Online'}",
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                "${lessonData['price']} ₺",
                style: GoogleFonts.poppins(
                  color: Colors.greenAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // TAKVİM SLOTLARI (Birleşik Talep Listesi)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: isUnified && requestedSlots.isNotEmpty
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: requestedSlots.map((slot) {
                      DateTime? parsedDate;
                      try {
                        parsedDate = DateFormat(
                          'yyyy-MM-dd',
                        ).parse(slot['date']);
                      } catch (_) {}

                      String formattedDate = parsedDate != null
                          ? DateFormat('dd MMM', 'tr_TR').format(parsedDate)
                          : slot['date'];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              color: ColorConstants.primaryColor,
                              size: 14,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "$formattedDate, ${slot['dayName']}",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white10,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                slot['hour'] ?? '',
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  )
                : // Geriye dönük uyumluluk (Eski talepler)
                  Row(
                    children: [
                      const Icon(Icons.event, color: Colors.white54, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          "${(lessonData['days'] as List?)?.first ?? '-'} • ${(lessonData['hours'] as List?)?.first ?? '-'}",
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),

          const SizedBox(height: 16),

          // ALT KISIM: Aksiyon Butonları (Reddet / Onayla)
          Row(
            children: [
              Expanded(
                child: ScaleButton(
                  onPressed: () =>
                      _updateLessonStatus(docId, 'rejected', lessonData),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.redAccent.withOpacity(0.3),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        "Tümünü Reddet",
                        style: GoogleFonts.poppins(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ScaleButton(
                  onPressed: () =>
                      _updateLessonStatus(docId, 'approved', lessonData),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: ColorConstants.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        "Tümünü Onayla",
                        style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
