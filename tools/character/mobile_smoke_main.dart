// Device smoke test independent of flutter_test (uses the real platform view).
// flutter run -d <device> -t tools/character/mobile_smoke_main.dart
//   --dart-define=GLOW_CHARACTER_DIAGNOSTICS=true
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:Glow/core/animation/story_motion.dart';
import 'package:Glow/core/services/character_asset_cache.dart';
import 'package:Glow/core/widgets/smart_character_viewer.dart';

class _NoNetwork extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      throw StateError('Network is forbidden in the character smoke test');
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _NoNetwork();
  unawaited(CharacterAssetCache.instance.prewarm());
  runApp(const MaterialApp(home: _Check()));
}

class _Check extends StatefulWidget {
  const _Check();
  @override
  State<_Check> createState() => _CheckState();
}

class _CheckState extends State<_Check> {
  Timer? timer;
  int step = 0;
  bool testing = false;
  final position = ValueNotifier(Duration.zero);
  static const colors = ['port', 'fort', 'lort', 'mort', 'qort'];

  @override
  void initState() {
    super.initState();
    timer = Timer(const Duration(seconds: 20), run);
  }

  void run() {
    if (testing) return;
    setState(() => testing = true);
    timer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!mounted) return;
      setState(() => step++);
      position.value = Duration(seconds: step * 2);
      debugPrint(
        'MOBILE_CHECK step=$step motion=${CharacterMotion.values[step % 10].clipName}',
      );
      if (step == 12) {
        timer.cancel();
        final navigator = Navigator.of(context);
        this.timer = Timer(const Duration(seconds: 10), () {
          if (mounted && navigator.canPop()) navigator.pop();
        });
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) => Scaffold(
              appBar: AppBar(title: const Text('Second 3D route')),
              body: const SmartCharacterViewer(
                characterName: 'port',
                motion: CharacterMotion.laugh,
              ),
            ),
          ),
        );
        if (mounted) setState(() { testing = false; step = 0; });
        debugPrint('MOBILE_CHECK returned to original route');
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Glow offline device check')),
    body: Column(
      children: [
        Text(
          'Step $step • ${colors[step % 5]} • ${CharacterMotion.values[step % 10].clipName}',
        ),
        SizedBox(
          height: step.isEven ? 400 : 300,
          child: SmartCharacterViewer(
            characterName: colors[step % 5],
            motion: CharacterMotion.values[step % 10],
            isPlaying: true,
            isSpeaking: step % 3 == 1,
            playbackPosition: position,
            showSkeleton: step == 10,
          ),
        ),
        FilledButton(
          onPressed: run,
          child: const Text('Run motions, palette, resize and navigation'),
        ),
        FilledButton(
          onPressed: () => setState(() => step = 0),
          child: const Text('Original character'),
        ),
      ],
    ),
  );

  @override
  void dispose() {
    timer?.cancel();
    position.dispose();
    super.dispose();
  }
}
