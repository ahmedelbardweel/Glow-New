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
  bool _isLoading = false;
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

  void _loadModel() async {
    final modelUrl = CharacterHelper.getModelPath(widget.characterName);
    
    if (modelUrl.startsWith('http')) {
      final resourceManager = sl<ResourceManager>();
      
      // Check if already cached
      final cachedPath = resourceManager.getLocalFilePath(modelUrl);
      if (cachedPath != null) {
        if (mounted) {
          setState(() {
            _modelSrc = 'file://$cachedPath';
            _isLoading = false;
          });
        }
        return;
      }
      
      // If not cached, show loading and download
      if (mounted) {
        setState(() {
          _isLoading = true;
          _modelSrc = modelUrl; // fallback to url if download fails
        });
      }
      
      final downloadedPath = await resourceManager.downloadAndCacheFile(modelUrl, folder: '3d_models');
      if (downloadedPath != null && mounted) {
        setState(() {
          _modelSrc = 'file://$downloadedPath';
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      // Local asset
      if (mounted) {
        setState(() {
          _modelSrc = modelUrl;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _modelSrc.isEmpty) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            CharacterHelper.getColor(widget.characterName),
          ),
        ),
      );
    }

    return Stack(
      children: [
        ModelViewer(
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
        ),
        if (_isLoading)
          Positioned(
            top: 8,
            right: 8,
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  CharacterHelper.getColor(widget.characterName),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
