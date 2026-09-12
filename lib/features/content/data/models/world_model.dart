import '../../domain/entities/world_entity.dart';

class WorldModel extends WorldEntity {
  const WorldModel({
    required super.id,
    required super.title,
    required super.description,
    required super.imageUrl,
  });

  factory WorldModel.fromJson(Map<String, dynamic> json) {
    return WorldModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'title': title,
      'description': description,
      'image_url': imageUrl,
    };
  }
}
