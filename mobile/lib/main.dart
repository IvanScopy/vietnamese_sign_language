import 'package:flutter/material.dart';
import 'package:mobile/config/app_config.dart';
import 'package:mobile/models/call_state.dart';
import 'package:mobile/models/user_type.dart';
import 'package:mobile/screens/calls/active_call_screen.dart';
import 'package:mobile/screens/calls/call_result_screen.dart';
import 'package:mobile/screens/calls/incoming_call_screen.dart';
import 'package:mobile/screens/calls/outgoing_call_screen.dart';
import 'package:mobile/screens/conversation_history_screen.dart';
import 'package:mobile/screens/conversation_screen.dart';
import 'package:mobile/screens/recognition_screen.dart';
import 'package:mobile/screens/sos_screen.dart';
import 'package:mobile/services/call_api_service.dart';
import 'package:mobile/services/call_signaling_service.dart';
import 'package:mobile/services/livekit_call_service.dart';
import 'package:mobile/services/push_notification_service.dart';
import 'package:mobile/services/sos_api_service.dart';
import 'package:mobile/services/sos_location_service.dart';
import 'package:mobile/services/sos_platform_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Global navigator key for push notification routing
final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load configuration
  final config = AppConfig.load();

  // Get auth token from shared preferences
  final prefs = await SharedPreferences.getInstance();
  final authToken = prefs.getString('auth_token') ?? '';

  // Initialize PushNotificationService before runApp
  final pushService = PushNotificationService(
    baseUrl: config.httpUrl,
    authToken: authToken.isNotEmpty ? authToken : null,
  );
  await pushService.initialize(navigatorKey);

  runApp(
    VSLBridgeApp(
      config: config,
      authToken: authToken,
      pushService: pushService,
    ),
  );
}

class VSLBridgeApp extends StatelessWidget {
  final AppConfig config;
  final String authToken;
  final PushNotificationService pushService;

  const VSLBridgeApp({
    super.key,
    required this.config,
    required this.authToken,
    required this.pushService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VSL Bridge',
      navigatorKey: navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: HomeScreen(config: config, authToken: authToken),
      routes: {
        '/recognition': (context) => RecognitionScreen(
          serverUrl: config.serverUrl,
          serverPort: config.serverPort,
          authToken: authToken,
          config: config,
        ),
        '/conversation': (context) =>
            ConversationScreen(config: config, authToken: authToken),
        '/history': (context) => const ConversationHistoryScreen(),
      },
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/calls/incoming':
            final args = settings.arguments as Map<String, dynamic>?;
            final callId = args?['callId'] as int? ?? 0;
            final fromUserName = args?['fromUserName'] as String?;
            return MaterialPageRoute(
              builder: (_) => IncomingCallScreen(
                callApiService: CallApiService(
                  baseUrl: config.httpUrl,
                  authToken: authToken,
                ),
                callId: callId,
                fromUserName: fromUserName,
              ),
            );

          case '/calls/outgoing':
            final args = settings.arguments as Map<String, dynamic>?;
            final outgoingCallId = args?['callId'] as int? ?? 0;
            final calleeName = args?['calleeName'] as String?;
            return MaterialPageRoute(
              builder: (_) => OutgoingCallScreen(
                callApiService: CallApiService(
                  baseUrl: config.httpUrl,
                  authToken: authToken,
                ),
                callSignalingService: CallSignalingService(
                  websocketUrl: config.websocketUrl,
                  authToken: authToken,
                ),
                callId: outgoingCallId,
                calleeName: calleeName,
              ),
            );

          case '/calls/active':
            final args = settings.arguments as Map<String, dynamic>?;
            final callSession = args?['callSession'] as CallSession?;
            final currentUserType =
                args?['currentUserType'] as UserType? ?? UserType.deaf;
            if (callSession == null) {
              return MaterialPageRoute(
                builder: (_) => const Scaffold(
                  body: Center(child: Text('No call session provided')),
                ),
              );
            }
            return MaterialPageRoute(
              builder: (_) => ActiveCallScreen(
                liveKitCallService: LiveKitCallService(),
                callApiService: CallApiService(
                  baseUrl: config.httpUrl,
                  authToken: authToken,
                ),
                callSession: callSession,
                liveKitUrl: config.liveKitUrl,
                config: config,
                authToken: authToken,
                currentUserType: currentUserType,
              ),
            );

          case '/calls/result':
            final args = settings.arguments as Map<String, dynamic>?;
            final callState = args?['callState'] as CallState? ?? CallState.ended;
            final callerName = args?['callerName'] as String?;
            return MaterialPageRoute(
              builder: (_) => CallResultScreen(
                callState: callState,
                callerName: callerName,
              ),
            );

          case '/sos':
            return MaterialPageRoute(
              builder: (_) => SosScreen(
                sosApiService: SosApiService(authToken: authToken),
                locationService: SosLocationService(),
                platformService: SosPlatformService(),
              ),
            );

          default:
            return null;
        }
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  final AppConfig config;
  final String authToken;

  const HomeScreen({super.key, required this.config, required this.authToken});

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = authToken.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('VSL Bridge'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to VSL Bridge',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Environment: ${config.environment}\nServer: ${config.serverUrl}:${config.serverPort}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 32),
            if (isLoggedIn)
              Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/conversation');
                    },
                    icon: const Icon(Icons.forum),
                    label: const Text('Start Conversation'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/calls/incoming', arguments: {
                        'callId': 0,
                        'fromUserName': 'Demo Caller',
                      });
                    },
                    icon: const Icon(Icons.videocam),
                    label: const Text('Start video call'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/recognition');
                    },
                    icon: const Icon(Icons.back_hand),
                    label: const Text('Sign Recognition'),
                  ),
                  const SizedBox(height: 16),
                  // SOS emergency entry — below primary actions, above history (D-02)
                  Semantics(
                    label: 'Nút SOS khẩn cấp. Nhấn giữ 2 giây để bắt đầu.',
                    child: SizedBox(
                      height: 64,
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pushNamed('/sos');
                        },
                        icon: const Icon(
                          Icons.warning_rounded,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'SOS khẩn cấp',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFDC2626),
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Nhấn giữ 2 giây để bắt đầu',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/history');
                    },
                    icon: const Icon(Icons.history),
                    label: const Text('History'),
                  ),
                ],
              )
            else
              Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to login (to be implemented)
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Login not yet implemented. Please add auth token manually.',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.login),
                    label: const Text('Login'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Authentication required for recognition service',
                    style: TextStyle(color: Colors.orange),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            const Text(
              'Connect with others using Vietnamese Sign Language',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
