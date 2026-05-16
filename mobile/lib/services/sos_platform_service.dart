import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

enum SmsComposerResult { composerOpened, composerFailed }

enum DialerResult { dialerOpened, dialerFailed }

/// Seam for testing — abstracts url_launcher static calls.
abstract class UrlLauncherAdapter {
  Future<bool> canLaunch(String url);
  Future<bool> launch(String url);
}

/// Production adapter delegates to the real url_launcher plugin.
class RealUrlLauncherAdapter implements UrlLauncherAdapter {
  @override
  Future<bool> canLaunch(String url) => canLaunchUrl(Uri.parse(url));

  @override
  Future<bool> launch(String url) => launchUrl(Uri.parse(url));
}

/// Platform service for SOS native handoffs: SMS composer and tel:115 dialer.
///
/// Design decisions (D-08, D-10, D-11, D-16):
/// - SMS composer opens and hands off to the system SMS app. The app cannot
///   confirm the message was actually sent — result is [SmsComposerResult.composerOpened]
///   only, never "confirmed_sent" or "delivered".
/// - Emergency dialer opens tel:115. The app must NOT auto-call; the user
///   confirms the call in the phone dialer.
/// - Haptic methods are no-ops when [hapticEnabled] is false, allowing test isolation.
class SosPlatformService {
  final UrlLauncherAdapter _launcher;
  final bool hapticEnabled;

  SosPlatformService({
    UrlLauncherAdapter? launcher,
    this.hapticEnabled = true,
  }) : _launcher = launcher ?? RealUrlLauncherAdapter();

  /// Open the native SMS composer pre-filled with [phoneNumber] and [body].
  ///
  /// Returns [SmsComposerResult.composerOpened] if the system SMS app was
  /// launched, or [SmsComposerResult.composerFailed] on any failure.
  ///
  /// IMPORTANT: composerOpened means the composer was shown — it does NOT
  /// mean the message was sent. Do not display "Đã gửi" for this result.
  Future<SmsComposerResult> openSmsComposer({
    required String phoneNumber,
    required String body,
  }) async {
    final uri = 'sms:$phoneNumber?body=${Uri.encodeComponent(body)}';
    try {
      final canOpen = await _launcher.canLaunch(uri);
      if (!canOpen) return SmsComposerResult.composerFailed;
      final opened = await _launcher.launch(uri);
      if (hapticEnabled) await HapticFeedback.mediumImpact();
      return opened
          ? SmsComposerResult.composerOpened
          : SmsComposerResult.composerFailed;
    } catch (_) {
      return SmsComposerResult.composerFailed;
    }
  }

  /// Open the system dialer with 115 pre-filled.
  ///
  /// The app must NOT auto-call. The user must confirm the call in the
  /// system dialer (D-11).
  Future<DialerResult> openEmergencyDialer() async {
    const uri = 'tel:115';
    try {
      final canOpen = await _launcher.canLaunch(uri);
      if (!canOpen) return DialerResult.dialerFailed;
      final opened = await _launcher.launch(uri);
      return opened ? DialerResult.dialerOpened : DialerResult.dialerFailed;
    } catch (_) {
      return DialerResult.dialerFailed;
    }
  }

  // --- Haptic helpers ---

  /// Called when the user begins pressing the SOS hold button.
  Future<void> hapticHoldStart() async {
    if (hapticEnabled) await HapticFeedback.lightImpact();
  }

  /// Called when the 2-second hold completes and countdown begins.
  Future<void> hapticHoldComplete() async {
    if (hapticEnabled) await HapticFeedback.heavyImpact();
  }

  /// Called once per second during the 5-second countdown.
  Future<void> hapticCountdownTick() async {
    if (hapticEnabled) await HapticFeedback.selectionClick();
  }

  /// Called when backend SMS send succeeds.
  Future<void> hapticSendSuccess() async {
    if (hapticEnabled) await HapticFeedback.heavyImpact();
  }

  /// Called when native SMS composer or dialer is opened (fallback path).
  Future<void> hapticFallback() async {
    if (hapticEnabled) await HapticFeedback.mediumImpact();
  }

  /// Called when SOS send fails (all paths exhausted).
  Future<void> hapticFailure() async {
    if (hapticEnabled) await HapticFeedback.vibrate();
  }
}
