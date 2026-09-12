import '../../domain/entities/story_entity.dart';

class StoryModel extends StoryEntity {
  const StoryModel({
    required super.id,
    required super.missionId,
    required super.title,
    required super.characterName,
    required super.content,
    required super.imageUrl,
    required super.orderIndex,
    super.audioUrl,
  });

  factory StoryModel.fromEntity(StoryEntity entity) {
    return StoryModel(
      id: entity.id,
      missionId: entity.missionId,
      title: entity.title,
      characterName: entity.characterName,
      content: entity.content,
      imageUrl: entity.imageUrl,
      orderIndex: entity.orderIndex,
      audioUrl: entity.audioUrl,
    );
  }

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    return StoryModel(
      id: json['id'] as String,
      missionId: json['mission_id'] as String,
      title: json['title'] as String? ?? '',
      characterName: json['character_name'] as String? ?? 'الراوي',
      content: json['content'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      orderIndex: json['order_index'] as int? ?? 0,
      audioUrl: json['audio_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'mission_id': missionId,
      'title': title,
      'character_name': characterName,
      'content': content,
      'image_url': imageUrl,
      'order_index': orderIndex,
      if (audioUrl != null) 'audio_url': audioUrl,
    };
  }
}
