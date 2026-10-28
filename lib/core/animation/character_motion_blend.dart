import 'package:three_js/three_js.dart' as three;

/// A normalized, interruptible blend. A new selection starts from the visible
/// mixture, rather than resetting outgoing actions to full strength.
class CharacterMotionBlend {
  final _weights = <three.AnimationAction, double>{};
  final _start = <three.AnimationAction, double>{};
  three.AnimationAction? active;
  double _elapsed = 0;
  static const duration = .7;

  void select(three.AnimationAction next, {bool immediate = false}) {
    if (identical(next, active)) return;
    if (!_weights.containsKey(next)) next.reset().setEffectiveWeight(0).play();
    _start
      ..clear()
      ..addAll(_weights);
    _weights.putIfAbsent(next, () => 0);
    active = next;
    _elapsed = 0;
    if (immediate || _start.isEmpty) update(duration);
  }

  void update(double dt) {
    if (active == null) return;
    _elapsed = (_elapsed + dt).clamp(0, duration);
    final u = _elapsed / duration;
    final ease = u * u * u * (10 + u * (-15 + 6 * u));
    for (final action in _weights.keys.toList()) {
      final weight =
          (_start[action] ?? 0) * (1 - ease) +
          (identical(action, active) ? ease : 0);
      action.setEffectiveWeight(weight);
      _weights[action] = weight;
      if (u == 1 && !identical(action, active)) {
        action.stop();
        _weights.remove(action);
      }
    }
  }

  void clear() {
    for (final action in _weights.keys) {
      action.stop();
    }
    _weights.clear();
    _start.clear();
    active = null;
  }
}
