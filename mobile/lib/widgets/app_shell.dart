import 'package:flutter/material.dart';
import 'package:mobile/screens/dictionary/dictionary_screen.dart';
import 'package:mobile/screens/profile/profile_screen.dart';
import 'package:mobile/services/auth_service.dart';
import 'package:mobile/services/dictionary_service.dart';

enum VslSessionState { authenticated, expired }

class VslAppShell extends StatefulWidget {
  const VslAppShell({
    super.key,
    required this.authToken,
    required this.sessionState,
    this.dictionaryService,
    this.authService,
    this.communicateBuilder,
    this.sosBuilder,
  });

  final String authToken;
  final VslSessionState sessionState;
  final DictionaryService? dictionaryService;
  final AuthService? authService;
  final WidgetBuilder? communicateBuilder;
  final WidgetBuilder? sosBuilder;

  @override
  State<VslAppShell> createState() => _VslAppShellState();
}

class _VslAppShellState extends State<VslAppShell> {
  int _selectedIndex = 1;

  @override
  Widget build(BuildContext context) {
    if (widget.sessionState == VslSessionState.expired) {
      return Scaffold(
        appBar: AppBar(title: const Text('VSL Bridge')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Your session expired. Log in again to continue.'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {},
                child: const Text('Log in'),
              ),
            ],
          ),
        ),
      );
    }

    final destinations = const [
      NavigationDestination(
        icon: Icon(Icons.chat_bubble_outline, semanticLabel: 'Communicate'),
        label: 'Communicate',
      ),
      NavigationDestination(
        icon: Icon(Icons.menu_book_outlined, semanticLabel: 'Dictionary'),
        label: 'Dictionary',
      ),
      NavigationDestination(
        icon: Icon(Icons.sos, semanticLabel: 'SOS emergency'),
        label: 'SOS',
      ),
      NavigationDestination(
        icon: Icon(Icons.person_outline, semanticLabel: 'Profile'),
        label: 'Profile',
      ),
    ];

    final builtPages = [
      widget.communicateBuilder?.call(context) ??
          const _ShellPage(
            title: 'Messages',
            body: 'Conversation tools and History',
            secondaryLabel: 'History',
          ),
      widget.dictionaryService != null
          ? DictionaryScreen(dictionaryService: widget.dictionaryService!)
          : const _ShellPage(
              title: 'Sign library',
              body: 'Search signs and browse categories',
            ),
      widget.sosBuilder?.call(context) ??
          const _ShellPage(
            title: 'Emergency support',
            body: 'SOS emergency help and contacts',
          ),
      widget.authService != null
          ? ProfileScreen(authService: widget.authService!)
          : const _ShellPage(
              title: 'Account',
              body: 'Profile, account settings, and History',
              secondaryLabel: 'History',
            ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('VSL Bridge')),
      body: IndexedStack(
        index: _selectedIndex,
        children: builtPages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        destinations: destinations,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}

class _ShellPage extends StatelessWidget {
  const _ShellPage({
    required this.title,
    required this.body,
    this.secondaryLabel,
  });

  final String title;
  final String body;
  final String? secondaryLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: title,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title),
            const SizedBox(height: 8),
            Text(body, textAlign: TextAlign.center),
            if (secondaryLabel != null) ...[
              const SizedBox(height: 8),
              Text(secondaryLabel!),
            ],
          ],
        ),
      ),
    );
  }
}
