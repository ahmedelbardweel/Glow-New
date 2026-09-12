import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String email;
  final String role; // 'parent' or 'admin'

  const UserEntity({
    required this.id,
    required this.email,
    required this.role,
  });

  @override
  List<Object?> get props => [id, email, role];
}
