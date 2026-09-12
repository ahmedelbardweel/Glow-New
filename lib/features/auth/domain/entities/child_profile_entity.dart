import 'package:equatable/equatable.dart';

class ChildProfileEntity extends Equatable {
  final String id;
  final String name;
  final int age;
  final String avatarUrl;
  final String childCode;
  final String? parentId;

  const ChildProfileEntity({
    required this.id,
    required this.name,
    required this.age,
    required this.avatarUrl,
    required this.childCode,
    this.parentId,
  });

  @override
  List<Object?> get props => [id, name, age, avatarUrl, childCode, parentId];
}

