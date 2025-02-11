import 'package:syncly_flutter/syncly_flutter.dart';

/// Enum representing different conflict resolution strategies.
enum ConflictResolutionStrategy {
  lastWriteWins, // The most recently updated data is kept.
  serverWins, // The server's data always takes precedence.
  localWins, // The local data always takes precedence.
  mergeFields, // Merge fields from local and remote data.
  manual, // Manual intervention is required to resolve conflicts.
}

/// Handles conflicts between local and remote data during synchronization.
class ConflictHandler {
  final ConflictResolutionStrategy strategy;

  /// Optional callback for custom manual conflict resolution.
  final SyncData Function(SyncData localData, SyncData remoteData)?
      manualConflictResolver;

  ConflictHandler({
    this.strategy = ConflictResolutionStrategy.lastWriteWins,
    this.manualConflictResolver,
  });

  /// Resolves a conflict between local and remote data based on the selected strategy.
  SyncData resolveConflict(SyncData localData, SyncData remoteData) {
    switch (strategy) {
      case ConflictResolutionStrategy.lastWriteWins:
        return _resolveLastWriteWins(localData, remoteData);
      case ConflictResolutionStrategy.serverWins:
        return remoteData.copyWith(status: SyncStatus.synced);
      case ConflictResolutionStrategy.localWins:
        return localData.copyWith(status: SyncStatus.synced);
      case ConflictResolutionStrategy.mergeFields:
        return _mergeFields(localData, remoteData);
      case ConflictResolutionStrategy.manual:
        if (manualConflictResolver != null) {
          return manualConflictResolver!(localData, remoteData);
        } else {
          throw Exception(
              'Manual conflict resolution requires a resolver callback.');
        }
    }
  }

  /// Resolves conflict by keeping the most recently updated data.
  SyncData _resolveLastWriteWins(SyncData localData, SyncData remoteData) {
    if (localData.updatedAt.isAfter(remoteData.updatedAt)) {
      return localData.copyWith(status: SyncStatus.synced);
    } else {
      return remoteData.copyWith(status: SyncStatus.synced);
    }
  }

  /// Merges fields from both local and remote data.
  SyncData _mergeFields(SyncData localData, SyncData remoteData) {
    final mergedData = {
      ...remoteData.data,
      ...localData.data
    }; // Local data takes precedence for overlapping fields
    return SyncData(
      id: localData.id,
      key: localData.key,
      data: mergedData,
      createdAt: remoteData.createdAt,
      updatedAt: DateTime.now(),
      status: SyncStatus.synced,
    );
  }
}
