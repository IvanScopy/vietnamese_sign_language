import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/services/sos_platform_service.dart';
import 'package:mocktail/mocktail.dart';

class MockUrlLauncherAdapter extends Mock implements UrlLauncherAdapter {}

void main() {
  late MockUrlLauncherAdapter mockLauncher;
  late SosPlatformService service;

  setUp(() {
    mockLauncher = MockUrlLauncherAdapter();
    service = SosPlatformService(
      launcher: mockLauncher,
      hapticEnabled: false, // disable haptics in tests
    );
  });

  group('openSmsComposer', () {
    test('returns composerOpened when launcher succeeds', () async {
      when(() => mockLauncher.canLaunch(any())).thenAnswer((_) async => true);
      when(() => mockLauncher.launch(any())).thenAnswer((_) async => true);

      final result = await service.openSmsComposer(
        phoneNumber: '+84901234567',
        body: 'Tôi cần trợ giúp khẩn cấp.',
      );

      expect(result, SmsComposerResult.composerOpened);
    });

    test('returns composerFailed when canLaunch returns false', () async {
      when(() => mockLauncher.canLaunch(any())).thenAnswer((_) async => false);

      final result = await service.openSmsComposer(
        phoneNumber: '+84901234567',
        body: 'Tôi cần trợ giúp khẩn cấp.',
      );

      expect(result, SmsComposerResult.composerFailed);
      // launch should not be called if canLaunch returns false
      verifyNever(() => mockLauncher.launch(any()));
    });

    test('returns composerFailed when launch returns false', () async {
      when(() => mockLauncher.canLaunch(any())).thenAnswer((_) async => true);
      when(() => mockLauncher.launch(any())).thenAnswer((_) async => false);

      final result = await service.openSmsComposer(
        phoneNumber: '+84901234567',
        body: 'Tôi cần trợ giúp khẩn cấp.',
      );

      expect(result, SmsComposerResult.composerFailed);
    });

    test('returns composerFailed when launcher throws — no exception propagated',
        () async {
      when(() => mockLauncher.canLaunch(any()))
          .thenThrow(Exception('platform error'));

      final result = await service.openSmsComposer(
        phoneNumber: '+84901234567',
        body: 'Tôi cần trợ giúp khẩn cấp.',
      );

      // Must not throw — returns composerFailed
      expect(result, SmsComposerResult.composerFailed);
    });

    test('SmsComposerResult has only composerOpened and composerFailed variants',
        () {
      // Ensure no "confirmed_sent" or "delivered" variant was accidentally added.
      const values = SmsComposerResult.values;
      expect(values, containsAll([
        SmsComposerResult.composerOpened,
        SmsComposerResult.composerFailed,
      ]));
      expect(values.length, 2,
          reason:
              'SmsComposerResult must have exactly 2 variants — '
              'confirmed_sent/delivered must never be added because '
              'the app cannot confirm the user actually sent the SMS.');
    });

    test('passes URL with encoded body to launcher', () async {
      String? capturedUrl;
      when(() => mockLauncher.canLaunch(any())).thenAnswer((invocation) async {
        capturedUrl = invocation.positionalArguments[0] as String;
        return true;
      });
      when(() => mockLauncher.launch(any())).thenAnswer((_) async => true);

      await service.openSmsComposer(
        phoneNumber: '+84901234567',
        body: 'Hello world',
      );

      expect(capturedUrl, startsWith('sms:+84901234567?body='));
      expect(capturedUrl, contains('Hello%20world'));
    });
  });

  group('openEmergencyDialer', () {
    test('builds tel:115 URI — not tel:911 or any other number', () async {
      String? capturedUri;
      when(() => mockLauncher.canLaunch(any())).thenAnswer((invocation) async {
        capturedUri = invocation.positionalArguments[0] as String;
        return true;
      });
      when(() => mockLauncher.launch(any())).thenAnswer((_) async => true);

      await service.openEmergencyDialer();

      expect(capturedUri, equals('tel:115'),
          reason: 'Must dial 115 (Vietnamese emergency), not 911 or any other number.');
    });

    test('returns dialerOpened when launcher succeeds', () async {
      when(() => mockLauncher.canLaunch(any())).thenAnswer((_) async => true);
      when(() => mockLauncher.launch(any())).thenAnswer((_) async => true);

      final result = await service.openEmergencyDialer();

      expect(result, DialerResult.dialerOpened);
    });

    test('returns dialerFailed when canLaunch returns false', () async {
      when(() => mockLauncher.canLaunch(any())).thenAnswer((_) async => false);

      final result = await service.openEmergencyDialer();

      expect(result, DialerResult.dialerFailed);
    });

    test('returns dialerFailed when launcher throws — no exception propagated',
        () async {
      when(() => mockLauncher.canLaunch(any()))
          .thenThrow(Exception('platform error'));

      final result = await service.openEmergencyDialer();

      expect(result, DialerResult.dialerFailed);
    });
  });
}
