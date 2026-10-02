import 'package:supabase_flutter/supabase_flutter.dart';

/// Who is signed in. Screens read this instead of a cloud client.
abstract class AppSession {
  String? get userId;

  Future<void> signOutLocal();
}

class SupabaseAppSession implements AppSession {
  SupabaseAppSession(this._client);

  final SupabaseClient _client;

  @override
  String? get userId => _client.auth.currentUser?.id;

  @override
  Future<void> signOutLocal() {
    return _client.auth.signOut(scope: SignOutScope.local);
  }
}
