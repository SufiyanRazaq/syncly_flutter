import 'dart:async';
import 'connectivity_monitor.dart';
import 'conflict_handler.dart';
import 'local_storage.dart';
import 'models/sync_data.dart';
import 'models/sync_event.dart';

class SyncManager {
  final LocalStorage localStorage;
  final ConnectivityMonitor connectivityMonitor;
  final ConflictHandler conflictHandler;

  final StreamController<SyncEvent> _syncEventController =
      StreamController<SyncEvent>.broadcast();

  Stream<SyncEvent> get onSyncEvent => _syncEventController.stream;

  SyncManager({
    required this.localStorage,
    required this.connectivityMonitor,
    required this.conflictHandler,
  }) {
    _init();
  }

  void _init() {
    connectivityMonitor.onConnectionRestored.listen((_) {
      _emitEvent(SyncEvent(
        type: SyncEventType.connectionRestored,
        message: 'Internet connection restored. Starting sync...',
      ));
      syncNow();
    });

    connectivityMonitor.onConnectionLost.listen((_) {
      _emitEvent(SyncEvent(
        type: SyncEventType.connectionLost,
        message: 'Internet connection lost. Sync paused.',
      ));
    });
  }

  Future<void> addOfflineData(String key, Map<String, dynamic> data) async {
    await localStorage.saveData(key, data);
    _emitEvent(SyncEvent(
      type: SyncEventType.dataUnsynced,
      message: 'Data saved locally and marked as unsynced.',
      data: data,
    ));
  }

  Future<void> syncNow() async {
    _emitEvent(SyncEvent(
      type: SyncEventType.syncStarted,
      message: 'Synchronization process started.',
    ));

    final unsyncedData = await localStorage.getUnsyncedData();

    for (var data in unsyncedData) {
      await _syncDataWithRetry(data);
    }

    _emitEvent(SyncEvent(
      type: SyncEventType.syncCompleted,
      message: 'Synchronization process completed.',
    ));
  }

  Future<void> _syncDataWithRetry(SyncData data, {int retryCount = 0}) async {
    const maxRetries = 5;
    const baseDelay = 1000;

    try {
      final remoteData = await _fetchRemoteData(data);

      if (_isConflictDetected(data, remoteData)) {
        final resolvedData = conflictHandler.resolveConflict(data, remoteData!);
        await _pushToServer(resolvedData);
        await localStorage.markAsSynced(resolvedData);

        _emitEvent(SyncEvent(
          type: SyncEventType.conflictDetected,
          message: 'Conflict detected and resolved.',
          data: resolvedData,
        ));
      } else {
        await _pushDeltaToServer(data);
        await localStorage.markAsSynced(data);
        _emitEvent(SyncEvent(
          type: SyncEventType.dataSynced,
          message: 'Data successfully synced with server.',
          data: data,
        ));
      }
    } catch (e) {
      if (retryCount < maxRetries) {
        final delay = baseDelay * (1 << retryCount);
        await Future.delayed(Duration(milliseconds: delay));
        await _syncDataWithRetry(data, retryCount: retryCount + 1);
      } else {
        _emitEvent(SyncEvent(
          type: SyncEventType.syncFailed,
          message: 'Failed to sync data after $maxRetries attempts: $e',
          data: data,
        ));
      }
    }
  }

  bool _isConflictDetected(SyncData localData, SyncData? remoteData) {
    if (remoteData == null) return false;
    return localData.updatedAt.isAfter(remoteData.updatedAt) == false;
  }

  Future<SyncData?> _fetchRemoteData(SyncData localData) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return null;
  }

  Future<void> _pushToServer(SyncData data) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> _pushDeltaToServer(SyncData data) async {
    final delta = _calculateDelta(data.previousData, data.data);
    if (delta.isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  Map<String, dynamic> _calculateDelta(
      Map<String, dynamic>? previous, Map<String, dynamic> current) {
    if (previous == null) return current;

    final delta = <String, dynamic>{};
    current.forEach((key, value) {
      if (previous[key] != value) {
        delta[key] = value;
      }
    });
    return delta;
  }

  void _emitEvent(SyncEvent event) {
    _syncEventController.add(event);
  }

  void dispose() {
    _syncEventController.close();
    connectivityMonitor.dispose();
  }
}
