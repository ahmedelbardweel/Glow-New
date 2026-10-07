import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../di/injection_container.dart';

/// Keys the admin can replace from settings when a quota runs out.
/// An empty value keeps the original key.
class AdminApiKeys {
  AdminApiKeys._();

  static const _gemini = 'ADMIN_GEMINI_API_KEY';
  static const _eleven = 'ADMIN_ELEVEN_API_KEY';
  static const _groq = 'ADMIN_GROQ_API_KEY';
  static const _geminiOut = 'ADMIN_GEMINI_OUT';
  static const _geminiModel = 'ADMIN_GEMINI_MODEL';
  static const _montageModel = 'ADMIN_MONTAGE_MODEL';
  static const defaultGeminiModel = 'gemini-3.8-flash';
  static const defaultMontageModel = 'groq:qwen/qwen3.8-27b';

  static String? get gemini => _read(_gemini);

  static String? get eleven => _read(_eleven);

  static String? get groq => _read(_groq);

  static bool get hasGemini => gemini != null;

  static bool get hasEleven => eleven != null;

  static bool get hasGroq => groq != null;

  static bool get geminiExhausted => Hive.box('auth').get(_geminiOut) == true;

  static String get geminiModel {
    final saved = _read(_geminiModel);
    if (saved != null && geminiModelChoices.any((model) => model.id == saved)) {
      return saved;
    }
    return defaultGeminiModel;
  }

  static Future<void> saveGeminiModel(String value) {
    final known = geminiModelChoices.any((model) => model.id == value);
    return _write(_geminiModel, known ? value : defaultGeminiModel);
  }

  static Future<void> markGeminiExhausted() {
    return Hive.box('auth').put(_geminiOut, true);
  }

  static Future<void> saveGemini(String value) async {
    await _write(_gemini, value);
    if (value.trim().isNotEmpty) await Hive.box('auth').delete(_geminiOut);
  }

  static Future<void> saveEleven(String value) => _write(_eleven, value);

  static Future<void> saveGroq(String value) => _write(_groq, value);

  static MontageModelChoice get montageChoice {
    final saved = _read(_montageModel);
    for (final choice in montageModelChoices) {
      if (choice.id == saved) return choice;
    }
    return montageModelChoices.first;
  }

  static Future<void> saveMontageModel(String value) {
    final known = montageModelChoices.any((model) => model.id == value);
    return _write(_montageModel, known ? value : defaultMontageModel);
  }

  /// Pulls the shared admin keys. If the account has none yet, the keys on
  /// this phone are uploaded so the next device can read them.
  static Future<void> sync() async {
    try {
      final client = sl<SupabaseClient>();
      if (client.auth.currentSession == null) return;
      final row = await client
          .from('admin_settings')
          .select('gemini_key, eleven_key, gemini_model, groq_key, montage_model')
          .eq('id', 'keys')
          .maybeSingle();
      final remoteGemini = '${row?['gemini_key'] ?? ''}'.trim();
      final remoteEleven = '${row?['eleven_key'] ?? ''}'.trim();
      final remoteGroq = '${row?['groq_key'] ?? ''}'.trim();
      if (row == null || (remoteGemini.isEmpty && remoteEleven.isEmpty && remoteGroq.isEmpty)) {
        if (gemini != null || eleven != null || groq != null) await push();
        return;
      }
      await saveGemini(remoteGemini);
      await saveEleven(remoteEleven);
      if (remoteGroq.isNotEmpty) await saveGroq(remoteGroq);
      final remoteModel = '${row['gemini_model'] ?? ''}'.trim();
      if (remoteModel.isNotEmpty) await saveGeminiModel(remoteModel);
      final remoteMontage = '${row['montage_model'] ?? ''}'.trim();
      if (remoteMontage.isNotEmpty) await saveMontageModel(remoteMontage);
    } catch (_) {}
  }

  static Future<bool> push() async {
    try {
      final client = sl<SupabaseClient>();
      if (client.auth.currentSession == null) return false;
      await client.from('admin_settings').upsert({
        'id': 'keys',
        'gemini_key': gemini ?? '',
        'eleven_key': eleven ?? '',
        'gemini_model': geminiModel,
        'groq_key': groq ?? '',
        'montage_model': montageChoice.id,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
      return true;
    } catch (_) {
      return false;
    }
  }

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

class GeminiModelChoice {
  const GeminiModelChoice(this.label, this.id);

  final String label;
  final String id;
}

class MontageModelChoice {
  const MontageModelChoice(this.label, this.provider, this.model);

  final String label;
  final String provider;
  final String model;

  String get id => '$provider:$model';
}

const montageModelChoices = <MontageModelChoice>[
  MontageModelChoice('Qwen 3.8 27B · Groq مجاني', 'groq', 'qwen/qwen3.8-27b'),
  MontageModelChoice('GPT-OSS 120B · Groq مجاني', 'groq', 'openai/gpt-oss-120b'),
  MontageModelChoice('GPT-OSS 20B · Groq مجاني', 'groq', 'openai/gpt-oss-20b'),
  MontageModelChoice('Gemini 3.8 Flash', 'gemini', 'gemini-3.8-flash'),
  MontageModelChoice('Gemini 3.7 Flash', 'gemini', 'gemini-3.7-flash'),
  MontageModelChoice('Gemini 3.6 Flash', 'gemini', 'gemini-3.6-flash'),
  MontageModelChoice('Gemini 3.5 Flash', 'gemini', 'gemini-3.5-flash'),
  MontageModelChoice('Gemini 3.5 Flash-Lite', 'gemini', 'gemini-3.5-flash-lite'),
  MontageModelChoice('Gemini 3.1 Flash-Lite', 'gemini', 'gemini-3.1-flash-lite'),
  MontageModelChoice('Gemini 3.1 Pro', 'gemini', 'gemini-3.1-pro-preview'),
  MontageModelChoice('Gemini 3 Flash', 'gemini', 'gemini-3-flash-preview'),
  MontageModelChoice('Gemini 2.5 Pro', 'gemini', 'gemini-2.5-pro'),
  MontageModelChoice('Gemini 2.5 Flash', 'gemini', 'gemini-2.5-flash'),
  MontageModelChoice('Gemini 2.5 Flash-Lite', 'gemini', 'gemini-2.5-flash-lite'),
];

const geminiModelChoices = <GeminiModelChoice>[
  GeminiModelChoice('Gemini 3.8 Flash', 'gemini-3.8-flash'),
  GeminiModelChoice('Gemini 3.7 Flash', 'gemini-3.7-flash'),
  GeminiModelChoice('Gemini 3.6 Flash', 'gemini-3.6-flash'),
  GeminiModelChoice('Gemini 3.5 Flash', 'gemini-3.5-flash'),
  GeminiModelChoice('Gemini 3.5 Flash-Lite', 'gemini-3.5-flash-lite'),
  GeminiModelChoice('Gemini 3.1 Flash-Lite', 'gemini-3.1-flash-lite'),
  GeminiModelChoice('Gemini 3.1 Pro', 'gemini-3.1-pro-preview'),
  GeminiModelChoice('Gemini 3 Flash', 'gemini-3-flash-preview'),
  GeminiModelChoice('Gemini 2.5 Pro', 'gemini-2.5-pro'),
  GeminiModelChoice('Gemini 2.5 Flash', 'gemini-2.5-flash'),
  GeminiModelChoice('Gemini 2.5 Flash-Lite', 'gemini-2.5-flash-lite'),
];
