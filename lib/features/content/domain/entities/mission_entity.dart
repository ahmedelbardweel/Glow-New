import 'package:equatable/equatable.dart';

class MissionEntity extends Equatable {
  final String id;
  final String worldId;
  final String title;
  final String badgeName;
  final int starsReward;
  final int orderIndex;

  const MissionEntity({
    required this.id,
    required this.worldId,
    required this.title,
    required this.badgeName,
    required this.starsReward,
    required this.orderIndex,
  });

  @override
  List<Object?> get props => [id, worldId, title, badgeName, starsReward, orderIndex];
}
