import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

/// WebRTC call service using Firestore for signaling.
///
/// Flow:
/// 1. Caller creates a call doc with an offer SDP
/// 2. Callee watches for incoming calls, sets answer SDP
/// 3. ICE candidates exchanged via sub-collections
/// 4. Call ended by setting status to 'ended'
class CallService {
  static final _db = FirebaseFirestore.instance;
  static const _roomId = 'our-space';
  static DocumentReference get _room => _db.collection('rooms').doc(_roomId);
  static CollectionReference get _calls => _room.collection('calls');

  RTCPeerConnection? _pc;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  StreamSubscription? _callSub;
  StreamSubscription? _candidateSub;
  String? _activeCallId;

  bool get isInCall => _activeCallId != null;
  MediaStream? get localStream => _localStream;
  MediaStream? get remoteStream => _remoteStream;

  // Callbacks
  void Function(MediaStream)? onRemoteStream;
  void Function(MediaStream)? onLocalStream;
  void Function()? onCallEnded;
  void Function(String callId, String callerEmail, bool isVideo)? onIncomingCall;

  static const _iceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ]
  };

  /// Start watching for incoming calls.
  void listenForIncomingCalls(String myEmail) {
    _callSub?.cancel();
    _callSub = _calls
        .where('calleeEmail', isEqualTo: myEmail)
        .where('status', isEqualTo: 'ringing')
        .snapshots()
        .listen((snap) {
      for (final doc in snap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        onIncomingCall?.call(
          doc.id,
          data['callerEmail'] as String,
          data['isVideo'] as bool? ?? false,
        );
        break; // Handle one call at a time
      }
    });
  }

  void stopListening() {
    _callSub?.cancel();
    _callSub = null;
  }

  /// Initiate a call.
  Future<String> startCall({
    required String callerEmail,
    required String calleeEmail,
    required bool isVideo,
  }) async {
    await _createPeerConnection();
    await _getUserMedia(isVideo);

    // Add local tracks to peer connection
    _localStream!.getTracks().forEach((track) {
      _pc!.addTrack(track, _localStream!);
    });

    // Create offer
    final offer = await _pc!.createOffer({
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': isVideo,
    });
    await _pc!.setLocalDescription(offer);

    // Create call document
    final callRef = _calls.doc();
    _activeCallId = callRef.id;
    await callRef.set({
      'callerEmail': callerEmail,
      'calleeEmail': calleeEmail,
      'isVideo': isVideo,
      'status': 'ringing',
      'offer': {'sdp': offer.sdp, 'type': offer.type},
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Listen for answer
    callRef.snapshots().listen((snap) {
      if (!snap.exists) return;
      final data = snap.data() as Map<String, dynamic>;
      final status = data['status'];

      if (status == 'answered' && data['answer'] != null) {
        final answer = data['answer'] as Map<String, dynamic>;
        _pc?.setRemoteDescription(
            RTCSessionDescription(answer['sdp'], answer['type']));
      }
      if (status == 'ended' || status == 'declined') {
        endCall();
      }
    });

    // Listen for remote ICE candidates
    _listenForCandidates(callRef.id, 'callee_candidates');

    // Send local ICE candidates
    _pc!.onIceCandidate = (candidate) {
      callRef.collection('caller_candidates').add(candidate.toMap());
    };

    return callRef.id;
  }

  /// Accept an incoming call.
  Future<void> acceptCall(String callId, bool isVideo) async {
    _activeCallId = callId;
    await _createPeerConnection();
    await _getUserMedia(isVideo);

    _localStream!.getTracks().forEach((track) {
      _pc!.addTrack(track, _localStream!);
    });

    // Get call doc
    final callDoc = await _calls.doc(callId).get();
    final data = callDoc.data() as Map<String, dynamic>;
    final offer = data['offer'] as Map<String, dynamic>;

    await _pc!.setRemoteDescription(
        RTCSessionDescription(offer['sdp'], offer['type']));

    final answer = await _pc!.createAnswer();
    await _pc!.setLocalDescription(answer);

    await _calls.doc(callId).update({
      'status': 'answered',
      'answer': {'sdp': answer.sdp, 'type': answer.type},
    });

    // Listen for remote ICE candidates
    _listenForCandidates(callId, 'caller_candidates');

    // Send local ICE candidates
    _pc!.onIceCandidate = (candidate) {
      _calls.doc(callId).collection('callee_candidates').add(candidate.toMap());
    };

    // Listen for call end
    _calls.doc(callId).snapshots().listen((snap) {
      if (!snap.exists) return;
      final d = snap.data() as Map<String, dynamic>;
      if (d['status'] == 'ended') {
        endCall();
      }
    });
  }

  /// Decline an incoming call.
  Future<void> declineCall(String callId) async {
    await _calls.doc(callId).update({'status': 'declined'});
  }

  /// End the current call.
  Future<void> endCall() async {
    if (_activeCallId != null) {
      try {
        await _calls.doc(_activeCallId).update({'status': 'ended'});
      } catch (_) {}
    }

    _candidateSub?.cancel();
    _candidateSub = null;

    _localStream?.getTracks().forEach((t) => t.stop());
    _localStream?.dispose();
    _localStream = null;

    _remoteStream?.dispose();
    _remoteStream = null;

    await _pc?.close();
    _pc = null;
    _activeCallId = null;

    onCallEnded?.call();
  }

  // ── Media controls ──

  void toggleMute() {
    final audioTrack = _localStream?.getAudioTracks().firstOrNull;
    if (audioTrack != null) audioTrack.enabled = !audioTrack.enabled;
  }

  bool get isMuted {
    final audioTrack = _localStream?.getAudioTracks().firstOrNull;
    return audioTrack != null ? !audioTrack.enabled : false;
  }

  void toggleCamera() {
    final videoTrack = _localStream?.getVideoTracks().firstOrNull;
    if (videoTrack != null) videoTrack.enabled = !videoTrack.enabled;
  }

  bool get isCameraOff {
    final videoTrack = _localStream?.getVideoTracks().firstOrNull;
    return videoTrack != null ? !videoTrack.enabled : true;
  }

  void toggleSpeaker() {
    _localStream?.getAudioTracks().forEach((track) {
      Helper.setSpeakerphoneOn(!_speakerOn);
    });
    _speakerOn = !_speakerOn;
  }

  bool _speakerOn = false;
  bool get isSpeakerOn => _speakerOn;

  Future<void> flipCamera() async {
    final videoTrack = _localStream?.getVideoTracks().firstOrNull;
    if (videoTrack != null) {
      Helper.switchCamera(videoTrack);
    }
  }

  // ── Private ──

  Future<void> _createPeerConnection() async {
    _pc = await createPeerConnection(_iceServers);

    _pc!.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams[0];
        onRemoteStream?.call(_remoteStream!);
      }
    };

    _pc!.onConnectionState = (state) {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        endCall();
      }
    };
  }

  Future<void> _getUserMedia(bool isVideo) async {
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': isVideo ? {'facingMode': 'user'} : false,
    });
    onLocalStream?.call(_localStream!);
  }

  void _listenForCandidates(String callId, String collection) {
    _candidateSub?.cancel();
    _candidateSub = _calls
        .doc(callId)
        .collection(collection)
        .snapshots()
        .listen((snap) {
      for (final change in snap.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data()!;
          _pc?.addCandidate(RTCIceCandidate(
            data['candidate'],
            data['sdpMid'],
            data['sdpMLineIndex'],
          ));
        }
      }
    });
  }

  void dispose() {
    stopListening();
    endCall();
  }
}
