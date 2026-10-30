import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_colors.dart';

enum ShimmerType { list, grid, card, form, timeline }

const _base = Color(0xFFE6ECF4);
const _highlight = Color(0xFFF8FAFC);

/// Skeleton placeholder shown while a page loads, in place of a spinner.
class ShimmerLoading extends StatelessWidget {
  final ShimmerType type;
  final int itemCount;

  const ShimmerLoading({
    super.key,
    this.type = ShimmerType.list,
    this.itemCount = 5,
  });

  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
        baseColor: _base,
        highlightColor: _highlight,
        child: switch (type) {
          ShimmerType.grid => _grid(),
          ShimmerType.card => _card(),
          ShimmerType.form => _form(),
          ShimmerType.timeline => _timeline(),
          ShimmerType.list => _list(),
        },
      );

  Widget _grid() => GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1,
        ),
        itemCount: itemCount,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (_, __) => const ShimmerBox(),
      );

  Widget _card() => const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        physics: NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerBox(height: 250),
            SizedBox(height: 24),
            ShimmerBox(width: 200, height: 24),
            SizedBox(height: 16),
            ShimmerBox(height: 16),
            SizedBox(height: 8),
            ShimmerBox(height: 16),
            SizedBox(height: 8),
            ShimmerBox(width: 150, height: 16),
          ],
        ),
      );

  Widget _list() => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: itemCount,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ShimmerBox(width: 38, height: 38, circle: true),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerBox(width: 140, height: 12),
                        SizedBox(height: 6),
                        ShimmerBox(width: 90, height: 10),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              ShimmerBox(height: 130),
            ],
          ),
        ),
      );

  Widget _form() => ListView(
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          for (var i = 0; i < itemCount; i++) ...[
            const ShimmerBox(width: 110, height: 12),
            const SizedBox(height: 8),
            ShimmerBox(height: i == 1 ? 96 : 50),
            const SizedBox(height: 18),
          ],
        ],
      );

  Widget _timeline() => const SingleChildScrollView(
        padding: EdgeInsets.all(12),
        physics: NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ShimmerBox(height: 14),
            SizedBox(height: 10),
            ShimmerBox(height: 48),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(flex: 3, child: ShimmerBox(height: 36)),
                SizedBox(width: 6),
                Expanded(flex: 2, child: ShimmerBox(height: 36)),
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: ShimmerBox(height: 36)),
                SizedBox(width: 6),
                Expanded(flex: 3, child: ShimmerBox(height: 36)),
              ],
            ),
          ],
        ),
      );
}

/// One skeleton block. Inside [ShimmerLoading] it inherits the shimmer; alone, pass [animate].
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    this.width = double.infinity,
    this.height = double.infinity,
    this.circle = false,
    this.animate = false,
  });

  final double width;
  final double height;
  final bool circle;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(AppColors.border_radius),
      ),
    );
    if (!animate) return box;
    return Shimmer.fromColors(baseColor: _base, highlightColor: _highlight, child: box);
  }
}
