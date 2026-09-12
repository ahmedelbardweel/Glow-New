// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$AuthEvent {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String name, int age, String avatarUrl)
    registerChild,
    required TResult Function(String email, String password, String childCode)
    registerParent,
    required TResult Function(String email, String password) loginAdmin,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String name, int age, String avatarUrl)? registerChild,
    TResult? Function(String email, String password, String childCode)?
    registerParent,
    TResult? Function(String email, String password)? loginAdmin,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String name, int age, String avatarUrl)? registerChild,
    TResult Function(String email, String password, String childCode)?
    registerParent,
    TResult Function(String email, String password)? loginAdmin,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_RegisterChild value) registerChild,
    required TResult Function(_RegisterParent value) registerParent,
    required TResult Function(_LoginAdmin value) loginAdmin,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_RegisterChild value)? registerChild,
    TResult? Function(_RegisterParent value)? registerParent,
    TResult? Function(_LoginAdmin value)? loginAdmin,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_RegisterChild value)? registerChild,
    TResult Function(_RegisterParent value)? registerParent,
    TResult Function(_LoginAdmin value)? loginAdmin,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AuthEventCopyWith<$Res> {
  factory $AuthEventCopyWith(AuthEvent value, $Res Function(AuthEvent) then) =
      _$AuthEventCopyWithImpl<$Res, AuthEvent>;
}

/// @nodoc
class _$AuthEventCopyWithImpl<$Res, $Val extends AuthEvent>
    implements $AuthEventCopyWith<$Res> {
  _$AuthEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AuthEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$RegisterChildImplCopyWith<$Res> {
  factory _$$RegisterChildImplCopyWith(
    _$RegisterChildImpl value,
    $Res Function(_$RegisterChildImpl) then,
  ) = __$$RegisterChildImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String name, int age, String avatarUrl});
}

/// @nodoc
class __$$RegisterChildImplCopyWithImpl<$Res>
    extends _$AuthEventCopyWithImpl<$Res, _$RegisterChildImpl>
    implements _$$RegisterChildImplCopyWith<$Res> {
  __$$RegisterChildImplCopyWithImpl(
    _$RegisterChildImpl _value,
    $Res Function(_$RegisterChildImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AuthEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? age = null,
    Object? avatarUrl = null,
  }) {
    return _then(
      _$RegisterChildImpl(
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        age: null == age
            ? _value.age
            : age // ignore: cast_nullable_to_non_nullable
                  as int,
        avatarUrl: null == avatarUrl
            ? _value.avatarUrl
            : avatarUrl // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$RegisterChildImpl implements _RegisterChild {
  const _$RegisterChildImpl({
    required this.name,
    required this.age,
    required this.avatarUrl,
  });

  @override
  final String name;
  @override
  final int age;
  @override
  final String avatarUrl;

  @override
  String toString() {
    return 'AuthEvent.registerChild(name: $name, age: $age, avatarUrl: $avatarUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RegisterChildImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.age, age) || other.age == age) &&
            (identical(other.avatarUrl, avatarUrl) ||
                other.avatarUrl == avatarUrl));
  }

  @override
  int get hashCode => Object.hash(runtimeType, name, age, avatarUrl);

  /// Create a copy of AuthEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RegisterChildImplCopyWith<_$RegisterChildImpl> get copyWith =>
      __$$RegisterChildImplCopyWithImpl<_$RegisterChildImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String name, int age, String avatarUrl)
    registerChild,
    required TResult Function(String email, String password, String childCode)
    registerParent,
    required TResult Function(String email, String password) loginAdmin,
  }) {
    return registerChild(name, age, avatarUrl);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String name, int age, String avatarUrl)? registerChild,
    TResult? Function(String email, String password, String childCode)?
    registerParent,
    TResult? Function(String email, String password)? loginAdmin,
  }) {
    return registerChild?.call(name, age, avatarUrl);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String name, int age, String avatarUrl)? registerChild,
    TResult Function(String email, String password, String childCode)?
    registerParent,
    TResult Function(String email, String password)? loginAdmin,
    required TResult orElse(),
  }) {
    if (registerChild != null) {
      return registerChild(name, age, avatarUrl);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_RegisterChild value) registerChild,
    required TResult Function(_RegisterParent value) registerParent,
    required TResult Function(_LoginAdmin value) loginAdmin,
  }) {
    return registerChild(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_RegisterChild value)? registerChild,
    TResult? Function(_RegisterParent value)? registerParent,
    TResult? Function(_LoginAdmin value)? loginAdmin,
  }) {
    return registerChild?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_RegisterChild value)? registerChild,
    TResult Function(_RegisterParent value)? registerParent,
    TResult Function(_LoginAdmin value)? loginAdmin,
    required TResult orElse(),
  }) {
    if (registerChild != null) {
      return registerChild(this);
    }
    return orElse();
  }
}

abstract class _RegisterChild implements AuthEvent {
  const factory _RegisterChild({
    required final String name,
    required final int age,
    required final String avatarUrl,
  }) = _$RegisterChildImpl;

  String get name;
  int get age;
  String get avatarUrl;

  /// Create a copy of AuthEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RegisterChildImplCopyWith<_$RegisterChildImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$RegisterParentImplCopyWith<$Res> {
  factory _$$RegisterParentImplCopyWith(
    _$RegisterParentImpl value,
    $Res Function(_$RegisterParentImpl) then,
  ) = __$$RegisterParentImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String email, String password, String childCode});
}

/// @nodoc
class __$$RegisterParentImplCopyWithImpl<$Res>
    extends _$AuthEventCopyWithImpl<$Res, _$RegisterParentImpl>
    implements _$$RegisterParentImplCopyWith<$Res> {
  __$$RegisterParentImplCopyWithImpl(
    _$RegisterParentImpl _value,
    $Res Function(_$RegisterParentImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AuthEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? email = null,
    Object? password = null,
    Object? childCode = null,
  }) {
    return _then(
      _$RegisterParentImpl(
        email: null == email
            ? _value.email
            : email // ignore: cast_nullable_to_non_nullable
                  as String,
        password: null == password
            ? _value.password
            : password // ignore: cast_nullable_to_non_nullable
                  as String,
        childCode: null == childCode
            ? _value.childCode
            : childCode // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$RegisterParentImpl implements _RegisterParent {
  const _$RegisterParentImpl({
    required this.email,
    required this.password,
    required this.childCode,
  });

  @override
  final String email;
  @override
  final String password;
  @override
  final String childCode;

  @override
  String toString() {
    return 'AuthEvent.registerParent(email: $email, password: $password, childCode: $childCode)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RegisterParentImpl &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.password, password) ||
                other.password == password) &&
            (identical(other.childCode, childCode) ||
                other.childCode == childCode));
  }

  @override
  int get hashCode => Object.hash(runtimeType, email, password, childCode);

  /// Create a copy of AuthEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RegisterParentImplCopyWith<_$RegisterParentImpl> get copyWith =>
      __$$RegisterParentImplCopyWithImpl<_$RegisterParentImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String name, int age, String avatarUrl)
    registerChild,
    required TResult Function(String email, String password, String childCode)
    registerParent,
    required TResult Function(String email, String password) loginAdmin,
  }) {
    return registerParent(email, password, childCode);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String name, int age, String avatarUrl)? registerChild,
    TResult? Function(String email, String password, String childCode)?
    registerParent,
    TResult? Function(String email, String password)? loginAdmin,
  }) {
    return registerParent?.call(email, password, childCode);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String name, int age, String avatarUrl)? registerChild,
    TResult Function(String email, String password, String childCode)?
    registerParent,
    TResult Function(String email, String password)? loginAdmin,
    required TResult orElse(),
  }) {
    if (registerParent != null) {
      return registerParent(email, password, childCode);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_RegisterChild value) registerChild,
    required TResult Function(_RegisterParent value) registerParent,
    required TResult Function(_LoginAdmin value) loginAdmin,
  }) {
    return registerParent(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_RegisterChild value)? registerChild,
    TResult? Function(_RegisterParent value)? registerParent,
    TResult? Function(_LoginAdmin value)? loginAdmin,
  }) {
    return registerParent?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_RegisterChild value)? registerChild,
    TResult Function(_RegisterParent value)? registerParent,
    TResult Function(_LoginAdmin value)? loginAdmin,
    required TResult orElse(),
  }) {
    if (registerParent != null) {
      return registerParent(this);
    }
    return orElse();
  }
}

abstract class _RegisterParent implements AuthEvent {
  const factory _RegisterParent({
    required final String email,
    required final String password,
    required final String childCode,
  }) = _$RegisterParentImpl;

  String get email;
  String get password;
  String get childCode;

  /// Create a copy of AuthEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RegisterParentImplCopyWith<_$RegisterParentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$LoginAdminImplCopyWith<$Res> {
  factory _$$LoginAdminImplCopyWith(
    _$LoginAdminImpl value,
    $Res Function(_$LoginAdminImpl) then,
  ) = __$$LoginAdminImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String email, String password});
}

/// @nodoc
class __$$LoginAdminImplCopyWithImpl<$Res>
    extends _$AuthEventCopyWithImpl<$Res, _$LoginAdminImpl>
    implements _$$LoginAdminImplCopyWith<$Res> {
  __$$LoginAdminImplCopyWithImpl(
    _$LoginAdminImpl _value,
    $Res Function(_$LoginAdminImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AuthEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? email = null, Object? password = null}) {
    return _then(
      _$LoginAdminImpl(
        email: null == email
            ? _value.email
            : email // ignore: cast_nullable_to_non_nullable
                  as String,
        password: null == password
            ? _value.password
            : password // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$LoginAdminImpl implements _LoginAdmin {
  const _$LoginAdminImpl({required this.email, required this.password});

  @override
  final String email;
  @override
  final String password;

  @override
  String toString() {
    return 'AuthEvent.loginAdmin(email: $email, password: $password)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LoginAdminImpl &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.password, password) ||
                other.password == password));
  }

  @override
  int get hashCode => Object.hash(runtimeType, email, password);

  /// Create a copy of AuthEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LoginAdminImplCopyWith<_$LoginAdminImpl> get copyWith =>
      __$$LoginAdminImplCopyWithImpl<_$LoginAdminImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String name, int age, String avatarUrl)
    registerChild,
    required TResult Function(String email, String password, String childCode)
    registerParent,
    required TResult Function(String email, String password) loginAdmin,
  }) {
    return loginAdmin(email, password);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String name, int age, String avatarUrl)? registerChild,
    TResult? Function(String email, String password, String childCode)?
    registerParent,
    TResult? Function(String email, String password)? loginAdmin,
  }) {
    return loginAdmin?.call(email, password);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String name, int age, String avatarUrl)? registerChild,
    TResult Function(String email, String password, String childCode)?
    registerParent,
    TResult Function(String email, String password)? loginAdmin,
    required TResult orElse(),
  }) {
    if (loginAdmin != null) {
      return loginAdmin(email, password);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_RegisterChild value) registerChild,
    required TResult Function(_RegisterParent value) registerParent,
    required TResult Function(_LoginAdmin value) loginAdmin,
  }) {
    return loginAdmin(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_RegisterChild value)? registerChild,
    TResult? Function(_RegisterParent value)? registerParent,
    TResult? Function(_LoginAdmin value)? loginAdmin,
  }) {
    return loginAdmin?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_RegisterChild value)? registerChild,
    TResult Function(_RegisterParent value)? registerParent,
    TResult Function(_LoginAdmin value)? loginAdmin,
    required TResult orElse(),
  }) {
    if (loginAdmin != null) {
      return loginAdmin(this);
    }
    return orElse();
  }
}

abstract class _LoginAdmin implements AuthEvent {
  const factory _LoginAdmin({
    required final String email,
    required final String password,
  }) = _$LoginAdminImpl;

  String get email;
  String get password;

  /// Create a copy of AuthEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LoginAdminImplCopyWith<_$LoginAdminImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
