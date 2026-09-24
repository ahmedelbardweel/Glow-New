import 'package:flutter/services.dart';

import '../utils/character_helper.dart';

/// Only immutable file bytes are shared. Each viewer owns its GPU resources,
/// materials and skeleton so closing one route cannot invalidate another.
class CharacterAssetCache {
  CharacterAssetCache({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static final instance = CharacterAssetCache();
  final AssetBundle _bundle;
  final _assets = <String, Future<Uint8List>>{};

  Future<Uint8List> load(String path) {
    final cached = _assets[path];
    if (cached != null) return cached;
    final pending = _read(path);
    _assets[path] = pending;
    return pending;
  }

  Future<Uint8List> _read(String path) async {
    try {
      final data = await Future<ByteData>.sync(() => _bundle.load(path));
      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    } catch (_) {
      _assets.remove(path); // A transient failure must not poison later visits.
      rethrow;
    }
  }

  Future<void> prewarm() async {
    try {
      await load(CharacterHelper.sharedModelPath);
    } catch (_) {
      // The visible viewer owns error reporting and can retry the asset load.
    }
  }
}
