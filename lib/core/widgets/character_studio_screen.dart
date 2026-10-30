import 'dart:async';

import 'package:Glow/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/content/data/models/custom_character_model.dart';
import '../../features/content/data/repositories/custom_character_repository.dart';
import '../animation/story_motion.dart';
import '../di/injection_container.dart';
import '../utils/character_helper.dart';
import '../utils/character_poses.dart';
import 'smart_character_viewer.dart';

enum _StudioMode { rigged, poses, legacy }

/// A backend-independent workbench for the same character used by stories.
class CharacterStudioScreen extends StatefulWidget {
  const CharacterStudioScreen({super.key});

  @override
  State<CharacterStudioScreen> createState() => _CharacterStudioScreenState();
}

class _CharacterStudioScreenState extends State<CharacterStudioScreen> {
  static const _ink = AppColors.onPrimary;
  static const _muted = AppColors.onSecondary;
  static const _sample =
      'مرحبا يا أصدقائي! مشى صديقنا إلى الحديقة. '
      'فكر كيف يساعد أصدقاءه؟ كان حزينا عندما خسر. '
      'ثم حاول من جديد وفاز! ضحك الجميع بسعادة.';

  final _storyController = TextEditingController(text: _sample);
  final _position = ValueNotifier(Duration.zero);
  final _clock = Stopwatch();
  late final Timer _timer;
  var _plan = StoryMotionPlan.fromText(_sample);
  var _storyText = _sample;
  var _basePosition = Duration.zero;
  var _character = 'port';
  CharacterMotion? _selectedMotion;
  var _referenceSequence = false;
  Duration get _playbackDuration => _referenceSequence
      ? Duration(seconds: referenceMotionSequence.length * 4)
      : _plan.duration;
  var _playing = true;
  var _isSpeaking = false;
  var _framing = 'body';
  var _cameraAngle = 0.0;
  var _autoBlink = true;
  var _blinkClosure = 0.0;
  var _clay = false;
  var _skeleton = false;
  var _showHat = false;
  var _showGlasses = true;
  var _showMuscles = true;
  var _hatColor = const Color(0xFF2C2C2E);
  var _mode = _StudioMode.rigged;
  var _pose = CharacterPoses.all.first;
  List<CustomCharacterModel> _customCharacters = const [];

  bool get _posesMode => _mode == _StudioMode.poses;
  bool get _rigged => _mode == _StudioMode.rigged;

  static const _hatColors = <Color>[
    Color(0xFF2C2C2E),
    Color(0xFF1A1A1A),
    Color(0xFF4A3728),
    Color(0xFF8B4513),
    Color(0xFFC0392B),
    Color(0xFF277A59),
    Color(0xFF2E86C1),
    Color(0xFFF5F5F5),
  ];

  @override
  void initState() {
    super.initState();
    _loadCustomCharacters();
    _clock.start();
    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!_playing) return;
      final duration = _playbackDuration.inMilliseconds;
      final elapsed = (_basePosition + _clock.elapsed).inMilliseconds;
      _position.value = Duration(
        milliseconds: duration > 0 ? elapsed % duration : elapsed,
      );
      _syncSequence(_position.value);
    });
  }

  Future<void> _loadCustomCharacters() async {
    if (!sl.isRegistered<CustomCharacterRepository>()) return;
    final repo = sl<CustomCharacterRepository>();
    setState(() => _customCharacters = repo.getCachedCharacters());
    final chars = await repo.fetchCharacters();
    if (!mounted) return;
    setState(() => _customCharacters = chars);
  }

  @override
  void dispose() {
    _timer.cancel();
    _clock.stop();
    _position.dispose();
    _storyController.dispose();
    super.dispose();
  }

  void _togglePlayback() {
    setState(() {
      _playing = !_playing;
      if (_playing) {
        _clock
          ..reset()
          ..start();
      } else {
        _basePosition = _position.value;
        _clock.stop();
      }
    });
  }

  void _seek(Duration position) {
    _basePosition = position;
    _position.value = position;
    _clock.reset();
    _syncSequence(position);
  }

  void _syncSequence(Duration position) {
    if (!_referenceSequence) return;
    final motion =
        referenceMotionSequence[(position.inMilliseconds ~/ 4000) %
            referenceMotionSequence.length];
    if (_selectedMotion != motion) setState(() => _selectedMotion = motion);
  }

  void _applyStory() {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _storyText = _storyController.text;
      _plan = StoryMotionPlan.fromText(_storyText);
      _selectedMotion = null;
      _referenceSequence = false;
      _seek(Duration.zero);
    });
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppColors.border_radius);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          foregroundColor: _ink,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: AppColors.inputBorder),
          ),
          title: const Text(
            'استوديو الشخصية',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          actions: [
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 12),
              child: TextButton(
                onPressed: () async {
                  await context.push('/custom-character-creator');
                  _loadCustomCharacters();
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(borderRadius: radius),
                ),
                child: const Text(
                  'اصنع شخصية',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth <= 0 || constraints.maxHeight <= 0) {
                return const SizedBox.shrink();
              }
              final wide = constraints.maxWidth >= 900;
              return SingleChildScrollView(
                padding: EdgeInsets.all(wide ? 28 : 16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1260),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'شخصية واحدة، بحكايات كثيرة.',
                          style: TextStyle(
                            color: _ink,
                            fontSize: 24,
                            height: 1.4,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'جرّب الحركة والتعبير واللون، ثم دع قصتك تقود المشهد.',
                          style: TextStyle(color: _muted, height: 1.6),
                        ),
                        const SizedBox(height: 20),
                        if (wide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _stage(570)),
                              const SizedBox(width: 22),
                              SizedBox(width: 350, child: _controls()),
                            ],
                          )
                        else ...[
                          _stage(
                            (constraints.maxWidth * 1.04).clamp(330.0, 480.0),
                          ),
                          const SizedBox(height: 18),
                          _controls(),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _stage(double height) {
    final radius = BorderRadius.circular(AppColors.border_radius);
    return Column(
      children: [
        Container(
          height: height,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: radius,
            color: AppColors.surface,
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              SmartCharacterViewer(
                characterName: _character,
                storyText: _storyText,
                isPlaying: _playing,
                isSpeaking: _isSpeaking,
                playbackPosition: _referenceSequence ? null : _position,
                motion: _selectedMotion,
                interactive: true,
                showSkeleton: _skeleton,
                showHat: _showHat,
                hatColor: _hatColor,
                showMuscles: _showMuscles,
                showGlasses: _showGlasses,
                framing: _framing,
                cameraAngle: _cameraAngle,
                autoBlink: _autoBlink,
                blink: _blinkClosure,
                clay: _clay,
                pose: _posesMode ? _pose.id : null,
                rigged: _rigged,
              ),
              PositionedDirectional(
                top: 16,
                start: 16,
                child: _badge(
                  label: switch (_mode) {
                    _StudioMode.poses =>
                      'الوضعيات · ${CharacterPoses.all.length} وضعية',
                    _StudioMode.rigged =>
                      'الشخصية الجديدة · ${CharacterMotion.values.length} حركات',
                    _StudioMode.legacy =>
                      'مجسم واحد · ${CharacterMotion.values.length} حركات وتعبيرات',
                  },
                ),
              ),
              PositionedDirectional(
                top: 16,
                end: 16,
                child: _posesMode
                    ? _badge(label: _pose.label)
                    : ValueListenableBuilder<Duration>(
                        valueListenable: _position,
                        builder: (context, position, child) => _badge(
                          label: _playing
                              ? (_selectedMotion ?? _plan.motionAt(position))
                                    .arabicLabel
                              : 'متوقف',
                        ),
                      ),
              ),
              // Floating quick actions on stage
              PositionedDirectional(
                top: 56,
                start: 16,
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _stageButton(
                      label: _framing == 'face' ? 'الوجه' : 'كامل الجسم',
                      active: _framing == 'face',
                      onTap: () => setState(
                        () => _framing = _framing == 'face' ? 'body' : 'face',
                      ),
                    ),
                    _stageButton(
                      label: _isSpeaking ? 'يتحدث' : 'تحدث',
                      active: _isSpeaking,
                      onTap: () => setState(() => _isSpeaking = !_isSpeaking),
                    ),
                  ],
                ),
              ),
              PositionedDirectional(
                bottom: 38,
                start: 0,
                end: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.94),
                      borderRadius: radius,
                      border: Border.all(color: AppColors.inputBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _angleChip('أمامي', 0),
                        _angleChip('مائل', -45),
                        _angleChip('جانبي', -90),
                        _angleChip('خلفي', 180),
                      ],
                    ),
                  ),
                ),
              ),
              const PositionedDirectional(
                bottom: 14,
                start: 0,
                end: 0,
                child: IgnorePointer(
                  child: Center(
                    child: Text(
                      'اسحب للتدوير • قرّب للتفاصيل والدقة',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 10,
                        shadows: [Shadow(color: Colors.white, blurRadius: 8)],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!_posesMode) ...[const SizedBox(height: 14), _playbackPanel()],
      ],
    );
  }

  Widget _modeSwitch() {
    final radius = BorderRadius.circular(AppColors.border_radius);
    return SegmentedButton<_StudioMode>(
      segments: const [
        ButtonSegment(
          value: _StudioMode.rigged,
          label: Text('الجديدة'),
        ),
        ButtonSegment(
          value: _StudioMode.poses,
          label: Text('الوضعيات'),
        ),
        ButtonSegment(
          value: _StudioMode.legacy,
          label: Text('القديمة'),
        ),
      ],
      selected: {_mode},
      showSelectedIcon: false,
      onSelectionChanged: (value) => setState(() => _mode = value.first),
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: AppColors.primary,
        selectedForegroundColor: Colors.white,
        foregroundColor: _ink,
        side: const BorderSide(color: AppColors.inputBorder),
        shape: RoundedRectangleBorder(borderRadius: radius),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }

  Widget _poseGrid() {
    final radius = BorderRadius.circular(AppColors.border_radius);
    return LayoutBuilder(
      builder: (context, constraints) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: CharacterPoses.all.map((pose) {
          final selected = _pose.id == pose.id;
          return SizedBox(
            width: (constraints.maxWidth - 16) / 3,
            child: Material(
              color: selected ? AppColors.primary : AppColors.background,
              borderRadius: radius,
              child: InkWell(
                borderRadius: radius,
                onTap: () => setState(() => _pose = pose),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 13,
                    horizontal: 6,
                  ),
                  child: Text(
                    pose.label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: selected ? Colors.white : _ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _playbackPanel() {
    final radius = BorderRadius.circular(AppColors.border_radius);
    return _panel(
      child: ValueListenableBuilder<Duration>(
        valueListenable: _position,
        builder: (context, position, child) {
          final cue = _plan.cueAt(position);
          final duration = _playbackDuration.inMilliseconds;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size(54, 48),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: radius),
                    ),
                    onPressed: _togglePlayback,
                    child: Text(
                      _playing ? 'إيقاف' : 'تشغيل',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: _ink,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 34),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () => _seek(Duration.zero),
                    child: const Text(
                      'إعادة',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_time(position)} / ${_time(_playbackDuration)}',
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(
                      fontSize: 12,
                      color: _muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.primary,
                  thumbColor: AppColors.primary,
                  inactiveTrackColor: AppColors.inputBorder,
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 6,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 14,
                  ),
                ),
                child: Slider(
                  value: duration > 0
                      ? (position.inMilliseconds / duration).clamp(0.0, 1.0)
                      : 0,
                  onChanged: duration > 0
                      ? (value) => _seek(
                          Duration(milliseconds: (value * duration).round()),
                        )
                      : null,
                  semanticFormatterCallback: (value) =>
                      '${(value * duration / 1000).round()} ثانية',
                ),
              ),
              Text(
                _selectedMotion == null
                    ? 'اللحظة الحالية'
                    : 'معاينة حركة يدوية',
                style: const TextStyle(
                  fontSize: 11,
                  color: _muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 44,
                child: Text(
                  _selectedMotion?.arabicLabel ??
                      cue?.text ??
                      'اكتب قصة قصيرة لبدء المشهد.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _ink, height: 1.5),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _controls() {
    final radius = BorderRadius.circular(AppColors.border_radius);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _modeSwitch(),
              const SizedBox(height: 22),
              _sectionTitle('الشخصية ولونها'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...CharacterHelper.characters.keys.map((key) {
                    final selected = _character == key;
                    return ChoiceChip(
                      label: Text(CharacterHelper.getCleanName(key)),
                      avatar: CircleAvatar(
                        backgroundColor: CharacterHelper.getColor(key),
                        radius: 10,
                      ),
                      selected: selected,
                      selectedColor: AppColors.secondaryContainer,
                      backgroundColor: AppColors.background,
                      shape: RoundedRectangleBorder(
                        borderRadius: radius,
                        side: BorderSide(
                          color: selected
                              ? AppColors.primary
                              : AppColors.inputBorder,
                        ),
                      ),
                      onSelected: (_) => setState(() => _character = key),
                    );
                  }),
                  ..._customCharacters.map((custom) {
                    final selected = _character == custom.name;
                    return ChoiceChip(
                      label: Text(custom.name),
                      avatar: CircleAvatar(
                        backgroundColor: custom.bodyColor,
                        radius: 10,
                      ),
                      selected: selected,
                      selectedColor: AppColors.secondaryContainer,
                      backgroundColor: AppColors.background,
                      shape: RoundedRectangleBorder(
                        borderRadius: radius,
                        side: BorderSide(
                          color: selected
                              ? AppColors.primary
                              : AppColors.inputBorder,
                        ),
                      ),
                      onSelected: (_) => setState(() {
                        _character = custom.name;
                        _showHat = custom.hasHat;
                        _hatColor = custom.hatColor;
                        _showGlasses = custom.hasGlasses;
                      }),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 22),
              _sectionTitle('زاوية الكاميرا والعرض'),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'body',
                      label: Text('كامل الجسم'),
                    ),
                    ButtonSegment(
                      value: 'face',
                      label: Text('تركيز على الوجه'),
                    ),
                  ],
                  selected: {_framing},
                  showSelectedIcon: false,
                  onSelectionChanged: (val) =>
                      setState(() => _framing = val.first),
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: AppColors.primary,
                    selectedForegroundColor: Colors.white,
                    foregroundColor: _ink,
                    side: const BorderSide(color: AppColors.inputBorder),
                    shape: RoundedRectangleBorder(borderRadius: radius),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _angleChip('أمامي 0°', 0),
                  _angleChip('مائل -45°', -45),
                  _angleChip('جانبي -90°', -90),
                  _angleChip('مائل 45°', 45),
                  _angleChip('خلفي 180°', 180),
                ],
              ),
              if (_posesMode) ...[
                const SizedBox(height: 22),
                _sectionTitle('الوضعيات'),
                const SizedBox(height: 12),
                _poseGrid(),
              ] else ...[
                const SizedBox(height: 22),
                _sectionTitle(
                  'الحركة والتعبير (${CharacterMotion.values.length} حركة)'),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => setState(() {
                      _referenceSequence = false;
                      _selectedMotion = null;
                      _seek(Duration.zero);
                    }),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      backgroundColor: _selectedMotion == null
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : AppColors.surface,
                      side: BorderSide(
                        color: _selectedMotion == null
                            ? AppColors.primary
                            : AppColors.inputBorder,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: radius),
                      padding: const EdgeInsets.all(13),
                    ),
                    child: const Text('تلقائي حسب القصة'),
                  ),
                ),
                const SizedBox(height: 10),
                LayoutBuilder(
                  builder: (context, constraints) => Column(
                    children: [
                      OutlinedButton(
                        onPressed: () => setState(() {
                          _referenceSequence = !_referenceSequence;
                          if (_referenceSequence) {
                            _selectedMotion = referenceMotionSequence.first;
                            _seek(Duration.zero);
                          }
                        }),
                        child: Text(
                          _referenceSequence
                              ? 'إيقاف العرض المتتابع'
                              : 'تشغيل حركات الصورة بالتتابع',
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
                LayoutBuilder(
                  builder: (context, constraints) => Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: CharacterMotion.values.map((motion) {
                      final selected = _selectedMotion == motion;
                      return SizedBox(
                        width: (constraints.maxWidth - 24) / 4,
                        child: Material(
                          color: selected
                              ? AppColors.primary
                              : AppColors.background,
                          borderRadius: radius,
                          child: InkWell(
                            borderRadius: radius,
                            onTap: () => setState(() {
                              _referenceSequence = false;
                              _selectedMotion = motion;
                            }),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                motion.arabicLabel,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: selected ? Colors.white : _ink,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 14),
                SwitchListTile.adaptive(
                  value: _isSpeaking,
                  onChanged: (value) => setState(() => _isSpeaking = value),
                  contentPadding: EdgeInsets.zero,
                  activeTrackColor: AppColors.primary,
                  title: const Text(
                    'حركة التحدث ونبضات الفم',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text(
                    'تفعيل حركة الشفاه والفك بنبضات الكلام للمعاينة',
                    style: TextStyle(color: _muted, fontSize: 11),
                  ),
                ),
                const SizedBox(height: 16),
                _sectionTitle('العيون والجفون'),
                const SizedBox(height: 8),
                SwitchListTile.adaptive(
                  value: _autoBlink,
                  onChanged: (value) => setState(() => _autoBlink = value),
                  contentPadding: EdgeInsets.zero,
                  activeTrackColor: AppColors.primary,
                  title: const Text(
                    'رمش تلقائي للعيون',
                    style: TextStyle(color: _ink, fontSize: 13),
                  ),
                  subtitle: const Text(
                    'حركات رمش طبيعية وتتبع النظر',
                    style: TextStyle(color: _muted, fontSize: 11),
                  ),
                ),
                if (!_autoBlink) ...[
                  const SizedBox(height: 6),
                  Text(
                    'إغلاق الجفن يدوياً: ${(_blinkClosure * 100).round()}%',
                    style: const TextStyle(color: _ink, fontSize: 12),
                  ),
                  Slider(
                    value: _blinkClosure,
                    min: 0.0,
                    max: 1.0,
                    activeColor: AppColors.primary,
                    onChanged: (val) => setState(() => _blinkClosure = val),
                  ),
                ],
                const SizedBox(height: 16),
                _sectionTitle('المظهر والمؤثرات'),
                const SizedBox(height: 8),
                SwitchListTile.adaptive(
                  value: _clay,
                  onChanged: (value) => setState(() => _clay = value),
                  contentPadding: EdgeInsets.zero,
                  activeTrackColor: AppColors.primary,
                  title: const Text(
                    'وضع الطين (Clay Shading)',
                    style: TextStyle(color: _ink, fontSize: 13),
                  ),
                  subtitle: const Text(
                    'فحص نحت الجسم والمجسم بدون خامات ملونة',
                    style: TextStyle(color: _muted, fontSize: 11),
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile.adaptive(
                  value: _showGlasses,
                  onChanged: (value) => setState(() => _showGlasses = value),
                  contentPadding: EdgeInsets.zero,
                  activeTrackColor: AppColors.primary,
                  title: const Text(
                    'إظهار النظارة',
                    style: TextStyle(color: _ink, fontSize: 13),
                  ),
                  subtitle: const Text(
                    'أضف إطار النظارة أو أخفه',
                    style: TextStyle(color: _muted, fontSize: 11),
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile.adaptive(
                  value: _showHat,
                  onChanged: (value) => setState(() => _showHat = value),
                  contentPadding: EdgeInsets.zero,
                  activeTrackColor: AppColors.primary,
                  title: const Text(
                    'إظهار الطاقية',
                    style: TextStyle(color: _ink, fontSize: 13),
                  ),
                  subtitle: const Text(
                    'أضف الطاقية أو أخفها',
                    style: TextStyle(color: _muted, fontSize: 11),
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile.adaptive(
                  value: _skeleton,
                  onChanged: (value) => setState(() => _skeleton = value),
                  contentPadding: EdgeInsets.zero,
                  activeTrackColor: AppColors.primary,
                  title: const Text(
                    'إظهار العظام',
                    style: TextStyle(color: _ink, fontSize: 13),
                  ),
                ),
                if (!_rigged) ...[
                  const SizedBox(height: 8),
                  SwitchListTile.adaptive(
                    value: _showMuscles,
                    onChanged: (value) => setState(() => _showMuscles = value),
                    contentPadding: EdgeInsets.zero,
                    activeTrackColor: AppColors.primary,
                    title: const Text(
                      'عضلات البطن',
                      style: TextStyle(color: _ink, fontSize: 13),
                    ),
                    subtitle: const Text(
                      'صدر وبطن على الجسم، وتقدر تشيلها',
                      style: TextStyle(color: _muted, fontSize: 11),
                    ),
                  ),
                ],
                if (_showHat && !_rigged) ...[
                  const SizedBox(height: 10),
                  const Text(
                    'لون الطاقية',
                    style: TextStyle(color: _ink, fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _hatColors.map((color) {
                      final selected = _hatColor.toARGB32() == color.toARGB32();
                      return Semantics(
                        button: true,
                        selected: selected,
                        label: 'لون الطاقية',
                        child: InkWell(
                          borderRadius: radius,
                          onTap: () => setState(() => _hatColor = color),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            height: 36,
                            width: 36,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: radius,
                              border: Border.all(
                                color: selected ? _ink : AppColors.inputBorder,
                                width: selected ? 2.2 : 1,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ],
          ),
        ),
        if (!_posesMode) ...[
          const SizedBox(height: 16),
          _panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _sectionTitle('جرّب حكايتك'),
                const SizedBox(height: 14),
                TextField(
                  controller: _storyController,
                  minLines: 4,
                  maxLines: 7,
                  maxLength: 2000,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 13,
                    height: 1.8,
                  ),
                  decoration: InputDecoration(
                    hintText: 'مرحبا! مشى صديقنا إلى الحديقة…',
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.all(14),
                    border: OutlineInputBorder(
                      borderRadius: radius,
                      borderSide: const BorderSide(
                        color: AppColors.inputBorder,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: radius,
                      borderSide: const BorderSide(
                        color: AppColors.inputBorder,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: radius,
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                FilledButton(
                  onPressed: _applyStory,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: radius),
                  ),
                  child: const Text('تطبيق القصة'),
                ),
                const SizedBox(height: 12),
                const Text(
                  'الحركات تتبع كلمات القصة بتوقيت تقريبي. '
                  'يمكنك اختيار الحركة يدويًا. حركة الفم للمعاينة '
                  'ولا تتزامن مع تسجيل صوتي.',
                  style: TextStyle(color: _muted, fontSize: 11, height: 1.7),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _panel({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.all(Radius.circular(AppColors.border_radius)),
      border: Border.all(color: AppColors.inputBorder),
    ),
    child: child,
  );

  Widget _sectionTitle(String title) => Text(
    title,
    style: const TextStyle(
      color: _ink,
      fontSize: 14,
      fontWeight: FontWeight.w700,
    ),
  );

  Widget _badge({required String label}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.surface.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(AppColors.border_radius),
      border: Border.all(color: AppColors.inputBorder),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: _ink,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  String _time(Duration time) =>
      '${time.inMinutes.toString().padLeft(2, '0')}:'
      '${(time.inSeconds % 60).toString().padLeft(2, '0')}';

  Widget _stageButton({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    final radius = BorderRadius.circular(AppColors.border_radius);
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
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: active ? Colors.white : _ink,
            ),
          ),
        ),
      ),
    );
  }

  Widget _angleChip(String label, double angle) {
    final active = _cameraAngle == angle;
    final radius = BorderRadius.circular(AppColors.border_radius);
    return InkWell(
      borderRadius: radius,
      onTap: () => setState(() => _cameraAngle = angle),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: radius,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : _ink,
          ),
        ),
      ),
    );
  }
}
