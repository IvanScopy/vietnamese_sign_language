import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile/services/sos_api_service.dart';
import 'package:mobile/services/sos_location_service.dart';
import 'package:mobile/services/sos_platform_service.dart';

// ---------------------------------------------------------------------------
// SOS state machine
// ---------------------------------------------------------------------------

/// Internal SOS state machine states.
/// Exposed for testing via [SosScreen.initialStateForTesting].
enum SosScreenState {
  /// Idle — waiting for user to hold the button.
  idle,

  /// User is holding the SOS button (0-2 seconds).
  holding,

  /// 5-second countdown before sending. User can cancel.
  countdown,

  /// Cancelled during countdown. Shows "Đã hủy" for ~2 s then pops.
  cancelled,

  /// Acquiring GPS location after countdown completes.
  locating,

  /// Calling backend createAlert.
  sending,

  /// Backend SMS provider confirmed send.
  sent,

  /// Native SMS fallback was opened (composer shown, not confirmed sent).
  nativeFallback,

  /// All send paths failed.
  failed,
}

// ---------------------------------------------------------------------------
// SosScreen
// ---------------------------------------------------------------------------

/// Full-screen SOS emergency activation and status screen.
///
/// State machine (D-01 through D-16):
///   idle → (hold 2 s) → countdown → (5 s) → locating → sending →
///     sent | nativeFallback | failed
///   countdown → (Hủy) → cancelled → (2 s) → pop
///
/// Behavioural invariants:
/// - Backend alert is created ONLY after countdown completes (D-01).
/// - Native SMS fallback is labelled "Đã mở SMS, chờ người dùng gửi",
///   never "Đã gửi" (D-10).
/// - Gọi 115 opens dialer only — the app must not auto-call (D-11).
/// - No-contact case still proceeds and shows "Gọi 115" (D-14).
/// - Visual: stable red, no flashing (D-16).
///
/// [initialStateForTesting] is a test-only seam — leave null in production.
class SosScreen extends StatefulWidget {
  final SosApiService sosApiService;
  final SosLocationService locationService;
  final SosPlatformService platformService;

  /// Test-only seam — starts the screen at a specific state.
  /// Pass null in production code.
  // ignore: prefer_final_fields, unused_element
  final SosScreenState? initialStateForTesting;

  const SosScreen({
    super.key,
    required this.sosApiService,
    required this.locationService,
    required this.platformService,
    this.initialStateForTesting,
  });

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> {
  static const int _holdDurationMs = 2000;
  static const int _countdownSeconds = 5;

  // Current state
  late SosScreenState _state;

  // Hold gesture tracking
  double _holdProgress = 0.0; // 0.0..1.0
  Timer? _holdTimer;
  int _holdElapsedMs = 0;

  // Countdown
  int _countdownRemaining = _countdownSeconds;
  Timer? _countdownTimer;

  // Results
  SosLocationResult? _locationResult;
  String? _statusMessage; // display text for current state
  bool _dialerVisible = false; // whether Gọi 115 action is shown

  // Whether no contacts were configured
  bool _noContacts = false;

  @override
  void initState() {
    super.initState();
    _state = widget.initialStateForTesting ?? SosScreenState.idle;
    if (_state == SosScreenState.countdown) {
      _countdownRemaining = _countdownSeconds;
      // Start countdown timer immediately when seeded in countdown state.
      // This allows tests to advance fake timers to trigger the send flow.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _state == SosScreenState.countdown) {
          _startCountdownTimer();
        }
      });
    }
  }

  /// Starts the countdown Timer. Extracted so initState can start it
  /// when seeded into countdown state for testing.
  void _startCountdownTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      widget.platformService.hapticCountdownTick();
      final next = _countdownRemaining - 1;
      if (next <= 0) {
        timer.cancel();
        _countdownTimer = null;
        if (_state == SosScreenState.countdown) {
          _beginSosFlow();
        }
      } else {
        setState(() => _countdownRemaining = next);
      }
    });
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Hold gesture
  // ---------------------------------------------------------------------------

  void _onHoldStart() {
    widget.platformService.hapticHoldStart();
    setState(() {
      _state = SosScreenState.holding;
      _holdElapsedMs = 0;
      _holdProgress = 0.0;
    });

    _holdTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _holdElapsedMs += 50;
      final progress = (_holdElapsedMs / _holdDurationMs).clamp(0.0, 1.0);
      setState(() => _holdProgress = progress);

      if (_holdElapsedMs >= _holdDurationMs) {
        timer.cancel();
        _startCountdown();
      }
    });
  }

  void _onHoldEnd() {
    _holdTimer?.cancel();
    _holdTimer = null;
    if (_state == SosScreenState.holding) {
      // Released before 2 seconds — reset
      setState(() {
        _state = SosScreenState.idle;
        _holdProgress = 0.0;
        _holdElapsedMs = 0;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Countdown
  // ---------------------------------------------------------------------------

  void _startCountdown() {
    widget.platformService.hapticHoldComplete();
    setState(() {
      _state = SosScreenState.countdown;
      _countdownRemaining = _countdownSeconds;
    });
    _startCountdownTimer();
  }

  void _cancelCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    setState(() => _state = SosScreenState.cancelled);

    // Return home after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  // ---------------------------------------------------------------------------
  // SOS send flow (after countdown)
  // ---------------------------------------------------------------------------

  Future<void> _beginSosFlow() async {
    // Step 1: locate
    setState(() {
      _state = SosScreenState.locating;
      _statusMessage = 'Đang lấy vị trí';
    });

    final location = await widget.locationService.getLocationForSos();

    if (!mounted) return;

    _locationResult = location;

    // Step 2: send
    setState(() {
      _state = SosScreenState.sending;
      _statusMessage = 'Đang gửi tin nhắn';
    });

    try {
      final response = await widget.sosApiService.createAlert(
        latitude: location.latitude,
        longitude: location.longitude,
        locationAccuracyMeters: location.accuracyMeters,
        locationLabel: location.machineLabel,
        locationCapturedAt: location.capturedAt?.toIso8601String(),
      );

      if (!mounted) return;

      _noContacts = response.contactsCount == 0;

      switch (response.status) {
        case SosAggregateStatus.sent:
          widget.platformService.hapticSendSuccess();
          setState(() {
            _state = SosScreenState.sent;
            _statusMessage = 'Đã gửi';
            _dialerVisible = true;
          });

        case SosAggregateStatus.partialFailed:
          widget.platformService.hapticFallback();
          setState(() {
            _state = SosScreenState.sent;
            _statusMessage = 'Một số tin nhắn chưa gửi được';
            _dialerVisible = true;
          });

        case SosAggregateStatus.nativeFallback:
        case SosAggregateStatus.failed:
          await _openNativeFallback(response);

        case SosAggregateStatus.sending:
          // Treat as partial success — show dialer
          setState(() {
            _state = SosScreenState.sent;
            _statusMessage = 'Đang gửi';
            _dialerVisible = true;
          });
      }
    } catch (e) {
      if (!mounted) return;
      // Network/backend failure → native fallback
      await _openNativeFallback(null);
    }
  }

  Future<void> _openNativeFallback(SosAlertResponse? response) async {
    final targets = response?.fallbackTargets ?? [];
    if (targets.isEmpty) {
      // No contacts → show dialer only
      widget.platformService.hapticFallback();
      setState(() {
        _state = SosScreenState.nativeFallback;
        _statusMessage = 'Không gửi được SOS qua hệ thống. Hãy mở SMS thủ công hoặc gọi 115.';
        _dialerVisible = true;
        _noContacts = true;
      });
      return;
    }

    // Open SMS composer for first target; record fallback
    final first = targets.first;
    final smsBody = response?.smsBody ?? _buildSmsBody();
    final result = await widget.platformService.openSmsComposer(
      phoneNumber: first.phoneE164,
      body: smsBody,
    );

    if (!mounted) return;

    if (result == SmsComposerResult.composerOpened) {
      // Record fallback attempt — best effort, don't block UX
      if (response != null) {
        widget.sosApiService
            .recordFallback(response.id, fallbackType: 'native_sms')
            .catchError((_) {});
      }
      setState(() {
        _state = SosScreenState.nativeFallback;
        // Honest copy — composer was opened, not confirmed sent (D-10)
        _statusMessage = 'Đã mở SMS, chờ người dùng gửi';
        _dialerVisible = true;
      });
    } else {
      widget.platformService.hapticFailure();
      setState(() {
        _state = SosScreenState.failed;
        _statusMessage = 'Không mở được SMS';
        _dialerVisible = true;
      });
    }
  }

  String _buildSmsBody() {
    final ts = DateTime.now().toIso8601String();
    final loc = _locationResult;
    final locStr = loc?.hasCoordinates == true
        ? '${loc!.latitude!.toStringAsFixed(6)}, ${loc.longitude!.toStringAsFixed(6)}'
        : 'không có';
    return 'Tôi cần trợ giúp khẩn cấp.\nVị trí: $locStr\nThời gian gửi: $ts';
  }

  Future<void> _onCallDialer() async {
    await widget.platformService.openEmergencyDialer();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _countdownBackground,
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Color get _countdownBackground =>
      _state == SosScreenState.countdown ? const Color(0xFFDC2626) : Colors.white;

  Widget _buildBody() {
    return switch (_state) {
      SosScreenState.idle || SosScreenState.holding => _buildIdleHold(),
      SosScreenState.countdown => _buildCountdown(),
      SosScreenState.cancelled => _buildCancelled(),
      SosScreenState.locating || SosScreenState.sending => _buildProgress(),
      SosScreenState.sent ||
      SosScreenState.nativeFallback ||
      SosScreenState.failed => _buildStatus(),
    };
  }

  // ---------------------------------------------------------------------------
  // Idle / Hold state
  // ---------------------------------------------------------------------------

  Widget _buildIdleHold() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.warning_rounded,
            size: 64,
            color: Color(0xFFDC2626),
            semanticLabel: 'Biểu tượng khẩn cấp SOS',
          ),
          const SizedBox(height: 16),
          const Text(
            'SOS khẩn cấp',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: Color(0xFFDC2626),
            ),
          ),
          const SizedBox(height: 32),
          // Hold button with progress
          GestureDetector(
            onLongPressStart: (_) => _onHoldStart(),
            onLongPressEnd: (_) => _onHoldEnd(),
            onLongPressCancel: _onHoldEnd,
            child: Semantics(
              label: 'Nút SOS khẩn cấp. Nhấn giữ 2 giây để bắt đầu.',
              child: Container(
                height: 96,
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_state == SosScreenState.holding)
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: LinearProgressIndicator(
                            value: _holdProgress,
                            backgroundColor: const Color(0xFFDC2626),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFFB91C1C),
                            ),
                            minHeight: 96,
                          ),
                        ),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.sos, color: Colors.white, size: 32),
                        const SizedBox(width: 8),
                        Text(
                          _state == SosScreenState.holding
                              ? 'Giữ để gửi SOS'
                              : 'SOS khẩn cấp',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Nhấn giữ 2 giây để bắt đầu',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Countdown state
  // ---------------------------------------------------------------------------

  Widget _buildCountdown() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.warning_rounded,
            size: 64,
            color: Colors.white,
            semanticLabel: 'Biểu tượng khẩn cấp SOS',
          ),
          const SizedBox(height: 16),
          const Text(
            'SOS khẩn cấp',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          // Countdown number
          Semantics(
            liveRegion: true,
            label: 'Đếm ngược $_countdownRemaining giây',
            child: Text(
              '$_countdownRemaining',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 80,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Progress bar (linear, readable without animation reliance)
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _countdownRemaining / _countdownSeconds,
              backgroundColor: const Color(0xFFB91C1C),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Tin nhắn khẩn cấp sẽ được gửi sau 5 giây.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 48),
          // Large Hủy action (minimum 64px)
          Semantics(
            label: 'Hủy SOS',
            child: SizedBox(
              height: 64,
              child: ElevatedButton(
                onPressed: _cancelCountdown,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB91C1C),
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Hủy'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Cancelled state
  // ---------------------------------------------------------------------------

  Widget _buildCancelled() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.cancel_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Đã hủy',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'SOS chưa được gửi.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Progress state (locating / sending)
  // ---------------------------------------------------------------------------

  Widget _buildProgress() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const CircularProgressIndicator(
            color: Color(0xFF2563EB),
          ),
          const SizedBox(height: 24),
          Text(
            _statusMessage ?? '',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2563EB),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Status state (sent / fallback / failed)
  // ---------------------------------------------------------------------------

  Widget _buildStatus() {
    final Color statusColor = switch (_state) {
      SosScreenState.sent => const Color(0xFF16A34A),
      SosScreenState.nativeFallback => const Color(0xFFF59E0B),
      _ => const Color(0xFFDC2626),
    };

    final IconData statusIcon = switch (_state) {
      SosScreenState.sent => Icons.check_circle_outline,
      SosScreenState.nativeFallback => Icons.sms_outlined,
      _ => Icons.error_outline,
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32),
          Icon(statusIcon, size: 64, color: statusColor,
              semanticLabel: 'Trạng thái SOS'),
          const SizedBox(height: 16),
          Text(
            _statusMessage ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
          const SizedBox(height: 16),

          // Location card
          if (_locationResult != null) _buildLocationCard(),

          const SizedBox(height: 16),

          // No contacts warning
          if (_noContacts) _buildNoContactsWarning(),

          const SizedBox(height: 16),

          // Gọi 115 — only after user sees status (D-11)
          if (_dialerVisible) _buildDialerSection(),

          const SizedBox(height: 16),

          // Close action
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    final loc = _locationResult!;
    final Color cardColor = switch (loc.label) {
      SosLocationLabel.current => const Color(0xFF16A34A),
      SosLocationLabel.approximate ||
      SosLocationLabel.lastKnown => const Color(0xFFF59E0B),
      SosLocationLabel.unavailable => const Color(0xFF6B7280),
    };

    return Card(
      color: const Color(0xFFF3F4F6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.location_on, color: cardColor),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.hasCoordinates ? 'Đã lấy vị trí' : 'Không có vị trí',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    loc.displayLabel,
                    style: TextStyle(fontSize: 14, color: cardColor),
                  ),
                  if (loc.hasCoordinates)
                    Text(
                      '${loc.latitude!.toStringAsFixed(5)}, '
                      '${loc.longitude!.toStringAsFixed(5)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoContactsWarning() {
    return Card(
      color: const Color(0xFFFEF3C7),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Icon(Icons.warning_amber, color: Color(0xFFF59E0B)),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chưa có liên hệ khẩn cấp',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Bạn vẫn có thể gọi 115.',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: 'Gọi 115 — mở ứng dụng điện thoại',
          child: SizedBox(
            height: 64,
            child: ElevatedButton.icon(
              onPressed: _onCallDialer,
              icon: const Icon(Icons.phone, color: Colors.white),
              label: const Text(
                'Gọi 115',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Bạn sẽ xác nhận cuộc gọi trong ứng dụng Điện thoại.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }
}
