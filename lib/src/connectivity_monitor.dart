import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityMonitor {
  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectionStatusController =
      StreamController<bool>.broadcast();

  Stream<bool> get onConnectionStatusChanged =>
      _connectionStatusController.stream;
  Stream<void> get onConnectionRestored =>
      _connectionStatusController.stream.where((status) => status).map((_) {});
  Stream<void> get onConnectionLost =>
      _connectionStatusController.stream.where((status) => !status).map((_) {});

  bool _isConnected = false;

  ConnectivityMonitor() {
    _initConnectivity();
    _connectivity.onConnectivityChanged.listen((results) {
      if (results.isNotEmpty) {
        _updateConnectionStatus(results.first);
      }
    });
  }

  Future<void> _initConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      await _updateConnectionStatus(result.first);
    } catch (e) {
      print('Failed to get connectivity: $e');
    }
  }

  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    final bool hasInternet = await _checkInternetConnection();

    if (hasInternet != _isConnected) {
      _isConnected = hasInternet;
      _connectionStatusController.add(_isConnected);

      if (_isConnected) {
        print('Internet connection restored.');
      } else {
        print('Internet connection lost.');
      }
    }
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }
    } catch (_) {
      return false;
    }
    return false;
  }

  bool get isConnected => _isConnected;

  void dispose() {
    _connectionStatusController.close();
  }
}
