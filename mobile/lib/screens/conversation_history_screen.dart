import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/models/conversation.dart';
import 'package:mobile/services/conversation_history_service.dart';

class ConversationHistoryScreen extends StatefulWidget {
  final ConversationHistoryService? historyService;

  const ConversationHistoryScreen({super.key, this.historyService});

  @override
  State<ConversationHistoryScreen> createState() =>
      _ConversationHistoryScreenState();
}

class _ConversationHistoryScreenState extends State<ConversationHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  ConversationHistoryService? _historyService;
  List<ConversationSession> _sessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final service =
        widget.historyService ?? await ConversationHistoryService.create();
    final sessions = await service.loadSessions();

    if (!mounted) {
      return;
    }

    setState(() {
      _historyService = service;
      _sessions = sessions;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: SearchBar(
                    controller: _searchController,
                    hintText: 'Search',
                    leading: const Icon(Icons.search),
                    trailing: [
                      IconButton(
                        tooltip: 'Clear',
                        onPressed: () {
                          _searchController.clear();
                          _runSearch('');
                        },
                        icon: const Icon(Icons.close),
                      ),
                    ],
                    onChanged: _runSearch,
                  ),
                ),
                Expanded(child: _buildSessionsList()),
              ],
            ),
    );
  }

  Widget _buildSessionsList() {
    if (_sessions.isEmpty) {
      return Center(
        child: Icon(
          Icons.history,
          size: 48,
          color: Theme.of(context).disabledColor,
        ),
      );
    }

    return ListView.separated(
      itemCount: _sessions.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final session = _sessions[index];
        return ListTile(
          leading: const Icon(Icons.forum),
          title: Text(_formatTimestamp(session.startedAt)),
          subtitle: Text(
            '${session.confirmedMessages.length} messages - ${session.preview}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _openDetail(session),
        );
      },
    );
  }

  Future<void> _runSearch(String query) async {
    final service = _historyService;
    if (service == null) {
      return;
    }

    final results = await service.searchSessions(query);
    if (mounted) {
      setState(() {
        _sessions = results;
      });
    }
  }

  void _openDetail(ConversationSession session) {
    final service = _historyService;
    if (service == null) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ConversationHistoryDetailScreen(
          session: session,
          service: service,
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime value) {
    final local = value.toLocal();
    String two(int number) => number.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }
}

class _ConversationHistoryDetailScreen extends StatelessWidget {
  final ConversationSession session;
  final ConversationHistoryService service;

  const _ConversationHistoryDetailScreen({
    required this.session,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transcript'),
        actions: [
          IconButton(
            tooltip: 'Copy',
            onPressed: () => _copyTranscript(context),
            icon: const Icon(Icons.copy),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: session.confirmedMessages.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final message = session.confirmedMessages[index];
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: message.role == ConversationRole.signer
                  ? Colors.green.withValues(alpha: 0.08)
                  : Colors.blue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: message.role == ConversationRole.signer
                    ? Colors.green.withValues(alpha: 0.24)
                    : Colors.blue.withValues(alpha: 0.24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      message.role.label,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      message.source.label,
                      style: TextStyle(color: Colors.grey[700], fontSize: 12),
                    ),
                    const Spacer(),
                    Text(
                      _formatTime(message.timestamp),
                      style: TextStyle(color: Colors.grey[700], fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(message.text, style: const TextStyle(fontSize: 16)),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _copyTranscript(BuildContext context) async {
    await Clipboard.setData(
      ClipboardData(text: service.formatSessionAsPlainText(session)),
    );

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Copied')));
    }
  }

  String _formatTime(DateTime value) {
    final local = value.toLocal();
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(local.hour)}:${two(local.minute)}';
  }
}
