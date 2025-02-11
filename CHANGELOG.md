## [0.0.2] - 2025-02-11

### Added
- Initial implementation of **offline-first data synchronization** using SQLite.
- **SyncManager** class to manage the synchronization of local data with remote servers.
- **LocalStorage** class for storing unsynced and synced data in a SQLite database.
- **ConnectivityMonitor** to detect real internet connectivity using `connectivity_plus` and DNS checks.
- **ConflictHandler** for resolving data conflicts with customizable strategies:
  - `lastWriteWins`, `serverWins`, `localWins`, `mergeFields`, `manual`.

### Features
- **Offline task creation**: Users can add tasks while offline, which are automatically synced when the connection is restored.
- **Real-time sync status** updates using stream listeners (`SyncEvent`).
- **Manual sync trigger** option via UI for immediate data synchronization.
- **Delta sync** support to push only updated fields, reducing network load.
- **Customizable conflict resolution strategies** to handle data discrepancies.

### Fixed
- Handled scenarios where internet connection is reported as available but actual access is not possible.
- Ensured data consistency by verifying internet access with DNS lookup before attempting to sync.
- Prevented data duplication during sync retries.

### Known Issues
- Sync conflicts might not be handled properly if manual resolution logic isn't provided.
- No built-in UI for conflict resolution; developers need to implement custom UIs if `manual` strategy is used.

---

### **Usage Instructions**
1. Add tasks offline and they will be saved in local storage.
2. When the internet is restored, tasks automatically sync with the server.
3. Use the **sync button** to manually trigger synchronization.
4. Customize conflict resolution logic by modifying the `ConflictHandler`.

---

### **Next Steps (Planned for Future Releases)**
- Add **encryption** for sensitive local data.
- Implement **background sync** for seamless data updates.
- Support for **multi-device conflict resolution**.
- Improve **UI feedback** with detailed sync progress indicators.
