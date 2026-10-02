import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/di/injection_container.dart';
import 'datasources/auth_local_data_source.dart';
import 'models/user_model.dart';

/// Eight-digit mailbox check for staff and parents. Children never use it.
class EmailLoginCode {
  EmailLoginCode(this._client);

  final SupabaseClient _client;

  Future<void> send(String email) async {
    try {
      await _client.auth.signInWithOtp(
        email: email.trim(),
        shouldCreateUser: false,
      );
    } on AuthException catch (error) {
      throw Exception(_message(error.message));
    }
  }

  Future<void> verify(String email, String code) async {
    try {
      final response = await _client.auth.verifyOTP(
        email: email.trim(),
        token: code.trim(),
        type: OtpType.email,
      );
      if (response.session == null) {
        throw Exception('الرمز غير صحيح');
      }
    } on AuthException catch (error) {
      throw Exception(_message(error.message));
    }
  }

  Future<void> cancelLogin() async {
    await _client.auth.signOut();
    await sl<AuthLocalDataSource>().forgetUser();
  }

  Future<void> restoreKeeper() async {
    final refresh = _keptRefresh;
    final keeper = _keptUser;
    _keptRefresh = null;
    _keptUser = null;
    await _restore(refresh, keeper);
  }

  Future<void> holdKeeper() async {
    _keptRefresh = _client.auth.currentSession?.refreshToken;
    _keptUser = await sl<AuthLocalDataSource>().getLastUser();
  }

  String? _keptRefresh;
  UserModel? _keptUser;

  Future<void> _restore(String? refresh, UserModel? keeper) async {
    if (refresh != null && refresh.isNotEmpty) {
      await _client.auth.setSession(refresh);
    }
    if (keeper != null) {
      await sl<AuthLocalDataSource>().cacheUser(keeper);
    }
  }

  String _message(String raw) {
    final text = raw.toLowerCase();
    if (text.contains('rate') || text.contains('once every')) {
      return 'انتظر قليلاً ثم أعد إرسال الرمز';
    }
    if (text.contains('invalid') || text.contains('expired') || text.contains('otp')) {
      return 'الرمز غير صحيح أو انتهت صلاحيته';
    }
    return 'تعذر إرسال الرمز. حاول مرة ثانية';
  }
}
