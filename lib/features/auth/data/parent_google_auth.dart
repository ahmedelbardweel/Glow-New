import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/di/injection_container.dart';
import '../presentation/widgets/parent_google_sign_in_page.dart';
import 'datasources/auth_local_data_source.dart';
import 'models/user_model.dart';

/// Parent Google sign-in for iOS and Android.
/// The Google page opens inside the app and returns through [redirectTo].
class ParentGoogleAuth {
  ParentGoogleAuth._();

  static const redirectTo = 'glow://parent-auth';

  /// Null means the parent closed the Google page.
  static Future<Session?> signIn(BuildContext context) {
    return Navigator.of(context).push<Session>(
      PageRouteBuilder<Session>(
        opaque: true,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, _, _) => const ParentGoogleSignInPage(),
      ),
    );
  }

  static bool isGoogleUser(User user) {
    final identities = user.identities;
    if (identities == null) return false;
    return identities.any((identity) => identity.provider == 'google');
  }

  static Future<void> rememberAsParent(Session session) async {
    final user = session.user;
    await _rejectStaff(user);
    await sl<AuthLocalDataSource>().cacheUser(UserModel(
      id: user.id,
      email: user.email ?? '',
      role: 'parent',
    ));
  }

  static Future<void> _rejectStaff(User user) async {
    final client = Supabase.instance.client;
    final admin = await _roleOf(client, user.id);
    if (admin == 'admin') {
      await client.auth.signOut();
      throw Exception('هذا حساب إدارة النظام. ادخل من شاشته.');
    }
    final org = await _exists(client, 'organizations', user.id);
    if (org) {
      await client.auth.signOut();
      throw Exception('هذا حساب منظمة. ادخل من شاشة المنظمة.');
    }
    final teacher = await _exists(client, 'organization_teachers', user.id);
    if (teacher) {
      await client.auth.signOut();
      throw Exception('هذا حساب معلم. ادخل من شاشة المنظمة.');
    }
  }

  static Future<String?> _roleOf(SupabaseClient client, String id) async {
    try {
      final row = await client.from('users').select('role').eq('id', id).maybeSingle();
      return row?['role'] as String?;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> _exists(SupabaseClient client, String table, String id) async {
    try {
      final row = await client.from(table).select('id').eq('id', id).maybeSingle();
      return row != null;
    } catch (_) {
      return false;
    }
  }
}
