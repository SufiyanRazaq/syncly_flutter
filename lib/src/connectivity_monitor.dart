import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Monitors the device's network connectivity status and confirms real internet access.
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
    // Adjust listener to handle lists of ConnectivityResult
    _connectivity.onConnectivityChanged.listen((results) {
      if (results.isNotEmpty) {
        _updateConnectionStatus(results.first); // Use the first result
      }
    });
  }

  /// Initializes the connectivity status on app start.
  Future<void> _initConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      await _updateConnectionStatus(
          result.first); // Handle single ConnectivityResult
    } catch (e) {
      print('Failed to get connectivity: $e');
    }
  }

  /// Updates the connection status based on connectivity result.
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

  /// Checks actual internet access by pinging Google's DNS server.
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

  /// Returns the current connectivity status.
  bool get isConnected => _isConnected;

  /// Disposes the stream controller when no longer needed.
  void dispose() {
    _connectionStatusController.close();
  }
}
