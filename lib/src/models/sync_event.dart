enum SyncEventType {
  syncStarted,
  syncCompleted,
  syncFailed,
  conflictDetected,
  dataSynced,
  dataUnsynced,
  connectionRestored,
  connectionLost,
}

class SyncEvent {
  final SyncEventType type;
  final String message;
  final dynamic data;
  final DateTime timestamp;

  SyncEvent({
    required this.type,
    required this.message,
    this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() {
    return 'SyncEvent(type: $type, message: $message, timestamp: $timestamp, data: $data)';
  }
}
