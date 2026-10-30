import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/world_model.dart';
import '../models/mission_model.dart';
import '../models/story_model.dart';
import '../models/question_model.dart';

/// Copies bundled content once into the editable admin draft tables.
class LaunchAdminPackage {
  static const id = 'a1000000-0000-4000-8000-000000000100';
  static const title = 'بكج البداية — العادات الخمس';

  static Future<Map<String, dynamic>> loadPayload({AssetBundle? bundle}) async {
    final assets = bundle ?? rootBundle;
    const kinds = ['worlds', 'missions', 'stories', 'questions'];
    final values = await Future.wait(
      kinds.map(
        (kind) => assets.loadString('assets/content/launch_$kind.json'),
      ),
    );
    List<Map<String, dynamic>> rows(int index) =>
        (jsonDecode(values[index]) as List)
            .map((row) => Map<String, dynamic>.from(row as Map))
            .toList();
    // Model serializers omit seed-only SQL expressions such as created_at.
    return {
      'worlds': rows(
        0,
      ).map((row) => WorldModel.fromJson(row).toJson()).toList(),
      'missions': rows(
        1,
      ).map((row) => MissionModel.fromJson(row).toJson()).toList(),
      'stories': rows(
        2,
      ).map((row) => StoryModel.fromJson(row).toJson()).toList(),
      'questions': rows(
        3,
      ).map((row) => QuestionModel.fromJson(row).toJson()).toList(),
    };
  }

  static Future<void> ensureCreated(SupabaseClient client) async {
    await client.rpc(
      'ensure_launch_admin_package',
      params: {'content': await loadPayload()},
    );
  }
}
