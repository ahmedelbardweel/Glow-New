import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/color_wheel_picker.dart';
import '../../../../core/widgets/smart_character_viewer.dart';
import '../../data/models/custom_character_model.dart';
import '../../data/repositories/custom_character_repository.dart';

enum _ColorTarget { body, belly, hat }

class CustomCharacterCreatorScreen extends StatefulWidget {
  final CustomCharacterModel? characterToEdit;

  const CustomCharacterCreatorScreen({
    super.key,
    this.characterToEdit,
  });

  @override
  State<CustomCharacterCreatorScreen> createState() => _CustomCharacterCreatorScreenState();
}

class _CustomCharacterCreatorScreenState extends State<CustomCharacterCreatorScreen> {
  final _nameController = TextEditingController();

  late Color _bodyColor;
  late Color _bellyColor;
  late Color _hatColor;
  bool _customBelly = false;
  bool _hasHat = false;
  bool _hasGlasses = false;
  bool _isSaving = false;

  _ColorTarget _selectedTarget = _ColorTarget.body;

  @override
  void initState() {
    super.initState();
    final edit = widget.characterToEdit;
    if (edit != null) {
      _nameController.text = edit.name;
      _bodyColor = edit.bodyColor;
      _bellyColor = edit.bellyColor;
      _hatColor = edit.hatColor;
      _customBelly = true;
      _hasHat = edit.hasHat;
      _hasGlasses = edit.hasGlasses;
    } else {
      // Raw, neutral base character initially
      _bodyColor = const Color(0xFF8FA698); // Clay / Raw sage neutral base
      _bellyColor = const Color(0xFFEFECE6); // Default cream
      _hatColor = const Color(0xFF2C2C2E);
      _customBelly = false;
      _hasHat = false;
      _hasGlasses = false;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _resetToRaw() {
    setState(() {
      _bodyColor = const Color(0xFF8FA698);
      _bellyColor = const Color(0xFFEFECE6);
      _hatColor = const Color(0xFF2C2C2E);
      _customBelly = false;
      _hasHat = false;
      _hasGlasses = false;
      _selectedTarget = _ColorTarget.body;
    });
  }

  Color get _currentColorForTarget {
    switch (_selectedTarget) {
      case _ColorTarget.body:
        return _bodyColor;
      case _ColorTarget.belly:
        return _bellyColor;
      case _ColorTarget.hat:
        return _hatColor;
    }
  }

  void _onColorChanged(Color color) {
    setState(() {
      switch (_selectedTarget) {
        case _ColorTarget.body:
          _bodyColor = color;
          break;
        case _ColorTarget.belly:
          _bellyColor = color;
          _customBelly = true;
          break;
        case _ColorTarget.hat:
          _hatColor = color;
          break;
      }
    });
  }

  Future<void> _saveAndApply() async {
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

    final character = CustomCharacterModel(
      id: widget.characterToEdit?.id ?? 'char_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      bodyColorHex: CustomCharacterModel.colorToHex(_bodyColor),
      bellyColorHex: CustomCharacterModel.colorToHex(_bellyColor),
      hasHat: _hasHat,
      hatColorHex: CustomCharacterModel.colorToHex(_hatColor),
      hasGlasses: _hasGlasses,
      createdAt: widget.characterToEdit?.createdAt ?? DateTime.now(),
    );

    try {
      await sl<CustomCharacterRepository>().saveCharacter(character);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم حفظ الشخصية «$name» بنجاح! ستجدها في التايم لاين.'),
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
    final hexBody = CustomCharacterModel.colorToHex(_bodyColor);
    final characterString = 'custom|$hexBody|${_nameController.text.trim().isEmpty ? 'غلو' : _nameController.text.trim()}';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('اصنع شخصيتك بنفسك'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'إعادة ضبط الشخصية للوضع الخام',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _resetToRaw,
          ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            // TOP HALF: 3D CHARACTER STAGE WITH DRAG TARGET
            Expanded(
              flex: 5,
              child: DragTarget<String>(
                onWillAcceptWithDetails: (details) =>
                    details.data == 'glasses' || details.data == 'hat',
                onAcceptWithDetails: (details) {
                  if (details.data == 'glasses') {
                    setState(() => _hasGlasses = true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تمت إضافة النظارة!'), duration: Duration(milliseconds: 900)),
                    );
                  } else if (details.data == 'hat') {
                    setState(() {
                      _hasHat = true;
                      _selectedTarget = _ColorTarget.hat;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تمت إضافة الطاقية!'), duration: Duration(milliseconds: 900)),
                    );
                  }
                },
                builder: (context, candidateData, rejectedData) {
                  final isHovered = candidateData.isNotEmpty;
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border(
                              bottom: BorderSide(
                                color: isHovered ? AppColors.primary : AppColors.inputBorder,
                                width: isHovered ? 3 : 1,
                              ),
                            ),
                          ),
                          child: SmartCharacterViewer(
                            key: ValueKey('creator_${_hasHat}_${_hasGlasses}_${_bodyColor.value}_${_bellyColor.value}_${_hatColor.value}'),
                            characterName: characterString,
                            showHat: _hasHat,
                            hatColor: _hatColor,
                            bellyColor: _customBelly ? _bellyColor : null,
                            showGlasses: _hasGlasses,
                            framing: 'body',
                            cameraFit: 1.15,
                            autoBlink: true,
                            isPlaying: true,
                            interactive: true,
                          ),
                        ),
                      ),

                      // Hover drop highlight badge
                      if (isHovered)
                        Positioned.fill(
                          child: Container(
                            color: AppColors.primary.withOpacity(0.12),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(AppColors.border_radius),
                                  boxShadow: const [
                                    BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.add_circle, color: AppColors.onPrimary),
                                    SizedBox(width: 8),
                                    Text(
                                      'أفلت الإكسسوار لتطبيقه على الشخصية',
                                      style: TextStyle(
                                        color: AppColors.onPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Rotate Hint Pill
                      Positioned(
                        top: 10,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.touch_app_rounded, size: 14, color: Colors.black54),
                              SizedBox(width: 4),
                              Text(
                                'اسحب لتدوير الشخصية',
                                style: TextStyle(fontSize: 11, color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // BOTTOM HALF: CUSTOMIZATION TOOLS & COLOR WHEEL (Scrollable)
            Expanded(
              flex: 6,
              child: Container(
                color: AppColors.background,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    // 1. Character Name Input
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppColors.border_radius),
                        border: Border.all(color: AppColors.inputBorder),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: TextField(
                        controller: _nameController,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        decoration: const InputDecoration(
                          icon: Icon(Icons.badge_outlined, color: AppColors.secondary),
                          hintText: 'اكتب اسماً لشخصيتك (مثال: بطل العلوم، غلو المبتسم...)',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 2. Part Selector Tabs (جسم / بطن كريمي / طاقية)
                    Row(
                      children: [
                        _buildTargetTab(
                          label: 'الجسم الأساسي',
                          icon: Icons.palette_outlined,
                          target: _ColorTarget.body,
                          activeColor: _bodyColor,
                        ),
                        const SizedBox(width: 8),
                        _buildTargetTab(
                          label: 'الجزء الكريمي (البطن)',
                          icon: Icons.cookie_outlined,
                          target: _ColorTarget.belly,
                          activeColor: _bellyColor,
                        ),
                        if (_hasHat) ...[
                          const SizedBox(width: 8),
                          _buildTargetTab(
                            label: 'الطاقية',
                            icon: Icons.face_retouching_natural,
                            target: _ColorTarget.hat,
                            activeColor: _hatColor,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 3. The Interactive Color Wheel
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppColors.border_radius),
                        border: Border.all(color: AppColors.inputBorder),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
                        ],
                      ),
                      child: ColorWheelPicker(
                        key: ValueKey('wheel_${_selectedTarget.name}_${_currentColorForTarget.value}'),
                        initialColor: _currentColorForTarget,
                        onColorChanged: _onColorChanged,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 4. Draggable Accessories Shelf (رف الإكسسوارات)
                    const Text(
                      'الإكسسوارات (اسحب للإضافة أو انقر للتبديل):',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Draggable Glasses
                        Expanded(
                          child: _buildDraggableAccessory(
                            type: 'glasses',
                            title: 'نظارة',
                            icon: Icons.visibility_outlined,
                            isActive: _hasGlasses,
                            onToggle: () => setState(() => _hasGlasses = !_hasGlasses),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Draggable Hat
                        Expanded(
                          child: _buildDraggableAccessory(
                            type: 'hat',
                            title: 'طاقية',
                            icon: Icons.face_retouching_natural,
                            isActive: _hasHat,
                            onToggle: () => setState(() {
                              _hasHat = !_hasHat;
                              if (_hasHat) _selectedTarget = _ColorTarget.hat;
                              else if (_selectedTarget == _ColorTarget.hat) _selectedTarget = _ColorTarget.body;
                            }),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 5. Save & Apply Button
                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        onPressed: _isSaving ? null : _saveAndApply,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppColors.border_radius),
                          ),
                          elevation: 2,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.onPrimary),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_rounded, size: 22),
                                  SizedBox(width: 8),
                                  Text(
                                    'تطبيق وحفظ الشخصية',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetTab({
    required String label,
    required IconData icon,
    required _ColorTarget target,
    required Color activeColor,
  }) {
    final isSelected = _selectedTarget == target;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTarget = target),
        borderRadius: BorderRadius.circular(AppColors.border_radius),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.secondary : Colors.white,
            borderRadius: BorderRadius.circular(AppColors.border_radius),
            border: Border.all(
              color: isSelected ? AppColors.secondary : AppColors.inputBorder,
              width: isSelected ? 2 : 1,
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
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
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
                    color: isSelected ? Colors.white : AppColors.secondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDraggableAccessory({
    required String type,
    required String title,
    required IconData icon,
    required bool isActive,
    required VoidCallback onToggle,
  }) {
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? AppColors.secondaryContainer : Colors.white,
        borderRadius: BorderRadius.circular(AppColors.border_radius),
        border: Border.all(
          color: isActive ? AppColors.secondary : AppColors.inputBorder,
          width: isActive ? 1.8 : 1,
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isActive ? AppColors.secondary : Colors.black54,
            size: 20,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isActive ? AppColors.secondary : Colors.black87,
                ),
              ),
              Text(
                isActive ? 'مُضافة (انقر للحذف)' : 'اسحب إلى الشخصية',
                style: TextStyle(
                  fontSize: 10,
                  color: isActive ? AppColors.secondary : Colors.grey,
                ),
              ),
            ],
          ),
          const Spacer(),
          Icon(
            isActive ? Icons.check_circle : Icons.drag_indicator,
            size: 18,
            color: isActive ? AppColors.secondary : Colors.grey,
          ),
        ],
      ),
    );

    return Draggable<String>(
      data: type,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: 150,
          child: Opacity(opacity: 0.85, child: content),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.4, child: content),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(AppColors.border_radius),
        child: content,
      ),
    );
  }
}
