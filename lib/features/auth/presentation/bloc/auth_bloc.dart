import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/login_admin_usecase.dart';
import '../../domain/usecases/register_child_usecase.dart';
import '../../domain/usecases/register_parent_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final RegisterChildUseCase registerChild;
  final RegisterParentUseCase registerParent;
  final LoginAdminUseCase loginAdmin;

  AuthBloc({
    required this.registerChild,
    required this.registerParent,
    required this.loginAdmin,
  }) : super(const AuthState.initial()) {
    on<AuthEvent>((event, emit) async {
      await event.map(
        registerChild: (e) async {
          emit(const AuthState.loading());
          final result = await registerChild(RegisterChildParams(
            name: e.name,
            age: e.age,
            avatarUrl: e.avatarUrl,
          ));
          result.fold(
            (failure) => emit(AuthState.error(failure.message)),
            (child) => emit(AuthState.childRegistered(child)),
          );
        },
        registerParent: (e) async {
          emit(const AuthState.loading());
          final result = await registerParent(RegisterParentParams(
            email: e.email,
            password: e.password,
            childCode: e.childCode,
          ));
          result.fold(
            (failure) => emit(AuthState.error(failure.message)),
            (user) => emit(AuthState.parentRegistered(user)),
          );
        },
        loginAdmin: (e) async {
          emit(const AuthState.loading());
          final result = await loginAdmin(LoginAdminParams(
            email: e.email,
            password: e.password,
          ));
          result.fold(
            (failure) => emit(AuthState.error(failure.message)),
            (user) => emit(AuthState.adminLoggedIn(user)),
          );
        },
      );
    });
  }
}
