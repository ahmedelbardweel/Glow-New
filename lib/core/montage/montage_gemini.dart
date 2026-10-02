import 'dart:async';
import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../di/injection_container.dart';

class MontageGeminiException implements Exception {
  const MontageGeminiException(this.code, [this.detail = '']);

  final String code;
  final String detail;
}

/// One call. Gemini reads the numbered words and returns cues. The key stays
/// in the Supabase function, never in the app.
class MontageGemini {
  Future<Map<String, dynamic>> plan(List<Map<String, dynamic>> sentences) async {
    final client = sl<SupabaseClient>();
    if (client.auth.currentSession == null) {
      throw const MontageGeminiException('signed_out');
    }
    try {
      final response = await client.functions
          .invoke(
            'smooth-service',
            body: {'sentences': sentences},
          )
          .timeout(const Duration(seconds: 25));
      final data = response.data;
      if (data is Map && data['error'] == null && data['cues'] is List) {
        return Map<String, dynamic>.from(data);
      }
      final code = data is Map ? data['error']?.toString() : null;
      final detail = data is Map ? data['detail']?.toString() ?? '' : '';
      throw MontageGeminiException(code ?? 'bad_response', detail);
    } on MontageGeminiException {
      rethrow;
    } on FunctionException catch (error) {
      throw _exceptionFrom(error.details);
    } on TimeoutException {
      throw const MontageGeminiException('timeout');
    }
  }
}

MontageGeminiException _exceptionFrom(Object? details) {
  final map = _asMap(details);
  if (map != null) {
    final code = map['error'] ?? map['message'];
    if (code != null) {
      return MontageGeminiException(_normalize('$code'), '${map['detail'] ?? ''}');
    }
  }
  if (details is String && details.isNotEmpty) return MontageGeminiException(_normalize(details));
  return const MontageGeminiException('request_failed');
}

Map? _asMap(Object? details) {
  if (details is Map) return details;
  if (details is String && details.isNotEmpty) {
    try {
      final decoded = jsonDecode(details);
      if (decoded is Map) return decoded;
    } catch (_) {}
  }
  return null;
}

String _normalize(String raw) {
  final text = raw.toLowerCase();
  if (text.contains('jwt') || text.contains('unauthorized')) return 'jwt';
  return raw;
}
