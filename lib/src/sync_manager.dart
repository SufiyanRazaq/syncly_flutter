import 'dart:async';
import 'connectivity_monitor.dart';
import 'conflict_handler.dart';
import 'local_storage.dart';
import 'models/sync_data.dart';
import 'models/sync_event.dart';

/// Manages the synchronization of offline data with the remote server.
class SyncManager {
  final LocalStorage localStorage;
  final ConnectivityMonitor connectivityMonitor;
  final ConflictHandler conflictHandler;

  final StreamController<SyncEvent> _syncEventController =
      StreamController<SyncEvent>.broadcast();

  /// Stream to listen for sync-related events.
  Stream<SyncEvent> get onSyncEvent => _syncEventController.stream;

  SyncManager({
    required this.localStorage,
    required this.connectivityMonitor,
    required this.conflictHandler,
  }) {
    _init();
  }

  /// Initializes the sync manager and sets up connectivity listeners.
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

  /// Adds new data to local storage, marking it as unsynced.
  Future<void> addOfflineData(String key, Map<String, dynamic> data) async {
    await localStorage.saveData(key, data);
    _emitEvent(SyncEvent(
      type: SyncEventType.dataUnsynced,
      message: 'Data saved locally and marked as unsynced.',
      data: data,
    ));
  }

  /// Manually triggers data synchronization.
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

  /// Syncs data with retry logic for failed attempts.
  Future<void> _syncDataWithRetry(SyncData data, {int retryCount = 0}) async {
    const maxRetries = 5;
    const baseDelay = 1000; // in milliseconds

    try {
      final remoteData =
          await _fetchRemoteData(data); // Simulate fetching remote data

      if (_isConflictDetected(data, remoteData)) {
        final resolvedData = conflictHandler.resolveConflict(data, remoteData!);
        await _pushToServer(resolvedData); // Push resolved data to server
        await localStorage.markAsSynced(resolvedData);

        _emitEvent(SyncEvent(
          type: SyncEventType.conflictDetected,
          message: 'Conflict detected and resolved.',
          data: resolvedData,
        ));
      } else {
        await _pushDeltaToServer(data); // Push only the changed fields
        await localStorage.markAsSynced(data);
        _emitEvent(SyncEvent(
          type: SyncEventType.dataSynced,
          message: 'Data successfully synced with server.',
          data: data,
        ));
      }
    } catch (e) {
      if (retryCount < maxRetries) {
        final delay = baseDelay * (1 << retryCount); // Exponential backoff
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

  /// Checks if there's a conflict between local and remote data.
  bool _isConflictDetected(SyncData localData, SyncData? remoteData) {
    if (remoteData == null) return false; // No remote data means no conflict
    return localData.updatedAt.isAfter(remoteData.updatedAt) == false;
  }

  /// Simulates fetching remote data from the server.
  Future<SyncData?> _fetchRemoteData(SyncData localData) async {
    await Future.delayed(
        const Duration(milliseconds: 500)); // Simulate network delay
    return null; // Return null to simulate no conflict
  }

  Future<void> _pushToServer(SyncData data) async {
    // Replace this with actual API logic to push data
    await Future.delayed(
        const Duration(milliseconds: 500)); // Simulate network delay
  }

  /// Simulates pushing delta (only changed fields) to the server.
  Future<void> _pushDeltaToServer(SyncData data) async {
    final delta = _calculateDelta(data.previousData, data.data);
    if (delta.isNotEmpty) {
      await Future.delayed(
          const Duration(milliseconds: 500)); // Simulate network delay
    }
  }

  /// Calculates the delta (difference) between previous and current data.
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

  /// Emits a sync event to all listeners.
  void _emitEvent(SyncEvent event) {
    _syncEventController.add(event);
  }

  /// Disposes resources when no longer needed.
  void dispose() {
    _syncEventController.close();
    connectivityMonitor.dispose();
  }
}
