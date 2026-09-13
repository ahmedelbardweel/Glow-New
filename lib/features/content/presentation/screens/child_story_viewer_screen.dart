import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/resource_manager.dart';
import '../../domain/entities/mission_entity.dart';
import '../../domain/entities/story_entity.dart';
import '../bloc/content_bloc.dart';
import '../bloc/content_event.dart';
import '../bloc/content_state.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/character_helper.dart';
import '../../../../core/widgets/shimmer_loading.dart';

class ChildStoryViewerScreen extends StatefulWidget {
  final MissionEntity mission;

  const ChildStoryViewerScreen({super.key, required this.mission});

  @override
  State<ChildStoryViewerScreen> createState() => _ChildStoryViewerScreenState();
}

class _ChildStoryViewerScreenState extends State<ChildStoryViewerScreen> {
  late ContentBloc _contentBloc;
  
  List<StoryEntity> _stories = [];
  int _currentIndex = 0;
  
  // Audio Player and Progress
  final AudioPlayer _audioPlayer = AudioPlayer();
  final ValueNotifier<Duration> _positionNotifier = ValueNotifier<Duration>(Duration.zero);
  bool _isPlaying = false;
  Duration _totalDuration = const Duration(seconds: 10); // default if no audio
  bool _hasAudio = false;
  bool _isMuted = false;
  
  Timer? _fallbackTimer;

  @override
  void initState() {
    super.initState();
    _contentBloc = sl<ContentBloc>();
    _contentBloc.add(ContentEvent.getStories(widget.mission.id));

    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted && _hasAudio) setState(() => _totalDuration = duration);
    });
    
    _audioPlayer.onPositionChanged.listen((position) {
      if (_hasAudio) _positionNotifier.value = position;
    });
    
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted && _hasAudio) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted && _hasAudio) _nextStory();
    });
  }

  void _startStory() async {
    _fallbackTimer?.cancel();
    _positionNotifier.value = Duration.zero;
    if (_stories.isEmpty) return;

    final currentStory = _stories[_currentIndex];
    final audioUrl = currentStory.audioUrl?.trim() ?? '';
    
    // Pre-cache next scene's audio in the background for instant transition
    if (_currentIndex + 1 < _stories.length) {
      final nextStory = _stories[_currentIndex + 1];
      final nextAudio = nextStory.audioUrl?.trim() ?? '';
      if (nextAudio.startsWith('http')) {
        sl<ResourceManager>().downloadAndCacheFile(nextAudio, folder: 'audio');
      }
    }

    if (audioUrl.isNotEmpty) {
      final resourceManager = sl<ResourceManager>();
      final localAudioPath = resourceManager.getLocalFilePath(audioUrl);

      if (localAudioPath != null) {
        _hasAudio = true;
        try {
          await _audioPlayer.setSource(DeviceFileSource(localAudioPath));
          await _audioPlayer.resume();
          return;
        } catch (_) {
          // If local play failed, fallback to url
        }
      }

      if (audioUrl.startsWith('http')) {
        _hasAudio = true;
        try {
          await _audioPlayer.setSourceUrl(audioUrl);
          await _audioPlayer.resume();
          // Cache in background for offline use
          resourceManager.downloadAndCacheFile(audioUrl, folder: 'audio');
          return;
        } catch (e) {
          _hasAudio = false;
          _audioPlayer.stop(); // Explicitly stop if error
          _startFallbackTimer();
          return;
        }
      }
    }

    // No audio to play for this scene
    _hasAudio = false;
    _audioPlayer.stop(); // Explicitly stop any currently playing audio
    _startFallbackTimer();
  }

  void _startFallbackTimer() {
    _totalDuration = const Duration(seconds: 10); // 10 seconds default viewing time
    _isPlaying = true;
    _positionNotifier.value = Duration.zero;
    _fallbackTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_isPlaying) return;
      final next = _positionNotifier.value + const Duration(milliseconds: 100);
      _positionNotifier.value = next;
      if (next >= _totalDuration) {
        timer.cancel();
        _nextStory();
      }
    });
  }

  void _togglePlayPause() {
    if (_hasAudio) {
      if (_isPlaying) {
        _audioPlayer.pause();
      } else {
        _audioPlayer.resume();
      }
    } else {
      setState(() {
        _isPlaying = !_isPlaying;
      });
    }
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _audioPlayer.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  void _replayStory() {
    if (_hasAudio) {
      _audioPlayer.seek(Duration.zero);
      _audioPlayer.resume();
    } else {
      _positionNotifier.value = Duration.zero;
      _isPlaying = true;
    }
  }

  void _restartMission() {
    setState(() {
      _currentIndex = 0;
    });
    _startStory();
  }

  void _nextStory() {
    if (_currentIndex < _stories.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _startStory();
    } else {
      // Finished all stories
      _audioPlayer.stop();
      _fallbackTimer?.cancel();
      context.pushReplacement('/child/quiz-intro', extra: widget.mission);
    }
  }

  void _previousStory() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _startStory();
    } else {
      _replayStory();
    }
  }

  @override
  void dispose() {
    _positionNotifier.dispose();
    _audioPlayer.dispose();
    _fallbackTimer?.cancel();
    _contentBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _contentBloc,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFE0F7FA), // Light Blue
                Color(0xFFF3E5F5), // Light Purple
                Color(0xFFFFF3E0), // Light Orange
              ],
            ),
          ),
          child: SafeArea(
          child: BlocConsumer<ContentBloc, ContentState>(
            listener: (context, state) {
              state.maybeWhen(
                storiesLoaded: (stories) {
                  if (stories.isNotEmpty) {
                    setState(() {
                      _stories = stories;
                      _currentIndex = 0;
                    });
                    _startStory();
                  }
                },
                orElse: () {},
              );
            },
            builder: (context, state) {
              return state.maybeWhen(
                loading: () => const ShimmerLoading(type: ShimmerType.card),
                error: (msg) => Center(child: Text('خطأ: $msg', style: const TextStyle(color: Colors.red))),
                storiesLoaded: (stories) {
                  if (stories.isEmpty) {
                    return const Center(
                      child: Text(
                        'لا توجد قصص في هذه المهمة بعد.',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    );
                  }

                  final story = _stories[_currentIndex];

                  return Column(
                    children: [
                      // Top Bar (Segmented Progress + Title + Back Button)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Column(
                          children: [
                            // Progress Bars
                            Row(
                              children: List.generate(_stories.length, (index) {
                                return Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                                    child: _buildProgressBar(index, CharacterHelper.getColor(story.characterName)),
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: 16),
                            // Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Action Buttons (Left)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(AppColors.border_radius),
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
                                    ],
                                  ),
                                  child: const Text(
                                    'مغامرة',
                                    style: TextStyle(color: Color(0xFF2C3E50), fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                // Title & Scene Text
                                Column(
                                  children: [
                                    Text(
                                      widget.mission.title,
                                      style: const TextStyle(
                                        color: Color(0xFF2C3E50),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    Text(
                                      'مشهد ${_currentIndex + 1} من ${_stories.length}',
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                // Back Button (Right)
                                GestureDetector(
                                  onTap: () {
                                    _audioPlayer.stop();
                                    context.pop();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(AppColors.border_radius),
                                      boxShadow: [
                                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
                                      ],
                                    ),
                                    child: const Text(
                                      'رجوع',
                                      style: TextStyle(color: Color(0xFF2C3E50), fontSize: 14, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 8),

                      // Interactive Tap Areas & 3D Character
                      Expanded(
                        child: Stack(
                          children: [
                            // 3D Character Viewer
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(AppColors.border_radius),
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: CharacterHelper.getColor(story.characterName).withOpacity(0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(AppColors.border_radius),
                                child: RepaintBoundary(
                                  child: Flutter3DViewer(
                                    key: ValueKey(story.characterName),
                                    src: CharacterHelper.getModelPath(story.characterName),
                                  ),
                                ),
                              ),
                            ),
                            // Tap Gestures
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: _previousStory,
                                    behavior: HitTestBehavior.translucent,
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: _togglePlayPause,
                                    behavior: HitTestBehavior.translucent,
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: _currentIndex < _stories.length - 1 ? _nextStory : null,
                                    behavior: HitTestBehavior.translucent,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Text and Controls Area
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppColors.border_radius),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _isPlaying ? 'جارٍ القراءة...' : 'متوقف مؤقتاً',
                                  style: TextStyle(
                                    color: _isPlaying ? Colors.green : Colors.orange, 
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: CharacterHelper.getColor(story.characterName),
                                    borderRadius: BorderRadius.circular(AppColors.border_radius),
                                  ),
                                  child: Text(
                                    CharacterHelper.getCleanName(story.characterName),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              story.content,
                              style: const TextStyle(
                                color: Color(0xFF2C3E50),
                                fontSize: 14,
                                height: 1.6,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.right,
                              textDirection: TextDirection.rtl,
                            ),
                            const SizedBox(height: 24),
                            // Media Controls
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(AppColors.border_radius),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_hasAudio) ...[
                                      IconButton(
                                        icon: Icon(_isMuted ? Icons.volume_off : Icons.volume_up, color: CharacterHelper.getColor(story.characterName)),
                                        onPressed: _toggleMute,
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    IconButton(
                                      icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: CharacterHelper.getColor(story.characterName)),
                                      onPressed: _togglePlayPause,
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: Icon(Icons.replay, color: CharacterHelper.getColor(story.characterName)),
                                      onPressed: _restartMission,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Bottom Action Button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: FilledButton(
                            onPressed: () {
                              if (_currentIndex < _stories.length - 1) {
                                _nextStory();
                              } else {
                                _audioPlayer.stop();
                                context.pushReplacement('/child/quiz-intro', extra: widget.mission);
                              }
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: CharacterHelper.getColor(story.characterName),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppColors.border_radius),
                              ),
                            ),
                            child: Text(
                              _currentIndex < _stories.length - 1 ? 'متابعة المشهد' : 'إنهاء القصة والتحدي',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
                orElse: () => const SizedBox(),
              );
            },
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildProgressBar(int index, Color charColor) {
    if (index < _currentIndex) {
      return Container(
        height: 6,
        decoration: BoxDecoration(
          color: charColor,
          borderRadius: BorderRadius.circular(AppColors.border_radius),
        ),
      );
    } else if (index > _currentIndex) {
      return Container(
        height: 6,
        decoration: BoxDecoration(
          color: const Color(0x1A000000),
          borderRadius: BorderRadius.circular(AppColors.border_radius),
        ),
      );
    }

    return ValueListenableBuilder<Duration>(
      valueListenable: _positionNotifier,
      builder: (context, pos, _) {
        double percent = 0.0;
        if (_totalDuration.inMilliseconds > 0) {
          percent = (pos.inMilliseconds / _totalDuration.inMilliseconds).clamp(0.0, 1.0);
        }

        return Container(
          height: 6,
          decoration: BoxDecoration(
            color: const Color(0x1A000000),
            borderRadius: BorderRadius.circular(AppColors.border_radius),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppColors.border_radius),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(charColor),
            ),
          ),
        );
      },
    );
  }
}

