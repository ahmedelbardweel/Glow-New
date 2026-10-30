import 'package:Glow/features/content/data/services/launch_admin_package.dart';
import 'package:Glow/features/content/data/built_in_habit_audio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'launch draft includes linked habits, stories, questions and bundled audio',
    () async {
      final data = await LaunchAdminPackage.loadPayload();
      final worlds = data['worlds'] as List;
      final missions = data['missions'] as List;
      final stories = data['stories'] as List;
      final questions = data['questions'] as List;
      expect(worlds, hasLength(1));
      expect(missions, hasLength(5));
      expect(stories, hasLength(5));
      expect(questions, hasLength(25));
      final worldIds = worlds.map((row) => row['id']).toSet();
      final missionIds = missions.map((row) => row['id']).toSet();
      for (final mission in missions) {
        expect(worldIds, contains(mission['world_id']));
        expect(
          questions.where((row) => row['mission_id'] == mission['id']),
          hasLength(5),
        );
      }
      for (final story in stories) {
        expect(missionIds, contains(story['mission_id']));
        expect(story['content'], isNotEmpty);
        expect(story['timeline_data'], isNotEmpty);
        final asset = BuiltInHabitAudio.assetForSource(
          story['id'],
          story['audio_url'],
        );
        expect(asset, isNotNull);
        expect(
          (await rootBundle.load('assets/$asset')).lengthInBytes,
          greaterThan(44),
        );
        expect(
          BuiltInHabitAudio.assetForSource(
            story['id'],
            'https://example.com/new-recording.wav',
          ),
          isNull,
        );
      }
      for (final rows in data.values) {
        for (final row in rows as List) {
          expect(row.containsKey('created_at'), isFalse);
        }
      }
    },
  );
}
