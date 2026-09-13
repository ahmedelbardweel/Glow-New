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
    String clean = rawName
        .toUpperCase()
        .replaceAll('.GLB', '')
        .split('_')
        .first;
    if (clean.length > 1) {
      clean = clean[0] + clean.substring(1).toLowerCase();
    }
    return clean;
  }

  static Color getColor(String rawName) {
    final lower = rawName.toLowerCase();
    for (var key in characters.keys) {
      if (lower.contains(key)) {
        return characters[key]!['color'] as Color;
      }
    }
    return Colors.purple.shade300; // Default color for custom characters
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
