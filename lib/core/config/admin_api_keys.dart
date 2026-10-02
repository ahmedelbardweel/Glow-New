import 'package:hive_flutter/hive_flutter.dart';

/// Keys the admin can replace from settings when a quota runs out.
/// An empty value keeps the original key.
class AdminApiKeys {
  AdminApiKeys._();

  static const _gemini = 'ADMIN_GEMINI_API_KEY';
  static const _eleven = 'ADMIN_ELEVEN_API_KEY';
  static const _geminiOut = 'ADMIN_GEMINI_OUT';

  static String? get gemini => _read(_gemini);

  static String? get eleven => _read(_eleven);

  static bool get hasGemini => gemini != null;

  static bool get hasEleven => eleven != null;

  static bool get geminiExhausted => Hive.box('auth').get(_geminiOut) == true;

  static Future<void> markGeminiExhausted() {
    return Hive.box('auth').put(_geminiOut, true);
  }

  static Future<void> saveGemini(String value) async {
    await _write(_gemini, value);
    if (value.trim().isNotEmpty) await Hive.box('auth').delete(_geminiOut);
  }

  static Future<void> saveEleven(String value) => _write(_eleven, value);

  static String? _read(String key) {
    final value = Hive.box('auth').get(key);
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static Future<void> _write(String key, String value) async {
    final box = Hive.box('auth');
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      await box.delete(key);
      return;
    }
    await box.put(key, trimmed);
  }
}
