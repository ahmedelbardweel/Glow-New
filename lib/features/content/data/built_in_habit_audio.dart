import 'bundled_habit_audio.g.dart';

/// Audio bundled inside the APK.
///
/// Bundled habits must work on a brand-new device without a network
/// connection. Other habits keep their Supabase URL and play from the offline
/// cache after the sync service downloads them.
class BuiltInHabitAudio {
  BuiltInHabitAudio._();

  static const _assetsByStoryId = <String, String>{
    'a1000000-0000-4000-8000-000000000021': 'voice/habits/habit_1.wav',
    'a1000000-0000-4000-8000-000000000022': 'voice/habits/habit_2.wav',
    'a1000000-0000-4000-8000-000000000023': 'voice/habits/habit_3.wav',
    'a1000000-0000-4000-8000-000000000024': 'voice/habits/habit_4.wav',
    'a1000000-0000-4000-8000-000000000025': 'voice/habits/habit_5.wav',
    ...bundledHabitAudio,
  };

  static String? assetFor(String storyId) => _assetsByStoryId[storyId];

  /// A newly uploaded recording must take precedence over the bundled audio.
  static String? assetForSource(String storyId, String? audioUrl) {
    final url = audioUrl?.trim() ?? '';
    if (url.isNotEmpty && !RegExp(r'/habit_[1-5]_voice_').hasMatch(url)) return null;
    return assetFor(storyId);
  }
}
