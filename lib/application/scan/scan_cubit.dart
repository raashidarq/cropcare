import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

import '../../domain/usecases/diagnosis/run_diagnosis_use_case.dart';
import '../../domain/usecases/diagnosis/validate_image_use_case.dart';
import '../../domain/usecases/scan/capture_scan_use_case.dart';
import '../../domain/utils/crop_parser.dart';
import 'scan_state.dart';

abstract class CameraPermissionService {
  Future<ph.PermissionStatus> checkPermission();
  Future<ph.PermissionStatus> requestPermission();
  Future<bool> openAppSettings();
}

class DefaultCameraPermissionService implements CameraPermissionService {
  const DefaultCameraPermissionService();

  @override
  Future<ph.PermissionStatus> checkPermission() => ph.Permission.camera.status;

  @override
  Future<ph.PermissionStatus> requestPermission() => ph.Permission.camera.request();

  @override
  Future<bool> openAppSettings() => ph.openAppSettings();
}

class ScanCubit extends Cubit<ScanState> {
  final CaptureScanUseCase captureScanUseCase;
  final CameraPermissionService permissionService;
  final ValidateImageUseCase? validateImageUseCase;
  final RunDiagnosisUseCase? runDiagnosisUseCase;

  ScanCubit({
    required this.captureScanUseCase,
    this.permissionService = const DefaultCameraPermissionService(),
    this.validateImageUseCase,
    this.runDiagnosisUseCase,
  }) : super(const ScanInitial());

  Future<void> initializePermission([String cropId = 'unknown']) async {
    emit(const ScanPermissionChecking());
    try {
      final status = await permissionService.checkPermission();
      if (status.isGranted) {
        emit(ScanCameraReady(cropId: cropId));
      } else if (status.isDenied) {
        final reqStatus = await permissionService.requestPermission();
        if (reqStatus.isGranted) {
          emit(ScanCameraReady(cropId: cropId));
        } else {
          emit(ScanPermissionDenied(
            isPermanentlyDenied: reqStatus.isPermanentlyDenied,
          ));
        }
      } else {
        emit(ScanPermissionDenied(
          isPermanentlyDenied: status.isPermanentlyDenied,
        ));
      }
    } catch (_) {
      // Assumption: Permission exception on desktop/test environments resolves to denied UI gracefully without crashing.
      emit(const ScanPermissionDenied(isPermanentlyDenied: false));
    }
  }

  Future<void> requestPermission([String cropId = 'unknown']) async {
    emit(const ScanPermissionChecking());
    try {
      final reqStatus = await permissionService.requestPermission();
      if (reqStatus.isGranted) {
        emit(ScanCameraReady(cropId: cropId));
      } else {
        emit(ScanPermissionDenied(
          isPermanentlyDenied: reqStatus.isPermanentlyDenied,
        ));
      }
    } catch (_) {
      emit(const ScanPermissionDenied(isPermanentlyDenied: false));
    }
  }

  Future<void> openAppSettings() async {
    await permissionService.openAppSettings();
  }

  void photoCaptured({String cropId = 'unknown', required String tempImagePath}) {
    emit(ScanPhotoCaptured(cropId: cropId, tempImagePath: tempImagePath));
  }

  Future<void> retakePhoto() async {
    final currentState = state;
    if (currentState is ScanPhotoCaptured) {
      final cropId = currentState.cropId;
      try {
        final file = File(currentState.tempImagePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
      emit(ScanCameraReady(cropId: cropId));
    }
  }

  Future<void> confirmPhoto({
    required String userId,
    String? targetDirectoryPath,
  }) async {
    final currentState = state;
    if (currentState is! ScanPhotoCaptured) return;

    emit(const ScanCreating());
    try {
      final tempPath = currentState.tempImagePath;
      final cropId = currentState.cropId;

      String finalPath = tempPath;
      if (targetDirectoryPath != null) {
        final filename = 'scan_${DateTime.now().millisecondsSinceEpoch}${p.extension(tempPath)}';
        final savedFile = File(p.join(targetDirectoryPath, filename));
        final tempFile = File(tempPath);
        if (await tempFile.exists()) {
          await tempFile.copy(savedFile.path);
          try {
            await tempFile.delete();
          } catch (_) {}
          finalPath = savedFile.path;
        }
      } else {
        final docsDir = await getApplicationDocumentsDirectory();
        final scansDir = Directory(p.join(docsDir.path, 'scans'));
        if (!await scansDir.exists()) {
          await scansDir.create(recursive: true);
        }
        final filename = 'scan_${DateTime.now().millisecondsSinceEpoch}${p.extension(tempPath)}';
        final savedFile = File(p.join(scansDir.path, filename));
        final tempFile = File(tempPath);
        if (await tempFile.exists()) {
          await tempFile.copy(savedFile.path);
          try {
            await tempFile.delete();
          } catch (_) {}
          finalPath = savedFile.path;
        }
      }

      // ── Validate BEFORE creating anything ────────────────────────────────
      //
      // Validation runs first, on the file alone, so a rejected photo leaves
      // NOTHING behind: no scan row, no queued upload, no history entry, no
      // file on disk. Previously the scan was created first and then cleaned
      // up on rejection, which still put a row in the database — and since
      // the crop is only derived from a successful inference, every rejected
      // attempt showed up in history as an "Unknown" crop with no result.
      //
      // The `image_validation` audit row is not written for this path. That
      // table has no reader anywhere in the app (it is only ever written and
      // bulk-deleted), so keeping a scan alive purely to hang an unread audit
      // row off it is not a trade worth making.
      final validate = validateImageUseCase;
      final diagnose = runDiagnosisUseCase;

      if (validate != null && diagnose != null) {
        emit(const ScanDiagnosing());

        final validation = await validate(finalPath);

        if (!validation.isUsable) {
          final reason = validation.rejectionReason != null
              ? ValidateImageUseCase.rejectionReasonToString(validation.rejectionReason!)
              : 'UNKNOWN';

          // Discard the copy we just made; the user is about to retake.
          try {
            final rejected = File(finalPath);
            if (await rejected.exists()) await rejected.delete();
          } catch (_) {}

          emit(ScanImageInvalid(reason: reason));
          return;
        }

        final scan = await captureScanUseCase(
          cropId: cropId,
          imageLocalPath: finalPath,
          userId: userId,
        );

        final diagnosis = await diagnose(
          scanId: scan.id,
          imageLocalPath: finalPath,
          validationResult: validation,
        );

        final derivedCrop = CropParser.deriveCropId(diagnosis.diseaseId);
        final updatedScan = scan.copyWith(
          cropId: derivedCrop != 'unknown' ? derivedCrop : scan.cropId,
        );

        emit(ScanDiagnosed(scan: updatedScan, diagnosis: diagnosis));
      } else {
        // No ML wired (tests, or a build without the model): nothing to
        // validate against, so create the scan and stop there.
        final scan = await captureScanUseCase(
          cropId: cropId,
          imageLocalPath: finalPath,
          userId: userId,
        );
        emit(ScanCreated(scan));
      }
    } catch (e) {
      emit(ScanError(e.toString()));
    }
  }
}
