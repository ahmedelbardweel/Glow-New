import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../lib/core/animation/story_motion.dart';

void main() {
  group('StoryMotionPlan', () {
    test('empty and punctuation-only text stays idle', () {
      for (final text in ['', ' \n\t ', '...!؟؛، — 123']) {
        final plan = StoryMotionPlan.fromText(text);
        expect(plan.cues, isEmpty);
        expect(plan.duration, Duration.zero);
        expect(plan.motionAt(Duration.zero), CharacterMotion.idle);
      }
    });

    test('normalizes Arabic tashkeel, tatweel, alef and common prefixes', () {
      final plan = StoryMotionPlan.fromText(
        'مَرْحَبًا! أَنَا سَعِيدٌ. والـحَزِينُ بَكَى؟ إنتصر البطل!',
      );
      expect(plan.cues.map((cue) => cue.motion), [
        CharacterMotion.wave,
        CharacterMotion.happy,
        CharacterMotion.sad,
        CharacterMotion.victory,
      ]);
    });

    test('supports English without matching happy inside unhappy', () {
      final plan = StoryMotionPlan.fromText(
        'HELLO! She was unhappy. He is thinking; We won!',
      );
      expect(plan.cues.map((cue) => cue.motion), [
        CharacterMotion.wave,
        CharacterMotion.sad,
        CharacterMotion.thinking,
        CharacterMotion.victory,
      ]);
    });

    test('cue boundaries are contiguous and end returns to idle', () {
      final plan = StoryMotionPlan.fromText('مرحبا. مشى البطل؟ كان حزينا.');
      expect(plan.motionAt(const Duration(seconds: -1)), CharacterMotion.wave);
      for (var i = 0; i < plan.cues.length; i++) {
        final cue = plan.cues[i];
        expect(plan.cueAt(cue.start), same(cue));
        expect(
          plan.motionAt(cue.end - const Duration(microseconds: 1)),
          cue.motion,
        );
        if (i > 0) expect(cue.start, plan.cues[i - 1].end);
      }
      expect(plan.motionAt(plan.duration), CharacterMotion.idle);
      expect(plan.cueAt(plan.duration + const Duration(days: 1)), isNull);
    });

    test('uses editor overrides and keeps cue list immutable', () {
      final plan = StoryMotionPlan.fromText(
        'لم يكن سعيدا. مرحبا.',
        overrides: {0: CharacterMotion.sad},
      );
      expect(plan.cues.first.motion, CharacterMotion.sad);
      expect(plan.cues.last.motion, CharacterMotion.wave);
      expect(() => plan.cues.clear(), throwsUnsupportedError);
    });

    test('long unpunctuated passages have bounded deterministic cues', () {
      final text = List.filled(55, 'شجرة').join(' ');
      final first = StoryMotionPlan.fromText(text);
      final second = StoryMotionPlan.fromText(text);
      expect(first.cues, hasLength(4));
      expect(first.duration, second.duration);
      expect(first.cues.map((cue) => cue.text).join(' '), text);
      for (final cue in first.cues) {
        expect(cue.motion, CharacterMotion.talk);
        expect(cue.duration.inMilliseconds, inInclusiveRange(1800, 8000));
      }
    });

    test('GLB clip names remain unique and complete', () {
      final bytes = File('assets/3d/glow_rigged.glb').readAsBytesSync();
      final length = ByteData.sublistView(bytes).getUint32(12, Endian.little);
      final gltf = jsonDecode(utf8.decode(bytes.sublist(20, 20 + length)));
      final clips = (gltf['animations'] as List).map((a) => a['name']).toSet();
      final names = CharacterMotion.values.map((motion) => motion.clipName).toSet();
      expect(names.length, CharacterMotion.values.length);
      expect(names, clips);
    });

    test('new emotion cues and explicit overrides select the reference states', () {
      final plan = StoryMotionPlan.fromText(
        'أنا متحمس! كان فضوليا. أنا فضولي. إنه مرتبك. شعر بالتوتر. متوتر. '
        'أحسنت! احتفل بالفوز. رفع الكأس.',
        overrides: {1: CharacterMotion.curious, 4: CharacterMotion.nervous},
      );
      expect(plan.cues.map((cue) => cue.motion), [
        CharacterMotion.excited, CharacterMotion.curious, CharacterMotion.curious,
        CharacterMotion.confused, CharacterMotion.nervous, CharacterMotion.nervous,
        CharacterMotion.encourage, CharacterMotion.winCelebration, CharacterMotion.ultimateWin,
      ]);
    });
  });
}
