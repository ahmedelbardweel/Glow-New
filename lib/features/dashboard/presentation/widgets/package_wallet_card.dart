import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/offline_aware_image.dart';

class PackageWalletCard extends StatelessWidget {
  const PackageWalletCard({
    super.key,
    required this.package,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final Map<String, dynamic> package;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final draft = package['draft_content'];
    final worlds = draft is Map && draft['worlds'] is List
        ? (draft['worlds'] as List).whereType<Map>().toList()
        : <Map>[];
    final shown = worlds.take(3).toList();
    final count =
        package['_mission_count'] as int? ??
        worlds.fold<int>(
          0,
          (sum, world) =>
              sum +
              (world['habits'] is List ? (world['habits'] as List).length : 0),
        );
    final published = package['status'] == 'published';
    final description = '${package['description'] ?? ''}'.trim();
    final radius = AppColors.border_radius * 2;
    final strip =
        36.0 + (MediaQuery.textScalerOf(context).scale(13) - 13).clamp(0, 26);
    final slots = shown.isEmpty ? 1 : shown.length;
    final pocketTop = strip * slots + 8;

    void open() {
      HapticFeedback.lightImpact();
      onTap();
    }

    return Semantics(
      container: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Stack(
          children: [
            Positioned.fill(
              top: 12,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(radius),
                ),
              ),
            ),
            for (var i = 0; i < slots; i++)
              Positioned(
                top: strip * i,
                left: 0,
                right: 0,
                height: strip + 42,
                child: _WorldTab(
                  key: ValueKey('wallet-world-$i'),
                  world: shown.isEmpty ? null : shown[i],
                  index: i,
                  stripHeight: strip,
                  extra: i == slots - 1 ? worlds.length - shown.length : 0,
                  onTap: open,
                ),
              ),
            Padding(
              padding: EdgeInsets.only(top: pocketTop),
              child: PhysicalShape(
                clipper: _PocketClipper(radius),
                clipBehavior: Clip.antiAlias,
                color: AppColors.surface,
                elevation: 2,
                shadowColor: const Color(0x22001946),
                child: Material(
                  color: AppColors.surface,
                  child: InkWell(
                    onTap: open,
                    child: CustomPaint(
                      painter: _StitchPainter(radius),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Align(
                                    alignment: AlignmentDirectional.centerStart,
                                    child: _WalletLabel(
                                      text: published ? 'منشور' : 'مسودة',
                                      color: published
                                          ? AppColors.tertiaryContainer
                                          : AppColors.primaryContainer,
                                      foreground: published
                                          ? AppColors.onTertiaryContainer
                                          : AppColors.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  tooltip: 'خيارات البكج',
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(
                                    Icons.more_horiz_rounded,
                                    color: AppColors.secondary,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 160,
                                  ),
                                  onSelected: (value) =>
                                      value == 'edit' ? onEdit() : onDelete(),
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Text('تعديل البيانات'),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text(
                                        'حذف البكج',
                                        style: TextStyle(
                                          color: AppColors.error,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${package['title'] ?? 'بكج بدون اسم'}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 18,
                                height: 1.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.secondary,
                              ),
                            ),
                            if (description.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.6,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _WalletLabel(
                                  text: '${worlds.length} عوالم',
                                  color: AppColors.secondaryContainer,
                                  foreground: AppColors.onSecondaryContainer,
                                ),
                                _WalletLabel(
                                  text: '$count عادات',
                                  color: AppColors.primaryContainer,
                                  foreground: AppColors.onPrimaryContainer,
                                ),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 14),
                              child: Divider(
                                height: 1,
                                color: AppColors.inputBorder,
                              ),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'الإصدار ${package['version'] ?? 0}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                                const Text(
                                  'فتح البكج',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.secondary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 18,
                                  color: AppColors.secondary,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorldTab extends StatelessWidget {
  const _WorldTab({
    super.key,
    required this.world,
    required this.index,
    required this.stripHeight,
    required this.extra,
    required this.onTap,
  });
  final Map? world;
  final int index;
  final double stripHeight;
  final int extra;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final image = '${world?['image_url'] ?? ''}';
    return Material(
      color: index.isEven ? AppColors.secondary : const Color(0xFF254777),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.border_radius * 2),
        side: const BorderSide(color: AppColors.inputBorder, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (image.isNotEmpty)
              OfflineAwareImage(
                imageUrl: image,
                fit: BoxFit.cover,
                errorWidget: const ColoredBox(color: AppColors.secondary),
              ),
            if (image.isNotEmpty) const ColoredBox(color: Color(0x99001946)),
            Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                height: stripHeight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.public_rounded,
                        size: 16,
                        color: AppColors.primaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${world?['title'] ?? 'أضف عوالم إلى البكج'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (extra > 0) ...[
                        const SizedBox(width: 8),
                        Text(
                          '+$extra',
                          style: const TextStyle(
                            color: AppColors.primaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletLabel extends StatelessWidget {
  const _WalletLabel({
    required this.text,
    required this.color,
    required this.foreground,
  });
  final String text;
  final Color color;
  final Color foreground;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(AppColors.border_radius),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 12,
        height: 1.3,
        fontWeight: FontWeight.w700,
        color: foreground,
      ),
    ),
  );
}

Path _pocketTop(Size size, double radius, double inset) {
  final mid = size.width / 2;
  final spread = size.width * .18;
  return Path()
    ..moveTo(radius, inset)
    ..lineTo(mid - spread, inset)
    ..cubicTo(
      mid - spread / 2,
      inset,
      mid - spread / 2,
      inset + 10,
      mid,
      inset + 10,
    )
    ..cubicTo(
      mid + spread / 2,
      inset + 10,
      mid + spread / 2,
      inset,
      mid + spread,
      inset,
    )
    ..lineTo(size.width - radius, inset);
}

class _PocketClipper extends CustomClipper<Path> {
  const _PocketClipper(this.radius);
  final double radius;
  @override
  Path getClip(Size size) => Path()
    ..moveTo(0, radius)
    ..quadraticBezierTo(0, 0, radius, 0)
    ..extendWithPath(_pocketTop(size, radius, 0), Offset.zero)
    ..quadraticBezierTo(size.width, 0, size.width, radius)
    ..lineTo(size.width, size.height - radius)
    ..quadraticBezierTo(
      size.width,
      size.height,
      size.width - radius,
      size.height,
    )
    ..lineTo(radius, size.height)
    ..quadraticBezierTo(0, size.height, 0, size.height - radius)
    ..close();
  @override
  bool shouldReclip(_PocketClipper oldClipper) => oldClipper.radius != radius;
}

class _StitchPainter extends CustomPainter {
  const _StitchPainter(this.radius);
  final double radius;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round
      ..color = AppColors.secondaryContainer;
    for (final metric in _pocketTop(size, radius + 5, 6).computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 8) {
        canvas.drawPath(metric.extractPath(d, d + 4), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_StitchPainter oldDelegate) =>
      oldDelegate.radius != radius;
}
