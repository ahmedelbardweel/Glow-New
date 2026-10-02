import 'dart:math' as math;

import 'package:flutter/material.dart';

class StoryBlock {
  final String characterId;
  final double startTime; // In seconds
  final double endTime; // In seconds

  StoryBlock({
    required this.characterId,
    required this.startTime,
    required this.endTime,
  });

  bool isPlaying(double currentTime) {
    return currentTime >= startTime && currentTime <= endTime;
  }

  factory StoryBlock.fromJson(Map<String, dynamic> json) {
    return StoryBlock(
      characterId: json['characterId'] as String,
      startTime: (json['startTime'] as num).toDouble(),
      endTime: (json['endTime'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'characterId': characterId,
      'startTime': startTime,
      'endTime': endTime,
    };
  }
}

class StoryMotionBlock {
  final String motionId; // Usually the clipName of CharacterMotion
  final double startTime; // In seconds
  final double endTime; // In seconds

  StoryMotionBlock({
    required this.motionId,
    required this.startTime,
    required this.endTime,
  });

  bool isPlaying(double currentTime) {
    return currentTime >= startTime && currentTime <= endTime;
  }

  factory StoryMotionBlock.fromJson(Map<String, dynamic> json) {
    return StoryMotionBlock(
      motionId: json['motionId'] as String,
      startTime: (json['startTime'] as num).toDouble(),
      endTime: (json['endTime'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'motionId': motionId,
      'startTime': startTime,
      'endTime': endTime,
    };
  }
}

/// Timed hat overlay. Drag payload uses `hat:RRGGBB`.
class StoryHatBlock {
  final String colorHex; // RRGGBB, no leading #
  final double startTime;
  final double endTime;

  StoryHatBlock({
    required this.colorHex,
    required this.startTime,
    required this.endTime,
  });

  Color get color {
    final normalized = colorHex.replaceAll('#', '').padLeft(6, '0');
    return Color(int.parse('FF$normalized', radix: 16));
  }

  static String dragDataFor(Color color) {
    final hex = (color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0');
    return 'hat:$hex';
  }

  static String? colorHexFromDrag(String data) {
    if (!data.startsWith('hat:')) return null;
    final hex = data.substring(4).replaceAll('#', '');
    if (hex.length != 6) return null;
    return hex.toLowerCase();
  }

  bool isPlaying(double currentTime) {
    return currentTime >= startTime && currentTime <= endTime;
  }

  factory StoryHatBlock.fromJson(Map<String, dynamic> json) {
    return StoryHatBlock(
      colorHex: (json['colorHex'] as String? ?? '2c2c2e').replaceAll('#', ''),
      startTime: (json['startTime'] as num).toDouble(),
      endTime: (json['endTime'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'colorHex': colorHex,
      'startTime': startTime,
      'endTime': endTime,
    };
  }
}

/// Timed glasses overlay. Drag payload is `glasses`.
class StoryGlassesBlock {
  final double startTime;
  final double endTime;

  StoryGlassesBlock({required this.startTime, required this.endTime});

  static const dragData = 'glasses';

  static bool isDrag(String data) => data == dragData;

  bool isPlaying(double currentTime) {
    return currentTime >= startTime && currentTime <= endTime;
  }

  factory StoryGlassesBlock.fromJson(Map<String, dynamic> json) {
    return StoryGlassesBlock(
      startTime: (json['startTime'] as num).toDouble(),
      endTime: (json['endTime'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'startTime': startTime, 'endTime': endTime};
  }
}

/// Timed belly-muscle overlay. Drag payload is `muscles`.
class StoryMusclesBlock {
  final double startTime;
  final double endTime;

  StoryMusclesBlock({required this.startTime, required this.endTime});

  static const dragData = 'muscles';

  static bool isDrag(String data) => data == dragData;

  bool isPlaying(double currentTime) {
    return currentTime >= startTime && currentTime <= endTime;
  }

  factory StoryMusclesBlock.fromJson(Map<String, dynamic> json) {
    return StoryMusclesBlock(
      startTime: (json['startTime'] as num).toDouble(),
      endTime: (json['endTime'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'startTime': startTime, 'endTime': endTime};
  }
}

/// A jump the character performs on its own lane, under the character track.
class StoryJumpBlock {
  final double startTime;
  final double endTime;

  StoryJumpBlock({required this.startTime, required this.endTime});

  static const dragData = 'jump';

  static bool isDrag(String data) => data == dragData;

  bool isPlaying(double currentTime) {
    return currentTime >= startTime && currentTime <= endTime;
  }

  StoryTransitionPose poseAt(double time) {
    if (!isPlaying(time)) return StoryTransitionPose.rest;
    final phase = ((time - startTime) % 0.7) / 0.7;
    final hop = math.sin(phase * math.pi);
    return StoryTransitionPose(jump: -hop * 0.2);
  }

  factory StoryJumpBlock.fromJson(Map<String, dynamic> json) {
    return StoryJumpBlock(
      startTime: (json['startTime'] as num).toDouble(),
      endTime: (json['endTime'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'startTime': startTime, 'endTime': endTime};
  }
}

/// How the character looks while a timeline transition is playing.
class StoryTransitionPose {
  final double opacity;
  final double slide;
  final double jump;
  final double scale;

  const StoryTransitionPose({
    this.opacity = 1,
    this.slide = 0,
    this.jump = 0,
    this.scale = 1,
  });

  static const rest = StoryTransitionPose();
}

/// An effect placed on the seam between two character blocks.
class StoryTransition {
  static const fade = 'fade';
  static const slide = 'slide';
  static const pop = 'pop';
  static const types = [fade, slide, pop];

  final double time;
  final double duration;
  final String type;

  StoryTransition({
    required this.time,
    this.duration = 0.5,
    this.type = fade,
  });

  static String dragDataFor(String type) => 'transition:$type';

  static bool isDrag(String data) => data.startsWith('transition:');

  static String? typeOf(String data) {
    if (!isDrag(data)) return null;
    final type = data.substring('transition:'.length);
    return types.contains(type) ? type : null;
  }

  static String label(String type) {
    switch (type) {
      case slide:
        return 'انزلاق';
      case pop:
        return 'تكبير';
      default:
        return 'تلاشي';
    }
  }

  double get start => time - duration / 2;
  double get end => time + duration / 2;

  bool covers(double t) => t >= start && t <= end;

  StoryTransitionPose poseAt(double t) {
    if (!covers(t) || duration <= 0) return StoryTransitionPose.rest;
    final span = ((t - start) / duration).clamp(0.0, 1.0);
    final fromCenter = ((t - time) / (duration / 2)).clamp(-1.0, 1.0);
    switch (type) {
      case slide:
        final travel = fromCenter <= 0 ? -(fromCenter + 1) : (1 - fromCenter);
        return StoryTransitionPose(slide: travel);
      case pop:
        final pop = math.sin(span * math.pi);
        return StoryTransitionPose(scale: 1 + pop * 0.42);
      default:
        return StoryTransitionPose(opacity: fromCenter.abs().clamp(0.0, 1.0));
    }
  }

  factory StoryTransition.fromJson(Map<String, dynamic> json) {
    final raw = json['type'] as String?;
    return StoryTransition(
      time: (json['time'] as num).toDouble(),
      duration: (json['duration'] as num?)?.toDouble() ?? 0.5,
      type: raw != null && types.contains(raw) ? raw : fade,
    );
  }

  Map<String, dynamic> toJson() => {
        'time': time,
        'duration': duration,
        'type': type,
      };
}

class StoryTimeline {
  final List<StoryBlock> blocks;
  final List<StoryMotionBlock> motionBlocks;
  final List<StoryHatBlock> hatBlocks;
  final List<StoryGlassesBlock> glassesBlocks;
  final List<StoryMusclesBlock> musclesBlocks;
  final List<StoryJumpBlock> jumpBlocks;
  final List<StoryTransition> transitions;
  final double totalDuration; // In seconds

  StoryTimeline({
    required this.blocks,
    this.motionBlocks = const [],
    this.hatBlocks = const [],
    this.glassesBlocks = const [],
    this.musclesBlocks = const [],
    this.jumpBlocks = const [],
    this.transitions = const [],
    required this.totalDuration,
  });

  /// Returns the character that should be active at the given time.
  /// If multiple blocks overlap, it returns the first one found.
  /// If no block is active, it returns null.
  String? getActiveCharacterAt(double time) {
    for (final block in blocks) {
      if (block.isPlaying(time)) {
        return block.characterId;
      }
    }
    return null;
  }

  /// Returns the motion that should be active at the given time.
  String? getActiveMotionAt(double time) {
    for (final block in motionBlocks) {
      if (block.isPlaying(time)) {
        return block.motionId;
      }
    }
    return null;
  }

  /// Returns the hat block active at [time], or null when the hat is off.
  StoryHatBlock? getActiveHatAt(double time) {
    for (final block in hatBlocks) {
      if (block.isPlaying(time)) return block;
    }
    return null;
  }

  /// Whether the glasses should be on at [time].
  bool glassesOnAt(double time) {
    for (final block in glassesBlocks) {
      if (block.isPlaying(time)) return true;
    }
    return false;
  }

  /// Whether the belly muscles should be on at [time].
  bool musclesOnAt(double time) {
    for (final block in musclesBlocks) {
      if (block.isPlaying(time)) return true;
    }
    return false;
  }

  StoryTransitionPose poseAt(double time) {
    var pose = StoryTransitionPose.rest;
    for (final transition in transitions) {
      if (transition.covers(time)) {
        pose = transition.poseAt(time);
        break;
      }
    }
    for (final jump in jumpBlocks) {
      if (!jump.isPlaying(time)) continue;
      final hop = jump.poseAt(time);
      return StoryTransitionPose(
        opacity: pose.opacity,
        slide: pose.slide,
        jump: pose.jump + hop.jump,
        scale: pose.scale * hop.scale,
      );
    }
    return pose;
  }

  double characterOpacityAt(double time) => poseAt(time).opacity;

  /// Returns a unique list of all characters used in this timeline
  /// This is useful for preloading models.
  List<String> get allCharacterIds {
    return blocks.map((b) => b.characterId).toSet().toList();
  }

  factory StoryTimeline.fromJson(Map<String, dynamic> json) {
    final blocksList = json['blocks'] as List<dynamic>? ?? [];
    final motionBlocksList = json['motionBlocks'] as List<dynamic>? ?? [];
    final hatBlocksList = json['hatBlocks'] as List<dynamic>? ?? [];
    final glassesBlocksList = json['glassesBlocks'] as List<dynamic>? ?? [];
    final musclesBlocksList = json['musclesBlocks'] as List<dynamic>? ?? [];
    final jumpBlocksList = json['jumpBlocks'] as List<dynamic>? ?? [];
    final transitionsList = json['transitions'] as List<dynamic>? ?? [];
    return StoryTimeline(
      blocks: blocksList
          .map((b) => StoryBlock.fromJson(b as Map<String, dynamic>))
          .toList(),
      motionBlocks: motionBlocksList
          .map((b) => StoryMotionBlock.fromJson(b as Map<String, dynamic>))
          .toList(),
      hatBlocks: hatBlocksList
          .map((b) => StoryHatBlock.fromJson(b as Map<String, dynamic>))
          .toList(),
      glassesBlocks: glassesBlocksList
          .map((b) => StoryGlassesBlock.fromJson(b as Map<String, dynamic>))
          .toList(),
      musclesBlocks: musclesBlocksList
          .map((b) => StoryMusclesBlock.fromJson(b as Map<String, dynamic>))
          .toList(),
      jumpBlocks: jumpBlocksList
          .map((b) => StoryJumpBlock.fromJson(b as Map<String, dynamic>))
          .toList(),
      transitions: transitionsList
          .map((b) => StoryTransition.fromJson(b as Map<String, dynamic>))
          .toList(),
      totalDuration: (json['totalDuration'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'blocks': blocks.map((b) => b.toJson()).toList(),
      'motionBlocks': motionBlocks.map((b) => b.toJson()).toList(),
      'hatBlocks': hatBlocks.map((b) => b.toJson()).toList(),
      'glassesBlocks': glassesBlocks.map((b) => b.toJson()).toList(),
      'musclesBlocks': musclesBlocks.map((b) => b.toJson()).toList(),
      'jumpBlocks': jumpBlocks.map((b) => b.toJson()).toList(),
      'transitions': transitions.map((b) => b.toJson()).toList(),
      'totalDuration': totalDuration,
    };
  }
}
