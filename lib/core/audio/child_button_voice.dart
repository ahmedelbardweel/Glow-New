import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'admin_phrase_voice.dart';
import 'story_sentence_voice.dart';

/// Speaks a child button with Julia, then runs the action.
/// The clip is saved on the device so the next tap does not ask again.
class ChildButtonVoice {
  ChildButtonVoice._();

  static final AudioPlayer _player = AudioPlayer()
    ..setReleaseMode(ReleaseMode.stop);

  /// True while a button clip is playing.
  static final speaking = ValueNotifier<bool>(false);

  static var _playId = 0;
  static final _juliaJobs = <String, Future<File?>>{};
  static var _pressSerial = 0;
  static var _contextReady = false;
  static var _playerReady = false;
  static final _durations = <String, Duration>{};

  /// Plays [phrase], then runs [action].
  /// A newer tap replaces the previous one. Speech cannot cancel the action.
  static Future<bool> press(
    String phrase,
    Future<void> Function() action, {
    bool single = false,
  }) async {
    final ticket = ++_pressSerial;
    final id = ++_playId;
    final spoken = _speakOwned(id, phrase.trim());
    await Future.any([
      spoken,
      Future<void>.delayed(const Duration(seconds: 8)),
    ]);
    if (ticket != _pressSerial) return false;
    try {
      await action();
    } catch (_) {}
    return true;
  }

  /// Stops whatever is playing so a closed screen does not keep talking.
  static Future<void> stop() async {
    ++_playId;
    speaking.value = false;
    try {
      await _player.stop();
    } catch (_) {}
  }

  /// Plays each line. A bundled clip is used when it exists. Otherwise the
  /// line is spoken and saved so the child still hears it.
  static Future<void> speakLines(List<String> phrases) async {
    final id = ++_playId;
    final lines = [
      for (final phrase in phrases)
        if (phrase.trim().isNotEmpty) phrase.trim(),
    ];
    if (lines.isEmpty) return;
    speaking.value = true;
    try {
      await _ensureContext();
      for (final phrase in lines) {
        if (id != _playId) return;
        await _speakOwned(id, phrase, maxWait: const Duration(seconds: 12));
        if (id != _playId) return;
        await Future<void>.delayed(const Duration(milliseconds: 280));
      }
    } catch (_) {
    } finally {
      if (id == _playId) speaking.value = false;
    }
  }

  static Future<void> playSequence(List<String> phrases) async {
    final id = ++_playId;
    final lines = [
      for (final phrase in phrases)
        if (phrase.trim().isNotEmpty) phrase.trim(),
    ];
    if (lines.isEmpty) return;
    speaking.value = true;
    try {
      await _ensureContext();
      for (final phrase in lines) {
        if (id != _playId) return;
        await _speakOwned(id, phrase);
        if (id != _playId) return;
        await Future<void>.delayed(const Duration(milliseconds: 320));
      }
    } catch (_) {
    } finally {
      if (id == _playId) speaking.value = false;
    }
  }

  /// Saves Julia clips without playing them, so the splash can finish the
  /// work before the child taps anything.
  static Future<void> prepare(Iterable<String> phrases) async {
    if (kIsWeb) return;
    final pending = <String>[];
    final seen = <String>{};
    for (final raw in phrases) {
      final phrase = raw.trim();
      if (phrase.isEmpty || !seen.add(phrase)) continue;
      pending.add(phrase);
    }
    if (pending.isEmpty) return;
    var next = 0;
    Future<void> worker() async {
      while (true) {
        if (next >= pending.length) return;
        final phrase = pending[next];
        next += 1;
        await _juliaFile(phrase);
      }
    }

    await Future.wait([for (var i = 0; i < 3; i++) worker()]);
  }

  /// Prepares the local player before the first tap so the story audio
  /// is not interrupted by a late audio-session change.
  static Future<void> warm() async {
    await _ensureContext();
  }

  static Future<void> _ensureContext() async {
    if (_playerReady) return;
    try {
      if (!_contextReady) {
        await _player
            .setAudioContext(
              AudioContext(
                android: const AudioContextAndroid(
                  contentType: AndroidContentType.sonification,
                  usageType: AndroidUsageType.assistanceSonification,
                  audioFocus: AndroidAudioFocus.gainTransientMayDuck,
                ),
                iOS: AudioContextIOS(
                  category: AVAudioSessionCategory.playback,
                  options: const {
                    AVAudioSessionOptions.mixWithOthers,
                    AVAudioSessionOptions.duckOthers,
                  },
                ),
              ),
            )
            .timeout(const Duration(milliseconds: 400));
        _contextReady = true;
      }
      await _player.setPlayerMode(PlayerMode.mediaPlayer);
      await _player.setReleaseMode(ReleaseMode.stop);
      _playerReady = true;
    } catch (_) {}
  }

  /// Plays a clip that is already on the device. A missing clip stays silent
  /// so a tap never waits on the network.
  static Future<void> _speakOwned(
    int id,
    String phrase, {
    Duration maxWait = const Duration(seconds: 8),
  }) async {
    if (phrase.isEmpty || id != _playId) return;
    speaking.value = true;
    try {
      final file = await _juliaFile(phrase);
      if (file == null || id != _playId) return;
      await _ensureContext();
      if (id != _playId) return;
      await _playSource(
        DeviceFileSource(file.path),
        id,
        phrase,
        maxWait: maxWait,
      );
    } catch (_) {
    } finally {
      if (id == _playId) speaking.value = false;
    }
  }

  /// Plays [source] and waits for its length. The completion event on this
  /// player often never arrives, which left every button locked.
  static Future<void> _playSource(
    Source source,
    int id,
    String cacheKey, {
    Duration maxWait = const Duration(seconds: 4),
  }) async {
    if (id != _playId) return;
    await _player.play(source).timeout(const Duration(seconds: 8));
    if (id != _playId) return;
    var duration = _durations[cacheKey];
    if (duration == null) {
      try {
        duration = await _player
            .getDuration()
            .timeout(const Duration(milliseconds: 400));
        if (duration != null &&
            duration > Duration.zero &&
            duration <= maxWait) {
          _durations[cacheKey] = duration;
        } else {
          duration = null;
        }
      } catch (_) {}
    }
    var wait = duration == null || duration <= Duration.zero
        ? const Duration(milliseconds: 900)
        : duration;
    if (wait > maxWait) {
      wait = maxWait;
    }
    final end = DateTime.now().add(wait);
    while (id == _playId && DateTime.now().isBefore(end)) {
      final left = end.difference(DateTime.now());
      final step = left < const Duration(milliseconds: 120)
          ? left
          : const Duration(milliseconds: 120);
      if (step <= Duration.zero) break;
      await Future<void>.delayed(step);
    }
  }

  /// Julia clip saved on the device. Old bundled clips and old cached phrases
  /// are never played.
  static Future<File?> _juliaFile(String phrase) async {
    if (kIsWeb) return null;
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/julia_voice');
    if (!folder.existsSync()) folder.createSync(recursive: true);
    final file = File('${folder.path}/${AdminPhraseVoice.fileId(phrase)}.wav');
    if (file.existsSync() && file.lengthSync() > 256) return file;
    final pending = _juliaJobs[phrase];
    if (pending != null) return pending;
    final job = _renderJulia(phrase, file);
    _juliaJobs[phrase] = job;
    try {
      return await job;
    } finally {
      _juliaJobs.remove(phrase);
    }
  }

  static Future<File?> _renderJulia(String phrase, File file) async {
    try {
      final clip = await StorySentenceVoice.speakNarrator(phrase);
      await clip.file.copy(file.path);
      return file;
    } catch (_) {
      if (file.existsSync()) file.deleteSync();
      return null;
    }
  }
}
