// lib/services/connectivity_service.dart

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Wraps [Connectivity] and exposes a debounced stream of connectivity state.
///
/// `true`  → at least one usable network interface is available.
/// `false` → device is offline.
class ConnectivityService {
  final Connectivity _connectivity;

  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  /// Returns `true` if the latest connectivity result includes any network.
  static bool _isOnline(List<ConnectivityResult> results) {
    return results.any((r) =>
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet ||
        r == ConnectivityResult.vpn);
  }

  /// A stream that emits the current connectivity state whenever it changes.
  /// Debounced by [debounce] (default 3 s) to avoid reacting to transient
  /// signal fluctuations.
  Stream<bool> connectivityStream({
    Duration debounce = const Duration(seconds: 3),
  }) {
    return _connectivity.onConnectivityChanged
        .map(_isOnline)
        .transform(_DebounceStreamTransformer(debounce));
  }

  /// One-shot check for current connectivity.
  Future<bool> isConnected() async {
    final results = await _connectivity.checkConnectivity();
    return _isOnline(results);
  }
}

// ---------------------------------------------------------------------------
// Minimal debounce stream transformer
// ---------------------------------------------------------------------------

class _DebounceStreamTransformer<T> extends StreamTransformerBase<T, T> {
  final Duration duration;
  const _DebounceStreamTransformer(this.duration);

  @override
  Stream<T> bind(Stream<T> stream) {
    late StreamController<T> controller;
    Timer? timer;
    StreamSubscription<T>? subscription;

    controller = StreamController<T>(
      onListen: () {
        subscription = stream.listen(
          (event) {
            timer?.cancel();
            timer = Timer(duration, () => controller.add(event));
          },
          onError: controller.addError,
          onDone: () {
            timer?.cancel();
            controller.close();
          },
        );
      },
      onCancel: () {
        timer?.cancel();
        subscription?.cancel();
      },
    );

    return controller.stream;
  }
}
