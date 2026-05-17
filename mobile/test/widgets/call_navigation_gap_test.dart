import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/config/app_config.dart';
import 'package:mobile/main.dart';
import 'package:mobile/models/call_state.dart';
import 'package:mobile/models/user_type.dart';
import 'package:mobile/screens/calls/active_call_screen.dart';
import 'package:mobile/services/call_api_service.dart';
import 'package:mobile/services/push_notification_service.dart';

class FakeCallApiService extends CallApiService {
  final CallSession session;
  final Object? error;
  int? createdCalleeId;

  FakeCallApiService({required this.session, this.error})
    : super(baseUrl: 'http://localhost:3000', authToken: 'test-token');

  @override
  Future<CallSession> createCall(int calleeId) async {
    createdCalleeId = calleeId;
    final error = this.error;
    if (error != null) throw error;
    return session;
  }

  @override
  void dispose() {}
}

class RecordingNavigatorObserver extends NavigatorObserver {
  final pushed = <RouteSettings>[];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushed.add(route.settings);
    super.didPush(route, previousRoute);
  }
}

AppConfig createTestConfig() => AppConfig.create(
  environment: 'test',
  serverUrl: 'localhost',
  serverPort: 3000,
  liveKitUrl: 'ws://localhost:7880',
);

CallSession createCallSession({int callId = 42, String? fromUserName}) {
  return CallSession(
    callId: callId,
    roomName: 'vsl-room-$callId',
    fromUserId: 7,
    fromUserName: fromUserName,
    state: CallState.active,
  );
}

void main() {
  test('CallSession parses backend uppercase call states', () {
    final session = CallSession.fromJson({
      'callId': 42,
      'roomName': 'vsl-room',
      'fromUserId': 7,
      'state': 'ACTIVE',
    });

    expect(session.state, CallState.active);
  });

  testWidgets('/calls/active defaults currentUserType for ActiveCallScreen', (
    tester,
  ) async {
    final config = createTestConfig();

    await tester.pumpWidget(
      VSLBridgeApp(
        config: config,
        authToken: 'test-token',
        pushService: PushNotificationService(
          baseUrl: config.httpUrl,
          authToken: 'test-token',
        ),
      ),
    );
    await tester.pump();

    navigatorKey.currentState!.pushNamed(
      '/calls/active',
      arguments: {'callSession': createCallSession()},
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final activeCallScreen = tester.widget<ActiveCallScreen>(
      find.byType(ActiveCallScreen),
    );
    expect(activeCallScreen.config, same(config));
    expect(activeCallScreen.authToken, 'test-token');
    expect(activeCallScreen.currentUserType, UserType.deaf);
  });

  testWidgets('HomeScreen Start video call does not navigate to incoming', (
    tester,
  ) async {
    final config = createTestConfig();
    final callApiService = FakeCallApiService(
      session: createCallSession(callId: 77, fromUserName: 'Callee User'),
    );
    final observer = RecordingNavigatorObserver();

    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [observer],
        home: HomeScreen(
          config: config,
          authToken: 'test-token',
          callApiService: callApiService,
          selectCalleeId: (_) async => 7,
        ),
        onGenerateRoute: (settings) => MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => Text('Route ${settings.name}'),
        ),
      ),
    );

    await tester.tap(find.text('Start video call'));
    await tester.pumpAndSettle();

    expect(
      observer.pushed.map((settings) => settings.name),
      isNot(contains('/calls/incoming')),
    );
  });

  testWidgets('HomeScreen creates call and navigates to outgoing route', (
    tester,
  ) async {
    final config = createTestConfig();
    final callApiService = FakeCallApiService(
      session: createCallSession(callId: 88, fromUserName: 'Callee User'),
    );
    final observer = RecordingNavigatorObserver();

    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [observer],
        home: HomeScreen(
          config: config,
          authToken: 'test-token',
          callApiService: callApiService,
          selectCalleeId: (_) async => 9,
        ),
        onGenerateRoute: (settings) => MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => Text('Route ${settings.name}'),
        ),
      ),
    );

    await tester.tap(find.text('Start video call'));
    await tester.pumpAndSettle();

    expect(callApiService.createdCalleeId, 9);
    expect(observer.pushed.last.name, '/calls/outgoing');
    expect(observer.pushed.last.arguments, {
      'callId': 88,
      'calleeName': 'Callee User',
    });
  });
}
