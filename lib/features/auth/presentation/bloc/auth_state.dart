import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/child_profile_entity.dart';
import '../../domain/entities/user_entity.dart';

part 'auth_state.freezed.dart';

@freezed
class AuthState with _$AuthState {
  const factory AuthState.initial() = _Initial;
  const factory AuthState.loading() = _Loading;
  const factory AuthState.childRegistered(ChildProfileEntity child) = _ChildRegistered;
  const factory AuthState.parentRegistered(UserEntity user) = _ParentRegistered;
  const factory AuthState.adminLoggedIn(UserEntity user) = _AdminLoggedIn;
  const factory AuthState.error(String message) = _Error;
}
