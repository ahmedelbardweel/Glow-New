import 'dart:io';

import 'package:audioplayers/audioplayers.dart';

import '../di/injection_container.dart';
import '../storage/media_store.dart';
import 'story_sentence_voice.dart';

/// One soft child voice for admin text fields, stored so the child can hear it.
class AdminPhraseVoice {
  AdminPhraseVoice._();

  static const _bucket = 'story_audio';

  /// 64-bit FNV-1a in two 32-bit halves so web (JS numbers) and native agree.
  /// The output keeps the native signed-int hex format of stored file names.
  static String fileId(String text) {
    const word = 0x100000000;
    var hi = 0xcbf29ce4;
    var lo = 0x84222325;
    for (final unit in text.trim().codeUnits) {
      lo ^= unit;
      final low = lo * 0x1b3;
      final carry = low ~/ word;
      hi = (hi * 0x1b3 + carry + lo * 0x100) % word;
      lo = low % word;
    }
    var sign = '';
    if (hi >= 0x80000000) {
      sign = '-';
      final borrow = lo == 0 ? 1 : 0;
      lo = (word - lo) % word;
      hi = (word - 1 - hi + borrow) % word;
    }
    final digits = hi == 0
        ? lo.toRadixString(16)
        : hi.toRadixString(16) + lo.toRadixString(16).padLeft(8, '0');
    return '$sign$digits'.padLeft(16, '0');
  }

  static String urlFor(String text) {
    final id = fileId(text);
    return sl<MediaStore>().publicUrl(
      bucket: _bucket,
      path: 'phrase_$id.wav',
    );
  }

  static Future<File> speak(String text) async {
    final clip = await StorySentenceVoice.speakNarrator(text.trim());
    final id = fileId(text);
    try {
      await sl<MediaStore>().uploadPublic(
        bucket: _bucket,
        path: 'phrase_$id.wav',
        file: clip.file,
        contentType: 'audio/wav',
        upsert: true,
      );
    } catch (_) {}
    return clip.file;
  }

  static Future<void> play(File file) async {
    final player = AudioPlayer();
    try {
      await player.setPlayerMode(PlayerMode.mediaPlayer);
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setVolume(1);
      final done = player.onPlayerComplete.first;
      await player.play(DeviceFileSource(file.path));
      await done.timeout(const Duration(seconds: 30));
    } catch (_) {
    } finally {
      await player.dispose();
    }
  }
}
