import '../../domain/entities/mission_entity.dart';

class MissionModel extends MissionEntity {
  const MissionModel({
    required super.id,
    required super.worldId,
    required super.title,
    required super.badgeName,
    required super.starsReward,
    required super.orderIndex,
  });

  factory MissionModel.fromJson(Map<String, dynamic> json) {
    return MissionModel(
      id: json['id'] as String,
      worldId: json['world_id'] as String,
      title: json['title'] as String? ?? '',
      badgeName: json['badge_name'] as String? ?? '',
      starsReward: json['stars_reward'] as int? ?? 0,
      orderIndex: json['order_index'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'world_id': worldId,
      'title': title,
      'badge_name': badgeName,
      'stars_reward': starsReward,
      'order_index': orderIndex,
    };
  }
}
