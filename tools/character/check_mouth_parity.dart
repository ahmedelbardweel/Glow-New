import 'dart:convert';
import 'dart:io';
import '../../lib/core/animation/mouth_expression.dart';
import '../../lib/core/animation/story_motion.dart';

void main(List<String> args) {
  final samples = jsonDecode(File(args.single).readAsStringSync()) as List;
  var error = 0.0;
  for (final sample in samples) {
    final motion = CharacterMotion.values.firstWhere((m) => m.clipName == sample['motion']);
    final actual = sampleMouthExpression((sample['time'] as num).toDouble(), motion, speaking: sample['speaking']);
    for (var i = 0; i < 4; i++) {
      final difference = (actual[i] - (sample['pose'][i] as num)).abs();
      if (difference > error) error = difference;
      if (difference > 1e-10) throw StateError('JS/Dart mouth divergence: $sample');
    }
  }
  stdout.writeln(jsonEncode({'matchingSamples': samples.length, 'maxError': error}));
}
