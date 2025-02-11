import 'dart:async';
import 'package:flutter/material.dart';
import 'package:syncly_flutter/syncly_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final localStorage = LocalStorage();
  await localStorage.init();

  final syncManager = SyncManager(
    localStorage: localStorage,
    connectivityMonitor: ConnectivityMonitor(),
    conflictHandler: ConflictHandler(),
  );

  runApp(MyApp(syncManager: syncManager));
}

class MyApp extends StatelessWidget {
  final SyncManager syncManager;

  MyApp({required this.syncManager});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Offline Task Sync',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomeScreen(syncManager: syncManager),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final SyncManager syncManager;

  HomeScreen({required this.syncManager});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

enum TaskFilter { all, synced, unsynced }

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _taskController = TextEditingController();
  List<SyncData> _tasks = [];
  String _syncStatus = 'Idle';
  TaskFilter _currentFilter = TaskFilter.all;
  bool _isSyncing = false;

  late StreamSubscription<SyncEvent> _syncSubscription;

  @override
  void initState() {
    super.initState();
    _loadTasks();

    _syncSubscription = widget.syncManager.onSyncEvent.listen((event) {
      if (mounted) {
        setState(() {
          _syncStatus = _formatSyncStatus(event);
        });
      }

      if (event.type == SyncEventType.dataSynced ||
          event.type == SyncEventType.dataUnsynced ||
          event.type == SyncEventType.syncCompleted) {
        _loadTasks();
      }
    });
  }

  String _formatSyncStatus(SyncEvent event) {
    switch (event.type) {
      case SyncEventType.syncStarted:
        _isSyncing = true;
        return 'Syncing...';
      case SyncEventType.syncCompleted:
        _isSyncing = false;
        return 'All data synced!';
      case SyncEventType.syncFailed:
        _isSyncing = false;
        return 'Sync failed. Retrying...';
      case SyncEventType.dataSynced:
        if (event.data is SyncData) {
          return 'Task synced: ${(event.data as SyncData).data['title']}';
        }
        return 'Data synced successfully.';
      case SyncEventType.dataUnsynced:
        return 'Task saved offline.';
      case SyncEventType.connectionRestored:
        return 'Connection restored. Syncing now...';
      case SyncEventType.connectionLost:
        return 'Offline mode. Data will sync when connected.';
      default:
        _isSyncing = false;
        return 'Idle';
    }
  }

  Future<void> _loadTasks() async {
    List<SyncData> tasks;

    switch (_currentFilter) {
      case TaskFilter.synced:
        tasks = await widget.syncManager.localStorage.getSyncedData();
        break;
      case TaskFilter.unsynced:
        tasks = await widget.syncManager.localStorage.getUnsyncedData();
        break;
      case TaskFilter.all:
      default:
        tasks = await widget.syncManager.localStorage.getAllData();
        break;
    }

    if (mounted) {
      setState(() {
        _tasks = tasks;
      });
    }
  }

  Future<void> _addTask() async {
    final taskText = _taskController.text.trim();
    if (taskText.isEmpty) return;

    final newTask = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': taskText,
      'completed': false,
    };

    await widget.syncManager.addOfflineData('tasks', newTask);
    _taskController.clear();
    await _loadTasks();
  }

  void _toggleTask(SyncData task) async {
    final updatedTask = task.copyWith(
      data: {
        ...task.data,
        'completed': !(task.data['completed'] as bool),
      },
      updatedAt: DateTime.now(),
    );
    await widget.syncManager.localStorage.saveData(task.key, updatedTask.data);
    _loadTasks();
  }

  void _manualSync() {
    setState(() => _isSyncing = true);
    widget.syncManager.syncNow().then((_) {
      setState(() => _isSyncing = false);
    });
  }

  Future<void> _clearSyncedTasks() async {
    await widget.syncManager.localStorage.clearSyncedTasks();
    _loadTasks();
  }

  @override
  void dispose() {
    _syncSubscription.cancel();
    _taskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Task Sync'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: _manualSync,
            tooltip: 'Sync Now',
          ),
          PopupMenuButton<TaskFilter>(
            onSelected: (filter) {
              setState(() {
                _currentFilter = filter;
                _loadTasks();
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                  value: TaskFilter.all, child: Text('All Tasks')),
              const PopupMenuItem(
                  value: TaskFilter.synced, child: Text('Synced')),
              const PopupMenuItem(
                  value: TaskFilter.unsynced, child: Text('Unsynced')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _clearSyncedTasks,
            tooltip: 'Clear Synced Tasks',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _taskController,
                    decoration: const InputDecoration(
                      labelText: 'Enter new task',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addTask,
                  child: const Icon(Icons.add),
                ),
              ],
            ),
          ),
          if (_isSyncing) const LinearProgressIndicator(),
          if (_tasks.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'No tasks available.\nAdd tasks to see them here!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _tasks.length,
                itemBuilder: (context, index) {
                  final task = _tasks[index];
                  final isCompleted = task.data['completed'] as bool;
                  final isSynced = task.status == SyncStatus.synced;

                  return ListTile(
                    leading: Icon(
                      isSynced ? Icons.cloud_done : Icons.cloud_off,
                      color: isSynced ? Colors.green : Colors.red,
                    ),
                    title: Text(
                      task.data['title'],
                      style: TextStyle(
                        decoration:
                            isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    subtitle: Text(isSynced ? 'Synced' : 'Unsynced'),
                    trailing: IconButton(
                      icon: Icon(isCompleted ? Icons.undo : Icons.check),
                      onPressed: () => _toggleTask(task),
                    ),
                  );
                },
              ),
            ),
          Container(
            padding: const EdgeInsets.all(12),
            width: double.infinity,
            color: Colors.blue.shade50,
            child: Text(
              'Status: $_syncStatus',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
