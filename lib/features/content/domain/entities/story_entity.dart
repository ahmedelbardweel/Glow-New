import 'package:equatable/equatable.dart';

class StoryEntity extends Equatable {
  final String id;
  final String missionId;
  final String title;
  final String characterName;
  final String content;
  final String imageUrl;
  final int orderIndex;
  final String? audioUrl;

  const StoryEntity({
    required this.id,
    required this.missionId,
    required this.title,
    required this.characterName,
    required this.content,
    required this.imageUrl,
    required this.orderIndex,
    this.audioUrl,
  });

  @override
  List<Object?> get props => [id, missionId, title, characterName, content, imageUrl, orderIndex, audioUrl];
}
