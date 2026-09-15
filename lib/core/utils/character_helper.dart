import 'package:flutter/material.dart';

class CharacterHelper {
  static const Map<String, Map<String, dynamic>> characters = {
    'fort': {
      'color': Color(0xFF733434), // Red/Coral
      'model': 'fort_frontal.glb',
    },
    'lort': {
      'color': Color(0xFFD4AC0D), // Golden/Yellow
      'model': 'lort_frontal.glb',
    },
    'mort': {
      'color': Color(0xFF9C1B42), // Deep Magenta/Red
      'model': 'mort_frontal.glb',
    },
    'port': {
      'color': Color(0xFF22592A), // Darker Green
      'model': 'port_frontal.glb',
    },
    'qort': {
      'color': Color(0xFF033E8C), // Blue
      'model': 'qort_frontal.glb',
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
    return 'fort'; // Default
  }

  static String getModelPath(String rawName) {
    if (rawName.startsWith('http')) return rawName;

    final lower = rawName.toLowerCase();
    for (var key in characters.keys) {
      if (lower.contains(key)) {
        return 'assets/3d/${characters[key]!['model']}';
      }
    }

    // Custom uploaded local model fallback
    String clean = rawName.trim().toLowerCase();
    if (!clean.endsWith('.glb') && !clean.endsWith('.gltf')) {
      clean += '.glb';
    }
    return 'assets/3d/$clean';
  }
}
