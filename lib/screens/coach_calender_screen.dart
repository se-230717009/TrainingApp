import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart'; // Geri geldi :)
import 'package:intl/date_symbol_data_local.dart'; // Türkçe formatı yüklemek için gerekli
import '../core/constants/color_constants.dart';

class CoachCalendarScreen extends StatefulWidget {
  const CoachCalendarScreen({super.key});

  @override
  State<CoachCalendarScreen> createState() => _CoachCalendarScreenState();
}

class _CoachCalendarScreenState extends State<CoachCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // SAHTE VERİLER (Test Amaçlı)
  final Map<DateTime, List<Map<String, dynamic>>> _dummyLessons = {
    DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day): [
      {
        'athleteName': 'Ahmet Yılmaz',
        'time': '14:00 - 15:00',
        'sport': 'Fitness',
        'gender': 'Erkek',
      },
    ],
    DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    ).add(const Duration(days: 1)): [
      {
        'athleteName': 'Ayşe Demir',
        'time': '10:00 - 11:00',
        'sport': 'Pilates',
        'gender': 'Kadın',
      },
    ],
  };

  @override
  void initState() {
    super.initState();
    // Türkçe tarih formatını başlatıyoruz
    initializeDateFormatting('tr_TR', null);
  }

  List<Map<String, dynamic>> _getLessonsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _dummyLessons[normalizedDay] ?? [];
  }

  // --- ALTTAN AÇILAN ÖĞRENCİ DETAY PANELİ ---
  void _showLessonDetails(Map<String, dynamic> lesson) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "Ders Detayı",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                // Öğrenci Kartı
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.white10,
                        child: Icon(
                          lesson['gender'] == 'Kadın'
                              ? Icons.face_3
                              : Icons.face,
                          color: Colors.white54,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lesson['athleteName'],
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "Öğrenci",
                              style: GoogleFonts.poppins(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: ColorConstants.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        Icons.access_time_rounded,
                        "Saat",
                        lesson['time'],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInfoCard(
                        Icons.sports_gymnastics_rounded,
                        "Branş",
                        lesson['sport'],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: ColorConstants.primaryColor, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
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
          "Takvimim",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // TAKVİM KISMI
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
            ),
            child: TableCalendar(
              locale: 'tr_TR', // İŞTE BURASI TÜRKÇE YAPIYOR 🇹🇷
              firstDay: DateTime.utc(2023, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              eventLoader: _getLessonsForDay,
              startingDayOfWeek:
                  StartingDayOfWeek.monday, // Haftayı Pazartesi başlat
              // Takvim Stili
              calendarStyle: CalendarStyle(
                defaultTextStyle: GoogleFonts.poppins(color: Colors.white),
                weekendTextStyle: GoogleFonts.poppins(
                  color: Colors.redAccent.withOpacity(0.8),
                ), // Hafta sonu hafif kırmızı
                outsideTextStyle: GoogleFonts.poppins(color: Colors.white24),
                todayDecoration: BoxDecoration(
                  color: Colors.white10,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: const BoxDecoration(
                  color: ColorConstants.primaryColor,
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: GoogleFonts.poppins(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
                markerDecoration: const BoxDecoration(
                  color: ColorConstants.primaryColor,
                  shape: BoxShape.circle,
                ),
              ),

              // Başlık Stili (Şubat 2026)
              headerStyle: HeaderStyle(
                titleCentered: true,
                formatButtonVisible: false,
                titleTextStyle: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                leftChevronIcon: const Icon(
                  Icons.chevron_left,
                  color: Colors.white,
                ),
                rightChevronIcon: const Icon(
                  Icons.chevron_right,
                  color: Colors.white,
                ),
              ),

              // Gün İsimleri Stili (Pzt, Sal, Çar...)
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: GoogleFonts.poppins(color: Colors.white70),
                weekendStyle: GoogleFonts.poppins(
                  color: Colors.redAccent.withOpacity(0.5),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // SEÇİLEN TARİH BAŞLIĞI
          if (_selectedDay != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.date_range,
                    color: ColorConstants.primaryColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat(
                      'd MMMM yyyy, EEEE',
                      'tr_TR',
                    ).format(_selectedDay!), // "24 Şubat 2026, Salı" gibi yazar
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

          // SEÇİLEN GÜNÜN DERSLERİ
          Expanded(
            child: _selectedDay == null
                ? Center(
                    child: Text(
                      "Dersleri görmek için bir gün seçin.",
                      style: GoogleFonts.poppins(color: Colors.white54),
                    ),
                  )
                : _buildLessonListForDay(_selectedDay!),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonListForDay(DateTime day) {
    final lessons = _getLessonsForDay(day);

    if (lessons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy_rounded, color: Colors.white24, size: 50),
            const SizedBox(height: 16),
            Text(
              "Bu tarihte dersiniz bulunmuyor.",
              style: GoogleFonts.poppins(color: Colors.white54),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: lessons.length,
      itemBuilder: (context, index) {
        final lesson = lessons[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            onTap: () => _showLessonDetails(lesson),
            tileColor: Colors.white.withOpacity(0.05),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: ColorConstants.primaryColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.fitness_center_rounded,
                color: ColorConstants.primaryColor,
                size: 20,
              ),
            ),
            title: Text(
              lesson['athleteName'],
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              "${lesson['time']} • ${lesson['sport']}",
              style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
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
  }
}
