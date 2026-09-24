import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:Glow/core/services/character_asset_cache.dart';

class _Bundle extends CachingAssetBundle {
  int reads = 0;
  bool fail = false;
  final bytes = Uint8List.fromList([0, 1, 2, 3, 4]);

  @override
  Future<ByteData> load(String key) async {
    reads++;
    if (fail) throw StateError('Temporary read failure');
    return ByteData.view(bytes.buffer, 1, 3);
  }
}

void main() {
  test(
    'coalesces concurrent asset reads and respects byte view offsets',
    () async {
      final bundle = _Bundle();
      final cache = CharacterAssetCache(bundle: bundle);
      final reads = await Future.wait([
        cache.load('mascot'),
        cache.load('mascot'),
      ]);
      expect(bundle.reads, 1);
      expect(reads.first, [1, 2, 3]);
      expect(identical(reads.first, reads.last), isTrue);
      await cache.load('mascot');
      expect(bundle.reads, 1);
    },
  );

  test('a failed read does not prevent the next route from loading', () async {
    final bundle = _Bundle()..fail = true;
    final cache = CharacterAssetCache(bundle: bundle);
    await expectLater(cache.load('mascot'), throwsStateError);
    bundle.fail = false;
    expect(await cache.load('mascot'), [1, 2, 3]);
    expect(bundle.reads, 2);
  });

  test('prewarm failure does not abort app startup', () async {
    final bundle = _Bundle()..fail = true;
    await CharacterAssetCache(bundle: bundle).prewarm();
    expect(bundle.reads, 1);
  });
}
