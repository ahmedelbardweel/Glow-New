import 'package:flutter/material.dart';

class CustomCharacterModel {
  final String id;
  final String name;
  final String bodyColorHex;
  final String bellyColorHex;
  final bool hasHat;
  final String hatColorHex;
  final bool hasGlasses;
  final DateTime createdAt;

  const CustomCharacterModel({
    required this.id,
    required this.name,
    required this.bodyColorHex,
    required this.bellyColorHex,
    this.hasHat = false,
    this.hatColorHex = '#2C2C2E',
    this.hasGlasses = false,
    required this.createdAt,
  });

  Color get bodyColor => _hexToColor(bodyColorHex, defaultColor: const Color(0xFFD09236));
  Color get bellyColor => _hexToColor(bellyColorHex, defaultColor: const Color(0xFFEFECE6));
  Color get hatColor => _hexToColor(hatColorHex, defaultColor: const Color(0xFF2C2C2E));

  static Color _hexToColor(String hex, {required Color defaultColor}) {
    try {
      String clean = hex.replaceAll('#', '').trim();
      if (clean.length == 6) {
        clean = 'FF$clean';
      }
      if (clean.length == 8) {
        return Color(int.parse(clean, radix: 16));
      }
    } catch (_) {}
    return defaultColor;
  }

  static String colorToHex(Color color) {
    return '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'body_color': bodyColorHex,
      'belly_color': bellyColorHex,
      'has_hat': hasHat,
      'hat_color': hatColorHex,
      'has_glasses': hasGlasses,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory CustomCharacterModel.fromJson(Map<String, dynamic> json) {
    return CustomCharacterModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'شخصية',
      bodyColorHex: json['body_color'] as String? ?? '#D09236',
      bellyColorHex: json['belly_color'] as String? ?? '#EFECE6',
      hasHat: json['has_hat'] as bool? ?? false,
      hatColorHex: json['hat_color'] as String? ?? '#2C2C2E',
      hasGlasses: json['has_glasses'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  CustomCharacterModel copyWith({
    String? id,
    String? name,
    String? bodyColorHex,
    String? bellyColorHex,
    bool? hasHat,
    String? hatColorHex,
    bool? hasGlasses,
    DateTime? createdAt,
  }) {
    return CustomCharacterModel(
      id: id ?? this.id,
      name: name ?? this.name,
      bodyColorHex: bodyColorHex ?? this.bodyColorHex,
      bellyColorHex: bellyColorHex ?? this.bellyColorHex,
      hasHat: hasHat ?? this.hasHat,
      hatColorHex: hatColorHex ?? this.hatColorHex,
      hasGlasses: hasGlasses ?? this.hasGlasses,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
