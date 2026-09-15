import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../services/resource_manager.dart';
import '../di/injection_container.dart';
import '../utils/character_helper.dart';

class SmartCharacterViewer extends StatefulWidget {
  final String characterName;

  const SmartCharacterViewer({
    super.key,
    required this.characterName,
  });

  @override
  State<SmartCharacterViewer> createState() => _SmartCharacterViewerState();
}

class _SmartCharacterViewerState extends State<SmartCharacterViewer> {
  String? _localPath;
  bool _isLoading = false; // Kept for compatibility if used elsewhere, but not needed.
  String _modelSrc = '';

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  @override
  void didUpdateWidget(covariant SmartCharacterViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.characterName != widget.characterName) {
      _loadModel();
    }
  }

  void _loadModel() {
    final modelUrl = CharacterHelper.getModelPath(widget.characterName);
    
    if (modelUrl.startsWith('http')) {
      final resourceManager = sl<ResourceManager>();
      
      // Check if already cached
      final cachedPath = resourceManager.getLocalFilePath(modelUrl);
      if (cachedPath != null) {
        if (mounted) {
          setState(() {
            _modelSrc = 'file://$cachedPath';
          });
        }
        return;
      }
      
      // If not cached, instantly set the HTTP URL so ModelViewer streams it immediately
      if (mounted) {
        setState(() {
          _modelSrc = modelUrl;
        });
      }
      
      // In the background, silently cache it for future use without awaiting
      resourceManager.downloadAndCacheInBackground(modelUrl, folder: '3d_models');
    } else {
      // Local asset
      if (mounted) {
        setState(() {
          _modelSrc = modelUrl;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_modelSrc.isEmpty) {
      return const SizedBox();
    }

    return ModelViewer(
      key: ValueKey(_modelSrc),
      src: _modelSrc,
      alt: "3D Character",
      autoRotate: true,
      cameraControls: true,
      // Add smart environment for better colors!
      environmentImage: 'neutral', // Better lighting
      interactionPrompt: InteractionPrompt.none,
      // Hide default UI
      poster: '',
    );
  }
}
