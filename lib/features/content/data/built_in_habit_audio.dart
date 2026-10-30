/// Audio bundled with the first release.
///
/// The five launch habits must work on a brand-new device without a network
/// connection. Later habits continue to use their Supabase URL after the
/// sync service has downloaded it into the offline cache.
class BuiltInHabitAudio {
  BuiltInHabitAudio._();

  static const _assetsByStoryId = <String, String>{
    'a1000000-0000-4000-8000-000000000021': 'voice/habits/habit_1.wav',
    'a1000000-0000-4000-8000-000000000022': 'voice/habits/habit_2.wav',
    'a1000000-0000-4000-8000-000000000023': 'voice/habits/habit_3.wav',
    'a1000000-0000-4000-8000-000000000024': 'voice/habits/habit_4.wav',
    'a1000000-0000-4000-8000-000000000025': 'voice/habits/habit_5.wav',
  };

  static String? assetFor(String storyId) => _assetsByStoryId[storyId];

  /// A newly uploaded recording must take precedence over the launch audio.
  static String? assetForSource(String storyId, String? audioUrl) {
    final url = audioUrl?.trim() ?? '';
    if (url.isNotEmpty && !RegExp(r'/habit_[1-5]_voice_').hasMatch(url)) return null;
    return assetFor(storyId);
  }
}
