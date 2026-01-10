import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class NetworkService {
  // Singleton pattern
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();

  final Connectivity _connectivity = Connectivity();
  final InternetConnection _internetConnection = InternetConnection();

  // Stream controller to broadcast connection status to the app
  final _controller = StreamController<bool>.broadcast();
  Stream<bool> get internetStatusStream => _controller.stream;

  // Debounce timer to prevent false notifications on app start
  Timer? _debounceTimer;
  bool _isInitialized = false;

  void initialize() {
    // 1. Listen to connectivity changes (Wi-Fi, Mobile, None)
    _connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      _checkInternetConnection(results);
    });

    // 2. Listen to actual internet status (Data access)
    _internetConnection.onStatusChange.listen((InternetStatus status) {
      bool hasInternet = status == InternetStatus.connected;
      _broadcastStatus(hasInternet);
    });

    // 3. Perform initial check after a short delay to avoid false negatives
    _debounceTimer = Timer(const Duration(seconds: 3), () async {
      final results = await _connectivity.checkConnectivity();
      _checkInternetConnection(results);
      _isInitialized = true;
    });
  }

  // Helper to broadcast status with debounce on initialization
  void _broadcastStatus(bool hasInternet) {
    if (_isInitialized) {
      _controller.add(hasInternet);
    }
  }

  // Helper to check manual status
  Future<void> _checkInternetConnection(
    List<ConnectivityResult> results,
  ) async {
    if (results.contains(ConnectivityResult.none)) {
      _broadcastStatus(false);
    } else {
      bool hasInternet = await _internetConnection.hasInternetAccess;
      _broadcastStatus(hasInternet);
    }
  }

  void dispose() {
    _debounceTimer?.cancel();
    _controller.close();
  }
}
