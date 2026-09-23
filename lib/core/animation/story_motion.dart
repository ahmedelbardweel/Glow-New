/// Shared animation names exported by the single, rigged Glow character.
enum CharacterMotion {
  idle('Idle', 'هدوء'),
  talk('Talk', 'كلام'),
  wave('Wave', 'تحية'),
  happy('Happy', 'سعادة'),
  sad('Sad', 'حزن'),
  thinking('Thinking', 'تفكير'),
  victory('Victory', 'انتصار'),
  walk('Walk', 'مشي'),
  smile('Smile', 'ابتسامة'),
  laugh('Laugh', 'ضحك');

  const CharacterMotion(this.clipName, this.arabicLabel);

  final String clipName;
  final String arabicLabel;
}

/// A sentence-sized movement cue. [start] is inclusive, [end] exclusive.
class StoryMotionCue {
  const StoryMotionCue({
    required this.start,
    required this.duration,
    required this.text,
    required this.motion,
  });

  final Duration start;
  final Duration duration;
  final String text;
  final CharacterMotion motion;

  Duration get end => start + duration;
}

/// Deterministic, local keyword cues, with estimated reading durations.
///
/// This is deliberately not semantic language understanding, audio analysis,
/// or lip synchronization. Editors can override a cue by its zero-based index;
/// callers with narration timing should provide the real playback position.
class StoryMotionPlan {
  StoryMotionPlan._(List<StoryMotionCue> cues) : cues = List.unmodifiable(cues);

  factory StoryMotionPlan.fromText(
    String text, {
    Map<int, CharacterMotion> overrides = const {},
  }) {
    final cues = <StoryMotionCue>[];
    var elapsed = Duration.zero;
    for (final sentence in text.split(RegExp(r'[.!?؟؛;\n\r…]+'))) {
      final words = sentence.trim().split(RegExp(r'\s+'));
      // Long, unpunctuated passages still receive bounded, readable cues.
      for (var offset = 0; offset < words.length; offset += 18) {
        final end = (offset + 18).clamp(0, words.length);
        final phrase = words.sublist(offset, end).join(' ').trim();
        final normalized = _normalize(phrase);
        if (normalized.isEmpty) continue;
        final wordCount = normalized.split(' ').length;
        final duration = Duration(
          milliseconds: (800 + wordCount * 360).clamp(1800, 8000),
        );
        cues.add(
          StoryMotionCue(
            start: elapsed,
            duration: duration,
            text: phrase,
            motion: overrides[cues.length] ?? _classify(normalized),
          ),
        );
        elapsed += duration;
      }
    }
    return StoryMotionPlan._(cues);
  }

  final List<StoryMotionCue> cues;

  Duration get duration => cues.isEmpty ? Duration.zero : cues.last.end;

  StoryMotionCue? cueAt(Duration position) {
    if (cues.isEmpty) return null;
    final time = position.isNegative ? Duration.zero : position;
    if (time >= duration) return null;
    var low = 0;
    var high = cues.length - 1;
    while (low <= high) {
      final middle = (low + high) ~/ 2;
      final cue = cues[middle];
      if (time < cue.start) {
        high = middle - 1;
      } else if (time >= cue.end) {
        low = middle + 1;
      } else {
        return cue;
      }
    }
    return null;
  }

  CharacterMotion motionAt(Duration position) =>
      cueAt(position)?.motion ?? CharacterMotion.idle;

  static String _normalize(String value) => value
      .toLowerCase()
      .replaceAll(
        RegExp('[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06EDـ]'),
        '',
      )
      .replaceAll(RegExp('[أإآٱ]'), 'ا')
      .replaceAll('ى', 'ي')
      .replaceAll('ة', 'ه')
      .replaceAll(RegExp(r'[^a-z\u0621-\u063A\u0641-\u064A\s]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static CharacterMotion _classify(String sentence) {
    final tokens = sentence.split(' ').toSet();
    // Permit common Arabic conjunction/article prefixes without substring
    // matching English words (for example "unhappy" must not match "happy").
    for (final token in tokens.toList()) {
      if (!RegExp(r'^[\u0621-\u064A]+$').hasMatch(token)) continue;
      var bare = token;
      if (bare.length > 3 && (bare.startsWith('و') || bare.startsWith('ف'))) {
        bare = bare.substring(1);
        tokens.add(bare);
      }
      if (bare.startsWith('ال') && bare.length > 4) {
        tokens.add(bare.substring(2));
      }
    }
    for (final rule in _rules) {
      if (rule.$2.any(tokens.contains)) return rule.$1;
    }
    return CharacterMotion.talk;
  }

  // Fixed priority is intentional and testable. A sentence containing several
  // emotions needs an editor override when these simple rules are insufficient.
  static const _rules = <(CharacterMotion, List<String>)>[
    (
      CharacterMotion.victory,
      [
        'فاز',
        'فازت',
        'فزت',
        'فزنا',
        'فوز',
        'انتصر',
        'انتصار',
        'بطل',
        'نجح',
        'نجحت',
        'نجحنا',
        'won',
        'win',
        'victory',
        'champion',
      ],
    ),
    (
      CharacterMotion.sad,
      [
        'حزين',
        'حزينا',
        'حزينه',
        'حزن',
        'بكي',
        'تبكي',
        'يبكي',
        'بكت',
        'خائف',
        'خائفه',
        'محبط',
        'خسر',
        'sad',
        'cry',
        'crying',
        'afraid',
        'unhappy',
        'lost',
      ],
    ),
    (
      CharacterMotion.thinking,
      [
        'فكر',
        'يفكر',
        'تفكر',
        'فكرت',
        'تفكير',
        'يتساءل',
        'تساءل',
        'فضول',
        'فضولي',
        'محتار',
        'لماذا',
        'كيف',
        'think',
        'thinking',
        'wonder',
        'curious',
        'why',
        'how',
      ],
    ),
    (
      CharacterMotion.laugh,
      [
        'ضحك',
        'يضحك',
        'ضحكت',
        'ضحكوا',
        'تضحك',
        'نضحك',
        'ضحكه',
        'laugh',
        'laughs',
        'laughed',
        'laughing',
        'giggle',
        'giggled',
      ],
    ),
    (
      CharacterMotion.smile,
      [
        'ابتسم',
        'ابتسمت',
        'ابتسامه',
        'يبتسم',
        'تبتسم',
        'ابتسموا',
        'smile',
        'smiles',
        'smiled',
        'smiling',
      ],
    ),
    (
      CharacterMotion.happy,
      [
        'سعيد',
        'سعيدا',
        'سعيده',
        'سعاده',
        'فرح',
        'فرحان',
        'فرحه',
        'متحمس',
        'happy',
        'excited',
        'joy',
      ],
    ),
    (
      CharacterMotion.wave,
      [
        'مرحبا',
        'اهلا',
        'تحيه',
        'وداعا',
        'لوح',
        'يلوح',
        'لوحت',
        'hello',
        'hi',
        'wave',
        'waved',
        'goodbye',
        'welcome',
      ],
    ),
    (
      CharacterMotion.walk,
      [
        'مشي',
        'يمشي',
        'تمشي',
        'مشت',
        'سار',
        'سارت',
        'سير',
        'يسير',
        'انطلق',
        'ذهب',
        'ذهبت',
        'walk',
        'walked',
        'walking',
        'stroll',
      ],
    ),
  ];
}
