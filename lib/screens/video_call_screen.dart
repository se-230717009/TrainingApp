import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

import '../core/constants/color_constants.dart';
import '../widgets/scale_button.dart';

// --- BURAYA KENDİ APP ID'Nİ YAPIŞTIR ---
const String appId = "c53fe7f02cf645f5a2fe398231f2af5e";
// Test modunda olduğumuz için token boş kalacak
const String token = "";

class VideoCallScreen extends StatefulWidget {
  final String roomName;
  final String remoteUserName;

  const VideoCallScreen({
    super.key,
    required this.roomName,
    required this.remoteUserName,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  bool _isMicMuted = false;
  bool _isCameraOff = false;

  int _secondsElapsed = 0;
  Timer? _timer;

  // --- AGORA DEĞİŞKENLERİ ---
  int? _remoteUid;
  bool _localUserJoined = false;
  late RtcEngine _engine;
  late String _channelName;

  @override
  void initState() {
    super.initState();
    // Agora kanal isimlerinde boşluk ve Türkçe karakter pek sevilmez, o yüzden temizliyoruz
    _channelName = widget.roomName
        .replaceAll(' ', '_')
        .replaceAll('ı', 'i')
        .replaceAll('ş', 's')
        .replaceAll('ç', 'c')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ö', 'o');

    // Motoru başlat
    initAgora();
  }

  Future<void> initAgora() async {
    // 1. İzinleri İste
    await [Permission.microphone, Permission.camera].request();

    // 2. Motoru Oluştur
    _engine = createAgoraRtcEngine();
    await _engine.initialize(
      const RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );

    await _engine.enableVideo();

    // 3. Olay Dinleyicileri (Event Handlers)
    _engine.registerEventHandler(
      RtcEngineEventHandler(
        // Biz odaya başarıyla girdiğimizde
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint("Odya girildi: ${connection.channelId}");
          setState(() {
            _localUserJoined = true;
          });
        },
        // Karşı taraf (Öğrenci/Hoca) odaya girdiğinde
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint("Karşı taraf geldi: $remoteUid");
          setState(() {
            _remoteUid = remoteUid; // Karşı tarafın ID'sini kaydet
          });
          _startTimer(); // DERS BAŞLADI! KRONOMETREYİ ÇALIŞTIR!
        },
        // Karşı taraf odadan çıktığında veya bağlantısı koptuğunda
        onUserOffline:
            (
              RtcConnection connection,
              int remoteUid,
              UserOfflineReasonType reason,
            ) {
              debugPrint("Karşı taraf çıktı");
              setState(() {
                _remoteUid = null;
              });
              _timer?.cancel(); // Süreyi durdur
            },
        // Karşı taraf kendi kamerasını kapatır/açarsa
        onRemoteVideoStateChanged: (connection, remoteUid, state, reason, elapsed) {
          // İleride buraya "Karşı taraf kamerasını kapattı" ui güncellemesi eklenebilir
        },
      ),
    );

    // 4. Odaya Gir
    await _engine.startPreview();
    await _engine.joinChannel(
      token: token,
      channelId: _channelName,
      uid: 0, // 0 verirsek Agora bize rastgele bir ID atar
      options: const ChannelMediaOptions(),
    );
  }

  void _startTimer() {
    _timer?.cancel(); // Varsa eskisini iptal et
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsElapsed++;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _disposeAgora();
    super.dispose();
  }

  Future<void> _disposeAgora() async {
    await _engine.leaveChannel();
    await _engine.release();
  }

  String get _formattedTime {
    int minutes = _secondsElapsed ~/ 60;
    int seconds = _secondsElapsed % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _endCall() {
    Navigator.pop(
      context,
      true,
    ); // true = Ders bitti sinyali (Değerlendirme ekranı için)
  }

  // Kamera açma/kapatma fonksiyonu
  void _toggleCamera() {
    setState(() {
      _isCameraOff = !_isCameraOff;
    });
    _engine.muteLocalVideoStream(_isCameraOff);
  }

  // Mikrofon açma/kapatma fonksiyonu
  void _toggleMic() {
    setState(() {
      _isMicMuted = !_isMicMuted;
    });
    _engine.muteLocalAudioStream(_isMicMuted);
  }

  @override
  Widget build(BuildContext context) {
    bool isRemoteUserJoined = _remoteUid != null;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ----------------------------------------------------------------
          // 1. ARKA PLAN: EĞER KARŞISI YOKSA SENİN KAMERAN, VARSA ONUN KAMERASI
          // ----------------------------------------------------------------
          Container(
            width: double.infinity,
            height: double.infinity,
            color: const Color(0xFF121212),
            child: isRemoteUserJoined
                ? _buildRemoteVideo() // Karşı taraf geldiğinde onu tam ekran yap
                : _buildLocalVideo(
                    isFullScreen: true,
                  ), // Sen tek başınayken kendini tam ekran yap
          ),

          // ----------------------------------------------------------------
          // 2. BEKLEME EKRANI YAZILARI (Sadece tek başınayken)
          // ----------------------------------------------------------------
          if (!isRemoteUserJoined)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(
                  0.6,
                ), // Kameranın üstüne hafif siyah perde
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      color: ColorConstants.primaryColor,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "Odada teksiniz",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${widget.remoteUserName} bekleniyor...",
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ----------------------------------------------------------------
          // 3. KÜÇÜK EKRAN (PiP): SADECE KARŞI TARAF GELDİĞİNDE GÖZÜKÜR
          // ----------------------------------------------------------------
          if (isRemoteUserJoined)
            Positioned(
              top: 120,
              right: 20,
              child: Container(
                width: 110,
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: _buildLocalVideo(isFullScreen: false),
                ),
              ),
            ),

          // ----------------------------------------------------------------
          // 4. ÜST BİLGİ BARI (Oda Adı ve Süre)
          // ----------------------------------------------------------------
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      ScaleButton(
                        onPressed: _endCall,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.roomName,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            // Süre sadece görüşme başladığında gözükür
                            if (isRemoteUserJoined)
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Colors.redAccent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _formattedTime,
                                    style: GoogleFonts.poppins(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              )
                            else
                              Text(
                                "Bekleniyor...",
                                style: GoogleFonts.poppins(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.lock_outline_rounded,
                        color: ColorConstants.primaryColor,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ----------------------------------------------------------------
          // 5. ALT KONTROL BARI (Mikrofon, Kapatma, Kamera)
          // ----------------------------------------------------------------
          Positioned(
            bottom: 40,
            left: 30,
            right: 30,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 24,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildControlButton(
                        icon: _isMicMuted
                            ? Icons.mic_off_rounded
                            : Icons.mic_rounded,
                        isActive: !_isMicMuted,
                        onTap: _toggleMic,
                      ),
                      ScaleButton(
                        onPressed: _endCall,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.redAccent.withOpacity(0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.call_end_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                      _buildControlButton(
                        icon: _isCameraOff
                            ? Icons.videocam_off_rounded
                            : Icons.videocam_rounded,
                        isActive: !_isCameraOff,
                        onTap: _toggleCamera,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- GERÇEK KAMERA GÖRÜNTÜLERİ ---

  // Benim Kameram
  Widget _buildLocalVideo({required bool isFullScreen}) {
    if (_isCameraOff) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam_off_rounded,
              color: Colors.white24,
              size: isFullScreen ? 60 : 30,
            ),
            if (isFullScreen) ...[
              const SizedBox(height: 12),
              Text(
                "Kameranız Kapalı",
                style: GoogleFonts.poppins(color: Colors.white54),
              ),
            ],
          ],
        ),
      );
    }

    // Motor başladıysa gerçek kamerayı göster
    if (_localUserJoined) {
      return AgoraVideoView(
        controller: VideoViewController(
          rtcEngine: _engine,
          canvas: const VideoCanvas(
            uid: 0,
          ), // 0 her zaman yerel (kendi) kamerandır
        ),
      );
    } else {
      return const Center(
        child: CircularProgressIndicator(color: ColorConstants.primaryColor),
      );
    }
  }

  // Karşı Tarafın Kamerası
  Widget _buildRemoteVideo() {
    if (_remoteUid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: RtcConnection(channelId: _channelName),
        ),
      );
    } else {
      return const Center(child: Text("Bekleniyor..."));
    }
  }

  Widget _buildControlButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return ScaleButton(
      onPressed: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.white.withOpacity(0.1)
              : Colors.white.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.white : Colors.black,
          size: 24,
        ),
      ),
    );
  }
}
