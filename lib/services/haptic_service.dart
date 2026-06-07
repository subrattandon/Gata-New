import 'dart:io';

import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

/// Unified haptic/vibration service.
/// iOS  → native UIFeedbackGenerator via HapticFeedback (premium taptic feel).
/// Android → VibrationEffect with amplitude for rich, satisfying feedback.
class Haptic {
  // ── Selection — nav tabs, option switches, toggles
  static void select() {
    if (Platform.isIOS) {
      HapticFeedback.selectionClick();
    } else {
      Vibration.vibrate(duration: 15, amplitude: 70);
    }
  }

  // ── Light — icon taps, list items, minor interactions
  static void light() {
    if (Platform.isIOS) {
      HapticFeedback.lightImpact();
    } else {
      Vibration.vibrate(duration: 22, amplitude: 110);
    }
  }

  // ── Medium — standard button presses, confirms, back
  static void medium() {
    if (Platform.isIOS) {
      HapticFeedback.mediumImpact();
    } else {
      Vibration.vibrate(duration: 35, amplitude: 175);
    }
  }

  // ── Heavy — primary CTA, send, post, submit
  static void heavy() {
    if (Platform.isIOS) {
      HapticFeedback.heavyImpact();
    } else {
      Vibration.vibrate(duration: 50, amplitude: 230);
    }
  }

  // ── Love — double-pulse for like/heart/love reactions
  static Future<void> love() async {
    if (Platform.isIOS) {
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 75));
      HapticFeedback.mediumImpact();
    } else {
      Vibration.vibrate(
        pattern: [0, 45, 70, 28],
        intensities: [0, 255, 0, 190],
      );
    }
  }

  // ── Success — double tap: confirm, done, sent
  static Future<void> success() async {
    if (Platform.isIOS) {
      HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 95));
      HapticFeedback.lightImpact();
    } else {
      Vibration.vibrate(
        pattern: [0, 32, 80, 20],
        intensities: [0, 190, 0, 110],
      );
    }
  }

  // ── Error — triple sharp buzz for validation failures
  static Future<void> error() async {
    if (Platform.isIOS) {
      for (var i = 0; i < 3; i++) {
        HapticFeedback.heavyImpact();
        if (i < 2) await Future.delayed(const Duration(milliseconds: 65));
      }
    } else {
      Vibration.vibrate(
        pattern: [0, 28, 48, 28, 48, 28],
        intensities: [0, 210, 0, 210, 0, 210],
      );
    }
  }

  // ── Impact — max strength single hit (double-tap like burst)
  static void impact() {
    if (Platform.isIOS) {
      HapticFeedback.heavyImpact();
    } else {
      Vibration.vibrate(duration: 55, amplitude: 255);
    }
  }

  // ── Soft — subtle background confirmations, passive info
  static void soft() {
    if (Platform.isIOS) {
      HapticFeedback.lightImpact();
    } else {
      Vibration.vibrate(duration: 12, amplitude: 55);
    }
  }
}
