import 'package:equatable/equatable.dart';

class ChildProgressEntity extends Equatable {
  final String id;
  final String childId;
  final String missionId;
  final DateTime completedAt;
  
  // Joined fields for Badges screen
  final String? missionTitle;
  final String? badgeName;
  final int? starsReward;

  const ChildProgressEntity({
    required this.id,
    required this.childId,
    required this.missionId,
    required this.completedAt,
    this.missionTitle,
    this.badgeName,
    this.starsReward,
  });

  @override
  List<Object?> get props => [id, childId, missionId, completedAt, missionTitle, badgeName, starsReward];
}
