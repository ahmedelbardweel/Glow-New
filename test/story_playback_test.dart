import 'dart:async';

import 'package:Glow/core/widgets/smart_character_viewer.dart';
import 'package:Glow/features/content/domain/entities/story_entity.dart';
import 'package:Glow/features/content/presentation/screens/story_preview_screen.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _story = StoryEntity(
  id: 'story-one',
  missionId: 'mission',
  title: 'A happy story',
  characterName: 'سعيد',
  content: 'The character is happy and waves hello.',
  imageUrl: '',
  orderIndex: 0,
  audioUrl: 'https://example.com/story-one.mp3',
);

const _nextStory = StoryEntity(
  id: 'story-two',
  missionId: 'mission',
  title: 'A curious story',
  characterName: 'فضولي',
  content: 'The character discovers something new.',
  imageUrl: '',
  orderIndex: 1,
  audioUrl: 'https://example.com/story-two.mp3',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _AudioHarness audio;

  setUpAll(() async {
    audio = _AudioHarness()..install();
    await AudioPlayer.global.ensureInitialized();
  });

  setUp(() {
    audio.calls.clear();
    audio.playerIds.clear();
    audio.positionMs = 0;
    audio.pendingSource = null;
    audio.delayNextSource = null;
  });

  tearDownAll(() => audio.uninstall());

  testWidgets('preview resumes the same audio and shares its playback clock', (
    tester,
  ) async {
    await tester.pumpWidget(_preview(_story));
    await _flush(tester);
    expect(_viewer(tester).storyText, '${_story.title}\n${_story.content}');
    expect(_viewer(tester).isSpeaking, isFalse);

    await tester.tap(find.byIcon(Icons.play_arrow));
    await _flush(tester);
    expect(audio.count('setSourceUrl'), 1);
    expect(_viewer(tester).isPlaying, isTrue);
    expect(_viewer(tester).isSpeaking, isTrue);

    audio.positionMs = 2400;
    await _flush(tester);
    expect(
      _viewer(tester).playbackPosition!.value,
      const Duration(milliseconds: 2400),
    );
    await tester.tap(find.byIcon(Icons.pause));
    await _flush(tester);
    expect(_viewer(tester).isPlaying, isFalse);
    expect(_viewer(tester).isSpeaking, isFalse);

    await tester.tap(find.byIcon(Icons.play_arrow));
    await _flush(tester);
    expect(audio.count('setSourceUrl'), 1);
    expect(audio.count('resume'), 2);
    expect(audio.count('seek'), 0);
    expect(_viewer(tester).isSpeaking, isTrue);

    await tester.pumpWidget(const SizedBox());
    await _flush(tester);
    expect(
      audio.count('dispose'),
      1,
      reason: audio.calls.map((call) => call.method).join(', '),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'lifecycle keeps user pause and completed audio replays from zero',
    (tester) async {
      await tester.pumpWidget(_preview(_story));
      await tester.tap(find.byIcon(Icons.play_arrow));
      await _flush(tester);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await _flush(tester);
      expect(_viewer(tester).isSpeaking, isFalse);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await _flush(tester);
      expect(_viewer(tester).isSpeaking, isTrue);

      await tester.tap(find.byIcon(Icons.pause));
      await _flush(tester);
      final resumesBeforeBackground = audio.count('resume');
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await _flush(tester);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await _flush(tester);
      expect(audio.count('resume'), resumesBeforeBackground);
      expect(_viewer(tester).isPlaying, isFalse);

      await tester.tap(find.byIcon(Icons.play_arrow));
      await _flush(tester);
      audio.positionMs = 8000;
      await audio.emit(audio.playerIds.single, 'audio.onComplete');
      await _flush(tester);
      expect(_viewer(tester).isSpeaking, isFalse);

      await tester.tap(find.byIcon(Icons.play_arrow));
      await _flush(tester);
      expect(audio.count('setSourceUrl'), 1);
      expect(audio.count('seek'), 1);
      expect(_viewer(tester).playbackPosition!.value, Duration.zero);
      expect(_viewer(tester).isSpeaking, isTrue);

      await tester.pumpWidget(const SizedBox());
      await _flush(tester);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('a delayed old source cannot start after the preview changes', (
    tester,
  ) async {
    audio.delayNextSource = Completer<void>();
    await tester.pumpWidget(_preview(_story));
    await tester.tap(find.byIcon(Icons.play_arrow));
    await _flush(tester);
    final oldPlayerId = audio.playerIds.single;

    await tester.pumpWidget(_preview(_nextStory));
    await _flush(tester);
    expect(
      _viewer(tester).storyText,
      '${_nextStory.title}\n${_nextStory.content}',
    );
    audio.pendingSource!.complete();
    await _flush(tester);
    expect(audio.count('resume', playerId: oldPlayerId), 0);

    await tester.tap(find.byIcon(Icons.play_arrow));
    await _flush(tester);
    expect(audio.playerIds, hasLength(2));
    expect(audio.count('resume', playerId: audio.playerIds.last), 1);
    expect(_viewer(tester).isSpeaking, isTrue);

    await tester.pumpWidget(const SizedBox());
    await _flush(tester);
    expect(audio.count('dispose'), 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a native audio error stops speech and allows a clean retry', (
    tester,
  ) async {
    await tester.pumpWidget(_preview(_story));
    await tester.tap(find.byIcon(Icons.play_arrow));
    await _flush(tester);
    await audio.emitError(audio.playerIds.single);
    await _flush(tester);
    expect(_viewer(tester).isSpeaking, isFalse);
    expect(find.text('تعذّر تشغيل الصوت. حاول مرة أخرى.'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.play_arrow));
    await _flush(tester);
    expect(audio.playerIds, hasLength(2));
    expect(_viewer(tester).isSpeaking, isTrue);

    await tester.pumpWidget(const SizedBox());
    await _flush(tester);
    expect(audio.count('dispose'), 2);
    expect(tester.takeException(), isNull);
  });
}

Widget _preview(StoryEntity story) => MaterialApp(
  theme: ThemeData(splashFactory: NoSplash.splashFactory),
  home: StoryPreviewScreen(story: story),
);

SmartCharacterViewer _viewer(WidgetTester tester) =>
    tester.widget<SmartCharacterViewer>(find.byType(SmartCharacterViewer));

Future<void> _flush(WidgetTester tester) async {
  for (var frame = 0; frame < 5; frame++) {
    // Native event-channel cancellation and the global audio singleton can
    // complete outside the test clock. Flush that queue as well as frames.
    await tester.runAsync(() async {
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Simulates the native audio boundary; the real AudioPlayer and screen run.
class _AudioHarness {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final calls = <MethodCall>[];
  final playerIds = <String>[];
  final _eventChannels = <MethodChannel>[];
  int positionMs = 0;
  Completer<void>? delayNextSource;
  Completer<void>? pendingSource;

  static const _playerChannel = MethodChannel('xyz.luan/audioplayers');
  static const _globalChannel = MethodChannel('xyz.luan/audioplayers.global');
  static const _globalEvents = MethodChannel(
    'xyz.luan/audioplayers.global/events',
  );

  void install() {
    messenger.setMockMethodCallHandler(_globalChannel, (_) async => null);
    messenger.setMockMethodCallHandler(_globalEvents, (_) async => null);
    messenger.setMockMethodCallHandler(_playerChannel, (call) async {
      calls.add(call);
      final args = call.arguments as Map<dynamic, dynamic>;
      final playerId = args['playerId'] as String;
      switch (call.method) {
        case 'create':
          playerIds.add(playerId);
          final events = MethodChannel(
            'xyz.luan/audioplayers/events/$playerId',
          );
          _eventChannels.add(events);
          messenger.setMockMethodCallHandler(events, (_) async => null);
        case 'setSourceUrl':
          pendingSource = delayNextSource;
          delayNextSource = null;
          if (pendingSource != null) await pendingSource!.future;
          await emit(playerId, 'audio.onPrepared', true);
        case 'seek':
          positionMs = args['position'] as int;
          await emit(playerId, 'audio.onSeekComplete');
        case 'getCurrentPosition':
          return positionMs;
        case 'getDuration':
          return 10000;
      }
      return null;
    });
  }

  int count(String method, {String? playerId}) => calls.where((call) {
    return call.method == method &&
        (playerId == null || call.arguments['playerId'] == playerId);
  }).length;

  Future<void> emit(String playerId, String event, [Object? value]) =>
      messenger.handlePlatformMessage(
        'xyz.luan/audioplayers/events/$playerId',
        const StandardMethodCodec().encodeSuccessEnvelope({
          'event': event,
          'value': value,
        }),
        (_) {},
      );

  Future<void> emitError(String playerId) => messenger.handlePlatformMessage(
    'xyz.luan/audioplayers/events/$playerId',
    const StandardMethodCodec().encodeErrorEnvelope(
      code: 'audio_error',
      message: 'Test playback failure',
    ),
    (_) {},
  );

  void uninstall() {
    messenger.setMockMethodCallHandler(_playerChannel, null);
    messenger.setMockMethodCallHandler(_globalChannel, null);
    messenger.setMockMethodCallHandler(_globalEvents, null);
    for (final channel in _eventChannels) {
      messenger.setMockMethodCallHandler(channel, null);
    }
  }
}
