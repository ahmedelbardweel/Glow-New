import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/custom_character_model.dart';

class CustomCharacterRepository {
  final SupabaseClient _supabase;
  final SharedPreferences _prefs;

  static const _cacheKey = 'cached_custom_characters';

  List<CustomCharacterModel>? _memoryCache;

  CustomCharacterRepository({
    required SupabaseClient supabase,
    required SharedPreferences prefs,
  })  : _supabase = supabase,
        _prefs = prefs;

  /// Returns instantly from in-memory cache or local storage (0ms latency, zero choking)
  List<CustomCharacterModel> getCachedCharacters() {
    if (_memoryCache != null) return _memoryCache!;
    try {
      final raw = _prefs.getString(_cacheKey);
      if (raw == null || raw.trim().isEmpty) {
        _memoryCache = const [];
        return const [];
      }
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        _memoryCache = List.unmodifiable(
          decoded
              .map((item) => CustomCharacterModel.fromJson(item as Map<String, dynamic>))
              .toList(),
        );
        return _memoryCache!;
      }
    } catch (e) {
      debugPrint('Error reading cached custom characters: $e');
    }
    _memoryCache = const [];
    return const [];
  }

  /// Syncs with Supabase in background and updates local cache
  Future<List<CustomCharacterModel>> fetchCharacters({bool forceRefresh = false}) async {
    final cached = getCachedCharacters();
    if (!forceRefresh && cached.isNotEmpty) {
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
    final list = getCachedCharacters().toList();
    final index = list.indexWhere((c) => c.id == character.id);
    if (index >= 0) {
      list[index] = character;
    } else {
      list.insert(0, character);
    }
    await _saveToCache(list);

    try {
      await _supabase.from('custom_characters').upsert(character.toJson());
    } catch (e) {
      debugPrint('Warning: Could not sync custom character to Supabase: $e');
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
        final second = parts[1].trim();
        // If parts[1] is a live hex color preview (e.g. custom|#FF0000|name),
        // do not override live preview settings with a saved character by name.
        if (second.startsWith('#')) {
          return null;
        }
        final byId = getCharacterById(second);
        if (byId != null) return byId;
        final byName = getCharacterByName(second);
        if (byName != null) return byName;
      }
      if (parts.length > 2) {
        final byId = getCharacterById(parts[2]);
        if (byId != null) return byId;
        final byName = getCharacterByName(parts[2]);
        if (byName != null) return byName;
      }
      return null;
    }
    final byId = getCharacterById(trimmed);
    if (byId != null) return byId;

    return getCharacterByName(trimmed);
  }

  Future<void> _saveToCache(List<CustomCharacterModel> list) async {
    _memoryCache = List.unmodifiable(list);
    try {
      final raw = jsonEncode(list.map((c) => c.toJson()).toList());
      await _prefs.setString(_cacheKey, raw);
    } catch (e) {
      debugPrint('Error caching custom characters: $e');
    }
  }
}
