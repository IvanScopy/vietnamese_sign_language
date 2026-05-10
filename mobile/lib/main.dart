import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile/config/app_config.dart';
import 'package:mobile/screens/recognition_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load configuration
  final config = AppConfig.load();

  // Get auth token from shared preferences
  final prefs = await SharedPreferences.getInstance();
  final authToken = prefs.getString('auth_token') ?? '';

  runApp(VSLBridgeApp(
    config: config,
    authToken: authToken,
  ));
}

class VSLBridgeApp extends StatelessWidget {
  final AppConfig config;
  final String authToken;

  const VSLBridgeApp({
    super.key,
    required this.config,
    required this.authToken,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VSL Bridge',
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
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  final AppConfig config;
  final String authToken;

  const HomeScreen({
    super.key,
    required this.config,
    required this.authToken,
  });

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
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushNamed('/recognition');
                },
                icon: const Icon(Icons.handshake),
                label: const Text('Start Sign Recognition'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              )
            else
              Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to login (to be implemented)
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Login not yet implemented. Please add auth token manually.'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.login),
                    label: const Text('Login'),
                    style: ElevatedButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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
