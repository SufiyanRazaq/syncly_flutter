
# Syncly Flutter

A Flutter package that enables offline-first data synchronization with seamless real-time syncing when the device reconnects to the internet. Perfect for apps that require reliable data storage and synchronization, even when the user is offline.

Features:\
✔ Offline-First Data Handling – Automatically saves tasks locally and syncs when online.\
✔ Real-Time Sync Status – Get live updates on syncing status through stream listeners.\
✔ Customizable Conflict Resolution – Multiple strategies like Last Write Wins, Server Wins, Local Wins, and Manual Merge.\
✔ Automatic Network Detection – Detects real internet connectivity, not just network presence.\
✔ Delta Sync – Efficient synchronization by pushing only changed fields.\
✔ Manual Sync Trigger – Option to manually trigger data sync for full control.\
✔ Filter Tasks – View all, synced, or unsynced tasks.\


## Installation:
To use this package, add the following dependency to your pubspec.yaml:
```
dependencies:
  syncly_flutter: ^0.0.1

```


https://github.com/user-attachments/assets/4e024684-8b6d-4689-bba4-81ab7a1ba205



## Getting Started:
Import the package in your Dart file:

```
import 'package:syncly_flutter/syncly_flutter.dart';

```

## Example Usage:
Initialize Sync Manager:
```
final localStorage = LocalStorage();
await localStorage.init();

final syncManager = SyncManager(
  localStorage: localStorage,
  connectivityMonitor: ConnectivityMonitor(),
  conflictHandler: ConflictHandler(),
);

```

## Add Tasks Offline:
```
final newTask = {
  'id': DateTime.now().millisecondsSinceEpoch.toString(),
  'title': 'New Task',
  'completed': false,
};

await syncManager.addOfflineData('tasks', newTask);

```

## Listen for Sync Events:
```
syncManager.onSyncEvent.listen((event) {
  print('Sync Status: ${event.message}');
});

```

## Manual Sync Trigger:
```
syncManager.syncNow();

```

## Authors

- [@SufiyanRazaq](https://github.com/SufiyanRazaq/syncly_flutter)

