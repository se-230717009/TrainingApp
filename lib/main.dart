import 'package:flutter/material.dart';

void main() {
  runApp(const CoachAppPrototip());
}

class CoachAppPrototip extends StatelessWidget {
  const CoachAppPrototip({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Coach Prototip',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[100],
        ),
      ),
      home: const WelcomeScreen(),
    );
  }
}

// 1. KARŞILAMA EKRANI
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple, Colors.indigoAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sports_gymnastics, size: 100, color: Colors.white),
            const SizedBox(height: 20),
            const Text(
              "CoachApp",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Text(
              "Antrenörünü Bul, Harekete Geç",
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 50),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.deepPurple,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () {
                // Giriş yapınca direkt ana sayfaya atar
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                );
              },
              child: const Text(
                "Giriş Yap",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 15),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () {}, // Kayıt ol butonu şimdilik boş
              child: const Text("Kayıt Ol"),
            ),
          ],
        ),
      ),
    );
  }
}

// 2. ANA EKRAN (SEÇİM)
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ne yapmak istiyorsun?")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildOptionCard(
              context,
              title: "Online Ders Almak İstiyorum",
              subtitle: "Görüntülü görüşme ile evinden spor yap.",
              icon: Icons.video_call,
              color: Colors.orange.shade100,
              isOnline: true,
            ),
            const SizedBox(height: 20),
            _buildOptionCard(
              context,
              title: "Yüz Yüze Ders Almak İstiyorum",
              subtitle: "Sana en yakın antrenörle buluş.",
              icon: Icons.people_alt,
              color: Colors.blue.shade100,
              isOnline: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isOnline,
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FilterScreen(isOnline: isOnline),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 40, color: Colors.black54),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(subtitle, style: TextStyle(color: Colors.grey[700])),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}

// 3. FİLTRE EKRANI (ARMUT TARZI)
class FilterScreen extends StatefulWidget {
  final bool isOnline;
  const FilterScreen({super.key, required this.isOnline});

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  // Seçim değişkenleri
  String? selectedSport;
  String? selectedAge;
  String? selectedGroup;
  String? selectedGender;
  String? selectedLocation;
  String? selectedPrice;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isOnline ? "Online Ders Detayları" : "Yüz Yüze Ders Detayları",
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Hocanı bulmamız için birkaç detay ver:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // ORTAK SORULAR
            _buildDropdown("Hangi spor dalı?", [
              "Fitness",
              "Pilates",
              "Yoga",
              "Kick Box",
              "Yüzme",
            ], (val) => selectedSport = val),
            _buildDropdown("Yaş grubu nedir?", [
              "Çocuk (7-14)",
              "Genç (15-24)",
              "Yetişkin (25+)",
            ], (val) => selectedAge = val),
            _buildDropdown("Kaç kişi katılacak?", [
              "Birebir (Sadece Ben)",
              "2 Kişi",
              "3-5 Kişi Grup",
            ], (val) => selectedGroup = val),
            _buildDropdown("Tercih edilen hoca cinsiyeti?", [
              "Fark Etmez",
              "Kadın",
              "Erkek",
            ], (val) => selectedGender = val),

            // SADECE YÜZ YÜZE İSE GÖZÜKECEK SORULAR
            if (!widget.isOnline) ...[
              const Divider(height: 40),
              const Text(
                "Konum ve Bütçe",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _buildDropdown("Hangi Bölge?", [
                "İstanbul - Kadıköy",
                "İstanbul - Beşiktaş",
                "Ankara - Çankaya",
                "İzmir - Bornova",
              ], (val) => selectedLocation = val),
              _buildDropdown("Ders başı bütçe aralığı?", [
                "500 - 1000 TL",
                "1000 - 2000 TL",
                "2000 TL +",
              ], (val) => selectedPrice = val),
            ],

            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 55),
              ),
              onPressed: () {
                if (widget.isOnline) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TrainerListScreen(),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MapPlaceholderScreen(),
                    ),
                  );
                }
              },
              child: const Text(
                "Hocaları Listele",
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String hint,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(labelText: hint),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

// 4. SONUÇ EKRANI A: HARİTA SİNYALİ (YÜZ YÜZE İÇİN)
class MapPlaceholderScreen extends StatelessWidget {
  const MapPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Yakındaki Hocalar")),
      body: Stack(
        children: [
          // Gri Arka Plan (Harita gibi davransın diye)
          Container(
            color: Colors.grey[300],
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_on,
                    size: 80,
                    color: Colors.red.withOpacity(0.7),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Harita Entegrasyonu",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text(
                      "Yatırımcıya Not: Burada Google Maps API kullanılacak. Hocaların konumları pin olarak gözükecek.",
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Alt kısımda örnek bir hoca kartı (Tinder/Armut gibi haritanın üstünde durur)
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Card(
              elevation: 10,
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundImage: NetworkImage(
                    'https://i.pravatar.cc/150?img=12',
                  ),
                ),
                title: const Text("Mert Yılmaz"),
                subtitle: const Text("Fitness Antrenörü • 500m Uzakta"),
                trailing: ElevatedButton(
                  onPressed: () {},
                  child: const Text("Seç"),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 4. SONUÇ EKRANI B: DÜMENDEN LİSTE (ONLINE İÇİN)
class TrainerListScreen extends StatelessWidget {
  const TrainerListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dümenden veri listesi
    final List<Map<String, String>> trainers = [
      {
        "name": "Ayşe Demir",
        "branch": "Pilates Eğitmeni",
        "img": "https://i.pravatar.cc/150?img=5",
        "price": "750 TL",
      },
      {
        "name": "Burak Can",
        "branch": "Kick Box Hocası",
        "img": "https://i.pravatar.cc/150?img=11",
        "price": "900 TL",
      },
      {
        "name": "Elif Şahin",
        "branch": "Yoga Eğitmeni",
        "img": "https://i.pravatar.cc/150?img=9",
        "price": "600 TL",
      },
      {
        "name": "Caner Erkin",
        "branch": "Fitness Koçu",
        "img": "https://i.pravatar.cc/150?img=3",
        "price": "850 TL",
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Online Hocalar")),
      body: ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: trainers.length,
        itemBuilder: (context, index) {
          final trainer = trainers[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 15),
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Row(
                children: [
                  // Profil Resmi
                  CircleAvatar(
                    radius: 35,
                    backgroundImage: NetworkImage(trainer['img']!),
                  ),
                  const SizedBox(width: 15),
                  // Bilgiler
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trainer['name']!,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          trainer['branch']!,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 18,
                            ),
                            const Text(" 4.9 (120 Ders)"),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Fiyat ve Buton
                  Column(
                    children: [
                      Text(
                        trainer['price']!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(height: 5),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text("Ders Al"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
