import 'package:flutter/material.dart';
import '../../../../core/widgets/smart_character_viewer.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../content/domain/entities/story_entity.dart';

class StoryPreviewScreen extends StatefulWidget {
  final StoryEntity story;

  const StoryPreviewScreen({super.key, required this.story});

  @override
  State<StoryPreviewScreen> createState() => _StoryPreviewScreenState();
}

class _StoryPreviewScreenState extends State<StoryPreviewScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('معاينة القصة (شكلها للطفل)'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // 3D Character Area
              Expanded(
                flex: 4,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(AppColors.border_radius),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: SmartCharacterViewer(
                    characterName: widget.story.characterName,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Story Text Area
              Expanded(
                flex: 5,
                child: Card(
                  elevation: 0,
                  margin: EdgeInsets.zero,
                  color: Theme.of(context).colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppColors.border_radius),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            if (widget.story.audioUrl != null && widget.story.audioUrl!.isNotEmpty)
                              IconButton.filledTonal(
                                icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                                onPressed: () async {
                                  if (_isPlaying) {
                                    await _audioPlayer.pause();
                                  } else {
                                    await _audioPlayer.play(UrlSource(widget.story.audioUrl!));
                                  }
                                },
                              ),
                            Expanded(
                              child: Text(
                                widget.story.title,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            if (widget.story.audioUrl != null && widget.story.audioUrl!.isNotEmpty)
                              const SizedBox(width: 48), // Balance the title centering
                          ],
                        ),
                        Divider(
                          height: 24,
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Text(
                              widget.story.content,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                height: 1.8,
                              ),
                              textAlign: TextAlign.justify,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Button Outside the Card
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('فهمت القصة!'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppColors.border_radius),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
