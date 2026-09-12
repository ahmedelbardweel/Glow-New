import 'package:equatable/equatable.dart';

class WorldEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final String imageUrl;

  const WorldEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
  });

  @override
  List<Object?> get props => [id, title, description, imageUrl];
}
