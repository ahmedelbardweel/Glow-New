import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/animation/story_motion.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/color_wheel_picker.dart';
import '../../../../core/widgets/smart_character_viewer.dart';
import '../../data/models/custom_character_model.dart';
import '../../data/repositories/custom_character_repository.dart';

enum _ColorTarget { body, belly, hat }

enum _CreatorSection { colors, accessories, saved }

class _CharacterDraft {
  final Color bodyColor;
  final Color bellyColor;
  final Color hatColor;
  final bool customBelly;
  final bool hasHat;
  final bool hasGlasses;
  final String framing;
  final double cameraAngle;
  final CharacterMotion motion;

  const _CharacterDraft({
    required this.bodyColor,
    required this.bellyColor,
    required this.hatColor,
    required this.customBelly,
    required this.hasHat,
    required this.hasGlasses,
    this.framing = 'body',
    this.cameraAngle = 0.0,
    this.motion = CharacterMotion.idle,
  });

  _CharacterDraft copyWith({
    Color? bodyColor,
    Color? bellyColor,
    Color? hatColor,
    bool? customBelly,
    bool? hasHat,
    bool? hasGlasses,
    String? framing,
    double? cameraAngle,
    CharacterMotion? motion,
  }) {
    return _CharacterDraft(
      bodyColor: bodyColor ?? this.bodyColor,
      bellyColor: bellyColor ?? this.bellyColor,
      hatColor: hatColor ?? this.hatColor,
      customBelly: customBelly ?? this.customBelly,
      hasHat: hasHat ?? this.hasHat,
      hasGlasses: hasGlasses ?? this.hasGlasses,
      framing: framing ?? this.framing,
      cameraAngle: cameraAngle ?? this.cameraAngle,
      motion: motion ?? this.motion,
    );
  }
}

class CustomCharacterCreatorScreen extends StatefulWidget {
  final CustomCharacterModel? characterToEdit;

  const CustomCharacterCreatorScreen({
    super.key,
    this.characterToEdit,
  });

  @override
  State<CustomCharacterCreatorScreen> createState() =>
      _CustomCharacterCreatorScreenState();
}

class _CustomCharacterCreatorScreenState
    extends State<CustomCharacterCreatorScreen> {
  static const Color _defaultBodyColor = Color(0xFF28542F);
  static const Color _defaultBellyColor = Color(0xFFEFECE6);
  static const Color _defaultHatColor = Color(0xFF001946);

  static const List<Color> _bodyPresets = [
    Color(0xFF28542F), // Emerald
    Color(0xFF912740), // Ruby
    Color(0xFF4A90B8), // Sky Blue
    Color(0xFFD09236), // Golden Amber
    Color(0xFFB55D75), // Berry Rose
    Color(0xFF6E8B62), // Sage
    Color(0xFFFFB300), // App Primary
    Color(0xFF001946), // App Secondary
    Color(0xFF34A853), // App Tertiary
    Color(0xFFFF9800), // Orange
    Color(0xFF6B1A2A), // Burgundy
    Color(0xFF8FA698), // Clay Neutral
  ];

  static const List<Color> _bellyPresets = [
    Color(0xFFEFECE6), // Default Cream
    Color(0xFFFFF8E7), // Warm Ivory
    Color(0xFFFFE082), // Soft Gold
    Color(0xFFD6E4FF), // Soft Sky
    Color(0xFFB9F6CA), // Soft Mint
    Color(0xFFFCE4EC), // Soft Pink
    Color(0xFFEDE7F6), // Soft Lavender
    Color(0xFFE2E8F0), // Cool Grey
    Color(0xFFD9A9B2), // App Pink
    Color(0xFFFFCCBC), // Soft Peach
    Color(0xFFFFFFFF), // Pure White
    Color(0xFFD7CCC8), // Warm Sand
  ];

  static const List<Color> _hatPresets = [
    Color(0xFF001946), // Navy
    Color(0xFF2C2C2E), // Charcoal
    Color(0xFFFFB300), // Gold
    Color(0xFF912740), // Crimson
    Color(0xFF28542F), // Forest
    Color(0xFF4A90B8), // Ocean
    Color(0xFF6B1A2A), // Burgundy
    Color(0xFF34A853), // Green
    Color(0xFFFF9800), // Orange
    Color(0xFF4A3728), // Brown
    Color(0xFFD9A9B2), // Rose
    Color(0xFFF8FAFC), // White
  ];

  final _nameController = TextEditingController();
  late final ValueNotifier<_CharacterDraft> _draft;

  String? _editingId;
  DateTime? _editingCreatedAt;
  _ColorTarget _selectedTarget = _ColorTarget.body;
  _CreatorSection _activeSection = _CreatorSection.colors;
  bool _isSaving = false;
  List<CustomCharacterModel> _savedCharacters = const [];

  @override
  void initState() {
    super.initState();
    final edit = widget.characterToEdit;
    if (edit != null) {
      _editingId = edit.id;
      _editingCreatedAt = edit.createdAt;
      _nameController.text = edit.name;
      _draft = ValueNotifier(
        _CharacterDraft(
          bodyColor: edit.bodyColor,
          bellyColor: edit.bellyColor,
          hatColor: edit.hatColor,
          customBelly:
              edit.bellyColorHex.toUpperCase() != '#EFECE6',
          hasHat: edit.hasHat,
          hasGlasses: edit.hasGlasses,
        ),
      );
    } else {
      _draft = ValueNotifier(
        const _CharacterDraft(
          bodyColor: _defaultBodyColor,
          bellyColor: _defaultBellyColor,
          hatColor: _defaultHatColor,
          customBelly: false,
          hasHat: false,
          hasGlasses: false,
        ),
      );
    }
    _loadSavedCharacters();
  }

  void _loadSavedCharacters() {
    try {
      final repo = sl<CustomCharacterRepository>();
      setState(() {
        _savedCharacters = repo.getCachedCharacters();
      });
      repo.fetchCharacters().then((list) {
        if (mounted) {
          setState(() {
            _savedCharacters = list;
          });
        }
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _draft.dispose();
    super.dispose();
  }

  void _resetToRaw({bool clearEditing = false}) {
    if (clearEditing) {
      _editingId = null;
      _editingCreatedAt = null;
      _nameController.clear();
    }
    _draft.value = const _CharacterDraft(
      bodyColor: _defaultBodyColor,
      bellyColor: _defaultBellyColor,
      hatColor: _defaultHatColor,
      customBelly: false,
      hasHat: false,
      hasGlasses: false,
    );
    setState(() {
      _selectedTarget = _ColorTarget.body;
    });
  }

  void _randomizeCharacter() {
    final rng = math.Random();
    final body = _bodyPresets[rng.nextInt(_bodyPresets.length)];
    final belly = _bellyPresets[rng.nextInt(_bellyPresets.length)];
    final hat = _hatPresets[rng.nextInt(_hatPresets.length)];
    final hasHat = rng.nextBool();
    final hasGlasses = rng.nextBool();
    final motions = [
      CharacterMotion.idle,
      CharacterMotion.wave,
      CharacterMotion.happy,
      CharacterMotion.smile,
      CharacterMotion.victory,
    ];
    _draft.value = _draft.value.copyWith(
      bodyColor: body,
      bellyColor: belly,
      hatColor: hat,
      customBelly: belly.toARGB32() != _defaultBellyColor.toARGB32(),
      hasHat: hasHat,
      hasGlasses: hasGlasses,
      motion: motions[rng.nextInt(motions.length)],
    );
    setState(() {
      if (!hasHat && _selectedTarget == _ColorTarget.hat) {
        _selectedTarget = _ColorTarget.body;
      }
    });
  }

  void _loadCharacterForEdit(CustomCharacterModel character) {
    _editingId = character.id;
    _editingCreatedAt = character.createdAt;
    _nameController.text = character.name;
    _draft.value = _draft.value.copyWith(
      bodyColor: character.bodyColor,
      bellyColor: character.bellyColor,
      hatColor: character.hatColor,
      customBelly: character.bellyColorHex.toUpperCase() != '#EFECE6',
      hasHat: character.hasHat,
      hasGlasses: character.hasGlasses,
    );
    setState(() {
      _selectedTarget = _ColorTarget.body;
      _activeSection = _CreatorSection.colors;
    });
  }

  Future<void> _deleteSavedCharacter(CustomCharacterModel character) async {
    try {
      await sl<CustomCharacterRepository>().deleteCharacter(character.id);
      if (!mounted) return;
      if (_editingId == character.id) {
        _editingId = null;
        _editingCreatedAt = null;
      }
      _loadSavedCharacters();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم حذف الشخصية «${character.name}»'),
          backgroundColor: AppColors.secondary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر حذف الشخصية: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Color _colorForTarget(_CharacterDraft draft, _ColorTarget target) {
    switch (target) {
      case _ColorTarget.body:
        return draft.bodyColor;
      case _ColorTarget.belly:
        return draft.bellyColor;
      case _ColorTarget.hat:
        return draft.hatColor;
    }
  }

  List<Color> get _presetsForSelectedTarget {
    switch (_selectedTarget) {
      case _ColorTarget.body:
        return _bodyPresets;
      case _ColorTarget.belly:
        return _bellyPresets;
      case _ColorTarget.hat:
        return _hatPresets;
    }
  }

  String get _labelForSelectedTarget {
    switch (_selectedTarget) {
      case _ColorTarget.body:
        return 'لون الجسم الأساسي';
      case _ColorTarget.belly:
        return 'لون البطن الكريمي';
      case _ColorTarget.hat:
        return 'لون الطاقية';
    }
  }

  void _onColorChanged(Color color) {
    final current = _draft.value;
    switch (_selectedTarget) {
      case _ColorTarget.body:
        _draft.value = current.copyWith(bodyColor: color);
        break;
      case _ColorTarget.belly:
        _draft.value = current.copyWith(
          bellyColor: color,
          customBelly: true,
        );
        break;
      case _ColorTarget.hat:
        _draft.value = current.copyWith(
          hatColor: color,
          hasHat: true,
        );
        break;
    }
  }

  Future<void> _saveAndApply({bool saveAsNew = false}) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى كتابة اسم للشخصية قبل الحفظ'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final d = _draft.value;
    final isNew = saveAsNew || _editingId == null;
    final character = CustomCharacterModel(
      id: isNew
          ? 'char_${DateTime.now().millisecondsSinceEpoch}'
          : _editingId!,
      name: name,
      bodyColorHex: CustomCharacterModel.colorToHex(d.bodyColor),
      bellyColorHex: CustomCharacterModel.colorToHex(
        d.customBelly ? d.bellyColor : _defaultBellyColor,
      ),
      hasHat: d.hasHat,
      hatColorHex: CustomCharacterModel.colorToHex(d.hatColor),
      hasGlasses: d.hasGlasses,
      createdAt: isNew ? DateTime.now() : (_editingCreatedAt ?? DateTime.now()),
    );

    try {
      await sl<CustomCharacterRepository>().saveCharacter(character);
      if (!mounted) return;
      _loadSavedCharacters();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم حفظ الشخصية «$name» بنجاح!'),
          backgroundColor: AppColors.tertiary,
        ),
      );
      Navigator.of(context).pop(character);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء الحفظ: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppColors.border_radius);

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.secondary,
        title: Text(
          _editingId != null ? 'تعديل الشخصية' : 'اصنع شخصيتك',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
            color: AppColors.secondary,
          ),
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.inputBorder),
        ),
        actions: [
          // Randomize button
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: OutlinedButton(
              onPressed: _randomizeCharacter,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.secondary,
                backgroundColor: AppColors.surface,
                side: const BorderSide(color: AppColors.inputBorder),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                shape: RoundedRectangleBorder(borderRadius: radius),
              ),
              child: const Text(
                'عشوائي',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Reset button
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.secondary,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 34),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            onPressed: () => _resetToRaw(clearEditing: false),
            child: const Text(
              'إعادة ضبط',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Column(
            children: [
              // ============================================================
              // 1. TOP HALF: INTERACTIVE 3D STAGE (ZERO-RELOAD)
              // ============================================================
              Expanded(
                flex: 46,
                child: DragTarget<String>(
                  onWillAcceptWithDetails: (details) =>
                      details.data == 'glasses' || details.data == 'hat',
                  onAcceptWithDetails: (details) {
                    if (details.data == 'glasses') {
                      _draft.value = _draft.value.copyWith(hasGlasses: true);
                    } else if (details.data == 'hat') {
                      _draft.value = _draft.value.copyWith(hasHat: true);
                      setState(() {
                        _selectedTarget = _ColorTarget.hat;
                      });
                    }
                  },
                  builder: (context, candidateData, rejectedData) {
                    final isHovered = candidateData.isNotEmpty;
                    return Container(
                      margin: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: radius,
                        border: Border.all(
                          color: isHovered
                              ? AppColors.primary
                              : AppColors.inputBorder,
                          width: isHovered ? 2.5 : 1,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: ValueListenableBuilder<_CharacterDraft>(
                        valueListenable: _draft,
                        builder: (context, draft, _) {
                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              // 3D Character Viewer with constant Key — never reloads WebView/ThreeJS on state updates
                              SmartCharacterViewer(
                                key: const ValueKey(
                                  'custom_character_creator_stage_viewer',
                                ),
                                characterName: 'port',
                                bodyColor: draft.bodyColor,
                                bellyColor:
                                    draft.customBelly ? draft.bellyColor : null,
                                showHat: draft.hasHat,
                                hatColor: draft.hatColor,
                                showGlasses: draft.hasGlasses,
                                framing: draft.framing,
                                cameraAngle: draft.cameraAngle,
                                motion: draft.motion,
                                cameraFit: 1.12,
                                autoBlink: true,
                                isPlaying: true,
                                interactive: true,
                              ),

                              // Top-Right: Active Accessories & Rotate Hint
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.background,
                                        borderRadius: radius,
                                        border: Border.all(
                                          color: AppColors.inputBorder,
                                        ),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'اسحب للتدوير',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.secondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (draft.hasHat) ...[
                                      const SizedBox(width: 4),
                                      _buildStageQuickBadge(
                                        label: 'طاقية',
                                        onRemove: () {
                                          _draft.value =
                                              draft.copyWith(hasHat: false);
                                          if (_selectedTarget ==
                                              _ColorTarget.hat) {
                                            setState(() {
                                              _selectedTarget =
                                                  _ColorTarget.body;
                                            });
                                          }
                                        },
                                      ),
                                    ],
                                    if (draft.hasGlasses) ...[
                                      const SizedBox(width: 4),
                                      _buildStageQuickBadge(
                                        label: 'نظارة',
                                        onRemove: () {
                                          _draft.value =
                                              draft.copyWith(hasGlasses: false);
                                        },
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              // Top-Left: Framing & Angle Quick Controls
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildStageActionBtn(
                                      label: draft.framing == 'face'
                                          ? 'الوجه'
                                          : 'الجسم',
                                      isActive: draft.framing == 'face',
                                      onTap: () {
                                        _draft.value = draft.copyWith(
                                          framing: draft.framing == 'face'
                                              ? 'body'
                                              : 'face',
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 4),
                                    _buildStageActionBtn(
                                      label: draft.cameraAngle == 0
                                          ? 'أمامي'
                                          : draft.cameraAngle == -45
                                          ? 'مائل'
                                          : 'جانبي',
                                      isActive: draft.cameraAngle != 0,
                                      onTap: () {
                                        final nextAngle =
                                            draft.cameraAngle == 0
                                                ? -45.0
                                                : draft.cameraAngle == -45
                                                ? -90.0
                                                : 0.0;
                                        _draft.value = draft.copyWith(
                                          cameraAngle: nextAngle,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),

                              // Bottom of Stage: Quick Motion Preview Strip
                              Positioned(
                                left: 8,
                                right: 8,
                                bottom: 8,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      CharacterMotion.idle,
                                      CharacterMotion.wave,
                                      CharacterMotion.happy,
                                      CharacterMotion.smile,
                                      CharacterMotion.victory,
                                      CharacterMotion.thinking,
                                      CharacterMotion.walk,
                                    ].map((motion) {
                                      final selected = draft.motion == motion;
                                      return Padding(
                                        padding: const EdgeInsets.only(left: 4),
                                        child: InkWell(
                                          onTap: () {
                                            _draft.value =
                                                draft.copyWith(motion: motion);
                                          },
                                          borderRadius: radius,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: selected
                                                  ? AppColors.secondary
                                                  : AppColors.surface.withValues(
                                                      alpha: 0.92,
                                                    ),
                                              borderRadius: radius,
                                              border: Border.all(
                                                color: selected
                                                    ? AppColors.secondary
                                                    : AppColors.inputBorder,
                                              ),
                                            ),
                                            child: Text(
                                              motion.arabicLabel,
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: selected
                                                    ? AppColors.onSecondary
                                                    : AppColors.secondary,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),

                              // Drag & Drop Highlight Overlay
                              if (isHovered)
                                Positioned.fill(
                                  child: Container(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.14,
                                    ),
                                    child: Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius: radius,
                                          border: Border.all(
                                            color: AppColors.secondary,
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'أفلت الإكسسوار هنا لتطبيقه على الشخصية',
                                              style: TextStyle(
                                                color: AppColors.onPrimary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    );
                  },
                ),
              ),

              // ============================================================
              // 2. BOTTOM HALF: ORGANIZED WORKSPACE (NO SCROLL CONFLICTS)
              // ============================================================
              Expanded(
                flex: 54,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // A. Character Name Input Bar + Section Switcher
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 42,
                              child: TextField(
                                controller: _nameController,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppColors.onSurface,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'اسم الشخصية (مثال: بطل العلوم)...',
                                  hintStyle: const TextStyle(fontSize: 12),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  filled: true,
                                  fillColor: AppColors.surface,
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
                                    borderSide: const BorderSide(
                                      color: AppColors.secondary,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (_editingId != null) ...[
                            const SizedBox(width: 6),
                            SizedBox(
                              height: 42,
                              child: OutlinedButton(
                                onPressed: () =>
                                    _resetToRaw(clearEditing: true),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.secondary,
                                  backgroundColor: AppColors.surface,
                                  side: const BorderSide(
                                    color: AppColors.inputBorder,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: radius,
                                  ),
                                ),
                                child: const Text(
                                  'جديدة',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),

                      // B. Main Workspace Tabs (الألوان | الإكسسوارات | شخصياتي)
                      Row(
                        children: [
                          _buildSectionTab(
                            section: _CreatorSection.colors,
                            label: 'الألوان',
                          ),
                          const SizedBox(width: 6),
                          _buildSectionTab(
                            section: _CreatorSection.accessories,
                            label: 'الإكسسوارات',
                          ),
                          const SizedBox(width: 6),
                          _buildSectionTab(
                            section: _CreatorSection.saved,
                            label: 'شخصياتي (${_savedCharacters.length})',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // C. Active Section Panel
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: radius,
                            border: Border.all(color: AppColors.inputBorder),
                          ),
                          child: switch (_activeSection) {
                            _CreatorSection.colors => _buildColorsSection(),
                            _CreatorSection.accessories =>
                              _buildAccessoriesSection(),
                            _CreatorSection.saved =>
                              _buildSavedCharactersSection(),
                          },
                        ),
                      ),
                      const SizedBox(height: 8),

                      // D. Pinned Save & Apply Action Bar
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 46,
                                child: FilledButton(
                                  onPressed: _isSaving
                                      ? null
                                      : () => _saveAndApply(saveAsNew: false),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: AppColors.onPrimary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: radius,
                                    ),
                                  ),
                                  child: _isSaving
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: AppColors.onPrimary,
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              _editingId != null
                                                  ? 'حفظ تعديلات الشخصية'
                                                  : 'حفظ وتطبيق الشخصية',
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                            if (_editingId != null) ...[
                              const SizedBox(width: 8),
                              SizedBox(
                                height: 46,
                                child: OutlinedButton(
                                  onPressed: _isSaving
                                      ? null
                                      : () => _saveAndApply(saveAsNew: true),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.secondary,
                                    backgroundColor: AppColors.surface,
                                    side: const BorderSide(
                                      color: AppColors.secondary,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: radius,
                                    ),
                                  ),
                                  child: const Text(
                                    'حفظ كجديدة',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTab({
    required _CreatorSection section,
    required String label,
  }) {
    final isSelected = _activeSection == section;
    final radius = BorderRadius.circular(AppColors.border_radius);
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _activeSection = section),
        borderRadius: radius,
        child: Container(
          height: 36,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.secondary : AppColors.surface,
            borderRadius: radius,
            border: Border.all(
              color: isSelected ? AppColors.secondary : AppColors.inputBorder,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? AppColors.onSecondary
                        : AppColors.secondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorsSection() {
    return ValueListenableBuilder<_CharacterDraft>(
      valueListenable: _draft,
      builder: (context, draft, _) {
        final activeColor = _colorForTarget(draft, _selectedTarget);
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sub-target selector: Body | Belly | Hat
              Row(
                children: [
                  _buildTargetTab(
                    label: 'الجسم الأساسي',
                    target: _ColorTarget.body,
                    activeColor: draft.bodyColor,
                  ),
                  const SizedBox(width: 6),
                  _buildTargetTab(
                    label: 'البطن الكريمي',
                    target: _ColorTarget.belly,
                    activeColor: draft.bellyColor,
                  ),
                  const SizedBox(width: 6),
                  _buildTargetTab(
                    label: draft.hasHat ? 'الطاقية' : 'الطاقية (+)',
                    target: _ColorTarget.hat,
                    activeColor: draft.hatColor,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Color Wheel with stable key per target (NEVER keyed by color value!)
              ColorWheelPicker(
                key: ValueKey('wheel_target_${_selectedTarget.name}'),
                initialColor: activeColor,
                targetLabel: _labelForSelectedTarget,
                presetColors: _presetsForSelectedTarget,
                onColorChanged: _onColorChanged,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAccessoriesSection() {
    final radius = BorderRadius.circular(AppColors.border_radius);
    return ValueListenableBuilder<_CharacterDraft>(
      valueListenable: _draft,
      builder: (context, draft, _) {
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'انقر لتفعيل الإكسسوار أو اسحبه مباشرة إلى الشخصية في الأعلى:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildDraggableAccessory(
                      type: 'glasses',
                      title: 'نظارة ذكية',
                      subtitle: draft.hasGlasses ? 'مُفعّلة' : 'اضغط أو اسحب',
                      isActive: draft.hasGlasses,
                      onToggle: () {
                        _draft.value = draft.copyWith(
                          hasGlasses: !draft.hasGlasses,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildDraggableAccessory(
                      type: 'hat',
                      title: 'طاقية الرأس',
                      subtitle: draft.hasHat ? 'مُفعّلة' : 'اضغط أو اسحب',
                      isActive: draft.hasHat,
                      onToggle: () {
                        final nextHat = !draft.hasHat;
                        _draft.value = draft.copyWith(hasHat: nextHat);
                        if (!nextHat && _selectedTarget == _ColorTarget.hat) {
                          setState(() => _selectedTarget = _ColorTarget.body);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Quick Hat Color Swatches when Hat is active
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: radius,
                  border: Border.all(color: AppColors.inputBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'ألوان الطاقية السريعة',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondary,
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () {
                            _draft.value = draft.copyWith(hasHat: true);
                            setState(() {
                              _selectedTarget = _ColorTarget.hat;
                              _activeSection = _CreatorSection.colors;
                            });
                          },
                          borderRadius: radius,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryContainer,
                              borderRadius: radius,
                              border: Border.all(color: AppColors.secondary),
                            ),
                            child: const Text(
                              'عجلة ألوان الطاقية',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.onSecondaryContainer,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _hatPresets.map((color) {
                        final isSelected = draft.hasHat &&
                            (draft.hatColor.toARGB32() & 0xFFFFFF) ==
                                (color.toARGB32() & 0xFFFFFF);
                        return InkWell(
                          onTap: () {
                            _draft.value = draft.copyWith(
                              hasHat: true,
                              hatColor: color,
                            );
                          },
                          borderRadius: radius,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: radius,
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.secondary
                                    : AppColors.inputBorder,
                                width: isSelected ? 2.2 : 1,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSavedCharactersSection() {
    final radius = BorderRadius.circular(AppColors.border_radius);
    if (_savedCharacters.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'لا توجد شخصيات محفوظة حتى الآن',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'صمّم شخصيتك بالألوان والإكسسوارات ثم اضغط حفظ لتظهر هنا.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppColors.onSurface),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () =>
                  setState(() => _activeSection = _CreatorSection.colors),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.secondary,
                side: const BorderSide(color: AppColors.secondary),
                shape: RoundedRectangleBorder(borderRadius: radius),
              ),
              child: const Text('ابدأ التصميم الآن'),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _savedCharacters.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final c = _savedCharacters[index];
        final isEditingThis = _editingId == c.id;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isEditingThis
                ? AppColors.secondaryContainer.withValues(alpha: 0.45)
                : AppColors.background,
            borderRadius: radius,
            border: Border.all(
              color: isEditingThis
                  ? AppColors.secondary
                  : AppColors.inputBorder,
              width: isEditingThis ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              // Color preview swatch (Body + Belly)
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: c.bodyColor,
                  borderRadius: radius,
                  border: Border.all(color: AppColors.inputBorder),
                ),
                alignment: Alignment.center,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: c.bellyColor,
                    borderRadius: BorderRadius.circular(
                      AppColors.border_radius,
                    ),
                    border: Border.all(color: AppColors.surface, width: 1),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          c.bodyColorHex,
                          textDirection: TextDirection.ltr,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.onSurface,
                          ),
                        ),
                        if (c.hasHat) ...[
                          const SizedBox(width: 6),
                          const Text(
                            'طاقية',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                        if (c.hasGlasses) ...[
                          const SizedBox(width: 6),
                          const Text(
                            'نظارة',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Edit button
              InkWell(
                onTap: () => _loadCharacterForEdit(c),
                borderRadius: radius,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: radius,
                    border: Border.all(color: AppColors.primary),
                  ),
                  child: const Text(
                    'تعديل',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Delete button
              InkWell(
                onTap: () => _deleteSavedCharacter(c),
                borderRadius: radius,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: radius,
                    border: Border.all(color: AppColors.inputBorder),
                  ),
                  child: const Text(
                    'حذف',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTargetTab({
    required String label,
    required _ColorTarget target,
    required Color activeColor,
  }) {
    final isSelected = _selectedTarget == target;
    final radius = BorderRadius.circular(AppColors.border_radius);
    return Expanded(
      child: InkWell(
        onTap: () {
          if (target == _ColorTarget.hat && !_draft.value.hasHat) {
            _draft.value = _draft.value.copyWith(hasHat: true);
          }
          setState(() => _selectedTarget = target);
        },
        borderRadius: radius,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.secondaryContainer
                : AppColors.background,
            borderRadius: radius,
            border: Border.all(
              color: isSelected ? AppColors.secondary : AppColors.inputBorder,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: activeColor,
                  borderRadius: BorderRadius.circular(AppColors.border_radius),
                  border: Border.all(color: AppColors.secondary, width: 1),
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStageQuickBadge({
    required String label,
    required VoidCallback onRemove,
  }) {
    final radius = BorderRadius.circular(AppColors.border_radius);
    return InkWell(
      onTap: onRemove,
      borderRadius: radius,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.secondaryContainer,
          borderRadius: radius,
          border: Border.all(color: AppColors.secondary),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.onSecondaryContainer,
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              'إزالة',
              style: TextStyle(
                fontSize: 9,
                color: AppColors.onSecondaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStageActionBtn({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final radius = BorderRadius.circular(AppColors.border_radius);
    return InkWell(
      onTap: onTap,
      borderRadius: radius,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? AppColors.secondary : AppColors.background,
          borderRadius: radius,
          border: Border.all(
            color: isActive ? AppColors.secondary : AppColors.inputBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isActive ? AppColors.onSecondary : AppColors.secondary,
          ),
        ),
      ),
    );
  }

  Widget _buildDraggableAccessory({
    required String type,
    required String title,
    required String subtitle,
    required bool isActive,
    required VoidCallback onToggle,
  }) {
    final radius = BorderRadius.circular(AppColors.border_radius);
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? AppColors.secondaryContainer : AppColors.background,
        borderRadius: radius,
        border: Border.all(
          color: isActive ? AppColors.secondary : AppColors.inputBorder,
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: AppColors.secondary,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Draggable<String>(
      data: type,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: 155,
          child: Opacity(opacity: 0.9, child: content),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.4, child: content),
      child: InkWell(
        onTap: onToggle,
        borderRadius: radius,
        child: content,
      ),
    );
  }
}
