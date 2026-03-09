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

  // --- YENİ: ARAYÜZ (UI) VE SÜRÜKLEME DEĞİŞKENLERİ ---
  bool _showControls = true; // Ekrana dokununca menüleri gizlemek için
  double? _pipTop; // Küçük ekranın Y ekseni
  double? _pipLeft; // Küçük ekranın X ekseni

  @override
  void initState() {
    super.initState();
    _channelName = widget.roomName
        .replaceAll(' ', '_')
        .replaceAll('ı', 'i')
        .replaceAll('ş', 's')
        .replaceAll('ç', 'c')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ö', 'o');

    initAgora();
  }

  Future<void> initAgora() async {
    await [Permission.microphone, Permission.camera].request();

    _engine = createAgoraRtcEngine();
    await _engine.initialize(
      const RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );

    await _engine.enableVideo();

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint("Odya girildi: ${connection.channelId}");
          setState(() {
            _localUserJoined = true;
          });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint("Karşı taraf geldi: $remoteUid");
          setState(() {
            _remoteUid = remoteUid;
          });
          _startTimer();
        },
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
              _timer?.cancel();
            },
      ),
    );

    await _engine.startPreview();
    await _engine.joinChannel(
      token: token,
      channelId: _channelName,
      uid: 0,
      options: const ChannelMediaOptions(),
    );
  }

  void _startTimer() {
    _timer?.cancel();
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
    Navigator.pop(context, true);
  }

  void _toggleCamera() {
    setState(() {
      _isCameraOff = !_isCameraOff;
    });
    _engine.muteLocalVideoStream(_isCameraOff);
  }

  void _toggleMic() {
    setState(() {
      _isMicMuted = !_isMicMuted;
    });
    _engine.muteLocalAudioStream(_isMicMuted);
  }

  @override
  Widget build(BuildContext context) {
    bool isRemoteUserJoined = _remoteUid != null;
    final size = MediaQuery.of(context).size;
    final safePadding = MediaQuery.of(context).padding;

    // Küçük ekranın başlangıç pozisyonunu belirliyoruz (İlk açılışta sağ üstte)
    if (_pipTop == null || _pipLeft == null) {
      _pipTop = safePadding.top + 70;
      _pipLeft = size.width - 110 - 20; // 110 genişlik, 20 boşluk
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ----------------------------------------------------------------
          // 1. ARKA PLAN: TIKLANDIĞINDA UI'I GİZLER/GÖSTERİR
          // ----------------------------------------------------------------
          GestureDetector(
            onTap: () {
              setState(() {
                _showControls = !_showControls; // Menüleri aç/kapat
              });
            },
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: const Color(0xFF121212),
              child: isRemoteUserJoined
                  ? _buildRemoteVideo()
                  : _buildLocalVideo(isFullScreen: true),
            ),
          ),

          // ----------------------------------------------------------------
          // 2. BEKLEME EKRANI YAZILARI
          // ----------------------------------------------------------------
          if (!isRemoteUserJoined)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: Colors.black.withOpacity(0.6),
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
            ),

          // ----------------------------------------------------------------
          // 3. HAREKETLİ (DRAGGABLE) KÜÇÜK EKRAN (PiP)
          // ----------------------------------------------------------------
          if (isRemoteUserJoined)
            Positioned(
              top: _pipTop,
              left: _pipLeft,
              child: GestureDetector(
                onPanUpdate: (details) {
                  // Ekranda sürüklerken pozisyonu güncelle ve sınırları aşmasını engelle (clamp)
                  setState(() {
                    _pipTop = (_pipTop! + details.delta.dy).clamp(
                      safePadding.top,
                      size.height - 160 - safePadding.bottom,
                    );
                    _pipLeft = (_pipLeft! + details.delta.dx).clamp(
                      0.0,
                      size.width - 110,
                    );
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(
                    milliseconds: 100,
                  ), // Akıcı bir his verir
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
            ),

          // ----------------------------------------------------------------
          // 4. ANİMASYONLU ÜST BİLGİ BARI
          // ----------------------------------------------------------------
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            top: _showControls
                ? 50
                : -100, // Menü kapalıysa ekranın dışına kayar
            left: 20,
            right: 20,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _showControls ? 1.0 : 0.0, // Saydamlaşarak kaybolur
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
          ),

          // ----------------------------------------------------------------
          // 5. ANİMASYONLU ALT KONTROL BARI
          // ----------------------------------------------------------------
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            bottom: _showControls ? 40 : -120, // Aşağı kayarak çıkar
            left: 30,
            right: 30,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _showControls ? 1.0 : 0.0,
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
          ),
        ],
      ),
    );
  }

  // --- GERÇEK KAMERA GÖRÜNTÜLERİ ---
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

    if (_localUserJoined) {
      return AgoraVideoView(
        controller: VideoViewController(
          rtcEngine: _engine,
          canvas: const VideoCanvas(uid: 0),
        ),
      );
    } else {
      return const Center(
        child: CircularProgressIndicator(color: ColorConstants.primaryColor),
      );
    }
  }

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
