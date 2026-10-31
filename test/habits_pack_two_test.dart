import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:Glow/features/content/data/services/habits_pack_two.dart';
import 'package:Glow/features/content/data/built_in_habit_audio.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('habits 6–20 include complete questions, character timing and audio', () async {
    final data = await HabitsPackTwo.loadPayload();
    expect(data, isNotNull);
    final missions = data!['missions'] as List;
    final stories = data['stories'] as List;
    final questions = data['questions'] as List;
    expect(missions, hasLength(15));
    expect(stories, hasLength(15));
    expect(questions, hasLength(75));
    expect(missions.map((m) => m['id']).toSet(), hasLength(15));
    for (final mission in missions) {
      expect(mission['stars_reward'], greaterThan(0));
      expect(questions.where((q) => q['mission_id'] == mission['id']), hasLength(5));
    }
    for (final question in questions) {
      expect(question['options'], hasLength(4));
      expect(question['correct_answer_index'], inInclusiveRange(0, 3));
    }
    for (final story in stories) {
      final asset = BuiltInHabitAudio.assetForSource(story['id'], story['audio_url']);
      expect(asset, isNotNull);
      expect((await rootBundle.load('assets/$asset')).lengthInBytes, greaterThan(10000));
      final timeline = jsonDecode(story['timeline_data'] as String) as Map;
      var previousEnd = 0.0;
      for (final block in timeline['blocks'] as List) {
        expect(block['startTime'], greaterThanOrEqualTo(previousEnd));
        expect(block['endTime'], greaterThan(block['startTime']));
        expect(block['endTime'], lessThanOrEqualTo(timeline['totalDuration']));
        expect(['port','mort','fort','sort','qort'], contains(block['characterId']));
        previousEnd = (block['endTime'] as num).toDouble();
      }
    }
  });
}
