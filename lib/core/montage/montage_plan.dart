import 'dart:math' as math;

import '../models/story_timeline.dart';

/// One spoken sentence already locked to a character block on the timeline.
class MontageSentence {
  const MontageSentence({
    required this.text,
    required this.characterName,
    required this.start,
    required this.end,
  });

  final String text;
  final String characterName;
  final double start;
  final double end;
}

class MontageApply {
  const MontageApply({
    required this.timeline,
    required this.placed,
    required this.missed,
  });

  final StoryTimeline timeline;
  final int placed;
  final int missed;
}

const _motions = {
  'wave',
  'happy',
  'sad',
  'thinking',
  'victory',
  'walk',
  'smile',
  'laugh',
};

/// Turns Gemini's word indexes into timeline blocks inside the existing
/// character windows. Character blocks and their times stay as they are.
MontageApply placeMontage({
  required List<StoryBlock> characters,
  required List<MontageSentence> sentences,
  required Map<String, dynamic> plan,
  required double totalDuration,
}) {
  final count = math.min(characters.length, sentences.length);
  final motions = <StoryMotionBlock>[];
  final jumps = <StoryJumpBlock>[];
  final hats = <StoryHatBlock>[];
  final glasses = <StoryGlassesBlock>[];
  final muscles = <StoryMusclesBlock>[];
  final transitions = <StoryTransition>[];
  var placed = 0;
  var missed = 0;

  final cues = plan['cues'];
  if (cues is List) {
    for (final raw in cues) {
      if (raw is! Map) continue;
      final sentence = _asInt(raw['sentence']);
      final startWord = _asInt(raw['startWord']);
      final endWord = _asInt(raw['endWord']) ?? startWord;
      final quote = (raw['quote'] ?? '').toString();
      final kind = (raw['kind'] ?? '').toString();
      final value = (raw['value'] ?? '').toString();
      if (sentence == null || sentence < 0 || sentence >= count) {
        missed++;
        continue;
      }
      final words = _words(sentences[sentence].text);
      final range = _wordRange(words, quote, startWord, endWord);
      if (range == null) {
        missed++;
        continue;
      }
      final block = characters[sentence];
      final window = _timeWindow(
        blockStart: block.startTime,
        blockEnd: block.endTime,
        textLength: sentences[sentence].text.length,
        charStart: range.$1,
        charEnd: range.$2,
        minDuration: kind == 'jump' ? 0.7 : 0.55,
      );
      if (window == null) {
        missed++;
        continue;
      }
      final kept = switch (kind) {
        'motion' when _motions.contains(value) => _placeSpan(
            motions,
            window,
            (start, end) => StoryMotionBlock(motionId: value, startTime: start, endTime: end),
            (block) => (block.startTime, block.endTime),
            (block, start, end) => StoryMotionBlock(motionId: block.motionId, startTime: start, endTime: end),
          ),
        'jump' => _placeSpan(
            jumps,
            window,
            (start, end) => StoryJumpBlock(startTime: start, endTime: end),
            (block) => (block.startTime, block.endTime),
            (block, start, end) => StoryJumpBlock(startTime: start, endTime: end),
          ),
        'hat' => _wear(
            hats,
            window.$1,
            block.endTime,
            (start, end) => StoryHatBlock(colorHex: '2c2c2e', startTime: start, endTime: end),
            (block) => (block.startTime, block.endTime),
          ),
        'glasses' => _wear(
            glasses,
            window.$1,
            block.endTime,
            (start, end) => StoryGlassesBlock(startTime: start, endTime: end),
            (block) => (block.startTime, block.endTime),
          ),
        'muscles' => _wear(
            muscles,
            window.$1,
            block.endTime,
            (start, end) => StoryMusclesBlock(startTime: start, endTime: end),
            (block) => (block.startTime, block.endTime),
          ),
        _ => false,
      };
      if (kept) {
        placed++;
      } else {
        missed++;
      }
    }
  }

  final seams = plan['seams'];
  if (seams is List) {
    for (final raw in seams) {
      if (raw is! Map) continue;
      final after = _asInt(raw['afterSentence']);
      final type = (raw['type'] ?? '').toString();
      if (after == null || after < 0 || after >= count - 1) continue;
      if (!StoryTransition.types.contains(type)) continue;
      final current = characters[after];
      final next = characters[after + 1];
      if (current.characterId == next.characterId) continue;
      final time = current.endTime <= next.startTime
          ? (current.endTime + next.startTime) / 2
          : current.endTime;
      transitions.removeWhere((item) => (item.time - time).abs() < 0.05);
      transitions.add(StoryTransition(time: time, type: type));
      placed++;
    }
  }

  motions.sort((a, b) => a.startTime.compareTo(b.startTime));
  jumps.sort((a, b) => a.startTime.compareTo(b.startTime));
  hats.sort((a, b) => a.startTime.compareTo(b.startTime));
  glasses.sort((a, b) => a.startTime.compareTo(b.startTime));
  muscles.sort((a, b) => a.startTime.compareTo(b.startTime));
  transitions.sort((a, b) => a.time.compareTo(b.time));

  return MontageApply(
    timeline: StoryTimeline(
      blocks: characters,
      motionBlocks: motions,
      hatBlocks: hats,
      glassesBlocks: glasses,
      musclesBlocks: muscles,
      jumpBlocks: jumps,
      transitions: transitions,
      totalDuration: totalDuration,
    ),
    placed: placed,
    missed: missed,
  );
}

List<Map<String, dynamic>> montageRequestSentences(List<MontageSentence> sentences) {
  return [
    for (final sentence in sentences)
      {
        'character': sentence.characterName,
        'words': [for (final word in _words(sentence.text)) word.text],
      },
  ];
}

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value');
}

class _Word {
  const _Word(this.text, this.start, this.end);

  final String text;
  final int start;
  final int end;
}

List<_Word> _words(String sentence) {
  return [
    for (final match in RegExp(r'\S+').allMatches(sentence))
      _Word(match.group(0)!, match.start, match.end),
  ];
}

String _fold(String input) {
  final buffer = StringBuffer();
  for (final unit in input.split('')) {
    switch (unit) {
      case 'أ':
      case 'إ':
      case 'آ':
      case 'ٱ':
        buffer.write('ا');
      case 'ة':
        buffer.write('ه');
      case 'ى':
      case 'ئ':
        buffer.write('ي');
      case 'ؤ':
        buffer.write('و');
      default:
        if (RegExp(r'[\u064B-\u065F\u0670\u0640]').hasMatch(unit)) break;
        buffer.write(unit.toLowerCase());
    }
  }
  return buffer.toString();
}

/// Character offsets of the quote, preferring the occurrence nearest [startWord].
(int, int)? _wordRange(List<_Word> words, String quote, int? startWord, int? endWord) {
  if (words.isEmpty) return null;
  final foldedQuote = _fold(quote.trim());
  if (foldedQuote.isNotEmpty) {
    final hits = <(int, int)>[];
    for (var i = 0; i < words.length; i++) {
      final chunk = StringBuffer();
      for (var j = i; j < words.length; j++) {
        if (chunk.isNotEmpty) chunk.write(' ');
        chunk.write(_fold(words[j].text));
        final text = chunk.toString();
        if (text == foldedQuote) {
          hits.add((words[i].start, words[j].end));
          break;
        }
        if (!foldedQuote.startsWith(text)) break;
      }
    }
    if (hits.isNotEmpty) {
      if (startWord == null || startWord < 0 || startWord >= words.length) {
        return hits.first;
      }
      final anchor = words[startWord].start;
      hits.sort((a, b) => (a.$1 - anchor).abs().compareTo((b.$1 - anchor).abs()));
      return hits.first;
    }
  }
  if (startWord == null || startWord < 0 || startWord >= words.length) return null;
  final last = (endWord ?? startWord).clamp(startWord, words.length - 1);
  return (words[startWord].start, words[last].end);
}

(double, double)? _timeWindow({
  required double blockStart,
  required double blockEnd,
  required int textLength,
  required int charStart,
  required int charEnd,
  required double minDuration,
}) {
  final duration = blockEnd - blockStart;
  if (duration <= 0.2 || textLength <= 0) return null;
  var start = blockStart + (charStart / textLength) * duration;
  var end = blockStart + (charEnd / textLength) * duration;
  if (end < start) end = start;
  if (end - start < minDuration) {
    final middle = (start + end) / 2;
    start = middle - minDuration / 2;
    end = middle + minDuration / 2;
  }
  if (start < blockStart) {
    end += blockStart - start;
    start = blockStart;
  }
  if (end > blockEnd) {
    start -= end - blockEnd;
    end = blockEnd;
  }
  if (start < blockStart) start = blockStart;
  if (end - start < 0.2) return null;
  return (start, end);
}

bool _placeSpan<T>(
  List<T> blocks,
  (double, double) window,
  T Function(double start, double end) create,
  (double, double) Function(T block) read,
  T Function(T block, double start, double end) trim,
) {
  final start = window.$1;
  final end = window.$2;
  for (var i = blocks.length - 1; i >= 0; i--) {
    final current = read(blocks[i]);
    if (start >= current.$2 || end <= current.$1) continue;
    if (current.$1 < start && start - current.$1 >= 0.25) {
      blocks[i] = trim(blocks[i], current.$1, start);
    } else {
      blocks.removeAt(i);
    }
  }
  blocks.add(create(start, end));
  return true;
}

bool _wear<T>(
  List<T> blocks,
  double start,
  double blockEnd,
  T Function(double start, double end) create,
  (double, double) Function(T block) read,
) {
  if (blockEnd - start < 0.2) return false;
  for (var i = blocks.length - 1; i >= 0; i--) {
    final current = read(blocks[i]);
    if (start >= current.$2 || blockEnd <= current.$1) continue;
    if (current.$1 < start && start - current.$1 >= 0.25) {
      blocks[i] = create(current.$1, start);
    } else {
      blocks.removeAt(i);
    }
  }
  blocks.add(create(start, blockEnd));
  return true;
}
