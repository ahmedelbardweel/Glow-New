import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/di/injection_container.dart';
import '../services/resource_manager.dart';

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
        // Trigger background download and caching
        resourceManager.downloadAndCacheFile(url, folder: 'images').then((downloadedPath) {
          if (mounted && downloadedPath != null && _localPath != downloadedPath) {
            setState(() => _localPath = downloadedPath);
          }
        });
      }
    } catch (_) {
      // ResourceManager may not be registered in tests
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    // Safely calculate raster cache width avoiding infinity/NaN crashes
    final int? memWidth = (widget.width != null && widget.width!.isFinite)
        ? (widget.width! * 2).round()
        : 800;

    if (_localPath != null) {
      imageWidget = Image.file(
        File(_localPath!),
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        cacheWidth: memWidth,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
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
        filterQuality: FilterQuality.medium,
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
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey.shade200,
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
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
