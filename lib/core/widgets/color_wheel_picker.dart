import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ColorWheelPicker extends StatefulWidget {
  final Color initialColor;
  final ValueChanged<Color> onColorChanged;
  final List<Color>? presetColors;
  final String? targetLabel;

  const ColorWheelPicker({
    super.key,
    required this.initialColor,
    required this.onColorChanged,
    this.presetColors,
    this.targetLabel,
  });

  @override
  State<ColorWheelPicker> createState() => _ColorWheelPickerState();
}

class _ColorWheelPickerState extends State<ColorWheelPicker> {
  static const List<Color> _defaultPresets = [
    Color(0xFF28542F), // Port Emerald
    Color(0xFF912740), // Fort Ruby
    Color(0xFF4A90B8), // Qort Sky Blue
    Color(0xFFD09236), // Sort Amber
    Color(0xFFB55D75), // Mort Berry
    Color(0xFF6E8B62), // Lort Sage
    Color(0xFFFFB300), // Primary Yellow
    Color(0xFF001946), // Secondary Navy
    Color(0xFF34A853), // Tertiary Green
    Color(0xFFFF9800), // Orange
    Color(0xFFD9A9B2), // Pink
    Color(0xFFEFECE6), // Cream Belly
  ];

  late HSVColor _hsvColor;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _hsvColor = HSVColor.fromColor(widget.initialColor);
  }

  @override
  void didUpdateWidget(covariant ColorWheelPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isDragging &&
        oldWidget.initialColor.toARGB32() != widget.initialColor.toARGB32()) {
      _hsvColor = HSVColor.fromColor(widget.initialColor);
    }
  }

  void _updateHueSaturation(double dx, double dy, double radius) {
    final dist = math.sqrt(dx * dx + dy * dy);
    final sat = (dist / radius).clamp(0.0, 1.0);
    var angle = math.atan2(dy, dx) * 180 / math.pi;
    if (angle < 0) angle += 360;

    final next = _hsvColor.withHue(angle).withSaturation(sat);
    setState(() {
      _hsvColor = next;
    });
    widget.onColorChanged(next.toColor());
  }

  void _updateValue(double val) {
    final next = _hsvColor.withValue(val.clamp(0.15, 1.0));
    setState(() {
      _hsvColor = next;
    });
    widget.onColorChanged(next.toColor());
  }

  void _selectPreset(Color color) {
    final next = HSVColor.fromColor(color);
    setState(() {
      _hsvColor = next;
    });
    widget.onColorChanged(color);
  }

  @override
  Widget build(BuildContext context) {
    final currentColor = _hsvColor.toColor();
    final currentArgb = currentColor.toARGB32();
    final hexCode =
        '#${(currentArgb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
    final presets = widget.presetColors ?? _defaultPresets;
    final radius = BorderRadius.circular(AppColors.border_radius);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Header Bar: Target Label + Live Color Swatch & HEX
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: radius,
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: currentColor,
                  borderRadius: radius,
                  border: Border.all(color: AppColors.inputBorder, width: 1.5),
                ),
              ),
              const SizedBox(width: 10),
              if (widget.targetLabel != null) ...[
                Text(
                  widget.targetLabel!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.secondary,
                  ),
                ),
                const Spacer(),
              ] else
                const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: radius,
                  border: Border.all(color: AppColors.inputBorder),
                ),
                child: Text(
                  hexCode,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.0,
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // 2. Interactive Wheel + Preset Swatches Grid Side-by-Side
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 360° Color Wheel (GPU cached base layer + fast overlay)
            SizedBox(
              width: 154,
              height: 154,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = constraints.biggest;
                  final wheelRadius = size.width / 2;
                  final center = Offset(wheelRadius, wheelRadius);

                  final rad = _hsvColor.hue * math.pi / 180;
                  final r = _hsvColor.saturation * wheelRadius;
                  final thumbPos =
                      center + Offset(r * math.cos(rad), r * math.sin(rad));

                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanDown: (details) {
                      _isDragging = true;
                      final local = details.localPosition - center;
                      _updateHueSaturation(local.dx, local.dy, wheelRadius);
                    },
                    onPanUpdate: (details) {
                      _isDragging = true;
                      final local = details.localPosition - center;
                      _updateHueSaturation(local.dx, local.dy, wheelRadius);
                    },
                    onPanEnd: (_) => _isDragging = false,
                    onPanCancel: () => _isDragging = false,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Static Hue + Saturation wheel cached once in GPU texture
                        const Positioned.fill(
                          child: RepaintBoundary(
                            child: CustomPaint(
                              painter: _BaseHueSatWheelPainter(),
                            ),
                          ),
                        ),
                        // Lightweight brightness shade + thumb indicator
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _WheelOverlayPainter(
                              value: _hsvColor.value,
                              thumbPos: thumbPos,
                              thumbColor: currentColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),

            // Quick Preset Swatches
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'ألوان مقترحة سريعة',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: presets.map((preset) {
                      final isSelected =
                          (preset.toARGB32() & 0xFFFFFF) == (currentArgb & 0xFFFFFF);
                      return InkWell(
                        onTap: () => _selectPreset(preset),
                        borderRadius: radius,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: preset,
                            borderRadius: radius,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.secondary
                                  : AppColors.inputBorder,
                              width: isSelected ? 2.2 : 1,
                            ),
                          ),
                          child: isSelected
                              ? Icon(
                                  Icons.check,
                                  size: 16,
                                  color: preset.computeLuminance() > 0.55
                                      ? AppColors.secondary
                                      : AppColors.onSecondary,
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // 3. Brightness Slider Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: radius,
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.brightness_low_rounded,
                size: 18,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 6),
              const Text(
                'الإضاءة',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.secondary,
                    inactiveTrackColor: AppColors.inputBorder,
                    thumbColor: AppColors.primary,
                    overlayColor: AppColors.primary.withValues(alpha: 0.15),
                    trackHeight: 5,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 7,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 14,
                    ),
                  ),
                  child: Slider(
                    value: _hsvColor.value.clamp(0.15, 1.0),
                    min: 0.15,
                    max: 1.0,
                    onChangeStart: (_) => _isDragging = true,
                    onChanged: _updateValue,
                    onChangeEnd: (_) => _isDragging = false,
                  ),
                ),
              ),
              SizedBox(
                width: 34,
                child: Text(
                  '${(_hsvColor.value * 100).round()}%',
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BaseHueSatWheelPainter extends CustomPainter {
  const _BaseHueSatWheelPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.width / 2;
    final center = Offset(radius, radius);
    final circleRect = Rect.fromCircle(center: center, radius: radius);

    const sweepGradient = SweepGradient(
      colors: [
        Color(0xFFFF0000),
        Color(0xFFFFFF00),
        Color(0xFF00FF00),
        Color(0xFF00FFFF),
        Color(0xFF0000FF),
        Color(0xFFFF00FF),
        Color(0xFFFF0000),
      ],
    );

    final sweepPaint = Paint()
      ..shader = sweepGradient.createShader(circleRect)
      ..isAntiAlias = true
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, sweepPaint);

    final radialSatGradient = RadialGradient(
      colors: [
        Colors.white,
        Colors.white.withValues(alpha: 0.0),
      ],
      stops: const [0.0, 1.0],
    );

    final satPaint = Paint()
      ..shader = radialSatGradient.createShader(circleRect)
      ..blendMode = BlendMode.screen
      ..isAntiAlias = true
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, satPaint);
  }

  @override
  bool shouldRepaint(covariant _BaseHueSatWheelPainter oldDelegate) => false;
}

class _WheelOverlayPainter extends CustomPainter {
  final double value;
  final Offset thumbPos;
  final Color thumbColor;

  const _WheelOverlayPainter({
    required this.value,
    required this.thumbPos,
    required this.thumbColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.width / 2;
    final center = Offset(radius, radius);

    if (value < 1.0) {
      final darkPaint = Paint()
        ..color = Colors.black.withValues(alpha: (1.0 - value).clamp(0.0, 0.90))
        ..isAntiAlias = true
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius, darkPaint);
    }

    final borderPaint = Paint()
      ..color = AppColors.inputBorder
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, borderPaint);

    // Draw thumb indicator
    final thumbFill = Paint()
      ..color = thumbColor
      ..isAntiAlias = true
      ..style = PaintingStyle.fill;
    final thumbOuter = Paint()
      ..color = AppColors.surface
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final thumbInner = Paint()
      ..color = AppColors.secondary
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawCircle(thumbPos, 11, thumbFill);
    canvas.drawCircle(thumbPos, 11, thumbOuter);
    canvas.drawCircle(thumbPos, 12.2, thumbInner);
  }

  @override
  bool shouldRepaint(covariant _WheelOverlayPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.thumbPos != thumbPos ||
        oldDelegate.thumbColor != thumbColor;
  }
}
