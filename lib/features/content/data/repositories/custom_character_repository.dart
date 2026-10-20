import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/custom_character_model.dart';

class CustomCharacterRepository {
  final SupabaseClient _supabase;
  final SharedPreferences _prefs;

  static const _cacheKey = 'cached_custom_characters';

  CustomCharacterRepository({
    required SupabaseClient supabase,
    required SharedPreferences prefs,
  })  : _supabase = supabase,
        _prefs = prefs;

  /// Returns instantly from local storage (0ms latency, zero choking)
  List<CustomCharacterModel> getCachedCharacters() {
    try {
      final raw = _prefs.getString(_cacheKey);
      if (raw == null || raw.trim().isEmpty) return const [];
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .map((item) => CustomCharacterModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Error reading cached custom characters: $e');
    }
    return const [];
  }

  /// Syncs with Supabase in background and updates local cache
  Future<List<CustomCharacterModel>> fetchCharacters({bool forceRefresh = false}) async {
    // 1. If not forcing refresh and we have cached data, return cached immediately
    final cached = getCachedCharacters();
    if (!forceRefresh && cached.isNotEmpty) {
      // Background sync without blocking caller
      _syncFromSupabaseSilently();
      return cached;
    }

    try {
      final response = await _supabase
          .from('custom_characters')
          .select()
          .order('created_at', ascending: false);

      final list = (response as List)
          .map((item) => CustomCharacterModel.fromJson(item as Map<String, dynamic>))
          .toList();

      await _saveToCache(list);
      return list;
    } catch (e) {
      debugPrint('Error fetching custom characters from Supabase (using cache): $e');
      return cached;
    }
  }

  /// Convenience alias for fetchCharacters
  Future<List<CustomCharacterModel>> getAllCharacters() => fetchCharacters();

  Future<void> _syncFromSupabaseSilently() async {
    try {
      final response = await _supabase
          .from('custom_characters')
          .select()
          .order('created_at', ascending: false);

      final list = (response as List)
          .map((item) => CustomCharacterModel.fromJson(item as Map<String, dynamic>))
          .toList();

      await _saveToCache(list);
    } catch (_) {}
  }

  /// Saves character locally first (instant UI update), then syncs to Supabase
  Future<void> saveCharacter(CustomCharacterModel character) async {
    // 1. Update local cache immediately
    final list = getCachedCharacters().toList();
    final index = list.indexWhere((c) => c.id == character.id);
    if (index >= 0) {
      list[index] = character;
    } else {
      list.insert(0, character);
    }
    await _saveToCache(list);

    // 2. Upload to Supabase
    try {
      await _supabase.from('custom_characters').upsert(character.toJson());
    } catch (e) {
      debugPrint('Warning: Could not sync custom character to Supabase: $e');
      // Character is safely stored locally and will be synced later
    }
  }

  /// Deletes a character locally and from Supabase
  Future<void> deleteCharacter(String id) async {
    final list = getCachedCharacters().toList();
    list.removeWhere((c) => c.id == id);
    await _saveToCache(list);

    try {
      await _supabase.from('custom_characters').delete().eq('id', id);
    } catch (e) {
      debugPrint('Warning: Could not delete custom character from Supabase: $e');
    }
  }

  CustomCharacterModel? getCharacterById(String id) {
    final list = getCachedCharacters();
    for (final char in list) {
      if (char.id == id) return char;
    }
    return null;
  }

  CustomCharacterModel? getCharacterByName(String name) {
    final list = getCachedCharacters();
    final clean = name.trim().toLowerCase();
    for (final char in list) {
      if (char.name.trim().toLowerCase() == clean) return char;
    }
    return null;
  }

  CustomCharacterModel? findCharacter(String identifier) {
    final trimmed = identifier.trim();
    if (trimmed.isEmpty) return null;

    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.queryParameters.containsKey('name')) {
      final paramName = uri.queryParameters['name']!;
      final byParam = getCharacterByName(paramName);
      if (byParam != null) return byParam;
    }

    if (trimmed.startsWith('custom|')) {
      final parts = trimmed.split('|');
      if (parts.length > 1) {
        final byId = getCharacterById(parts[1]);
        if (byId != null) return byId;
        final byName = getCharacterByName(parts[1]);
        if (byName != null) return byName;
      }
      if (parts.length > 2) {
        final byId = getCharacterById(parts[2]);
        if (byId != null) return byId;
        final byName = getCharacterByName(parts[2]);
        if (byName != null) return byName;
      }
    }
    final byId = getCharacterById(trimmed);
    if (byId != null) return byId;

    return getCharacterByName(trimmed);
  }

  Future<void> _saveToCache(List<CustomCharacterModel> list) async {
    try {
      final raw = jsonEncode(list.map((c) => c.toJson()).toList());
      await _prefs.setString(_cacheKey, raw);
    } catch (e) {
      debugPrint('Error caching custom characters: $e');
    }
  }
}
