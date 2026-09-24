import 'package:flutter/material.dart';

class CharacterHelper {
  /// The five identities share one mesh, skeleton and animation library.
  static const sharedModelPath = 'assets/3d/glow_mascot.glb';
  static const Map<String, Map<String, dynamic>> characters = {
    'fort': {
      'color': Color(0xFFA63352), // Red/Coral
      'model': 'glow_mascot.glb',
    },
    'lort': {
      'color': Color(0xFF8FA685), // Golden/Yellow
      'model': 'glow_mascot.glb',
    },
    'mort': {
      'color': Color(0xFFD9A9B2), // Deep Magenta/Red
      'model': 'glow_mascot.glb',
    },
    'port': {
      'color': Color(0xFF36593C), // Darker Green
      'model': 'glow_mascot.glb',
    },
    'qort': {
      'color': Color(0xFFAAD7E9), // Blue
      'model': 'glow_mascot.glb',
    },
  };

  static String getCleanName(String rawName) {
    if (rawName.trim().isEmpty) return 'شخصية';
    String lower = rawName.toLowerCase();

    // Find matching key
    for (var key in characters.keys) {
      if (lower.contains(key)) {
        return key[0].toUpperCase() + key.substring(1);
      }
    }

    // Fallback if it's a custom character
    String nameToProcess = rawName;
    if (rawName.startsWith('http')) {
      try {
        final uri = Uri.parse(rawName);
        if (uri.queryParameters.containsKey('name')) {
          return uri.queryParameters['name']!;
        }
        nameToProcess = uri.pathSegments.last;
      } catch (_) {}
    }

    String clean = nameToProcess
        .toUpperCase()
        .replaceAll('.GLB', '')
        .replaceAll('.GLTF', '')
        .split('_')
        .first;
    if (clean.length > 1) {
      clean = clean[0] + clean.substring(1).toLowerCase();
    }
    return clean;
  }

  static Color getColor(String rawName) {
    if (rawName.startsWith('http')) {
      try {
        final uri = Uri.parse(rawName);
        if (uri.queryParameters.containsKey('color')) {
          final colorKey = uri.queryParameters['color']!;
          if (characters.containsKey(colorKey)) {
            return characters[colorKey]!['color'] as Color;
          }
        }
      } catch (_) {}
    }

    final lower = rawName.toLowerCase();
    for (var key in characters.keys) {
      if (lower.contains(key)) {
        return characters[key]!['color'] as Color;
      }
    }
    return Colors.purple.shade300; // Default color for custom characters
  }

  static String getColorKey(String rawName) {
    if (rawName.startsWith('http')) {
      try {
        final uri = Uri.parse(rawName);
        if (uri.queryParameters.containsKey('color')) {
          final colorKey = uri.queryParameters['color']!;
          if (characters.containsKey(colorKey)) {
            return colorKey;
          }
        }
      } catch (_) {}
    }

    final lower = rawName.toLowerCase();
    for (var key in characters.keys) {
      if (lower.contains(key)) {
        return key;
      }
    }
    return 'qort'; // Default
  }

  static String getModelPath(String rawName) {
    if (rawName.startsWith('http') || rawName.startsWith('file://')) {
      return rawName;
    }

    // Resolve legacy saved filenames without changing the stored identity.
    return sharedModelPath;
  }
}
