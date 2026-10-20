import 'package:flutter/material.dart';
import '../di/injection_container.dart';
import '../../features/content/data/repositories/custom_character_repository.dart';

class CharacterHelper {
  /// The five identities share one mesh, skeleton and animation library.
  static const sharedModelPath = 'assets/3d/glow_mascot.glb';
  static const Map<String, Map<String, dynamic>> characters = {
    'fort': {
      'color': Color(0xFF912740), // Rich Ruby / Crimson
      'model': 'glow_mascot.glb',
    },
    'lort': {
      'color': Color(0xFF6E8B62), // Rich Sage Green
      'model': 'glow_mascot.glb',
    },
    'mort': {
      'color': Color(0xFFB55D75), // Deep Berry / Rose Mauve
      'model': 'glow_mascot.glb',
    },
    'port': {
      'color': Color(0xFF28542F), // Deep Emerald Forest Green
      'model': 'glow_mascot.glb',
    },
    'qort': {
      'color': Color(0xFF4A90B8), // Deep Vibrant Cyan Sky Blue
      'model': 'glow_mascot.glb',
    },
    'sort': {
      'color': Color(0xFFD09236), // Rich Golden Amber
      'model': 'glow_mascot.glb',
    },
  };

  static String getCleanName(String rawName) {
    if (rawName.trim().isEmpty) return 'شخصية';
    try {
      final custom = sl<CustomCharacterRepository>().findCharacter(rawName);
      if (custom != null) return custom.name;
    } catch (_) {}

    if (rawName.startsWith('custom|')) {
      final parts = rawName.split('|');
      if (parts.length >= 3 && parts[2].trim().isNotEmpty) {
        return parts[2].trim();
      }
      return 'شخصية مخصصة';
    }

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
    try {
      final custom = sl<CustomCharacterRepository>().findCharacter(rawName);
      if (custom != null) return custom.bodyColor;
    } catch (_) {}

    if (rawName.startsWith('custom|')) {
      final parts = rawName.split('|');
      if (parts.length >= 2) {
        final idOrHex = parts[1];
        if (idOrHex.startsWith('#')) {
          try {
            final clean = idOrHex.replaceAll('#', '').trim();
            if (clean.length == 6) return Color(int.parse('FF$clean', radix: 16));
            if (clean.length == 8) return Color(int.parse(clean, radix: 16));
          } catch (_) {}
        }
      }
    }

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
