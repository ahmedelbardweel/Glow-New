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

class StoryTimeline {
  final List<StoryBlock> blocks;
  final double totalDuration; // In seconds

  StoryTimeline({
    required this.blocks,
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

  /// Returns a unique list of all characters used in this timeline
  /// This is useful for preloading models.
  List<String> get allCharacterIds {
    return blocks.map((b) => b.characterId).toSet().toList();
  }

  factory StoryTimeline.fromJson(Map<String, dynamic> json) {
    final blocksList = json['blocks'] as List<dynamic>? ?? [];
    return StoryTimeline(
      blocks: blocksList.map((b) => StoryBlock.fromJson(b as Map<String, dynamic>)).toList(),
      totalDuration: (json['totalDuration'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'blocks': blocks.map((b) => b.toJson()).toList(),
      'totalDuration': totalDuration,
    };
  }
}
