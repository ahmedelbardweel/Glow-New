import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ColorWheelPicker extends StatefulWidget {
  final Color initialColor;
  final ValueChanged<Color> onColorChanged;

  const ColorWheelPicker({
    super.key,
    required this.initialColor,
    required this.onColorChanged,
  });

  @override
  State<ColorWheelPicker> createState() => _ColorWheelPickerState();
}

class _ColorWheelPickerState extends State<ColorWheelPicker> {
  late HSVColor _hsvColor;

  @override
  void initState() {
    super.initState();
    _hsvColor = HSVColor.fromColor(widget.initialColor);
  }

  @override
  void didUpdateWidget(covariant ColorWheelPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialColor != widget.initialColor) {
      _hsvColor = HSVColor.fromColor(widget.initialColor);
    }
  }

  void _updateHueSaturation(double dx, double dy, double radius) {
    final dist = math.sqrt(dx * dx + dy * dy);
    final sat = (dist / radius).clamp(0.0, 1.0);
    var angle = math.atan2(dy, dx) * 180 / math.pi;
    if (angle < 0) angle += 360;

    setState(() {
      _hsvColor = _hsvColor.withHue(angle).withSaturation(sat);
    });
    widget.onColorChanged(_hsvColor.toColor());
  }

  void _updateValue(double val) {
    setState(() {
      _hsvColor = _hsvColor.withValue(val.clamp(0.0, 1.0));
    });
    widget.onColorChanged(_hsvColor.toColor());
  }

  @override
  Widget build(BuildContext context) {
    final currentColor = _hsvColor.toColor();
    final hexCode = '#${(currentColor.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Color Preview & Hex Swatch
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppColors.border_radius),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: currentColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black12, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: currentColor.withOpacity(0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                hexCode,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  letterSpacing: 1.2,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 2. Full 360° Circular Color Wheel
        SizedBox(
          width: 190,
          height: 190,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = constraints.biggest;
              final radius = size.width / 2;
              final center = Offset(radius, radius);

              // Calculate current thumb position
              final rad = _hsvColor.hue * math.pi / 180;
              final r = _hsvColor.saturation * radius;
              final thumbPos = center + Offset(r * math.cos(rad), r * math.sin(rad));

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanDown: (details) {
                  final local = details.localPosition - center;
                  _updateHueSaturation(local.dx, local.dy, radius);
                },
                onPanUpdate: (details) {
                  final local = details.localPosition - center;
                  _updateHueSaturation(local.dx, local.dy, radius);
                },
                child: Stack(
                  children: [
                    CustomPaint(
                      size: size,
                      painter: _ColorWheelPainter(value: _hsvColor.value),
                    ),
                    Positioned(
                      left: thumbPos.dx - 12,
                      top: thumbPos.dy - 12,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: currentColor,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),

        // 3. Brightness Slider
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Icon(Icons.brightness_low, size: 18, color: Colors.grey),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: currentColor,
                    inactiveTrackColor: Colors.grey.shade300,
                    thumbColor: currentColor,
                    trackHeight: 6,
                  ),
                  child: Slider(
                    value: _hsvColor.value,
                    min: 0.15,
                    max: 1.0,
                    onChanged: _updateValue,
                  ),
                ),
              ),
              const Icon(Icons.brightness_high, size: 18, color: Colors.grey),
            ],
          ),
        ),
      ],
    );
  }
}

class _ColorWheelPainter extends CustomPainter {
  final double value;

  _ColorWheelPainter({required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.width / 2;
    final center = Offset(radius, radius);

    // 1. Sweep gradient for hues
    const sweepGradient = SweepGradient(
      colors: [
        Color(0xFFFF0000), // 0° Red
        Color(0xFFFFFF00), // 60° Yellow
        Color(0xFF00FF00), // 120° Green
        Color(0xFF00FFFF), // 180° Cyan
        Color(0xFF0000FF), // 240° Blue
        Color(0xFFFF00FF), // 300° Magenta
        Color(0xFFFF0000), // 360° Red
      ],
    );

    final sweepPaint = Paint()
      ..shader = sweepGradient.createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, sweepPaint);

    // 2. Radial gradient for saturation (white in center to transparent at edge)
    final radialSatGradient = RadialGradient(
      colors: [
        Colors.white,
        Colors.white.withOpacity(0.0),
      ],
      stops: const [0.0, 1.0],
    );

    final satPaint = Paint()
      ..shader = radialSatGradient.createShader(Rect.fromCircle(center: center, radius: radius))
      ..blendMode = BlendMode.screen
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, satPaint);

    // 3. Shading layer for value (brightness)
    if (value < 1.0) {
      final darkPaint = Paint()
        ..color = Colors.black.withOpacity((1.0 - value).clamp(0.0, 0.95))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius, darkPaint);
    }

    // Outer border
    final borderPaint = Paint()
      ..color = Colors.black12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _ColorWheelPainter oldDelegate) => oldDelegate.value != value;
}
