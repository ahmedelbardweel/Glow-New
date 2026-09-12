import '../../domain/entities/child_profile_entity.dart';

class ChildProfileModel extends ChildProfileEntity {
  const ChildProfileModel({
    required super.id,
    required super.name,
    required super.age,
    required super.avatarUrl,
    required super.childCode,
    super.parentId,
  });

  factory ChildProfileModel.fromJson(Map<String, dynamic> json) {
    return ChildProfileModel(
      id: json['id'] as String,
      name: json['name'] as String,
      age: json['age'] as int,
      avatarUrl: json['avatar_url'] as String,
      childCode: json['child_code'] as String,
      parentId: json['parent_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'avatar_url': avatarUrl,
      'child_code': childCode,
      'parent_id': parentId,
    };
  }
}

