import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Public file upload. The screen passes a file and gets a URL back.
abstract class MediaStore {
  Future<String> uploadPublic({
    required String bucket,
    required String path,
    required File file,
    required String contentType,
    bool upsert = false,
  });

  String publicUrl({required String bucket, required String path});
}

class SupabaseMediaStore implements MediaStore {
  SupabaseMediaStore(this._client);

  final SupabaseClient _client;

  @override
  Future<String> uploadPublic({
    required String bucket,
    required String path,
    required File file,
    required String contentType,
    bool upsert = false,
  }) async {
    await _client.storage.from(bucket).upload(
          path,
          file,
          fileOptions: FileOptions(contentType: contentType, upsert: upsert),
        );
    return publicUrl(bucket: bucket, path: path);
  }

  @override
  String publicUrl({required String bucket, required String path}) {
    return _client.storage.from(bucket).getPublicUrl(path);
  }
}
