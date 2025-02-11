import 'package:syncly_flutter/syncly_flutter.dart';

enum ConflictResolutionStrategy {
  lastWriteWins,
  serverWins,
  localWins,
  mergeFields,
  manual,
}

class ConflictHandler {
  final ConflictResolutionStrategy strategy;

  final SyncData Function(SyncData localData, SyncData remoteData)?
      manualConflictResolver;

  ConflictHandler({
    this.strategy = ConflictResolutionStrategy.lastWriteWins,
    this.manualConflictResolver,
  });
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

  SyncData _resolveLastWriteWins(SyncData localData, SyncData remoteData) {
    if (localData.updatedAt.isAfter(remoteData.updatedAt)) {
      return localData.copyWith(status: SyncStatus.synced);
    } else {
      return remoteData.copyWith(status: SyncStatus.synced);
    }
  }

  SyncData _mergeFields(SyncData localData, SyncData remoteData) {
    final mergedData = {...remoteData.data, ...localData.data};
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
