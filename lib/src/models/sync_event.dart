/// Enum to represent different types of sync events.
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

/// A class representing an event during the sync process.
class SyncEvent {
  final SyncEventType type; // Type of the event
  final String message; // A message describing the event
  final dynamic
      data; // Optional data associated with the event (e.g., conflicted data)
  final DateTime timestamp; // When the event occurred

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
