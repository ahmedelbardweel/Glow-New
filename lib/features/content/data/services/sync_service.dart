import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/resource_manager.dart';
import '../datasources/content_local_data_source.dart';
import '../datasources/content_remote_data_source.dart';
import '../models/story_model.dart';
import '../models/question_model.dart';

enum SyncStatus { idle, syncing, success, offline, error }

class SyncStatusState {
  final SyncStatus status;
  final String message;
  final int pendingCount;

  const SyncStatusState({
    required this.status,
    required this.message,
    this.pendingCount = 0,
  });

  bool get isSyncing => status == SyncStatus.syncing;
  bool get isOffline => status == SyncStatus.offline;
}

class SyncService {
  final ContentRemoteDataSource remoteDataSource;
  final ContentLocalDataSource localDataSource;
  final ResourceManager resourceManager;
  final NetworkInfo networkInfo;
  final InternetConnectionChecker connectionChecker;

  final ValueNotifier<SyncStatusState> syncState = ValueNotifier<SyncStatusState>(
    const SyncStatusState(status: SyncStatus.idle, message: 'جاهز'),
  );

  StreamSubscription<InternetConnectionStatus>? _networkSubscription;
  bool _isSyncRunning = false;

  SyncService({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.resourceManager,
    required this.networkInfo,
    required this.connectionChecker,
  });

  void startAutoSyncListener({String? childId}) {
    _networkSubscription?.cancel();
    _networkSubscription = connectionChecker.onStatusChange.listen((status) {
      if (status == InternetConnectionStatus.connected) {
        syncAll(childId: childId, silent: true);
      } else {
        syncState.value = const SyncStatusState(
          status: SyncStatus.offline,
          message: 'وضع عدم الاتصال (أوفلاين) - الموارد متاحة محلياً',
        );
      }
    });
  }

  void stopAutoSyncListener() {
    _networkSubscription?.cancel();
    _networkSubscription = null;
  }

  DateTime? _lastSyncTime;

  Future<void> syncAll({String? childId, bool silent = false}) async {
    if (_isSyncRunning) return;

    // Throttle silent background syncs if synced recently (within 30 seconds)
    if (silent && _lastSyncTime != null && DateTime.now().difference(_lastSyncTime!).inSeconds < 30) {
      return;
    }

    _isSyncRunning = true;

    final isConnected = await networkInfo.isConnected;
    if (!isConnected) {
      syncState.value = const SyncStatusState(
        status: SyncStatus.offline,
        message: 'وضع عدم الاتصال (أوفلاين) - الموارد متاحة محلياً',
      );
      _isSyncRunning = false;
      return;
    }

    if (!silent) {
      syncState.value = const SyncStatusState(
        status: SyncStatus.syncing,
        message: 'جارٍ تنزيل وتحديث المغامرات والموارد...',
      );
    }

    try {
      // 1. Upload Pending Offline Completions
      final pending = await localDataSource.getPendingCompletions();
      for (var item in pending) {
        final cId = item['child_id'];
        final mId = item['mission_id'];
        if (cId != null && mId != null) {
          try {
            await remoteDataSource.completeMission(mId, cId);
            await localDataSource.removePendingCompletion(cId, mId);
          } catch (e) {
            syncState.value = SyncStatusState(
              status: SyncStatus.error,
              message: 'تعذر رفع الإنجازات لسوبابيز. تأكد من إعدادات الأمان (RLS):\n$e',
            );
            _isSyncRunning = false;
            return;
          }
        }
      }

      // 2. Sync Worlds and collect media tasks
      final remoteWorlds = await remoteDataSource.getWorlds();
      await localDataSource.cacheWorlds(remoteWorlds);
      
      final List<Future> mediaTasks = [];
      for (var world in remoteWorlds) {
        if (world.imageUrl.isNotEmpty) {
          mediaTasks.add(resourceManager.downloadAndCacheFile(world.imageUrl, folder: 'images'));
        }
      }

      // 3. Parallel Sync for Worlds, Missions, Stories, Questions
      await Future.wait(remoteWorlds.map((world) async {
        final remoteMissions = await remoteDataSource.getMissions(world.id);
        await localDataSource.cacheMissions(world.id, remoteMissions);

        await Future.wait(remoteMissions.map((mission) async {
          try {
            final storiesFuture = remoteDataSource.getStories(mission.id);
            final questionsFuture = remoteDataSource.getQuestions(mission.id);
            final remoteStories = await storiesFuture;
            final remoteQuestions = await questionsFuture;

            await localDataSource.cacheStories(mission.id, remoteStories);
            await localDataSource.cacheQuestions(mission.id, remoteQuestions);

            for (var story in remoteStories) {
              resourceManager.cacheCharacterModels(story.characterName, story.timelineData);
              if (story.audioUrl != null && story.audioUrl!.isNotEmpty) {
                mediaTasks.add(resourceManager.downloadAndCacheFile(story.audioUrl!, folder: 'audio'));
              }
              if (story.imageUrl.isNotEmpty) {
                mediaTasks.add(resourceManager.downloadAndCacheFile(story.imageUrl, folder: 'images'));
              }
            }
          } catch (e) {
            debugPrint('Failed to sync mission ${mission.id}: $e');
          }
        }));
      }));

      // 4. Trigger media downloads in background without blocking
      Future.wait(mediaTasks);

      // 5. Sync Child Progress
      if (childId != null && childId.isNotEmpty) {
        try {
          final remoteProgress = await remoteDataSource.getCompletedMissions(childId);
          await localDataSource.cacheChildProgress(childId, remoteProgress);
        } catch (_) {}
      }

      _lastSyncTime = DateTime.now();

      syncState.value = const SyncStatusState(
        status: SyncStatus.success,
        message: 'تم تحديث وتنزيل جميع الموارد بنجاح ✓',
      );
    } catch (e) {
      syncState.value = SyncStatusState(
        status: SyncStatus.error,
        message: 'حدث خطأ أثناء المزامنة: $e',
      );
    } finally {
      _isSyncRunning = false;
    }
  }

  void dispose() {
    _networkSubscription?.cancel();
    syncState.dispose();
  }
}
