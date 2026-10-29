import 'dart:convert';

import 'package:flutter/services.dart';

import '../datasources/content_local_data_source.dart';
import '../models/mission_model.dart';
import '../models/question_model.dart';
import '../models/story_model.dart';
import '../models/world_model.dart';

/// Seeds the five launch habits from the APK before any network sync.
///
/// Supabase remains the source of updates, but a fresh install already owns a
/// complete playable copy of the launch package: world, missions, scripts,
/// questions, timelines, and bundled story audio.
class LaunchHabitBootstrapper {
  LaunchHabitBootstrapper(this._local);

  final ContentLocalDataSource _local;

  static const _worldId = 'a1000000-0000-4000-8000-000000000001';
  static const _missionIds = <String>{
    'a1000000-0000-4000-8000-000000000011',
    'a1000000-0000-4000-8000-000000000012',
    'a1000000-0000-4000-8000-000000000013',
    'a1000000-0000-4000-8000-000000000014',
    'a1000000-0000-4000-8000-000000000015',
  };

  Future<void> seedIfNeeded() async {
    final cachedWorlds = await _local.getCachedWorlds();
    final cachedMissions = await _local.getCachedMissions(_worldId);
    final hasEveryMission =
        cachedMissions.map((mission) => mission.id).toSet().containsAll(_missionIds);
    if (cachedWorlds.any((world) => world.id == _worldId) && hasEveryMission) {
      final complete = await Future.wait(cachedMissions
          .where((mission) => _missionIds.contains(mission.id))
          .map((mission) async {
        final stories = await _local.getCachedStories(mission.id);
        final questions = await _local.getCachedQuestions(mission.id);
        return stories.isNotEmpty && questions.length >= 5;
      }));
      if (complete.every((ready) => ready)) return;
    }

    final values = await Future.wait([
      rootBundle.loadString('assets/content/launch_worlds.json'),
      rootBundle.loadString('assets/content/launch_missions.json'),
      rootBundle.loadString('assets/content/launch_stories.json'),
      rootBundle.loadString('assets/content/launch_questions.json'),
    ]);

    final worlds = _decode(values[0], WorldModel.fromJson);
    final missions = _decode(values[1], MissionModel.fromJson);
    final stories = _decode(values[2], StoryModel.fromJson);
    final questions = _decode(values[3], QuestionModel.fromJson);

    final mergedWorlds = <String, WorldModel>{
      for (final world in cachedWorlds) world.id: world,
      for (final world in worlds) world.id: world,
    };
    await _local.cacheWorlds(mergedWorlds.values.toList());
    for (final world in worlds) {
      await _local.cacheMissions(
        world.id,
        missions.where((mission) => mission.worldId == world.id).toList(),
      );
    }
    for (final mission in missions) {
      await _local.cacheStories(
        mission.id,
        stories.where((story) => story.missionId == mission.id).toList(),
      );
      await _local.cacheQuestions(
        mission.id,
        questions.where((question) => question.missionId == mission.id).toList(),
      );
    }
  }

  List<T> _decode<T>(
    String source,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final decoded = jsonDecode(source) as List<dynamic>;
    return decoded
        .map((item) => fromJson(Map<String, dynamic>.from(item as Map)))
        .toList(growable: false);
  }
}
