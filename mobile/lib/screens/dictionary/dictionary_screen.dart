import 'package:flutter/material.dart';
import 'package:mobile/screens/dictionary/dictionary_detail_screen.dart';
import 'package:mobile/services/dictionary_service.dart';

class DictionaryScreen extends StatefulWidget {
  const DictionaryScreen({
    super.key,
    required this.dictionaryService,
  });

  final DictionaryService dictionaryService;

  @override
  State<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  final TextEditingController _searchController = TextEditingController();
  DictionarySearchResult? _result;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({String? query, String? category}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.dictionaryService.searchSigns(query: query, category: category);
      if (!mounted) return;
      setState(() {
        _result = result;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            labelText: 'Search signs',
            suffixIcon: IconButton(
              onPressed: () => _load(query: _searchController.text.trim()),
              icon: const Icon(Icons.search),
            ),
          ),
          onSubmitted: (value) => _load(query: value.trim()),
        ),
        const SizedBox(height: 16),
        if (_loading) const Center(child: CircularProgressIndicator()),
        if (_error != null) Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(_error!, textAlign: TextAlign.center),
        ),
        if (!_loading && _error == null && result != null) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: result.categories.map((category) => ActionChip(
                  label: Text(category.name),
                  onPressed: () => _load(category: category.slug),
                )).toList(),
          ),
          const SizedBox(height: 16),
          if (result.entries.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Text('No signs found', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                  SizedBox(height: 8),
                  Text('Try another Vietnamese word or choose a category.', textAlign: TextAlign.center),
                ],
              ),
            )
          else
            ...result.entries.map((entry) => Card(
                  child: ListTile(
                    title: Text(entry.term),
                    subtitle: Text(entry.category.name),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final navigator = Navigator.of(context);
                      final detail = await widget.dictionaryService.getSignDetail(entry.slug);
                      if (!mounted) return;
                      await navigator.push(
                        MaterialPageRoute(
                          builder: (_) => DictionaryDetailScreen(detail: detail),
                        ),
                      );
                    },
                  ),
                )),
        ],
      ],
    );
  }
}
