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

/// The montage model chosen in admin settings. Groq uses the saved Groq key.
/// Gemini uses the saved Gemini key, or the Supabase function when that key
/// is empty.
class MontageGemini {
  Future<Map<String, dynamic>> plan(List<Map<String, dynamic>> sentences) async {
    final choice = AdminApiKeys.montageChoice;
    try {
      if (choice.provider == 'groq') {
        final key = AdminApiKeys.groq;
        if (key == null) throw const MontageGeminiException('missing_key');
        return await _planWithGroq(sentences, key, choice.model);
      }
      return await _plan(sentences, choice.model);
    } on MontageGeminiException catch (error) {
      if (error.code == 'quota' && choice.provider == 'gemini') {
        await AdminApiKeys.markGeminiExhausted();
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _plan(List<Map<String, dynamic>> sentences, String model) async {
    final saved = AdminApiKeys.gemini;
    if (saved != null) return _planWithKey(sentences, saved, model);
    final client = sl<SupabaseClient>();
    if (client.auth.currentSession == null) {
      throw const MontageGeminiException('signed_out');
    }
    try {
      final response = await client.functions
          .invoke(
            'smooth-service',
            body: {
              'sentences': sentences,
              'model': model,
            },
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
  String model,
) async {
  final prompt = _montagePrompt(_montageScript(sentences));
  final response = await http
      .post(
        Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent',
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
    if (response.statusCode == 404 || body.contains('not found') || body.contains('not_found')) {
      throw const MontageGeminiException('unavailable');
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
  return _cuesFromText(text);
}

Future<Map<String, dynamic>> _planWithGroq(
  List<Map<String, dynamic>> sentences,
  String key,
  String model,
) async {
  final script = _montageScript(sentences);
  final response = await http
      .post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $key',
        },
        body: jsonEncode({
          'model': model,
          'temperature': 0.2,
          'max_tokens': 4096,
          'response_format': {'type': 'json_object'},
          'messages': [
            {'role': 'user', 'content': _montagePrompt(script)},
          ],
        }),
      )
      .timeout(const Duration(seconds: 25));
  if (response.statusCode != 200) {
    final body = response.body.toLowerCase();
    if (response.statusCode == 429 || body.contains('rate_limit') || body.contains('quota')) {
      throw const MontageGeminiException('quota');
    }
    if (response.statusCode == 401 || body.contains('invalid_api_key')) {
      throw const MontageGeminiException('missing_key');
    }
    throw const MontageGeminiException('gemini_failed');
  }
  final payload = jsonDecode(response.body);
  final choices = payload is Map ? payload['choices'] : null;
  final message = choices is List && choices.isNotEmpty && choices.first is Map
      ? choices.first['message']
      : null;
  final text = message is Map ? '${message['content'] ?? ''}' : '';
  return _cuesFromText(text);
}

List<Map<String, dynamic>> _montageScript(List<Map<String, dynamic>> sentences) {
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
  return [for (final row in script) Map<String, dynamic>.from(row)];
}

String _montagePrompt(List<Map<String, dynamic>> script) {
  return [
    'أنت مخرج مونتاج. مر على كل الجمل بالترتيب، ومن كل جملة على كل كلمة. لا تتوقف بعد أول معنى.',
    'افهم المعنى والمرادف واللهجة، لا تطابق قائمة كلمات حرفياً. الكلمة القريبة في المعنى تأخذ نفس الإشارة.',
    'wave للتحية والوداع وما يشبهها: مرحبا، هلا، أهلين، يا هلا، السلام، صباح الخير، مساء الخير، هاي، مرحبتين، مع السلامة، باي.',
    'sad للحزن والخوف والزعل والبكاء وما يشبهها.',
    'laugh للضحك والقهقهة. smile للابتسامة. happy للفرح والحماس.',
    'thinking للسؤال والحيرة: ليش، لماذا، كيف، يا ترى، محتار.',
    'victory للفوز والنجاح. walk للمشي والذهاب والركض.',
    'jump للنطة والقفز. kind يكون jump والقيمة فاضية.',
    'hat إذا ذُكرت قبعة. glasses إذا ذُكرت نظارة. muscles إذا ذُكرت قوة أو عضلات.',
    'إذا الجملة فيها أكثر من معنى، أرجع إشارة لكل معنى.',
    'كل إشارة فيها sentence و startWord و endWord و quote و kind و value.',
    'sentence هو رقم الجملة في المصفوفة من صفر. startWord و endWord فهرسان داخل words من صفر. quote منسوخة من words.',
    'kind يكون motion أو jump أو hat أو glasses أو muscles. value للحركة: wave أو sad أو laugh أو smile أو happy أو thinking أو victory أو walk.',
    'seams: لكل جملتين متتاليتين بشخصيتين مختلفتين أرجع afterSentence و type ويكون fade أو slide أو pop.',
    'أرجع JSON فيه cues و seams. لا تترك cues فاضية إذا لقيت معنى.',
    jsonEncode(script),
  ].join('\n');
}

Map<String, dynamic> _cuesFromText(String text) {
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
