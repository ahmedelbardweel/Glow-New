import '../../domain/entities/child_progress_entity.dart';

class ChildProgressModel extends ChildProgressEntity {
  const ChildProgressModel({
    required super.id,
    required super.childId,
    required super.missionId,
    required super.completedAt,
    super.missionTitle,
    super.badgeName,
    super.starsReward,
  });

  factory ChildProgressModel.fromJson(Map<String, dynamic> json) {
    // If joined with missions table or loaded from local cache
    final missionData = json['missions'] as Map<String, dynamic>?;
    
    return ChildProgressModel(
      id: (json['id'] as String?) ?? '',
      childId: json['child_id'] as String,
      missionId: json['mission_id'] as String,
      completedAt: json['completed_at'] != null 
          ? DateTime.parse(json['completed_at'] as String) 
          : DateTime.now(),
      missionTitle: (missionData?['title'] ?? json['mission_title']) as String?,
      badgeName: (missionData?['badge_name'] ?? json['badge_name']) as String?,
      starsReward: (missionData?['stars_reward'] ?? json['stars_reward']) as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'child_id': childId,
      'mission_id': missionId,
    };
  }

  Map<String, dynamic> toLocalJson() {
    return {
      'id': id,
      'child_id': childId,
      'mission_id': missionId,
      'completed_at': completedAt.toIso8601String(),
      if (missionTitle != null) 'mission_title': missionTitle,
      if (badgeName != null) 'badge_name': badgeName,
      if (starsReward != null) 'stars_reward': starsReward,
    };
  }
}
