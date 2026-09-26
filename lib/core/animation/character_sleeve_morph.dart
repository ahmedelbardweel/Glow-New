import 'dart:math' as math;
import 'package:three_js/three_js.dart' as three;

/// Rounds each arm's inner side into a full sleeve as the arm lifts.
///
/// The mascot's arms are merged into the torso between armpit and hand, so a
/// raised arm would otherwise show a thin wedge. The GLB carries one morph per
/// arm; its influence follows the upper arm's rotation away from rest, so the
/// rest pose is untouched and every clip or crossfade stays in sync.
class CharacterSleeveMorph {
  final _meshes = <three.Mesh>[];
  final _arms = <String, three.Object3D>{};

  void attach(three.Object3D model) {
    dispose();
    model.traverse((object) {
      if (object is three.Mesh &&
          object.morphTargetDictionary?.containsKey('ArmOpenLeft') == true) {
        _meshes.add(object);
      }
    });
    for (final name in ['LeftUpperArm', 'RightUpperArm']) {
      final bone = model.getObjectByName(name);
      if (bone != null) _arms[name] = bone;
    }
  }

  static double _influence(three.Object3D? bone) {
    if (bone == null) return 0;
    final w = bone.quaternion.w.abs().clamp(0.0, 1.0).toDouble();
    final t = ((2 * math.acos(w) - .35) / 1.4).clamp(0.0, 1.0);
    return t * t * (3 - 2 * t);
  }

  void update() {
    if (_meshes.isEmpty) return;
    final left = _influence(_arms['LeftUpperArm']);
    final right = _influence(_arms['RightUpperArm']);
    for (final mesh in _meshes) {
      final names = mesh.morphTargetDictionary!;
      mesh.morphTargetInfluences[names['ArmOpenLeft']!] = left;
      mesh.morphTargetInfluences[names['ArmOpenRight']!] = right;
    }
  }

  void dispose() {
    _meshes.clear();
    _arms.clear();
  }
}
