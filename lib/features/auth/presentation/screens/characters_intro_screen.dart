import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/animation/story_motion.dart';
import '../../../../core/audio/child_button_voice.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/character_helper.dart';
import '../../../../core/widgets/smart_character_viewer.dart';

class _CharacterIntroSlide {
  const _CharacterIntroSlide({
    required this.characterKey,
    required this.arabicName,
    required this.roleBadge,
    required this.description,
    required this.audioAsset,
    required this.primaryMotion,
    this.showHat = false,
    this.hatColor = const Color(0xFF2C2C2E),
    this.showGlasses = false,
    this.isFinalWelcome = false,
  });

  final String characterKey;
  final String arabicName;
  final String roleBadge;
  final String description;
  final String audioAsset;
  final CharacterMotion primaryMotion;
  final bool showHat;
  final Color hatColor;
  final bool showGlasses;
  final bool isFinalWelcome;
}

class CharactersIntroScreen extends StatefulWidget {
  const CharactersIntroScreen({super.key, this.nextRoute = '/role-selection'});

  static const String hiveSeenKey = 'CHARACTERS_INTRO_SEEN_V1';

  static bool hasSeen() {
    try {
      return Hive.box('auth').get(hiveSeenKey) == true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> markSeen() async {
    try {
      await Hive.box('auth').put(hiveSeenKey, true);
    } catch (_) {}
  }

  final String nextRoute;

  @override
  State<CharactersIntroScreen> createState() => _CharactersIntroScreenState();
}

class _CharactersIntroScreenState extends State<CharactersIntroScreen> {
  static const List<_CharacterIntroSlide> _slides = [
    _CharacterIntroSlide(
      characterKey: 'fort',
      arabicName: 'فورت (Fort)',
      roleBadge: 'البطل الشجاع',
      description:
          'أهلاً يا صديقي! أنا فورت، البطل الشجاع. أحب المغامرات الجديدة، وسأكون معك دائماً لنتعلم الشجاعة والثقة بالنفس!',
      audioAsset: 'voice/onboarding/fort.mp3',
      primaryMotion: CharacterMotion.victory,
    ),
    _CharacterIntroSlide(
      characterKey: 'sort',
      arabicName: 'سورت (Sort)',
      roleBadge: 'المفكر الذكي',
      description:
          'مرحباً بك! أنا سورت، صديقك الذكي. أحب الاكتشاف والتفكير في الحلول الذكية، وسنكتشف معاً أسراراً رائعة في كل قصة!',
      audioAsset: 'voice/onboarding/sort.mp3',
      primaryMotion: CharacterMotion.thinking,
      showGlasses: true,
    ),
    _CharacterIntroSlide(
      characterKey: 'lort',
      arabicName: 'لورت (Lort)',
      roleBadge: 'الصديق الهادئ والحكيم',
      description:
          'يا هلا بك! أنا لورت، أحب الهدوء والطبيعة ومساعدة الأصدقاء. معي ستتعلم كيف تكون صبوراً ومتعاوناً في كل تحدٍ!',
      audioAsset: 'voice/onboarding/lort.mp3',
      primaryMotion: CharacterMotion.smile,
    ),
    _CharacterIntroSlide(
      characterKey: 'mort',
      arabicName: 'مورت (Mort)',
      roleBadge: 'المرح والمبدع',
      description:
          'أهلاً يا بطل! أنا مورت، أحب الفرح والابتسامة والإبداع. سأجعل كل حكاية مليئة بالمتعة والسعادة والخيال الجميل!',
      audioAsset: 'voice/onboarding/mort.mp3',
      primaryMotion: CharacterMotion.laugh,
      showHat: true,
      hatColor: Color(0xFFB55D75),
    ),
    _CharacterIntroSlide(
      characterKey: 'port',
      arabicName: 'بورت (Port)',
      roleBadge: 'القوي والنشيط',
      description:
          'مرحباً يا صديقي! أنا بورت، نشيط ومليء بالحماس. أحب الحركة والعمل الجماعي، وسنحقق الفوز والنجاح معاً!',
      audioAsset: 'voice/onboarding/port.mp3',
      primaryMotion: CharacterMotion.walk,
    ),
    _CharacterIntroSlide(
      characterKey: 'qort',
      arabicName: 'كورت (Qort)',
      roleBadge: 'المستكشف الفضولي',
      description:
          'أهلاً بك! أنا كورت، المستكشف الفضولي. أحب طرح الأسئلة وتعلم العادات الجميلة لنجمع الأوسمة ونصبح أبطالاً حقيقيين!',
      audioAsset: 'voice/onboarding/qort.mp3',
      primaryMotion: CharacterMotion.happy,
      showHat: true,
      hatColor: Color(0xFF4A90B8),
      showGlasses: true,
    ),
    _CharacterIntroSlide(
      characterKey: 'fort',
      arabicName: 'أهلاً بك في عالم جلو!',
      roleBadge: 'رحلة الأبطال الصغار',
      description:
          'كل أصدقائك مستعدون للانطلاق معك في رحلة مليئة بالقصص الممتعة والتحديات الجميلة والأوسمة المميزة. اضغط «ابدأ الآن» لننطلق يا بطل!',
      audioAsset: 'voice/onboarding/welcome.mp3',
      primaryMotion: CharacterMotion.victory,
      isFinalWelcome: true,
    ),
  ];

  final AudioPlayer _voicePlayer = AudioPlayer()
    ..setReleaseMode(ReleaseMode.stop);
  final AudioPlayer _sfxPlayer = AudioPlayer()
    ..setReleaseMode(ReleaseMode.stop);
  final ValueNotifier<double> _angleNotifier = ValueNotifier<double>(0.0);

  StreamSubscription<void>? _completeSub;
  Timer? _rotationTimer;
  Timer? _waveTimer;

  int _currentIndex = 0;
  bool _isSpeaking = false;
  bool _isMuted = false;
  bool _autoRotate = true;
  bool _finishing = false;
  CharacterMotion _activeMotion = CharacterMotion.wave;
  String _welcomePreviewChar = 'fort';

  _CharacterIntroSlide get _currentSlide => _slides[_currentIndex];

  @override
  void initState() {
    super.initState();
    unawaited(ChildButtonVoice.stop());
    _completeSub = _voicePlayer.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _isSpeaking = false;
        _activeMotion = _currentSlide.primaryMotion;
      });
    });

    // Smooth continuous 3D auto-rotation ("يلف لوحده") isolated via ValueNotifier
    _rotationTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!mounted || !_autoRotate) return;
      final next = (_angleNotifier.value + 1.8) % 360.0;
      _angleNotifier.value = next;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _activateSlide(0);
    });
  }

  @override
  void dispose() {
    _rotationTimer?.cancel();
    _waveTimer?.cancel();
    _completeSub?.cancel();
    _angleNotifier.dispose();
    _voicePlayer.dispose();
    _sfxPlayer.dispose();
    super.dispose();
  }

  Future<void> _activateSlide(int index) async {
    _waveTimer?.cancel();
    await _voicePlayer.stop();
    if (!mounted) return;

    final slide = _slides[index];
    setState(() {
      _currentIndex = index;
      _activeMotion = CharacterMotion.wave;
      _isSpeaking = false;
      if (slide.isFinalWelcome) {
        _welcomePreviewChar = 'fort';
      }
    });

    // Switch from greeting wave to the character's signature motion
    _waveTimer = Timer(const Duration(milliseconds: 1600), () {
      if (!mounted || _currentIndex != index) return;
      setState(() {
        _activeMotion = slide.primaryMotion;
      });
    });

    if (!_isMuted) {
      await _playCurrentSlideVoice();
    }
  }

  Future<void> _playCurrentSlideVoice() async {
    if (_isMuted || !mounted) return;
    final slide = _currentSlide;
    try {
      await _voicePlayer.stop();
      setState(() => _isSpeaking = true);
      await _voicePlayer.play(AssetSource(slide.audioAsset));
    } catch (_) {
      if (mounted) {
        setState(() => _isSpeaking = false);
      }
    }
  }

  Future<void> _playLocalButtonClip(String assetPath) async {
    if (_isMuted) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource(assetPath));
    } catch (_) {}
  }

  Future<void> _onNextPressed() async {
    if (_finishing) return;
    HapticFeedback.lightImpact();

    if (_currentSlide.isFinalWelcome) {
      setState(() => _finishing = true);
      await _voicePlayer.stop();
      await CharactersIntroScreen.markSeen();
      await _playLocalButtonClip('voice/onboarding/start_now.mp3');
      await Future<void>.delayed(const Duration(milliseconds: 550));
      if (!mounted) return;
      context.go(widget.nextRoute);
      return;
    }

    unawaited(_playLocalButtonClip('voice/child/2fa619787bcb.mp3')); // "التالي"
    await _activateSlide(_currentIndex + 1);
  }

  Future<void> _onPreviousPressed() async {
    if (_currentIndex <= 0 || _finishing) return;
    HapticFeedback.selectionClick();
    unawaited(_playLocalButtonClip('voice/child/f533ebab64f4.mp3')); // "السابق"
    await _activateSlide(_currentIndex - 1);
  }

  Future<void> _onSkipToWelcome() async {
    if (_finishing) return;
    HapticFeedback.selectionClick();
    await _activateSlide(_slides.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    final slide = _currentSlide;
    final radius = BorderRadius.circular(AppColors.border_radius);
    final displayedCharKey = slide.isFinalWelcome
        ? _welcomePreviewChar
        : slide.characterKey;
    final charColor = CharacterHelper.getColor(displayedCharKey);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Top Header & Progress Indicator
                _buildTopBar(slide, radius),
                const SizedBox(height: 12),
                _buildStepProgressRow(radius),
                const SizedBox(height: 14),

                // 2. 3D Animated & Auto-Rotating Character Stage
                Expanded(
                  flex: 6,
                  child: _build3DStage(
                    slide: slide,
                    displayedCharKey: displayedCharKey,
                    charColor: charColor,
                    radius: radius,
                  ),
                ),
                const SizedBox(height: 14),

                // 3. Character Name, Spoken Description & Next / Start Now Button
                _buildBottomCard(
                  slide: slide,
                  charColor: charColor,
                  radius: radius,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(_CharacterIntroSlide slide, BorderRadius radius) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: radius,
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                slide.isFinalWelcome
                    ? 'البداية'
                    : 'تعرّف على الأبطال (${_currentIndex + 1}/${_slides.length - 1})',
                style: const TextStyle(
                  color: AppColors.onPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        // Mute / Unmute local voice button
        Material(
          color: AppColors.surface,
          borderRadius: radius,
          child: InkWell(
            borderRadius: radius,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _isMuted = !_isMuted);
              if (_isMuted) {
                _voicePlayer.stop();
                setState(() => _isSpeaking = false);
              } else {
                _playCurrentSlideVoice();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(color: AppColors.inputBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isMuted
                        ? Icons.volume_off_rounded
                        : Icons.volume_up_rounded,
                    size: 16,
                    color: _isMuted
                        ? AppColors.onSecondary
                        : AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isMuted ? 'صامت' : 'صوت محلي',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _isMuted
                          ? AppColors.onSecondary
                          : AppColors.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (!slide.isFinalWelcome) ...[
          const SizedBox(width: 8),
          Material(
            color: AppColors.surface,
            borderRadius: radius,
            child: InkWell(
              borderRadius: radius,
              onTap: _onSkipToWelcome,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  borderRadius: radius,
                  border: Border.all(color: AppColors.inputBorder),
                ),
                child: const Text(
                  'تخطي',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStepProgressRow(BorderRadius radius) {
    return Row(
      children: List.generate(_slides.length, (index) {
        final isActive = index == _currentIndex;
        final isDone = index < _currentIndex;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              _activateSlide(index);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              height: 6,
              margin: EdgeInsetsDirectional.only(
                end: index == _slides.length - 1 ? 0 : 6,
              ),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primary
                    : isDone
                        ? AppColors.secondary
                        : AppColors.inputBorder,
                borderRadius: radius,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _build3DStage({
    required _CharacterIntroSlide slide,
    required String displayedCharKey,
    required Color charColor,
    required BorderRadius radius,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: radius,
        border: Border.all(color: AppColors.inputBorder, width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Subtle top accent tint using character color + AppColors.surface
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    charColor.withValues(alpha: 0.10),
                    AppColors.surface,
                  ],
                ),
              ),
            ),
          ),

          // Single persistent 3D Viewer with smooth auto-rotation
          ValueListenableBuilder<double>(
            valueListenable: _angleNotifier,
            builder: (context, angle, _) {
              return SmartCharacterViewer(
                characterName: displayedCharKey,
                isPlaying: true,
                isSpeaking: _isSpeaking,
                motion: _activeMotion,
                interactive: true,
                framing: 'body',
                cameraAngle: angle,
                showHat: slide.showHat,
                hatColor: slide.hatColor,
                showGlasses: slide.showGlasses,
              );
            },
          ),

          // Top-right role badge + speaking wave indicator
          PositionedDirectional(
            top: 12,
            start: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.94),
                borderRadius: radius,
                border: Border.all(color: AppColors.inputBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: charColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    slide.roleBadge,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Top-left Auto-Rotate & Replay Voice controls
          PositionedDirectional(
            top: 12,
            end: 12,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _stageActionButton(
                  icon: Icons.threesixty_rounded,
                  label: _autoRotate ? 'يدور تلقائياً' : 'تدوير تلقائي',
                  active: _autoRotate,
                  radius: radius,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _autoRotate = !_autoRotate);
                  },
                ),
                const SizedBox(width: 6),
                _stageActionButton(
                  icon: _isSpeaking
                      ? Icons.graphic_eq_rounded
                      : Icons.replay_rounded,
                  label: _isSpeaking ? 'يتحدث...' : 'اسمعني',
                  active: _isSpeaking,
                  radius: radius,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    if (_isMuted) {
                      setState(() => _isMuted = false);
                    }
                    _playCurrentSlideVoice();
                  },
                ),
              ],
            ),
          ),

          // On the final welcome slide, show a character strip so the child can tap any friend!
          if (slide.isFinalWelcome)
            PositionedDirectional(
              bottom: 10,
              start: 12,
              end: 12,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.95),
                    borderRadius: radius,
                    border: Border.all(color: AppColors.inputBorder),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final item in _slides.where((s) => !s.isFinalWelcome))
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: InkWell(
                              borderRadius: radius,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _welcomePreviewChar = item.characterKey;
                                  _activeMotion = item.primaryMotion;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: _welcomePreviewChar == item.characterKey
                                      ? AppColors.primary
                                      : AppColors.background,
                                  borderRadius: radius,
                                  border: Border.all(
                                    color:
                                        _welcomePreviewChar == item.characterKey
                                            ? AppColors.primary
                                            : AppColors.inputBorder,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: CharacterHelper.getColor(
                                          item.characterKey,
                                        ),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      item.arabicName.split(' ').first,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: _welcomePreviewChar ==
                                                item.characterKey
                                            ? Colors.white
                                            : AppColors.onPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _stageActionButton({
    required IconData icon,
    required String label,
    required bool active,
    required BorderRadius radius,
    required VoidCallback onTap,
  }) {
    return Material(
      color: active
          ? AppColors.primary
          : AppColors.surface.withValues(alpha: 0.94),
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: active ? AppColors.primary : AppColors.inputBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: active ? Colors.white : AppColors.primary,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.white : AppColors.onPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomCard({
    required _CharacterIntroSlide slide,
    required Color charColor,
    required BorderRadius radius,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: radius,
        border: Border.all(color: AppColors.inputBorder, width: 1.2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Character Name Row
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: slide.isFinalWelcome
                      ? AppColors.primary.withValues(alpha: 0.14)
                      : charColor.withValues(alpha: 0.16),
                  borderRadius: radius,
                  border: Border.all(
                    color: slide.isFinalWelcome ? AppColors.primary : charColor,
                  ),
                ),
                child: Icon(
                  slide.isFinalWelcome
                      ? Icons.auto_awesome_rounded
                      : Icons.face_retouching_natural_rounded,
                  size: 20,
                  color: slide.isFinalWelcome ? AppColors.primary : charColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      slide.arabicName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      slide.roleBadge,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Tap to replay character voice
              IconButton(
                tooltip: 'إعادة سماع الوصف',
                onPressed: () {
                  HapticFeedback.lightImpact();
                  if (_isMuted) setState(() => _isMuted = false);
                  _playCurrentSlideVoice();
                },
                style: IconButton.styleFrom(
                  backgroundColor: _isSpeaking
                      ? AppColors.primary
                      : AppColors.background,
                  foregroundColor: _isSpeaking
                      ? Colors.white
                      : AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: radius,
                    side: BorderSide(
                      color: _isSpeaking
                          ? AppColors.primary
                          : AppColors.inputBorder,
                    ),
                  ),
                ),
                icon: Icon(
                  _isSpeaking
                      ? Icons.volume_up_rounded
                      : Icons.play_arrow_rounded,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Character Description Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: radius,
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: Text(
              slide.description,
              style: const TextStyle(
                fontSize: 14,
                height: 1.65,
                fontWeight: FontWeight.w600,
                color: AppColors.onPrimary,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Navigation Buttons Row ("السابق" + "التالي" / "ابدأ الآن")
          Row(
            children: [
              if (_currentIndex > 0) ...[
                OutlinedButton.icon(
                  onPressed: _finishing ? null : _onPreviousPressed,
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text(
                    'السابق',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.onPrimary,
                    backgroundColor: AppColors.surface,
                    side: const BorderSide(color: AppColors.inputBorder),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: radius),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: FilledButton.icon(
                  onPressed: _finishing ? null : _onNextPressed,
                  icon: Icon(
                    slide.isFinalWelcome
                        ? Icons.rocket_launch_rounded
                        : Icons.arrow_forward_rounded,
                    size: 19,
                  ),
                  label: Text(
                    slide.isFinalWelcome ? 'ابدأ الآن' : 'التالي',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: slide.isFinalWelcome
                        ? AppColors.secondary
                        : AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: radius),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
