import '../../domain/entities/scan.dart';

abstract class ScanState {
  const ScanState();
}

class ScanInitial extends ScanState {
  const ScanInitial();
}

class ScanPermissionChecking extends ScanState {
  const ScanPermissionChecking();
}

class ScanPermissionDenied extends ScanState {
  final bool isPermanentlyDenied;

  const ScanPermissionDenied({this.isPermanentlyDenied = false});
}

class ScanCameraReady extends ScanState {
  final String cropId;

  const ScanCameraReady({required this.cropId});
}

class ScanPhotoCaptured extends ScanState {
  final String cropId;
  final String tempImagePath;

  const ScanPhotoCaptured({
    required this.cropId,
    required this.tempImagePath,
  });
}

class ScanCreating extends ScanState {
  const ScanCreating();
}

class ScanCreated extends ScanState {
  final Scan scan;

  const ScanCreated(this.scan);
}

class ScanError extends ScanState {
  final String message;

  const ScanError(this.message);
}
