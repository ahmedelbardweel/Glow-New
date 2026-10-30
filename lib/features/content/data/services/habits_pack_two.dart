import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/mission_model.dart';
import '../models/question_model.dart';
import '../models/story_model.dart';
import '../models/world_model.dart';

/// Habits 6–20 with bundled offline voice, created once as an unpublished draft.
class HabitsPackTwo {
  static const id = 'a2000000-0000-4000-8000-000000000100';
  static const title = 'بكج العادات — من 6 إلى 20';
  static const description = 'خمس عشرة عادة بأصوات الشخصيات، تشتغل بدون إنترنت. جاهزة للمراجعة قبل النشر.';

  /// Null until tools/voice/build_habits_pack_2.mjs has generated the content and voice.
  static Future<Map<String, dynamic>?> loadPayload({AssetBundle? bundle}) async {
    final assets = bundle ?? rootBundle;
    const kinds = ['worlds', 'missions', 'stories', 'questions'];
    final List<String> values;
    try {
      values = await Future.wait(
        kinds.map((kind) => assets.loadString('assets/content/habits2_$kind.json')),
      );
    } on FlutterError {
      return null;
    }
    List<Map<String, dynamic>> rows(int index) => (jsonDecode(values[index]) as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
    return {
      'worlds': rows(0).map((row) => WorldModel.fromJson(row).toJson()).toList(),
      'missions': rows(1).map((row) => MissionModel.fromJson(row).toJson()).toList(),
      'stories': rows(2).map((row) => StoryModel.fromJson(row).toJson()).toList(),
      'questions': rows(3).map((row) => QuestionModel.fromJson(row).toJson()).toList(),
    };
  }

  /// Returns false when the bundled content has not been generated yet.
  static Future<bool> ensureCreated(SupabaseClient client) async {
    final content = await loadPayload();
    if (content == null) return false;
    await client.rpc('ensure_bundled_admin_package', params: {
      'package_id': id,
      'package_title': title,
      'package_description': description,
      'content': content,
    });
    return true;
  }
}
