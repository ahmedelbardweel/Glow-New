import 'dart:math' as math;
import 'package:three_js/three_js.dart' as three;
import 'mouth_expression.dart';
import 'story_motion.dart';

/// Keeps the jaw, lips and internal mouth parts on one expression clock.
class CharacterMouthAnimation {
  static const _targets = ['MouthOpen', 'MouthSmile', 'MouthSad', 'MouthRound'];
  final _meshes = <three.Mesh>[];
  final _current = <double>[0, .12, 0, 0];
  double _time = 0;
  double? _lastClock;
  void attach(three.Object3D model) {
    dispose();
    model.traverse((object) {
      if (object is three.Mesh &&
          object.morphTargetDictionary?.containsKey('MouthOpen') == true) {
        _meshes.add(object);
      }
    });
  }

  void update(
    double dt,
    CharacterMotion motion, {
    bool isSpeaking = false,
    double? clockTime,
    double? clipTime,
  }) {
    if (_meshes.isEmpty) return;
    final step = dt.isFinite ? dt.clamp(0.0, .08) : 0.0;
    final clock = clockTime != null && clockTime.isFinite
        ? clockTime
        : _time + step;
    final seek = _lastClock != null && (clock - _lastClock! - step).abs() > .20;
    _time = clock;
    _lastClock = clock;
    final target = sampleMouthExpression(
      clock,
      motion,
      speaking: isSpeaking,
      motionTime: clipTime,
    );
    for (var i = 0; i < 4; i++) {
      final rate = i == 0
          ? (target[i] < _current[i] ? 38 : 28)
          : (i == 3 ? 24 : 10);
      final blend = seek || step == 0 ? 1.0 : 1 - math.exp(-step * rate);
      _current[i] += (target[i] - _current[i]) * blend;
    }
    for (final mesh in _meshes) {
      for (var i = 0; i < 4; i++) {
        final index = mesh.morphTargetDictionary?[_targets[i]];
        if (index != null) {
          mesh.morphTargetInfluences[(index as num).toInt()] = _current[i];
        }
      }
    }
  }

  void dispose() {
    _meshes.clear();
    _current.setAll(0, [0, .12, 0, 0]);
    _time = 0;
    _lastClock = null;
  }
}
