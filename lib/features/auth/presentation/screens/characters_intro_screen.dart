import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/animation/story_motion.dart';
import '../../../../core/audio/child_button_voice.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/smart_character_viewer.dart';

class _CharacterIntroSlide {
  const _CharacterIntroSlide({
    required this.characterKey,
    required this.description,
    required this.audioAsset,
    this.showHat = false,
    this.hatColor = const Color(0xFF2C2C2E),
    this.showGlasses = false,
    this.isFinalWelcome = false,
  });

  final String characterKey;
  final String description;
  final String audioAsset;
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
      description:
          'أهلاً يا صديقي! أنا فورت، البطل الشجاع. أحب المغامرات الجديدة، وسأكون معك دائماً لنتعلم الشجاعة والثقة بالنفس!',
      audioAsset: 'voice/onboarding/fort.mp3',
    ),
    _CharacterIntroSlide(
      characterKey: 'sort',
      description:
          'مرحباً بك! أنا سورت، صديقك الذكي. أحب الاكتشاف والتفكير في الحلول الذكية، وسنكتشف معاً أسراراً رائعة في كل قصة!',
      audioAsset: 'voice/onboarding/sort.mp3',
      showGlasses: true,
    ),
    _CharacterIntroSlide(
      characterKey: 'lort',
      description:
          'يا هلا بك! أنا لورت، أحب الهدوء والطبيعة ومساعدة الأصدقاء. معي ستتعلم كيف تكون صبوراً ومتعاوناً في كل تحدٍ!',
      audioAsset: 'voice/onboarding/lort.mp3',
    ),
    _CharacterIntroSlide(
      characterKey: 'mort',
      description:
          'أهلاً يا بطل! أنا مورت، أحب الفرح والابتسامة والإبداع. سأجعل كل حكاية مليئة بالمتعة والسعادة والخيال الجميل!',
      audioAsset: 'voice/onboarding/mort.mp3',
      showHat: true,
      hatColor: Color(0xFFB55D75),
    ),
    _CharacterIntroSlide(
      characterKey: 'port',
      description:
          'مرحباً يا صديقي! أنا بورت، نشيط ومليء بالحماس. أحب الحركة والعمل الجماعي، وسنحقق الفوز والنجاح معاً!',
      audioAsset: 'voice/onboarding/port.mp3',
    ),
    _CharacterIntroSlide(
      characterKey: 'qort',
      description:
          'أهلاً بك! أنا كورت، المستكشف الفضولي. أحب طرح الأسئلة وتعلم العادات الجميلة لنجمع الأوسمة ونصبح أبطالاً حقيقيين!',
      audioAsset: 'voice/onboarding/qort.mp3',
      showHat: true,
      hatColor: Color(0xFF4A90B8),
      showGlasses: true,
    ),
    _CharacterIntroSlide(
      characterKey: 'fort',
      description:
          'كل أصدقائك مستعدون للانطلاق معك في رحلة مليئة بالقصص الممتعة والتحديات الجميلة والأوسمة المميزة. اضغط «ابدأ الآن» لننطلق يا بطل!',
      audioAsset: 'voice/onboarding/welcome.mp3',
      isFinalWelcome: true,
    ),
  ];

  final AudioPlayer _voicePlayer = AudioPlayer()
    ..setReleaseMode(ReleaseMode.stop);
  final AudioPlayer _sfxPlayer = AudioPlayer()
    ..setReleaseMode(ReleaseMode.stop);

  StreamSubscription<void>? _completeSub;

  int _currentIndex = 0;
  bool _isSpeaking = false;
  bool _finishing = false;

  _CharacterIntroSlide get _currentSlide => _slides[_currentIndex];

  @override
  void initState() {
    super.initState();
    unawaited(ChildButtonVoice.stop());
    _completeSub = _voicePlayer.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _isSpeaking = false;
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _activateSlide(0);
    });
  }

  @override
  void dispose() {
    _completeSub?.cancel();
    _voicePlayer.dispose();
    _sfxPlayer.dispose();
    super.dispose();
  }

  Future<void> _activateSlide(int index) async {
    await _voicePlayer.stop();
    if (!mounted) return;

    setState(() {
      _currentIndex = index;
      _isSpeaking = false;
    });

    await _playCurrentSlideVoice();
  }

  Future<void> _playCurrentSlideVoice() async {
    if (!mounted) return;
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

  @override
  Widget build(BuildContext context) {
    final slide = _currentSlide;
    final radius = BorderRadius.circular(AppColors.border_radius);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 3D Character Stage (Smooth, Calm, White Background, No Border)
                Expanded(
                  child: _build3DStage(
                    slide: slide,
                    radius: radius,
                  ),
                ),
                const SizedBox(height: 14),

                // Bottom Section: Description & Navigation Buttons Only
                _buildBottomCard(
                  slide: slide,
                  radius: radius,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _build3DStage({
    required _CharacterIntroSlide slide,
    required BorderRadius radius,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: radius,
      ),
      clipBehavior: Clip.antiAlias,
      child: SmartCharacterViewer(
        characterName: slide.characterKey,
        isPlaying: true,
        isSpeaking: _isSpeaking,
        motion: CharacterMotion.idle,
        interactive: false,
        framing: 'body',
        cameraFit: 1.45,
        cameraAngle: 0.0,
        showHat: slide.showHat,
        hatColor: slide.hatColor,
        showGlasses: slide.showGlasses,
      ),
    );
  }

  Widget _buildBottomCard({
    required _CharacterIntroSlide slide,
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
          // Character Description
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: radius,
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: Text(
              slide.description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.6,
                fontWeight: FontWeight.w600,
                color: AppColors.onPrimary,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Navigation Buttons without icons
          Row(
            children: [
              if (_currentIndex > 0) ...[
                OutlinedButton(
                  onPressed: _finishing ? null : _onPreviousPressed,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.onPrimary,
                    backgroundColor: AppColors.surface,
                    side: const BorderSide(color: AppColors.inputBorder),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: radius),
                  ),
                  child: const Text(
                    'السابق',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: FilledButton(
                  onPressed: _finishing ? null : _onNextPressed,
                  style: FilledButton.styleFrom(
                    backgroundColor: slide.isFinalWelcome
                        ? AppColors.secondary
                        : AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: radius),
                  ),
                  child: Text(
                    slide.isFinalWelcome ? 'ابدأ الآن' : 'التالي',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
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
