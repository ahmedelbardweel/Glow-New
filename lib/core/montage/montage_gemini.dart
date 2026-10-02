import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/admin_api_keys.dart';
import '../di/injection_container.dart';

class MontageGeminiException implements Exception {
  const MontageGeminiException(this.code, [this.detail = '']);

  final String code;
  final String detail;
}

/// One call. Gemini reads the numbered words and returns cues.
/// A key saved in admin settings is used directly. Otherwise the Supabase
/// function keeps using its own key.
class MontageGemini {
  Future<Map<String, dynamic>> plan(List<Map<String, dynamic>> sentences) async {
    try {
      return await _plan(sentences);
    } on MontageGeminiException catch (error) {
      if (error.code == 'quota') await AdminApiKeys.markGeminiExhausted();
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _plan(List<Map<String, dynamic>> sentences) async {
    final saved = AdminApiKeys.gemini;
    if (saved != null) return _planWithKey(sentences, saved);
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

Future<Map<String, dynamic>> _planWithKey(
  List<Map<String, dynamic>> sentences,
  String key,
) async {
  final script = sentences.take(80).map((item) {
    final words = item['words'];
    final clean = words is List
        ? words.map((word) => '$word'.trim()).where((word) => word.isNotEmpty && word.length <= 40).take(80).toList()
        : <String>[];
    return {
      'sentence': item['sentence'],
      'character': '${item['character'] ?? ''}'.length > 40
          ? '${item['character']}'.substring(0, 40)
          : '${item['character'] ?? ''}',
      'words': clean,
    };
  }).where((row) => (row['words'] as List).isNotEmpty).toList();
  if (script.isEmpty) throw const MontageGeminiException('empty_script');
  final prompt = [
    'أنت مخرج مونتاج. مر على كل الجمل بالترتيب، ومن كل جملة على كل كلمة. لا تتوقف بعد أول معنى.',
    'كل كلمة تحمل معنى، أو تشبه كلمة تحمل معنى، تأخذ إشارة على تلك الكلمة فقط.',
    'wave للتحية والوداع. sad للحزن. laugh للضحك. smile للابتسامة. happy للفرح.',
    'thinking للسؤال. victory للفوز. walk للمشي. jump للنطة وkind يكون jump.',
    'hat للقبعة. glasses للنظارة. muscles للقوة.',
    'startWord و endWord فهرسان داخل words من صفر. quote منسوخة من words.',
    'seams: لكل جملتين متتاليتين بشخصيتين مختلفتين أرجع fade أو slide أو pop.',
    jsonEncode(script),
  ].join('\n');
  final response = await http
      .post(
        Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.8-flash:generateContent',
        ),
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': key,
        },
        body: jsonEncode({
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': prompt},
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.2,
            'maxOutputTokens': 4096,
            'responseMimeType': 'application/json',
          },
        }),
      )
      .timeout(const Duration(seconds: 25));
  if (response.statusCode != 200) {
    final body = response.body.toLowerCase();
    if (response.statusCode == 429 ||
        body.contains('resource_exhausted') ||
        body.contains('quota')) {
      throw const MontageGeminiException('quota');
    }
    throw const MontageGeminiException('gemini_failed');
  }
  final payload = jsonDecode(response.body);
  if (payload is! Map) throw const MontageGeminiException('bad_response');
  final candidates = payload['candidates'];
  if (candidates is! List || candidates.isEmpty) {
    throw const MontageGeminiException('bad_response');
  }
  final content = candidates.first;
  final parts = content is Map ? content['content'] : null;
  final partList = parts is Map ? parts['parts'] : null;
  final text = partList is List
      ? partList.map((part) => part is Map ? '${part['text'] ?? ''}' : '').join()
      : '';
  final start = text.indexOf('{');
  final end = text.lastIndexOf('}');
  if (start < 0 || end <= start) throw const MontageGeminiException('bad_response');
  final parsed = jsonDecode(text.substring(start, end + 1));
  if (parsed is! Map || parsed['cues'] is! List) {
    throw const MontageGeminiException('bad_response');
  }
  return {
    'cues': parsed['cues'],
    'seams': parsed['seams'] is List ? parsed['seams'] : <dynamic>[],
  };
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
  if (text.contains('quota') || text.contains('resource_exhausted')) return 'quota';
  return raw;
}
