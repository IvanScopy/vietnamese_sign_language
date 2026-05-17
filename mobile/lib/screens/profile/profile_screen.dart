import 'package:flutter/material.dart';
import 'package:mobile/services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.authService,
  });

  final AuthService authService;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  AuthProfile? _profile;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await widget.authService.getProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is AuthException ? error.message : 'We could not load this content. Check your connection and try again.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final profile = _profile;
    if (profile == null) {
      return const Center(child: Text('Log in to continue.'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.name ?? 'No name set', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(profile.email),
                const SizedBox(height: 8),
                Text('User type: ${profile.userType}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Emergency contacts', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                if (profile.emergencyContacts.isEmpty)
                  const Text('No emergency contacts linked yet.')
                else
                  ...profile.emergencyContacts.map(
                    (contact) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('${contact['name']} - ${contact['phone']}'),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () async {
            await widget.authService.logout();
            if (!mounted) return;
            setState(() {
              _profile = null;
              _error = 'Your session expired. Log in again to continue.';
            });
          },
          child: const Text('Log out'),
        ),
      ],
    );
  }
}
