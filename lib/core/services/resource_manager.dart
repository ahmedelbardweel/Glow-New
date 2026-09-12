import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class ResourceManager {
  final Box cacheBox;
  Directory? _baseDir;

  // In-memory cache of verified local file paths to avoid repeated disk stat syscalls
  final Set<String> _verifiedLocalPaths = <String>{};

  // Coalesce simultaneous download requests for the same URL
  final Map<String, Future<String?>> _inFlightDownloads = <String, Future<String?>>{};

  ResourceManager(this.cacheBox);

  Future<void> init() async {
    if (_baseDir == null) {
      final appDir = await getApplicationDocumentsDirectory();
      _baseDir = Directory('${appDir.path}/offline_resources');
      if (!await _baseDir!.exists()) {
        await _baseDir!.create(recursive: true);
      }
    }
  }

  String _generateFileName(String url, String folder) {
    final cleanHash = url.hashCode.abs().toString();
    final uri = Uri.tryParse(url);
    String ext = '';
    if (uri != null && uri.pathSegments.isNotEmpty) {
      final last = uri.pathSegments.last;
      if (last.contains('.')) {
        ext = '.${last.split('.').last.split('?').first}';
      }
    }
    if (ext.isEmpty) {
      if (folder == 'audio') ext = '.mp3';
      if (folder == 'images') ext = '.png';
    }
    return '${folder}_$cleanHash$ext';
  }

  /// High-speed O(1) path resolver with zero unnecessary disk I/O on UI thread
  String? getLocalFilePath(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    final cachedPath = cacheBox.get(url.trim()) as String?;
    if (cachedPath == null) return null;

    // First check in-memory verified cache
    if (_verifiedLocalPaths.contains(cachedPath)) {
      return cachedPath;
    }

    // Verify on disk once and remember in memory
    if (File(cachedPath).existsSync()) {
      _verifiedLocalPaths.add(cachedPath);
      return cachedPath;
    }
    return null;
  }

  bool isFileCached(String? url) {
    return getLocalFilePath(url) != null;
  }

  /// Download and cache with in-flight deduplication to avoid redundant HTTP requests
  Future<String?> downloadAndCacheFile(String url, {String folder = 'media'}) async {
    final cleanUrl = url.trim();
    if (cleanUrl.isEmpty || !cleanUrl.startsWith('http')) return null;

    // Check if already verified and cached
    final existing = getLocalFilePath(cleanUrl);
    if (existing != null) return existing;

    // If an identical download is already in progress, share the future
    if (_inFlightDownloads.containsKey(cleanUrl)) {
      return _inFlightDownloads[cleanUrl]!;
    }

    final downloadFuture = _executeDownload(cleanUrl, folder);
    _inFlightDownloads[cleanUrl] = downloadFuture;

    try {
      return await downloadFuture;
    } finally {
      _inFlightDownloads.remove(cleanUrl);
    }
  }

  Future<String?> _executeDownload(String cleanUrl, String folder) async {
    try {
      await init();
      final subFolder = Directory('${_baseDir!.path}/$folder');
      if (!await subFolder.exists()) {
        await subFolder.create(recursive: true);
      }

      final fileName = _generateFileName(cleanUrl, folder);
      final file = File('${subFolder.path}/$fileName');

      final response = await http.get(Uri.parse(cleanUrl));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        await cacheBox.put(cleanUrl, file.path);
        _verifiedLocalPaths.add(file.path);
        return file.path;
      }
    } catch (e) {
      // Failed to download or save, continue silently
    }
    return null;
  }
}
