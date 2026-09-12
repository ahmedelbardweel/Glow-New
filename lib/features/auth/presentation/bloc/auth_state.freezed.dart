// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$AuthState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(ChildProfileEntity child) childRegistered,
    required TResult Function(UserEntity user) parentRegistered,
    required TResult Function(UserEntity user) adminLoggedIn,
    required TResult Function(String message) error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(ChildProfileEntity child)? childRegistered,
    TResult? Function(UserEntity user)? parentRegistered,
    TResult? Function(UserEntity user)? adminLoggedIn,
    TResult? Function(String message)? error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(ChildProfileEntity child)? childRegistered,
    TResult Function(UserEntity user)? parentRegistered,
    TResult Function(UserEntity user)? adminLoggedIn,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_ChildRegistered value) childRegistered,
    required TResult Function(_ParentRegistered value) parentRegistered,
    required TResult Function(_AdminLoggedIn value) adminLoggedIn,
    required TResult Function(_Error value) error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_ChildRegistered value)? childRegistered,
    TResult? Function(_ParentRegistered value)? parentRegistered,
    TResult? Function(_AdminLoggedIn value)? adminLoggedIn,
    TResult? Function(_Error value)? error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_ChildRegistered value)? childRegistered,
    TResult Function(_ParentRegistered value)? parentRegistered,
    TResult Function(_AdminLoggedIn value)? adminLoggedIn,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AuthStateCopyWith<$Res> {
  factory $AuthStateCopyWith(AuthState value, $Res Function(AuthState) then) =
      _$AuthStateCopyWithImpl<$Res, AuthState>;
}

/// @nodoc
class _$AuthStateCopyWithImpl<$Res, $Val extends AuthState>
    implements $AuthStateCopyWith<$Res> {
  _$AuthStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AuthState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$InitialImplCopyWith<$Res> {
  factory _$$InitialImplCopyWith(
    _$InitialImpl value,
    $Res Function(_$InitialImpl) then,
  ) = __$$InitialImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$InitialImplCopyWithImpl<$Res>
    extends _$AuthStateCopyWithImpl<$Res, _$InitialImpl>
    implements _$$InitialImplCopyWith<$Res> {
  __$$InitialImplCopyWithImpl(
    _$InitialImpl _value,
    $Res Function(_$InitialImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AuthState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$InitialImpl implements _Initial {
  const _$InitialImpl();

  @override
  String toString() {
    return 'AuthState.initial()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$InitialImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(ChildProfileEntity child) childRegistered,
    required TResult Function(UserEntity user) parentRegistered,
    required TResult Function(UserEntity user) adminLoggedIn,
    required TResult Function(String message) error,
  }) {
    return initial();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(ChildProfileEntity child)? childRegistered,
    TResult? Function(UserEntity user)? parentRegistered,
    TResult? Function(UserEntity user)? adminLoggedIn,
    TResult? Function(String message)? error,
  }) {
    return initial?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(ChildProfileEntity child)? childRegistered,
    TResult Function(UserEntity user)? parentRegistered,
    TResult Function(UserEntity user)? adminLoggedIn,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_ChildRegistered value) childRegistered,
    required TResult Function(_ParentRegistered value) parentRegistered,
    required TResult Function(_AdminLoggedIn value) adminLoggedIn,
    required TResult Function(_Error value) error,
  }) {
    return initial(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_ChildRegistered value)? childRegistered,
    TResult? Function(_ParentRegistered value)? parentRegistered,
    TResult? Function(_AdminLoggedIn value)? adminLoggedIn,
    TResult? Function(_Error value)? error,
  }) {
    return initial?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_ChildRegistered value)? childRegistered,
    TResult Function(_ParentRegistered value)? parentRegistered,
    TResult Function(_AdminLoggedIn value)? adminLoggedIn,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial(this);
    }
    return orElse();
  }
}

abstract class _Initial implements AuthState {
  const factory _Initial() = _$InitialImpl;
}

/// @nodoc
abstract class _$$LoadingImplCopyWith<$Res> {
  factory _$$LoadingImplCopyWith(
    _$LoadingImpl value,
    $Res Function(_$LoadingImpl) then,
  ) = __$$LoadingImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$LoadingImplCopyWithImpl<$Res>
    extends _$AuthStateCopyWithImpl<$Res, _$LoadingImpl>
    implements _$$LoadingImplCopyWith<$Res> {
  __$$LoadingImplCopyWithImpl(
    _$LoadingImpl _value,
    $Res Function(_$LoadingImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AuthState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$LoadingImpl implements _Loading {
  const _$LoadingImpl();

  @override
  String toString() {
    return 'AuthState.loading()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$LoadingImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(ChildProfileEntity child) childRegistered,
    required TResult Function(UserEntity user) parentRegistered,
    required TResult Function(UserEntity user) adminLoggedIn,
    required TResult Function(String message) error,
  }) {
    return loading();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(ChildProfileEntity child)? childRegistered,
    TResult? Function(UserEntity user)? parentRegistered,
    TResult? Function(UserEntity user)? adminLoggedIn,
    TResult? Function(String message)? error,
  }) {
    return loading?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(ChildProfileEntity child)? childRegistered,
    TResult Function(UserEntity user)? parentRegistered,
    TResult Function(UserEntity user)? adminLoggedIn,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_ChildRegistered value) childRegistered,
    required TResult Function(_ParentRegistered value) parentRegistered,
    required TResult Function(_AdminLoggedIn value) adminLoggedIn,
    required TResult Function(_Error value) error,
  }) {
    return loading(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_ChildRegistered value)? childRegistered,
    TResult? Function(_ParentRegistered value)? parentRegistered,
    TResult? Function(_AdminLoggedIn value)? adminLoggedIn,
    TResult? Function(_Error value)? error,
  }) {
    return loading?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_ChildRegistered value)? childRegistered,
    TResult Function(_ParentRegistered value)? parentRegistered,
    TResult Function(_AdminLoggedIn value)? adminLoggedIn,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading(this);
    }
    return orElse();
  }
}

abstract class _Loading implements AuthState {
  const factory _Loading() = _$LoadingImpl;
}

/// @nodoc
abstract class _$$ChildRegisteredImplCopyWith<$Res> {
  factory _$$ChildRegisteredImplCopyWith(
    _$ChildRegisteredImpl value,
    $Res Function(_$ChildRegisteredImpl) then,
  ) = __$$ChildRegisteredImplCopyWithImpl<$Res>;
  @useResult
  $Res call({ChildProfileEntity child});
}

/// @nodoc
class __$$ChildRegisteredImplCopyWithImpl<$Res>
    extends _$AuthStateCopyWithImpl<$Res, _$ChildRegisteredImpl>
    implements _$$ChildRegisteredImplCopyWith<$Res> {
  __$$ChildRegisteredImplCopyWithImpl(
    _$ChildRegisteredImpl _value,
    $Res Function(_$ChildRegisteredImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AuthState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? child = null}) {
    return _then(
      _$ChildRegisteredImpl(
        null == child
            ? _value.child
            : child // ignore: cast_nullable_to_non_nullable
                  as ChildProfileEntity,
      ),
    );
  }
}

/// @nodoc

class _$ChildRegisteredImpl implements _ChildRegistered {
  const _$ChildRegisteredImpl(this.child);

  @override
  final ChildProfileEntity child;

  @override
  String toString() {
    return 'AuthState.childRegistered(child: $child)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChildRegisteredImpl &&
            (identical(other.child, child) || other.child == child));
  }

  @override
  int get hashCode => Object.hash(runtimeType, child);

  /// Create a copy of AuthState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChildRegisteredImplCopyWith<_$ChildRegisteredImpl> get copyWith =>
      __$$ChildRegisteredImplCopyWithImpl<_$ChildRegisteredImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(ChildProfileEntity child) childRegistered,
    required TResult Function(UserEntity user) parentRegistered,
    required TResult Function(UserEntity user) adminLoggedIn,
    required TResult Function(String message) error,
  }) {
    return childRegistered(child);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(ChildProfileEntity child)? childRegistered,
    TResult? Function(UserEntity user)? parentRegistered,
    TResult? Function(UserEntity user)? adminLoggedIn,
    TResult? Function(String message)? error,
  }) {
    return childRegistered?.call(child);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(ChildProfileEntity child)? childRegistered,
    TResult Function(UserEntity user)? parentRegistered,
    TResult Function(UserEntity user)? adminLoggedIn,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (childRegistered != null) {
      return childRegistered(child);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_ChildRegistered value) childRegistered,
    required TResult Function(_ParentRegistered value) parentRegistered,
    required TResult Function(_AdminLoggedIn value) adminLoggedIn,
    required TResult Function(_Error value) error,
  }) {
    return childRegistered(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_ChildRegistered value)? childRegistered,
    TResult? Function(_ParentRegistered value)? parentRegistered,
    TResult? Function(_AdminLoggedIn value)? adminLoggedIn,
    TResult? Function(_Error value)? error,
  }) {
    return childRegistered?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_ChildRegistered value)? childRegistered,
    TResult Function(_ParentRegistered value)? parentRegistered,
    TResult Function(_AdminLoggedIn value)? adminLoggedIn,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (childRegistered != null) {
      return childRegistered(this);
    }
    return orElse();
  }
}

abstract class _ChildRegistered implements AuthState {
  const factory _ChildRegistered(final ChildProfileEntity child) =
      _$ChildRegisteredImpl;

  ChildProfileEntity get child;

  /// Create a copy of AuthState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChildRegisteredImplCopyWith<_$ChildRegisteredImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ParentRegisteredImplCopyWith<$Res> {
  factory _$$ParentRegisteredImplCopyWith(
    _$ParentRegisteredImpl value,
    $Res Function(_$ParentRegisteredImpl) then,
  ) = __$$ParentRegisteredImplCopyWithImpl<$Res>;
  @useResult
  $Res call({UserEntity user});
}

/// @nodoc
class __$$ParentRegisteredImplCopyWithImpl<$Res>
    extends _$AuthStateCopyWithImpl<$Res, _$ParentRegisteredImpl>
    implements _$$ParentRegisteredImplCopyWith<$Res> {
  __$$ParentRegisteredImplCopyWithImpl(
    _$ParentRegisteredImpl _value,
    $Res Function(_$ParentRegisteredImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AuthState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? user = null}) {
    return _then(
      _$ParentRegisteredImpl(
        null == user
            ? _value.user
            : user // ignore: cast_nullable_to_non_nullable
                  as UserEntity,
      ),
    );
  }
}

/// @nodoc

class _$ParentRegisteredImpl implements _ParentRegistered {
  const _$ParentRegisteredImpl(this.user);

  @override
  final UserEntity user;

  @override
  String toString() {
    return 'AuthState.parentRegistered(user: $user)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ParentRegisteredImpl &&
            (identical(other.user, user) || other.user == user));
  }

  @override
  int get hashCode => Object.hash(runtimeType, user);

  /// Create a copy of AuthState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ParentRegisteredImplCopyWith<_$ParentRegisteredImpl> get copyWith =>
      __$$ParentRegisteredImplCopyWithImpl<_$ParentRegisteredImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(ChildProfileEntity child) childRegistered,
    required TResult Function(UserEntity user) parentRegistered,
    required TResult Function(UserEntity user) adminLoggedIn,
    required TResult Function(String message) error,
  }) {
    return parentRegistered(user);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(ChildProfileEntity child)? childRegistered,
    TResult? Function(UserEntity user)? parentRegistered,
    TResult? Function(UserEntity user)? adminLoggedIn,
    TResult? Function(String message)? error,
  }) {
    return parentRegistered?.call(user);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(ChildProfileEntity child)? childRegistered,
    TResult Function(UserEntity user)? parentRegistered,
    TResult Function(UserEntity user)? adminLoggedIn,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (parentRegistered != null) {
      return parentRegistered(user);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_ChildRegistered value) childRegistered,
    required TResult Function(_ParentRegistered value) parentRegistered,
    required TResult Function(_AdminLoggedIn value) adminLoggedIn,
    required TResult Function(_Error value) error,
  }) {
    return parentRegistered(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_ChildRegistered value)? childRegistered,
    TResult? Function(_ParentRegistered value)? parentRegistered,
    TResult? Function(_AdminLoggedIn value)? adminLoggedIn,
    TResult? Function(_Error value)? error,
  }) {
    return parentRegistered?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_ChildRegistered value)? childRegistered,
    TResult Function(_ParentRegistered value)? parentRegistered,
    TResult Function(_AdminLoggedIn value)? adminLoggedIn,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (parentRegistered != null) {
      return parentRegistered(this);
    }
    return orElse();
  }
}

abstract class _ParentRegistered implements AuthState {
  const factory _ParentRegistered(final UserEntity user) =
      _$ParentRegisteredImpl;

  UserEntity get user;

  /// Create a copy of AuthState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ParentRegisteredImplCopyWith<_$ParentRegisteredImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$AdminLoggedInImplCopyWith<$Res> {
  factory _$$AdminLoggedInImplCopyWith(
    _$AdminLoggedInImpl value,
    $Res Function(_$AdminLoggedInImpl) then,
  ) = __$$AdminLoggedInImplCopyWithImpl<$Res>;
  @useResult
  $Res call({UserEntity user});
}

/// @nodoc
class __$$AdminLoggedInImplCopyWithImpl<$Res>
    extends _$AuthStateCopyWithImpl<$Res, _$AdminLoggedInImpl>
    implements _$$AdminLoggedInImplCopyWith<$Res> {
  __$$AdminLoggedInImplCopyWithImpl(
    _$AdminLoggedInImpl _value,
    $Res Function(_$AdminLoggedInImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AuthState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? user = null}) {
    return _then(
      _$AdminLoggedInImpl(
        null == user
            ? _value.user
            : user // ignore: cast_nullable_to_non_nullable
                  as UserEntity,
      ),
    );
  }
}

/// @nodoc

class _$AdminLoggedInImpl implements _AdminLoggedIn {
  const _$AdminLoggedInImpl(this.user);

  @override
  final UserEntity user;

  @override
  String toString() {
    return 'AuthState.adminLoggedIn(user: $user)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AdminLoggedInImpl &&
            (identical(other.user, user) || other.user == user));
  }

  @override
  int get hashCode => Object.hash(runtimeType, user);

  /// Create a copy of AuthState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AdminLoggedInImplCopyWith<_$AdminLoggedInImpl> get copyWith =>
      __$$AdminLoggedInImplCopyWithImpl<_$AdminLoggedInImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(ChildProfileEntity child) childRegistered,
    required TResult Function(UserEntity user) parentRegistered,
    required TResult Function(UserEntity user) adminLoggedIn,
    required TResult Function(String message) error,
  }) {
    return adminLoggedIn(user);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(ChildProfileEntity child)? childRegistered,
    TResult? Function(UserEntity user)? parentRegistered,
    TResult? Function(UserEntity user)? adminLoggedIn,
    TResult? Function(String message)? error,
  }) {
    return adminLoggedIn?.call(user);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(ChildProfileEntity child)? childRegistered,
    TResult Function(UserEntity user)? parentRegistered,
    TResult Function(UserEntity user)? adminLoggedIn,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (adminLoggedIn != null) {
      return adminLoggedIn(user);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_ChildRegistered value) childRegistered,
    required TResult Function(_ParentRegistered value) parentRegistered,
    required TResult Function(_AdminLoggedIn value) adminLoggedIn,
    required TResult Function(_Error value) error,
  }) {
    return adminLoggedIn(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_ChildRegistered value)? childRegistered,
    TResult? Function(_ParentRegistered value)? parentRegistered,
    TResult? Function(_AdminLoggedIn value)? adminLoggedIn,
    TResult? Function(_Error value)? error,
  }) {
    return adminLoggedIn?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_ChildRegistered value)? childRegistered,
    TResult Function(_ParentRegistered value)? parentRegistered,
    TResult Function(_AdminLoggedIn value)? adminLoggedIn,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (adminLoggedIn != null) {
      return adminLoggedIn(this);
    }
    return orElse();
  }
}

abstract class _AdminLoggedIn implements AuthState {
  const factory _AdminLoggedIn(final UserEntity user) = _$AdminLoggedInImpl;

  UserEntity get user;

  /// Create a copy of AuthState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AdminLoggedInImplCopyWith<_$AdminLoggedInImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ErrorImplCopyWith<$Res> {
  factory _$$ErrorImplCopyWith(
    _$ErrorImpl value,
    $Res Function(_$ErrorImpl) then,
  ) = __$$ErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$ErrorImplCopyWithImpl<$Res>
    extends _$AuthStateCopyWithImpl<$Res, _$ErrorImpl>
    implements _$$ErrorImplCopyWith<$Res> {
  __$$ErrorImplCopyWithImpl(
    _$ErrorImpl _value,
    $Res Function(_$ErrorImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AuthState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null}) {
    return _then(
      _$ErrorImpl(
        null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$ErrorImpl implements _Error {
  const _$ErrorImpl(this.message);

  @override
  final String message;

  @override
  String toString() {
    return 'AuthState.error(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ErrorImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of AuthState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ErrorImplCopyWith<_$ErrorImpl> get copyWith =>
      __$$ErrorImplCopyWithImpl<_$ErrorImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(ChildProfileEntity child) childRegistered,
    required TResult Function(UserEntity user) parentRegistered,
    required TResult Function(UserEntity user) adminLoggedIn,
    required TResult Function(String message) error,
  }) {
    return error(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(ChildProfileEntity child)? childRegistered,
    TResult? Function(UserEntity user)? parentRegistered,
    TResult? Function(UserEntity user)? adminLoggedIn,
    TResult? Function(String message)? error,
  }) {
    return error?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(ChildProfileEntity child)? childRegistered,
    TResult Function(UserEntity user)? parentRegistered,
    TResult Function(UserEntity user)? adminLoggedIn,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_ChildRegistered value) childRegistered,
    required TResult Function(_ParentRegistered value) parentRegistered,
    required TResult Function(_AdminLoggedIn value) adminLoggedIn,
    required TResult Function(_Error value) error,
  }) {
    return error(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_ChildRegistered value)? childRegistered,
    TResult? Function(_ParentRegistered value)? parentRegistered,
    TResult? Function(_AdminLoggedIn value)? adminLoggedIn,
    TResult? Function(_Error value)? error,
  }) {
    return error?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_ChildRegistered value)? childRegistered,
    TResult Function(_ParentRegistered value)? parentRegistered,
    TResult Function(_AdminLoggedIn value)? adminLoggedIn,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(this);
    }
    return orElse();
  }
}

abstract class _Error implements AuthState {
  const factory _Error(final String message) = _$ErrorImpl;

  String get message;

  /// Create a copy of AuthState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ErrorImplCopyWith<_$ErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
