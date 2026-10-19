import 'dart:math' as math;
import 'package:three_js/three_js.dart' as three;
import 'story_motion.dart';

/// Real-time expressive mouth animation for the updated Glow mascot in Dart/three_js.
/// Drives the 4 morph targets on ExpressiveMouth:
/// - MouthOpen
/// - MouthSmile
/// - MouthSad
/// - MouthRound
class CharacterMouthAnimation {
  three.Mesh? _mouth;
  Map<String, int>? _dict;
  double _time = 0;
  double _open = 0;
  double _smile = 0.14;
  double _sad = 0;
  double _round = 0;

  void attach(three.Object3D model) {
    dispose();
    model.traverse((object) {
      if (object is three.Mesh && object.name == 'ExpressiveMouth') {
        _mouth = object;
        final raw = object.morphTargetDictionary;
        if (raw != null) {
          _dict = raw.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
        }
      }
    });
  }

  void update(double dt, CharacterMotion motion, {bool isSpeaking = false}) {
    final mouth = _mouth;
    if (mouth == null) return;
    _time += dt;

    double targetOpen = 0.0;
    double targetSmile = 0.0;
    double targetSad = 0.0;
    double targetRound = 0.0;

    switch (motion) {
      case CharacterMotion.smile:
        targetSmile = 0.85;
        targetOpen = 0.04;
        break;
      case CharacterMotion.happy:
        targetSmile = 0.75;
        targetOpen = 0.16;
        break;
      case CharacterMotion.laugh:
        targetSmile = 0.72;
        targetOpen = 0.38 + 0.36 * math.sin(_time * 8.5);
        break;
      case CharacterMotion.sad:
        targetSad = 0.85;
        targetOpen = 0.0;
        break;
      case CharacterMotion.thinking:
        targetRound = 0.35;
        targetSmile = 0.05;
        targetOpen = 0.06;
        break;
      case CharacterMotion.victory:
        targetSmile = 0.65;
        targetOpen = 0.25;
        break;
      case CharacterMotion.talk:
        targetSmile = 0.22;
        if (!isSpeaking) {
          final u = _time * 3.5;
          targetOpen = 0.12 + 0.32 * math.pow(math.sin(u), 2.0);
        }
        break;
      case CharacterMotion.idle:
      case CharacterMotion.wave:
      case CharacterMotion.walk:
        targetSmile = 0.14;
        targetOpen = 0.0;
        break;
    }

    if (isSpeaking) {
      final u = _time * 4.4;
      final syllable =
          math.pow(math.sin(u), 2.0) * 0.72 + math.pow(math.sin(u * 1.6), 2.0) * 0.28;
      targetOpen = math.max(targetOpen, 0.18 + 0.62 * syllable);
      if (motion != CharacterMotion.sad) {
        targetSmile = math.max(targetSmile, 0.24 + 0.18 * math.sin(u * 0.6));
      }
    }

    final blend = 1.0 - math.exp(-dt * 22.0);
    _open += (targetOpen - _open) * blend;
    _smile += (targetSmile - _smile) * blend;
    _sad += (targetSad - _sad) * blend;
    _round += (targetRound - _round) * blend;

    final inf = mouth.morphTargetInfluences;
    final dict = _dict;
    final openIdx = dict?['MouthOpen'] ?? 0;
    final smileIdx = dict?['MouthSmile'] ?? 1;
    final sadIdx = dict?['MouthSad'] ?? 2;
    final roundIdx = dict?['MouthRound'] ?? 3;

    if (inf.length > openIdx) inf[openIdx] = _open.clamp(0.0, 1.0);
    if (inf.length > smileIdx) inf[smileIdx] = _smile.clamp(0.0, 1.0);
    if (inf.length > sadIdx) inf[sadIdx] = _sad.clamp(0.0, 1.0);
    if (inf.length > roundIdx) inf[roundIdx] = _round.clamp(0.0, 1.0);
  }

  void dispose() {
    _mouth = null;
    _dict = null;
    _open = 0;
    _smile = 0.14;
    _sad = 0;
    _round = 0;
  }
}
