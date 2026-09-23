import 'dart:async';

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

class _StoryPreviewScreenState extends State<StoryPreviewScreen>
    with WidgetsBindingObserver {
  AudioPlayer? _audioPlayer;
  final List<StreamSubscription<dynamic>> _audioSubscriptions = [];
  final ValueNotifier<Duration> _positionNotifier = ValueNotifier<Duration>(
    Duration.zero,
  );
  Future<void> _audioCommands = Future<void>.value();
  bool _isPlaying = false;
  bool _playRequested = false;
  bool _isAppActive = true;
  bool _loadingAudio = false;
  bool _hasLoadedAudio = false;
  bool _audioCompleted = false;
  int _audioGeneration = 0;

  bool get _hasAudioUrl => widget.story.audioUrl?.trim().isNotEmpty ?? false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _isAppActive = lifecycle == null || lifecycle == AppLifecycleState.resumed;
  }

  bool _isCurrentAudio(int generation) =>
      mounted && generation == _audioGeneration;

  Future<void> _loadAudio() async {
    if (_loadingAudio || _hasLoadedAudio || !_hasAudioUrl) return;
    final generation = ++_audioGeneration;
    _loadingAudio = true;
    final player = AudioPlayer();
    _audioPlayer = player;
    _audioSubscriptions.addAll([
      player.onPlayerStateChanged.listen((state) {
        if (_isCurrentAudio(generation)) {
          setState(() {
            _isPlaying =
                state == PlayerState.playing && _playRequested && _isAppActive;
          });
        }
      }),
      player.onPositionChanged.listen((position) {
        if (_isCurrentAudio(generation)) {
          _positionNotifier.value = position;
        }
      }, onError: (Object error) => _onAudioError(error, generation)),
      player.onPlayerComplete.listen((_) {
        if (_isCurrentAudio(generation)) {
          setState(() {
            _audioCompleted = true;
            _playRequested = false;
            _isPlaying = false;
          });
        }
      }, onError: (Object error) => _onAudioError(error, generation)),
    ]);
    try {
      await player.setReleaseMode(ReleaseMode.stop);
      if (!_isCurrentAudio(generation)) return;
      await player.setSourceUrl(widget.story.audioUrl!.trim());
      if (!_isCurrentAudio(generation)) return;
      _hasLoadedAudio = true;
      _loadingAudio = false;
      _syncPlayback();
    } catch (error) {
      if (_isCurrentAudio(generation)) _handleAudioError(error);
    }
  }

  void _onAudioError(Object error, int generation) {
    if (_isCurrentAudio(generation) && !_loadingAudio) {
      _handleAudioError(error);
    }
  }

  void _togglePlayPause() {
    setState(() => _playRequested = !_playRequested);
    if (!_hasLoadedAudio && _playRequested) {
      unawaited(_loadAudio());
    } else {
      _syncPlayback();
    }
  }

  void _syncPlayback() {
    if (!mounted) return;
    if (!_playRequested || !_isAppActive) {
      setState(() => _isPlaying = false);
    }
    final player = _audioPlayer;
    final generation = _audioGeneration;
    if (player == null || !_hasLoadedAudio) return;
    _audioCommands = _audioCommands.then((_) async {
      if (!_isCurrentAudio(generation)) return;
      try {
        if (_playRequested && _isAppActive) {
          if (_audioCompleted) {
            await player.seek(Duration.zero);
            if (!_isCurrentAudio(generation)) return;
            _audioCompleted = false;
            _positionNotifier.value = Duration.zero;
          }
          if (_playRequested && _isAppActive) await player.resume();
        } else {
          await player.pause();
        }
      } catch (error) {
        if (_isCurrentAudio(generation)) _handleAudioError(error);
      }
    });
  }

  void _handleAudioError(Object error) {
    debugPrint('Story preview audio failed: $error');
    _resetAudio();
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تعذّر تشغيل الصوت. حاول مرة أخرى.')),
    );
  }

  void _resetAudio({bool resetPosition = true}) {
    ++_audioGeneration;
    _playRequested = false;
    _isPlaying = false;
    _loadingAudio = false;
    _hasLoadedAudio = false;
    _audioCompleted = false;
    for (final subscription in _audioSubscriptions) {
      unawaited(subscription.cancel());
    }
    _audioSubscriptions.clear();
    final player = _audioPlayer;
    _audioPlayer = null;
    _audioCommands = Future<void>.value();
    if (player != null) unawaited(_disposePlayer(player));
    if (resetPosition) _positionNotifier.value = Duration.zero;
  }

  Future<void> _disposePlayer(AudioPlayer player) async {
    try {
      await player.dispose();
    } catch (error) {
      debugPrint('Story preview audio disposal failed: $error');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() => _isAppActive = state == AppLifecycleState.resumed);
    _syncPlayback();
  }

  @override
  void didUpdateWidget(covariant StoryPreviewScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.story != widget.story) _resetAudio();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _resetAudio(resetPosition: false);
    _positionNotifier.dispose();
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
                    color: Theme.of(context).colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(
                      AppColors.border_radius,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: SmartCharacterViewer(
                    characterName: widget.story.characterName,
                    storyText: '${widget.story.title}\n${widget.story.content}',
                    isPlaying: _hasAudioUrl ? _isPlaying : _isAppActive,
                    isSpeaking: _isPlaying,
                    playbackPosition: _hasAudioUrl ? _positionNotifier : null,
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
                    borderRadius: BorderRadius.circular(
                      AppColors.border_radius,
                    ),
                    side: BorderSide(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            if (_hasAudioUrl)
                              IconButton.filledTonal(
                                icon: Icon(
                                  (_loadingAudio ? _playRequested : _isPlaying)
                                      ? Icons.pause
                                      : Icons.play_arrow,
                                ),
                                onPressed: _togglePlayPause,
                              ),
                            Expanded(
                              child: Text(
                                widget.story.title,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            if (_hasAudioUrl)
                              const SizedBox(
                                width: 48,
                              ), // Balance the title centering
                          ],
                        ),
                        Divider(
                          height: 24,
                          color: Theme.of(
                            context,
                          ).colorScheme.outline.withValues(alpha: 0.2),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Text(
                              widget.story.content,
                              style: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.copyWith(height: 1.8),
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
                      borderRadius: BorderRadius.circular(
                        AppColors.border_radius,
                      ),
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
