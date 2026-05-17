import 'package:flutter/material.dart';
import 'package:mobile/services/dictionary_service.dart';
import 'package:video_player/video_player.dart';

class DictionaryDetailScreen extends StatefulWidget {
  const DictionaryDetailScreen({
    super.key,
    required this.detail,
  });

  final DictionaryDetailResult detail;

  @override
  State<DictionaryDetailScreen> createState() => _DictionaryDetailScreenState();
}

class _DictionaryDetailScreenState extends State<DictionaryDetailScreen> {
  VideoPlayerController? _controller;
  String? _error;
  double _speed = 1;

  @override
  void initState() {
    super.initState();
    final source = widget.detail.entry.videoUrl;
    if (source == null || source.isEmpty) {
      _error = 'This video could not be loaded. Try again later.';
      return;
    }
    _controller = VideoPlayerController.networkUrl(Uri.parse(source))
      ..initialize().then((_) {
        if (mounted) setState(() {});
      }).catchError((_) {
        if (mounted) {
          setState(() {
            _error = 'This video could not be loaded. Try again later.';
          });
        }
      });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final entry = widget.detail.entry;
    return Scaffold(
      appBar: AppBar(title: Text(entry.term)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ColoredBox(
                color: Colors.black,
                child: _error != null
                    ? Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(_error!, style: const TextStyle(color: Colors.white))))
                    : controller == null || !controller.value.isInitialized
                        ? const Center(child: Text('Loading video...', style: TextStyle(color: Colors.white)))
                        : VideoPlayer(controller),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: controller == null ? null : () => controller.value.isPlaying ? controller.pause() : controller.play(),
                child: Text(controller?.value.isPlaying == true ? 'Pause' : 'Play'),
              ),
              OutlinedButton(
                onPressed: controller == null ? null : () {
                  controller.seekTo(Duration.zero);
                  controller.play();
                },
                child: const Text('Replay'),
              ),
              ...[0.5, 0.75, 1.0].map((speed) => ChoiceChip(
                    label: Text('${speed}x'),
                    selected: _speed == speed,
                    onSelected: controller == null
                        ? null
                        : (_) {
                            setState(() => _speed = speed);
                            controller.setPlaybackSpeed(speed);
                          },
                  )),
            ],
          ),
          const SizedBox(height: 16),
          Text(entry.term, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(entry.category.name),
          const SizedBox(height: 8),
          Text('Updated ${entry.updatedAt?.toLocal().toIso8601String() ?? 'Unknown'}'),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: entry.keywords.map((keyword) => Chip(label: Text(keyword))).toList(),
          ),
          const SizedBox(height: 16),
          Text('Related signs', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ...widget.detail.related.map((item) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(item.term),
                subtitle: Text(item.category.name),
              )),
        ],
      ),
    );
  }
}
