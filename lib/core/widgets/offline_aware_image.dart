import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/di/injection_container.dart';
import '../services/resource_manager.dart';
import 'package:shimmer/shimmer.dart';

class OfflineAwareImage extends StatefulWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;

  const OfflineAwareImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
  });

  @override
  State<OfflineAwareImage> createState() => _OfflineAwareImageState();
}

class _OfflineAwareImageState extends State<OfflineAwareImage> {
  String? _localPath;

  @override
  void initState() {
    super.initState();
    _checkAndCache();
  }

  @override
  void didUpdateWidget(covariant OfflineAwareImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _checkAndCache();
    }
  }

  void _checkAndCache() {
    final url = widget.imageUrl?.trim() ?? '';
    if (url.isEmpty) {
      if (_localPath != null && mounted) setState(() => _localPath = null);
      return;
    }

    try {
      final resourceManager = sl<ResourceManager>();
      final local = resourceManager.getLocalFilePath(url);
      if (local != null) {
        if (_localPath != local && mounted) {
          setState(() => _localPath = local);
        }
      } else if (url.startsWith('http')) {
        // Trigger background download and caching WITHOUT updating state.
        // We will just show the network image for this session, and it will be 
        // loaded from cache next time we open this URL. This prevents UI flashing.
        resourceManager.downloadAndCacheInBackground(url, folder: 'images');
      }
    } catch (_) {
      // ResourceManager may not be registered in tests
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    // Safely calculate raster cache width using MediaQuery as fallback for infinite/null width
    double effectiveWidth = widget.width ?? MediaQuery.of(context).size.width;
    if (effectiveWidth.isInfinite || effectiveWidth.isNaN) {
      effectiveWidth = MediaQuery.of(context).size.width;
    }
    // Constrain to a reasonable maximum (e.g., 800) to prevent excessive memory usage
    int memWidth = (effectiveWidth * MediaQuery.of(context).devicePixelRatio).round();
    if (memWidth > 800) memWidth = 800;

    if (_localPath != null) {
      imageWidget = Image.file(
        File(_localPath!),
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        cacheWidth: memWidth,
        gaplessPlayback: true,
        filterQuality: FilterQuality.low,
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
      );
    } else if (widget.imageUrl != null && widget.imageUrl!.trim().startsWith('http')) {
      imageWidget = Image.network(
        widget.imageUrl!.trim(),
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        cacheWidth: memWidth,
        gaplessPlayback: true,
        filterQuality: FilterQuality.low,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return widget.placeholder ?? _buildPlaceholder();
        },
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
      );
    } else {
      imageWidget = _buildErrorWidget();
    }

    if (widget.borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: widget.borderRadius!,
        child: imageWidget,
      );
    }

    return RepaintBoundary(child: imageWidget);
  }

  Widget _buildPlaceholder() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: widget.width ?? double.infinity,
        height: widget.height ?? double.infinity,
        color: Colors.white,
      ),
    );
  }

  Widget _buildErrorWidget() {
    return widget.errorWidget ??
        Container(
          width: widget.width,
          height: widget.height,
          decoration: const BoxDecoration(
            color: Color(0x263498DB),
          ),
          child: const Center(
            child: Icon(
              Icons.image_rounded,
              color: Color(0xFF3498DB),
              size: 40,
            ),
          ),
        );
  }
}
