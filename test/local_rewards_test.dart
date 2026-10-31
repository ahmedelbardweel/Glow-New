import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:Glow/features/content/data/datasources/content_local_data_source.dart';
import 'package:Glow/features/content/data/models/child_progress_model.dart';

void main() {
  test('offline rewards survive empty sync and incomplete remote rows without duplicates', () async {
    final dir = await Directory.systemTemp.createTemp('glow_rewards_');
    Hive.init(dir.path);
    final boxes = await Future.wait(['w','m','s','q','p','pending'].map((name) => Hive.openBox(name)));
    final local = ContentLocalDataSourceImpl(worldsBox: boxes[0], missionsBox: boxes[1], storiesBox: boxes[2], questionsBox: boxes[3], progressBox: boxes[4], pendingBox: boxes[5]);
    try {
      await local.saveLocalCompletedMission(childId: 'child', missionId: 'mission', starsReward: 50, badgeName: 'وسام الشجاعة');
      await local.cacheChildProgress('child', []);
      await local.cacheChildProgress('child', [ChildProgressModel(id: 'server', childId: 'child', missionId: 'mission', completedAt: DateTime.now())]);
      await local.saveLocalCompletedMission(childId: 'child', missionId: 'mission', starsReward: 50);
      final progress = await local.getCachedChildProgress('child');
      expect(progress, hasLength(1));
      expect(progress.single.starsReward, 50);
      expect(progress.single.badgeName, 'وسام الشجاعة');
    } finally {
      await Hive.close();
      await dir.delete(recursive: true);
    }
  });
}
