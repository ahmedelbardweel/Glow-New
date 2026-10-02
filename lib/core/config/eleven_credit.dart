import 'dart:convert';

import 'package:http/http.dart' as http;

import '../audio/story_sentence_voice.dart';

enum ElevenCreditState { ready, empty, invalid, unknown }

class ElevenCredit {
  const ElevenCredit.ready(this.remaining) : state = ElevenCreditState.ready;

  const ElevenCredit.empty() : state = ElevenCreditState.empty, remaining = 0;

  const ElevenCredit.invalid() : state = ElevenCreditState.invalid, remaining = 0;

  const ElevenCredit.unknown() : state = ElevenCreditState.unknown, remaining = 0;

  final ElevenCreditState state;
  final int remaining;

  bool get exhausted => state == ElevenCreditState.empty;

  String get label {
    switch (state) {
      case ElevenCreditState.ready:
        return 'المتبقي ${groupDigits(remaining)}';
      case ElevenCreditState.empty:
        return 'خلص الرصيد';
      case ElevenCreditState.invalid:
        return 'المفتاح غير صالح';
      case ElevenCreditState.unknown:
        return 'تعذر قراءة الرصيد';
    }
  }

  static Future<ElevenCredit> load() async {
    try {
      final response = await http
          .get(
            Uri.parse('https://api.elevenlabs.io/v1/user/subscription'),
            headers: {'xi-api-key': StorySentenceVoice.activeApiKey},
          )
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 401) return const ElevenCredit.invalid();
      if (response.statusCode != 200) return const ElevenCredit.unknown();
      final data = jsonDecode(response.body);
      if (data is! Map) return const ElevenCredit.unknown();
      final used = (data['character_count'] as num?)?.toInt();
      final limit = (data['character_limit'] as num?)?.toInt();
      if (used == null || limit == null) return const ElevenCredit.unknown();
      final remaining = limit - used;
      if (remaining <= 0) return const ElevenCredit.empty();
      return ElevenCredit.ready(remaining);
    } catch (_) {
      return const ElevenCredit.unknown();
    }
  }
}

String groupDigits(int value) {
  final text = value.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    if (i > 0 && (text.length - i) % 3 == 0) buffer.write(',');
    buffer.write(text[i]);
  }
  return value < 0 ? '-$buffer' : buffer.toString();
}
