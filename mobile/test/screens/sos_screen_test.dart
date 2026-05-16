import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/screens/sos_screen.dart';
import 'package:mobile/services/sos_api_service.dart';
import 'package:mobile/services/sos_location_service.dart';
import 'package:mobile/services/sos_platform_service.dart';
import 'package:mocktail/mocktail.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockSosApiService extends Mock implements SosApiService {}

class MockSosLocationService extends Mock implements SosLocationService {}

class MockSosPlatformService extends Mock implements SosPlatformService {}

// ---------------------------------------------------------------------------
// Test data helpers
// ---------------------------------------------------------------------------

SosLocationResult _locationUnavailable() => SosLocationResult(
      label: SosLocationLabel.unavailable,
      displayLabel: 'Không có vị trí — SOS vẫn được gửi',
    );

SosLocationResult _locationCurrent() => SosLocationResult(
      label: SosLocationLabel.current,
      latitude: 10.762622,
      longitude: 106.660172,
      accuracyMeters: 10.0,
      capturedAt: DateTime(2026, 5, 16, 10, 0, 0),
      displayLabel: 'vị trí hiện tại',
    );

SosAlertResponse _successResponse({int contactsCount = 2}) => SosAlertResponse(
      id: 42,
      status: SosAggregateStatus.sent,
      contactsCount: contactsCount,
      attempts: [],
      fallbackTargets: [],
      smsBody: null,
    );

SosAlertResponse _nativeFallbackResponse() => SosAlertResponse(
      id: 43,
      status: SosAggregateStatus.nativeFallback,
      contactsCount: 1,
      attempts: [],
      fallbackTargets: [
        SosFallbackTarget(name: 'Nguyễn Văn A', phoneE164: '+84901234567'),
      ],
      smsBody: 'Tôi cần trợ giúp khẩn cấp.',
    );

SosAlertResponse _noContactsResponse() => SosAlertResponse(
      id: 44,
      status: SosAggregateStatus.nativeFallback,
      contactsCount: 0,
      attempts: [],
      fallbackTargets: [],
      smsBody: null,
    );

// ---------------------------------------------------------------------------
// Widget builder
// ---------------------------------------------------------------------------

Widget _buildScreen({
  required MockSosApiService api,
  required MockSosLocationService location,
  required MockSosPlatformService platform,
  SosScreenState? initialState,
}) {
  return MaterialApp(
    home: SosScreen(
      sosApiService: api,
      locationService: location,
      platformService: platform,
      initialStateForTesting: initialState,
    ),
  );
}

void _stubDefaultHaptics(MockSosPlatformService platform) {
  when(() => platform.hapticHoldStart()).thenAnswer((_) async {});
  when(() => platform.hapticHoldComplete()).thenAnswer((_) async {});
  when(() => platform.hapticCountdownTick()).thenAnswer((_) async {});
  when(() => platform.hapticSendSuccess()).thenAnswer((_) async {});
  when(() => platform.hapticFallback()).thenAnswer((_) async {});
  when(() => platform.hapticFailure()).thenAnswer((_) async {});
}

void main() {
  late MockSosApiService mockApi;
  late MockSosLocationService mockLocation;
  late MockSosPlatformService mockPlatform;

  setUp(() {
    mockApi = MockSosApiService();
    mockLocation = MockSosLocationService();
    mockPlatform = MockSosPlatformService();
    _stubDefaultHaptics(mockPlatform);
  });

  // -------------------------------------------------------------------------
  // Test 1: Hold released before 2 s → no countdown, no backend call (D-01)
  // -------------------------------------------------------------------------
  testWidgets(
      'Idle state renders SOS entry — no countdown, no backend call without hold',
      (tester) async {
    await tester.pumpWidget(
      _buildScreen(api: mockApi, location: mockLocation, platform: mockPlatform),
    );

    // In idle: Hủy must not be visible, Gọi 115 must not be visible
    expect(find.text('Đã gửi'), findsNothing);
    expect(find.text('Đang gửi tin nhắn'), findsNothing);
    expect(find.text('Hủy'), findsNothing);
    expect(find.text('Gọi 115'), findsNothing);

    // SOS entry label is visible
    expect(find.textContaining('SOS khẩn cấp'), findsWidgets);

    // No backend call
    verifyNever(() => mockApi.createAlert(
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          locationAccuracyMeters: any(named: 'locationAccuracyMeters'),
          locationLabel: any(named: 'locationLabel'),
          locationCapturedAt: any(named: 'locationCapturedAt'),
          idempotencyKey: any(named: 'idempotencyKey'),
        ));
  });

  // -------------------------------------------------------------------------
  // Test 2: Hủy during countdown → shows "Đã hủy", no backend call (D-01, D-04)
  // -------------------------------------------------------------------------
  testWidgets(
      'Tapping Hủy during countdown shows Đã hủy and makes no backend call',
      (tester) async {
    // Start directly in countdown state via test seam
    await tester.pumpWidget(
      _buildScreen(
        api: mockApi,
        location: mockLocation,
        platform: mockPlatform,
        initialState: SosScreenState.countdown,
      ),
    );
    await tester.pump();

    // Should be in countdown — Hủy button visible
    expect(find.text('Hủy'), findsOneWidget);

    // Tap Hủy
    await tester.tap(find.text('Hủy'));
    await tester.pump();

    // Should show cancelled state (D-04)
    expect(find.text('Đã hủy'), findsOneWidget);
    expect(find.text('SOS chưa được gửi.'), findsOneWidget);

    // Advance past the 2-second auto-dismiss timer to clear pending timers
    await tester.pump(const Duration(seconds: 3));

    // No backend call — alert only created AFTER countdown (D-01)
    verifyNever(() => mockApi.createAlert(
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          locationAccuracyMeters: any(named: 'locationAccuracyMeters'),
          locationLabel: any(named: 'locationLabel'),
          locationCapturedAt: any(named: 'locationCapturedAt'),
          idempotencyKey: any(named: 'idempotencyKey'),
        ));
  });

  // -------------------------------------------------------------------------
  // Test 3: Countdown completes → SOS flow runs; no-contact shows warning + Gọi 115
  // -------------------------------------------------------------------------
  testWidgets(
      'No-contact API response shows warning and keeps Gọi 115 visible (D-14)',
      (tester) async {
    when(() => mockLocation.getLocationForSos())
        .thenAnswer((_) async => _locationCurrent());
    when(() => mockApi.createAlert(
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          locationAccuracyMeters: any(named: 'locationAccuracyMeters'),
          locationLabel: any(named: 'locationLabel'),
          locationCapturedAt: any(named: 'locationCapturedAt'),
          idempotencyKey: any(named: 'idempotencyKey'),
        )).thenAnswer((_) async => _noContactsResponse());
    when(() => mockPlatform.openSmsComposer(
              phoneNumber: any(named: 'phoneNumber'),
              body: any(named: 'body'),
            ))
        .thenAnswer((_) async => SmsComposerResult.composerOpened);

    // Start in countdown, then trigger send by advancing past countdown
    await tester.pumpWidget(
      _buildScreen(
        api: mockApi,
        location: mockLocation,
        platform: mockPlatform,
        initialState: SosScreenState.countdown,
      ),
    );
    await tester.pump();
    expect(find.text('Hủy'), findsOneWidget);

    // Advance 5 seconds to complete countdown
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    await tester.pump(const Duration(milliseconds: 100));

    // Let async operations complete
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // No-contacts warning must be visible (D-14)
    expect(find.text('Chưa có liên hệ khẩn cấp'), findsOneWidget);
    // Gọi 115 must still be available even with no contacts (D-14)
    expect(find.text('Gọi 115'), findsOneWidget);
  });

  // -------------------------------------------------------------------------
  // Test 4: Location unavailable → shows location denied copy in status (D-05)
  // -------------------------------------------------------------------------
  testWidgets('Location unavailable shows proper copy in status screen (D-05)',
      (tester) async {
    when(() => mockLocation.getLocationForSos())
        .thenAnswer((_) async => _locationUnavailable());
    when(() => mockApi.createAlert(
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          locationAccuracyMeters: any(named: 'locationAccuracyMeters'),
          locationLabel: any(named: 'locationLabel'),
          locationCapturedAt: any(named: 'locationCapturedAt'),
          idempotencyKey: any(named: 'idempotencyKey'),
        )).thenAnswer((_) async => _successResponse());

    await tester.pumpWidget(
      _buildScreen(
        api: mockApi,
        location: mockLocation,
        platform: mockPlatform,
        initialState: SosScreenState.countdown,
      ),
    );
    await tester.pump();

    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Location card shows unavailable display label
    expect(
      find.textContaining('SOS vẫn được gửi'),
      findsOneWidget,
    );
  });

  // -------------------------------------------------------------------------
  // Test 5: Native fallback shows "Đã mở SMS, chờ người dùng gửi" not "Đã gửi" (D-10)
  // -------------------------------------------------------------------------
  testWidgets(
      'Native SMS fallback shows honest copy — not Đã gửi (D-10)',
      (tester) async {
    when(() => mockLocation.getLocationForSos())
        .thenAnswer((_) async => _locationCurrent());
    when(() => mockApi.createAlert(
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          locationAccuracyMeters: any(named: 'locationAccuracyMeters'),
          locationLabel: any(named: 'locationLabel'),
          locationCapturedAt: any(named: 'locationCapturedAt'),
          idempotencyKey: any(named: 'idempotencyKey'),
        )).thenAnswer((_) async => _nativeFallbackResponse());
    when(() => mockApi.recordFallback(
              any(),
              fallbackType: any(named: 'fallbackType'),
              attemptIds: any(named: 'attemptIds'),
            ))
        .thenAnswer((_) async {});
    when(() => mockPlatform.openSmsComposer(
              phoneNumber: any(named: 'phoneNumber'),
              body: any(named: 'body'),
            ))
        .thenAnswer((_) async => SmsComposerResult.composerOpened);

    await tester.pumpWidget(
      _buildScreen(
        api: mockApi,
        location: mockLocation,
        platform: mockPlatform,
        initialState: SosScreenState.countdown,
      ),
    );
    await tester.pump();

    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Must show honest fallback copy (D-10)
    expect(find.text('Đã mở SMS, chờ người dùng gửi'), findsOneWidget);
    // Must NOT claim the message was sent
    expect(find.text('Đã gửi'), findsNothing);
  });

  // -------------------------------------------------------------------------
  // Test 6: Gọi 115 only appears after status — not during countdown (D-11)
  // -------------------------------------------------------------------------
  testWidgets(
      'Gọi 115 button does not appear during countdown — only after status (D-11)',
      (tester) async {
    // Start in countdown state
    await tester.pumpWidget(
      _buildScreen(
        api: mockApi,
        location: mockLocation,
        platform: mockPlatform,
        initialState: SosScreenState.countdown,
      ),
    );
    await tester.pump();

    // In countdown: Gọi 115 must not be visible
    expect(find.text('Gọi 115'), findsNothing);
    // Hủy must be visible (D-03)
    expect(find.text('Hủy'), findsOneWidget);

    // Cancel to avoid pending timer warnings
    await tester.tap(find.text('Hủy'));
    await tester.pump(const Duration(seconds: 3));
  });
}
