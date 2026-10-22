import 'dart:math' as math;
import 'story_motion.dart';

/// Stylized preview cadence with complete closures and phrase rests.
/// This samples playback time; it does not infer phonemes from audio.
List<double> sampleMouthExpression(
  double time,
  CharacterMotion motion, {
  bool speaking = false,
}) {
  var open = 0.0, smile = .12, sad = 0.0, round = 0.0;
  switch (motion) {
    case CharacterMotion.smile:
      smile = .95;
      open = .12;
    case CharacterMotion.happy:
      smile = .80;
      open = .22;
    case CharacterMotion.laugh:
      smile = .80;
      open =
          .12 + .65 * math.pow(math.max(0, math.sin(time * math.pi * 6)), 1.2);
    case CharacterMotion.sad:
      smile = 0;
      sad = .95;
    case CharacterMotion.thinking:
      smile = 0;
      round = .16;
    case CharacterMotion.victory:
      smile = .80;
      open = .16;
    case CharacterMotion.wave:
      smile = .50;
      open = .04;
    case CharacterMotion.talk:
      smile = .16;
    case CharacterMotion.idle:
    case CharacterMotion.walk:
      break;
  }
  if (speaking || motion == CharacterMotion.talk) {
    const syllables = [
      [.06, .19, .70, .05],
      [.31, .14, .46, .10],
      [.52, .23, .83, .65],
      [.84, .17, .52, .15],
      [1.09, .26, .76, .48],
      [1.47, .15, .45, .05],
      [1.71, .21, .68, .72],
      [2.02, .18, .54, .12],
    ];
    final t = time % 2.8;
    open = 0;
    round = 0;
    for (final syllable in syllables) {
      final u = (t - syllable[0]) / syllable[1];
      if (u > 0 && u < 1) {
        final pulse = math.pow(math.sin(math.pi * u), 1.35);
        open = syllable[2] * pulse;
        round = syllable[3] * pulse;
      }
    }
    open *= 1 - .35 * round;
    smile *= 1 - .65 * round;
    sad *= .75;
  }
  return [open, smile, sad, round];
}
