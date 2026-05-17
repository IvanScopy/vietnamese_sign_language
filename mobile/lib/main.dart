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
import 'package:mobile/services/auth_service.dart';
import 'package:mobile/services/call_api_service.dart';
import 'package:mobile/services/call_signaling_service.dart';
import 'package:mobile/services/dictionary_service.dart';
import 'package:mobile/services/livekit_call_service.dart';
import 'package:mobile/services/push_notification_service.dart';
import 'package:mobile/services/sos_api_service.dart';
import 'package:mobile/services/sos_location_service.dart';
import 'package:mobile/services/sos_platform_service.dart';
import 'package:mobile/widgets/app_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Global navigator key for push notification routing
final navigatorKey = GlobalKey<NavigatorState>();

int? _parseRouteInt(Object? value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  return null;
}

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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          error: const Color(0xFFDC2626),
        ),
        useMaterial3: true,
      ),
      home: VslAppShell(
        authToken: authToken,
        sessionState: authToken.isEmpty ? VslSessionState.expired : VslSessionState.authenticated,
        dictionaryService: DictionaryService(
          authToken: authToken,
          baseUrl: config.httpUrl,
        ),
        authService: AuthService(baseUrl: config.httpUrl),
        communicateBuilder: (_) => HomeScreen(config: config, authToken: authToken),
        sosBuilder: (_) => SosScreen(
          sosApiService: SosApiService(authToken: authToken, baseUrl: config.httpUrl),
          locationService: SosLocationService(),
          platformService: SosPlatformService(),
        ),
      ),
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
            final callId = _parseRouteInt(args?['callId']);
            final fromUserName = args?['fromUserName'] as String?;
            if (callId == null || callId < 1) {
              return MaterialPageRoute(
                builder: (_) => const Scaffold(
                  body: Center(child: Text('Invalid call notification')),
                ),
              );
            }
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
            final resultCallId = _parseRouteInt(args?['callId']);
            final transcript = args?['transcript'] as String?;
            return MaterialPageRoute(
              builder: (_) => CallResultScreen(
                callState: callState,
                callerName: callerName,
                callId: resultCallId,
                transcript: transcript,
                config: config,
                authToken: authToken,
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

typedef SelectCalleeId = Future<int?> Function(BuildContext context);

class HomeScreen extends StatelessWidget {
  final AppConfig config;
  final String authToken;
  final CallApiService? callApiService;
  final SelectCalleeId? selectCalleeId;

  const HomeScreen({
    super.key,
    required this.config,
    required this.authToken,
    this.callApiService,
    this.selectCalleeId,
  });

  Future<int?> _defaultSelectCalleeId(BuildContext context) async {
    final controller = TextEditingController();
    final rawInput = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Start video call'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Callee user ID',
            hintText: 'Enter a user ID',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('Start'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (rawInput == null) return null;

    final calleeId = int.tryParse(rawInput.trim());
    if (calleeId == null || calleeId < 1) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a valid callee user ID')),
        );
      }
      return null;
    }

    return calleeId;
  }

  Future<void> _startVideoCall(BuildContext context) async {
    final calleeId = await (selectCalleeId ?? _defaultSelectCalleeId)(context);
    if (calleeId == null) return;

    if (calleeId < 1) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a valid callee user ID')),
        );
      }
      return;
    }

    final ownsService = callApiService == null;
    final service = callApiService ??
        CallApiService(baseUrl: config.httpUrl, authToken: authToken);

    try {
      final session = await service.createCall(calleeId);
      if (!context.mounted) return;

      Navigator.of(context).pushNamed('/calls/outgoing', arguments: {
        'callId': session.callId,
        'calleeName': session.fromUserName ?? 'User $calleeId',
      });
    } on CallApiException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to start video call: $error')),
        );
      }
    } finally {
      if (ownsService) {
        service.dispose();
      }
    }
  }

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
                    onPressed: () => _startVideoCall(context),
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
