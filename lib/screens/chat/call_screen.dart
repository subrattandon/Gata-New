import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/models.dart';
import '../../services/call_service.dart';
import '../../services/haptic_service.dart';
import '../../theme/gata_theme.dart';

class CallScreen extends StatefulWidget {
  const CallScreen({
    super.key,
    required this.callService,
    required this.partner,
    required this.isVideo,
    required this.isIncoming,
    this.callId,
    required this.myEmail,
    required this.partnerEmail,
  });

  final CallService callService;
  final AppUser partner;
  final bool isVideo;
  final bool isIncoming;
  final String? callId;
  final String myEmail;
  final String partnerEmail;

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();
  bool _connected = false;
  bool _muted = false;
  bool _speakerOn = false;
  bool _cameraOff = false;
  bool _callActive = false;
  Timer? _timer;
  int _seconds = 0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();

    widget.callService.onLocalStream = (stream) {
      setState(() {
        _localRenderer.srcObject = stream;
      });
    };

    widget.callService.onRemoteStream = (stream) {
      setState(() {
        _remoteRenderer.srcObject = stream;
        _connected = true;
        _callActive = true;
      });
      _startTimer();
    };

    widget.callService.onCallEnded = () {
      if (mounted) Navigator.of(context).pop();
    };

    if (widget.isIncoming) {
      // Wait for user to accept — handled by buttons
    } else {
      // Start outgoing call
      await widget.callService.startCall(
        callerEmail: widget.myEmail,
        calleeEmail: widget.partnerEmail,
        isVideo: widget.isVideo,
      );
      setState(() => _callActive = true);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
  }

  String _formatDuration() {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _accept() async {
    Haptic.success();
    await widget.callService.acceptCall(widget.callId!, widget.isVideo);
    setState(() => _callActive = true);
  }

  void _decline() {
    Haptic.error();
    widget.callService.declineCall(widget.callId!);
    Navigator.of(context).pop();
  }

  void _endCall() {
    Haptic.medium();
    widget.callService.endCall();
    Navigator.of(context).pop();
  }

  void _toggleMute() {
    Haptic.select();
    widget.callService.toggleMute();
    setState(() => _muted = widget.callService.isMuted);
  }

  void _toggleSpeaker() {
    Haptic.select();
    widget.callService.toggleSpeaker();
    setState(() => _speakerOn = widget.callService.isSpeakerOn);
  }

  void _toggleCamera() {
    Haptic.select();
    widget.callService.toggleCamera();
    setState(() => _cameraOff = widget.callService.isCameraOff);
  }

  void _flipCamera() {
    Haptic.select();
    widget.callService.flipCamera();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        children: [
          // Remote video (fullscreen) or avatar
          if (widget.isVideo && _connected)
            Positioned.fill(
              child: RTCVideoView(
                _remoteRenderer,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              ),
            )
          else
            _avatarView(),

          // Local video (pip)
          if (widget.isVideo && _callActive)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 110,
                  height: 160,
                  child: _cameraOff
                      ? Container(
                          color: GataColors.surfaceFloat,
                          child: const Center(
                            child: Icon(Icons.videocam_off_rounded,
                                color: GataColors.textMuted, size: 28),
                          ),
                        )
                      : RTCVideoView(
                          _localRenderer,
                          mirror: true,
                          objectFit:
                              RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                        ),
                ),
              ),
            ),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _topBar(),
          ),

          // Controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _controls(),
          ),
        ],
      ),
    );
  }

  Widget _avatarView() {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1020), Color(0xFF0A0A0A)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [GataColors.rose, GataColors.lavender],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: GataColors.rose.withValues(alpha: 0.3),
                      blurRadius: 40,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(widget.partner.emoji,
                      style: const TextStyle(fontSize: 56)),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                widget.partner.name,
                style: GoogleFonts.nunito(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _connected
                    ? _formatDuration()
                    : (widget.isIncoming && !_callActive
                        ? 'Incoming ${widget.isVideo ? 'video' : 'voice'} call…'
                        : 'Connecting…'),
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _connected ? GataColors.successGreen : GataColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 12, 20, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xCC000000), Color(0x00000000)],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.isVideo
                      ? Icons.videocam_rounded
                      : Icons.phone_rounded,
                  size: 16,
                  color: GataColors.rose,
                ),
                const SizedBox(width: 6),
                Text(
                  widget.isVideo ? 'Video' : 'Voice',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          if (_connected)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: GataColors.successGreen.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _formatDuration(),
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: GataColors.successGreen,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _controls() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).padding.bottom + 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Color(0xCC000000), Color(0x00000000)],
        ),
      ),
      child: widget.isIncoming && !_callActive
          ? _incomingControls()
          : _activeControls(),
    );
  }

  Widget _incomingControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Decline
        _callButton(
          icon: Icons.call_end_rounded,
          color: const Color(0xFFD32F2F),
          size: 64,
          onTap: _decline,
          label: 'Decline',
        ),
        // Accept
        _callButton(
          icon: widget.isVideo
              ? Icons.videocam_rounded
              : Icons.call_rounded,
          color: GataColors.successGreen,
          size: 64,
          onTap: _accept,
          label: 'Accept',
        ),
      ],
    );
  }

  Widget _activeControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _controlBtn(
              icon: _muted
                  ? Icons.mic_off_rounded
                  : Icons.mic_rounded,
              label: _muted ? 'Unmute' : 'Mute',
              active: _muted,
              onTap: _toggleMute,
            ),
            _controlBtn(
              icon: _speakerOn
                  ? Icons.volume_up_rounded
                  : Icons.volume_down_rounded,
              label: 'Speaker',
              active: _speakerOn,
              onTap: _toggleSpeaker,
            ),
            if (widget.isVideo) ...[
              _controlBtn(
                icon: _cameraOff
                    ? Icons.videocam_off_rounded
                    : Icons.videocam_rounded,
                label: 'Camera',
                active: _cameraOff,
                onTap: _toggleCamera,
              ),
              _controlBtn(
                icon: Icons.flip_camera_ios_rounded,
                label: 'Flip',
                onTap: _flipCamera,
              ),
            ],
          ],
        ),
        const SizedBox(height: 24),
        _callButton(
          icon: Icons.call_end_rounded,
          color: const Color(0xFFD32F2F),
          size: 64,
          onTap: _endCall,
          label: 'End',
        ),
      ],
    );
  }

  Widget _controlBtn({
    required IconData icon,
    required String label,
    bool active = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.08),
              border: Border.all(
                color: active
                    ? GataColors.rose.withValues(alpha: 0.4)
                    : Colors.white.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Icon(icon,
                color: active ? GataColors.rose : Colors.white, size: 22),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: GataColors.textMuted,
              )),
        ],
      ),
    );
  }

  Widget _callButton({
    required IconData icon,
    required Color color,
    required double size,
    required VoidCallback onTap,
    String? label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: size * 0.44),
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 8),
          Text(label,
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: GataColors.textMuted,
              )),
        ],
      ],
    );
  }
}
