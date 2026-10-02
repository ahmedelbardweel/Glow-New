import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';
import '../../../../core/utils/device_id_helper.dart';
import '../models/child_profile_model.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<ChildProfileModel> registerChild({
    required String name,
    required int age,
    required String avatarUrl,
  });

  Future<UserModel> registerParent({
    required String email,
    required String password,
    required String childCode,
  });

  Future<UserModel> loginParent({
    required String email,
    required String password,
  });

  Future<UserModel> loginAdmin({
    required String email,
    required String password,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient supabaseClient;

  AuthRemoteDataSourceImpl(this.supabaseClient);

  String _generateChildCode() {
    final random = Random();
    final code = random.nextInt(9999).toString().padLeft(4, '0');
    return 'CH-$code';
  }

  @override
  Future<ChildProfileModel> registerChild({
    required String name,
    required int age,
    required String avatarUrl,
  }) async {
    try {
      // 1. Get device ID and generate credentials
      final deviceId = await DeviceIdHelper.getDeviceId();
      final email = DeviceIdHelper.generateDeviceEmail(deviceId);
      final password = DeviceIdHelper.generateDevicePassword(deviceId);

      // 2. Sign up (or sign in if already exists but somehow data was cleared)
      User? user;
      try {
        final authResponse = await supabaseClient.auth.signUp(
          email: email,
          password: password,
        );
        user = authResponse.user;
      } on AuthException catch (e) {
        if (e.message.contains('already registered') || e.message.contains('User already registered')) {
          final authResponse = await supabaseClient.auth.signInWithPassword(
            email: email,
            password: password,
          );
          user = authResponse.user;
        } else {
          rethrow;
        }
      }

      if (user == null) throw Exception('Failed to create device-bound user');

      // Check if profile already exists for this device
      try {
        final existingData = await supabaseClient
            .from('children_profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();
            
        if (existingData != null) {
          return ChildProfileModel.fromJson(existingData);
        }
      } catch (_) {
        // Ignore and proceed to insert
      }

      // 3. Generate Child Code
      final childCode = _generateChildCode();

      // 4. Save to children_profiles table
      final data = await supabaseClient.from('children_profiles').insert({
        'id': user.id,
        'name': name,
        'age': age,
        'avatar_url': avatarUrl,
        'child_code': childCode,
        'total_stars': 0,
        'total_badges': 0,
      }).select().single();

      return ChildProfileModel.fromJson(data);
    } catch (e) {
      throw Exception('Failed to register child: $e');
    }
  }

  @override
  Future<UserModel> registerParent({
    required String email,
    required String password,
    required String childCode,
  }) async {
    final response = await supabaseClient.auth.signUp(
      email: email.trim(),
      password: password,
    );
    final user = response.user;
    final identities = user?.identities;
    if (user == null || (identities != null && identities.isEmpty)) {
      throw Exception('هذا البريد مسجّل من قبل. ادخل من صفحة الدخول.');
    }

    final code = childCode.trim();
    if (code.isNotEmpty) {
      await supabaseClient.rpc('link_parent_to_child', params: {
        'p_parent_id': user.id,
        'p_child_code': code,
      });
    }

    return UserModel(id: user.id, email: email.trim(), role: 'parent');
  }

  @override
  Future<UserModel> loginParent({
    required String email,
    required String password,
  }) async {
    final response = await supabaseClient.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    final user = response.user;
    if (user == null) {
      throw Exception('البريد أو كلمة المرور غير صحيحة.');
    }
    await _rejectIfNotParent(user.id);
    return UserModel(
      id: user.id,
      email: user.email ?? email.trim(),
      role: 'parent',
    );
  }

  Future<void> _rejectIfNotParent(String id) async {
    final role = await _roleOf(id);
    if (role == 'admin') {
      await supabaseClient.auth.signOut();
      throw Exception('هذا حساب إدارة. ادخل من شاشة الإدارة.');
    }
    if (await _rowExists('organizations', id)) {
      await supabaseClient.auth.signOut();
      throw Exception('هذا حساب منظمة. ادخل من شاشة المنظمة.');
    }
    if (await _rowExists('organization_teachers', id)) {
      await supabaseClient.auth.signOut();
      throw Exception('هذا حساب معلم. ادخل من شاشة المنظمة.');
    }
  }

  Future<String?> _roleOf(String id) async {
    try {
      final row = await supabaseClient
          .from('users')
          .select('role')
          .eq('id', id)
          .maybeSingle();
      return row?['role'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<bool> _rowExists(String table, String id) async {
    try {
      final row = await supabaseClient.from(table).select('id').eq('id', id).maybeSingle();
      return row != null;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<UserModel> loginAdmin({
    required String email,
    required String password,
  }) async {
    final authResponse = await supabaseClient.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    final user = authResponse.user;
    if (user == null) {
      throw Exception('البريد أو كلمة المرور غير صحيحة.');
    }

    final data = await supabaseClient
        .from('users')
        .select('role')
        .eq('id', user.id)
        .maybeSingle();

    if (data == null || data['role'] != 'admin') {
      await supabaseClient.auth.signOut();
      throw Exception('هذا الحساب ليس حساب الإدارة.');
    }

    return UserModel(
      id: user.id,
      email: user.email ?? email.trim(),
      role: 'admin',
    );
  }
}
