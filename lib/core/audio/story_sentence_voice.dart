import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../config/admin_api_keys.dart';

/// One fixed ElevenLabs voice per character, so every line keeps that tone.
class StorySentenceVoice {
  StorySentenceVoice._();

  static const _builtInKey =
      'sk_70ad200afdaeee4ef1fb1a42d9a9af9ca69ec2d01c8e617f';

  static String get _apiKey => AdminApiKeys.eleven ?? _builtInKey;

  static String get activeApiKey => _apiKey;

  static const _voices = <String, _Voice>{
    'fort': _Voice('ihKwLOjVUMG4lgUI6meZ'),
    'mort': _Voice('Vnqlgu3fdiFwisAye1qH'),
    'port': _Voice('4RloeZf2FRvGiu4uoKOf'),
    'qort': _Voice('1kvnzrSTos1KbmLKMLCC'),
    'sort': _Voice('hO2yZ8lxM3axUxL8OeKX'),
    'lort': _Voice('hO2yZ8lxM3axUxL8OeKX'),
  };

  static const _sampleRate = 22050;

  static Future<({File file, double seconds})> speak({
    required String characterId,
    required String text,
  }) {
    final voice = _voices[characterId];
    if (voice == null) {
      throw const StoryVoiceException('هالشخصية ما إلها نبرة محفوظة.');
    }
    return _render(voice, text);
  }

  /// Julia, the narrator for buttons and field speech. Pitch stays 1 so the
  /// ElevenLabs voice is unchanged.
  static Future<({File file, double seconds})> speakNarrator(String text) {
    return _render(const _Voice('Bsa1HP3wF8JGRzGouFEa'), text);
  }

  static String explain(Object error) {
    if (error is StoryVoiceException) return error.message;
    if (error is TimeoutException) return 'Eleven تأخر بالرد أكثر من اللازم. حاول مرة ثانية.';
    if (error is SocketException) return 'ما في نت، فما وصل الطلب لـ Eleven.';
    if (error is HttpException) return 'الاتصال بـ Eleven انقطع قبل ما يوصل الصوت.';
    return 'صار خطأ أثناء تجهيز الصوت. حاول مرة ثانية.';
  }

  static Future<({File file, double seconds})> _render(_Voice voice, String text) async {
    final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse(
              'https://api.elevenlabs.io/v1/text-to-speech/${voice.id}?output_format=pcm_22050',
            ),
            headers: {
              'xi-api-key': _apiKey,
              'Content-Type': 'application/json',
              'Accept': 'application/octet-stream',
            },
            body: jsonEncode({
              'text': text,
              'model_id': 'eleven_multilingual_v2',
            }),
          )
          .timeout(const Duration(seconds: 30));
    } on TimeoutException {
      throw const StoryVoiceException('Eleven تأخر بالرد أكثر من اللازم. حاول مرة ثانية.');
    } on SocketException {
      throw const StoryVoiceException('ما في نت، فما وصل الطلب لـ Eleven.');
    } on http.ClientException {
      throw const StoryVoiceException('الاتصال بـ Eleven انقطع قبل ما يوصل الصوت.');
    }

    if (response.statusCode == 200 && response.bodyBytes.length < 256) {
      throw const StoryVoiceException('Eleven رجّع صوت فاضي، فما في شي نسمعه.');
    }
    if (response.statusCode != 200) {
      throw StoryVoiceException(await _failureMessage(response.statusCode, response.body));
    }

    final pcm = voice.pitch == 1
        ? Uint8List.fromList(response.bodyBytes)
        : _childTone(response.bodyBytes, voice.pitch);
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/glow_line_${DateTime.now().microsecondsSinceEpoch}.wav',
    );
    await file.writeAsBytes(_wav(pcm), flush: true);
    return (file: file, seconds: _pcmSeconds(pcm.length));
  }

  static Future<({File file, double seconds})> join(List<File> clips) async {
    final pcm = BytesBuilder(copy: false);
    for (final clip in clips) {
      pcm.add(_pcmFromWav(await clip.readAsBytes()));
    }
    final bytes = pcm.toBytes();
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/glow_scene_${DateTime.now().microsecondsSinceEpoch}.wav',
    );
    await file.writeAsBytes(_wav(bytes), flush: true);
    return (file: file, seconds: _pcmSeconds(bytes.length));
  }

  static Uint8List _childTone(List<int> pcm, double factor) {
    final samples = pcm.length ~/ 2;
    if (samples < 2) return Uint8List.fromList(pcm);
    final input = ByteData.sublistView(Uint8List.fromList(pcm));
    final outCount = (samples / factor).floor();
    final out = Uint8List(outCount * 2);
    final output = ByteData.sublistView(out);
    var smooth = 0.0;
    for (var i = 0; i < outCount; i++) {
      final src = i * factor;
      final i0 = src.floor().clamp(0, samples - 1);
      final i1 = (i0 + 1).clamp(0, samples - 1);
      final t = src - i0;
      final s0 = input.getInt16(i0 * 2, Endian.little);
      final s1 = input.getInt16(i1 * 2, Endian.little);
      final mixed = s0 + (s1 - s0) * t;
      smooth = smooth * 0.35 + mixed * 0.65;
      final soft = (smooth * 0.82).round().clamp(-32768, 32767);
      output.setInt16(i * 2, soft, Endian.little);
    }
    return out;
  }

  static double _pcmSeconds(int byteLength) {
    final seconds = byteLength / (_sampleRate * 2);
    return seconds < 0.05 ? 0.05 : seconds;
  }

  static Uint8List _pcmFromWav(List<int> wav) {
    if (wav.length > 12 &&
        wav[0] == 0x52 &&
        wav[1] == 0x49 &&
        wav[2] == 0x46 &&
        wav[3] == 0x46) {
      var offset = 12;
      while (offset + 8 <= wav.length) {
        final size = wav[offset + 4] |
            (wav[offset + 5] << 8) |
            (wav[offset + 6] << 16) |
            (wav[offset + 7] << 24);
        final isData = wav[offset] == 0x64 &&
            wav[offset + 1] == 0x61 &&
            wav[offset + 2] == 0x74 &&
            wav[offset + 3] == 0x61;
        final start = offset + 8;
        if (isData) {
          final end = (start + size).clamp(start, wav.length);
          return Uint8List.fromList(wav.sublist(start, end));
        }
        offset = start + size + (size.isOdd ? 1 : 0);
      }
    }
    return Uint8List.fromList(wav);
  }

  static Uint8List _wav(List<int> pcm) {
    final dataSize = pcm.length;
    final out = BytesBuilder(copy: false);
    out.add('RIFF'.codeUnits);
    out.add(_le32(36 + dataSize));
    out.add('WAVE'.codeUnits);
    out.add('fmt '.codeUnits);
    out.add(_le32(16));
    out.add(_le16(1));
    out.add(_le16(1));
    out.add(_le32(_sampleRate));
    out.add(_le32(_sampleRate * 2));
    out.add(_le16(2));
    out.add(_le16(16));
    out.add('data'.codeUnits);
    out.add(_le32(dataSize));
    out.add(pcm);
    return out.toBytes();
  }

  static List<int> _le16(int value) => [value & 0xff, (value >> 8) & 0xff];

  static List<int> _le32(int value) => [
        value & 0xff,
        (value >> 8) & 0xff,
        (value >> 16) & 0xff,
        (value >> 24) & 0xff,
      ];
}

class StoryVoiceException implements Exception {
  const StoryVoiceException(this.message);

  final String message;
}

Future<String> _failureMessage(int httpStatus, String body) async {
  final error = _elevenError(body);
  final code = error.status.toLowerCase();
  final message = error.message;
  final lower = message.toLowerCase();

  if (code == 'paid_plan_required' ||
      code == 'payment_required' ||
      lower.contains('free users') ||
      lower.contains('library voice')) {
    return 'المفتاح على الخطة المجانية. هالنبرات من مكتبة Eleven، والمجاني ما بيولّدها من التطبيق حتى لو العداد لسّا فيه حروف. الصق مفتاح من اشتراك مدفوع.';
  }
  if (code == 'invalid_api_key' || lower.contains('invalid api key') || (httpStatus == 401 && code.isEmpty && message.isEmpty)) {
    return 'مفتاح Eleven مرفوض. بدّله من إعدادات الأدمن.';
  }
  if (code == 'voice_not_found' ||
      (lower.contains('voice') && (lower.contains('not found') || lower.contains('not author') || lower.contains('unauthorized')))) {
    return 'النبرة مش على حساب المفتاح المحفوظ. الصق مفتاح Eleven من نفس الحساب اللي فيه مورت وبورت وكورت وفورت وسورت.';
  }
  if (code == 'max_character_limit_exceeded') {
    return 'الجملة أطول من المسموح بطلب واحد. قصّرها وحاول مرة ثانية.';
  }
  if (code == 'detected_unusual_activity') {
    return 'Eleven أوقف الاستخدام مؤقتاً. الرصيد ما خلص.';
  }
  if (code.contains('paid_plan') || lower.contains('output format') || lower.contains('pcm_')) {
    return 'صيغة الصوت مش مسموحة على هاد الاشتراك. الرصيد ما خلص.';
  }
  if (httpStatus == 429 || code == 'system_busy' || code.contains('concurrent')) {
    return 'Eleven طلب انتظار لأن الطلبات كثيرة. الرصيد ما خلص. حاول بعد شوي.';
  }
  if (lower.contains('voice') && (lower.contains('not') || lower.contains('author'))) {
    return 'النبرة مش على حساب المفتاح المحفوظ. الصق مفتاح Eleven من نفس الحساب اللي فيه مورت وبورت وكورت وفورت وسورت.';
  }
  if (httpStatus == 402 || code == 'quota_exceeded' || lower.contains('quota') || lower.contains('insufficient')) {
    final remaining = await _characterRemaining();
    if (remaining != null && remaining > 0) {
      return 'الرصيد ما خلص. المتبقي ${_digits(remaining)} حرف، وEleven رفض التوليد مع هيك. ${_quotaWhy(message)}';
    }
    if (remaining != null) {
      return 'الرصيد خلص فعلياً. المتبقي 0. بدّل المفتاح من إعدادات الأدمن.';
    }
    final why = _quotaWhy(message);
    return why.isEmpty
        ? 'Eleven قال إن الحصة ما بتكفي، وما قدرنا نقرأ عداد الرصيد.'
        : 'Eleven قال إن الحصة ما بتكفي. $why';
  }
  if (httpStatus == 422) {
    return message.isEmpty ? 'Eleven رفض النص. قصّر الجملة وحاول مرة ثانية.' : 'Eleven رفض النص. ${_short(message)}';
  }
  if (message.isEmpty) return 'Eleven ما رجّع صوت. رقم الرد $httpStatus.';
  return 'Eleven رفض الصوت. رقم الرد $httpStatus. ${_short(message)}';
}

Future<int?> _characterRemaining() async {
  try {
    final response = await http
        .get(
          Uri.parse('https://api.elevenlabs.io/v1/user/subscription'),
          headers: {'xi-api-key': StorySentenceVoice.activeApiKey},
        )
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) return null;
    final data = jsonDecode(response.body);
    if (data is! Map) return null;
    final used = (data['character_count'] as num?)?.toInt();
    final limit = (data['character_limit'] as num?)?.toInt();
    if (used == null || limit == null) return null;
    return limit - used;
  } catch (_) {
    return null;
  }
}

String _quotaWhy(String message) {
  final lower = message.toLowerCase();
  if (lower.contains('voice') && (lower.contains('not') || lower.contains('author'))) {
    return 'النبرة مش على حساب المفتاح المحفوظ. الصق مفتاح Eleven من نفس الحساب اللي فيه مورت وبورت وكورت وفورت وسورت.';
  }
  if (lower.contains('model')) return 'موديل الصوت مش متاح على هاد الاشتراك.';
  if (lower.contains('format') || lower.contains('pcm')) {
    return 'صيغة ملف الصوت مش مسموحة على هاد الاشتراك.';
  }
  final needed = RegExp(
    r'have\s+([\d,]+)\s+credits remaining.*?([\d,]+)\s+credits are required',
    caseSensitive: false,
  ).firstMatch(message);
  if (needed != null) {
    return 'الطلب طالب ${needed.group(2)} حرف، والعداد بيقول عندك ${needed.group(1)}.';
  }
  final clean = _short(message);
  if (clean.isEmpty || clean.toLowerCase() == 'quota_exceeded') {
    return 'الرفض مكتوب حصة، من غير سبب أوضح.';
  }
  return clean;
}

String _short(String text) {
  final clean = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (clean.isEmpty) return '';
  if (clean.length <= 160) return clean;
  return '${clean.substring(0, 160)}…';
}

class _ElevenError {
  const _ElevenError(this.status, this.message);

  final String status;
  final String message;
}

_ElevenError _elevenError(String body) {
  try {
    return _elevenErrorValue(jsonDecode(body));
  } catch (_) {
    return _ElevenError('', _short(body));
  }
}

_ElevenError _elevenErrorValue(Object? value) {
  if (value is List) {
    final messages = value.map(_elevenErrorValue).map((error) => error.message).where((text) => text.isNotEmpty);
    return _ElevenError('', messages.join(' '));
  }
  if (value is Map) {
    final detail = value['detail'] ?? value['message'] ?? value['error'];
    if (detail is Map) {
      return _ElevenError(
        '${detail['code'] ?? detail['status'] ?? ''}'.trim(),
        '${detail['message'] ?? detail['msg'] ?? ''}'.trim(),
      );
    }
    if (detail is List || detail is Map) return _elevenErrorValue(detail);
    return _ElevenError('${value['status'] ?? value['code'] ?? ''}'.trim(), '$detail'.trim());
  }
  return _ElevenError('', '$value'.trim());
}

String _digits(int value) {
  final text = value.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    if (i > 0 && (text.length - i) % 3 == 0) buffer.write(',');
    buffer.write(text[i]);
  }
  return value < 0 ? '-$buffer' : buffer.toString();
}

class _Voice {
  const _Voice(this.id, {this.pitch = 1.0});

  final String id;
  final double pitch;
}
