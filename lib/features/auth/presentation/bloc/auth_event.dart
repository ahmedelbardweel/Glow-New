import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_event.freezed.dart';

@freezed
class AuthEvent with _$AuthEvent {
  const factory AuthEvent.registerChild({
    required String name,
    required int age,
    required String avatarUrl,
  }) = _RegisterChild;

  const factory AuthEvent.registerParent({
    required String email,
    required String password,
    required String childCode,
  }) = _RegisterParent;

  const factory AuthEvent.loginAdmin({
    required String email,
    required String password,
  }) = _LoginAdmin;
}
