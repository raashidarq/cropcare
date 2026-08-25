import '../../domain/entities/diagnosis.dart';
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

  const ScanCameraReady({this.cropId = 'unknown'});
}

class ScanPhotoCaptured extends ScanState {
  final String cropId;
  final String tempImagePath;

  const ScanPhotoCaptured({
    this.cropId = 'unknown',
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

/// ML inference is running.
class ScanDiagnosing extends ScanState {
  const ScanDiagnosing();
}

/// ML inference completed successfully.
class ScanDiagnosed extends ScanState {
  final Scan scan;
  final Diagnosis diagnosis;

  const ScanDiagnosed({required this.scan, required this.diagnosis});
}

/// Image failed validation — cannot run inference.
class ScanImageInvalid extends ScanState {
  final String reason;

  const ScanImageInvalid({required this.reason});
}
