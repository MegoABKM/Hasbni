import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkService {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();

  final Connectivity _connectivity = Connectivity();

  /// Returns true if connected to WiFi or Mobile Data
  Future<bool> get isConnected async {
    final result = await _connectivity.checkConnectivity();
    // checkConnectivity returns a List<ConnectivityResult> in newer versions
    if (result.contains(ConnectivityResult.mobile) || 
        result.contains(ConnectivityResult.wifi) || 
        result.contains(ConnectivityResult.ethernet)) {
      return true;
    }
    return false;
  }
}