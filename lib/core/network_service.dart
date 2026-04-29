import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkService {
  final Connectivity _connectivity = Connectivity();

  /// Check current internet status
  Future<bool> isConnected() async {
    final result = await _connectivity.checkConnectivity();

    if (result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet) {
      return true;
    }

    return false;
  }

  /// Listen to internet changes
  Stream<bool> get connectionStream async* {
    await for (final result
    in _connectivity.onConnectivityChanged) {
      yield result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet;
    }
  }
}