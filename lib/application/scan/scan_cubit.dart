import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

import '../../domain/usecases/scan/capture_scan_use_case.dart';
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

  ScanCubit({
    required this.captureScanUseCase,
    this.permissionService = const DefaultCameraPermissionService(),
  }) : super(const ScanInitial());

  Future<void> initializePermission(String cropId) async {
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

  Future<void> requestPermission(String cropId) async {
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

  void photoCaptured({required String cropId, required String tempImagePath}) {
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

      final scan = await captureScanUseCase(
        cropId: cropId,
        imageLocalPath: finalPath,
        userId: userId,
      );

      emit(ScanCreated(scan));
    } catch (e) {
      emit(ScanError(e.toString()));
    }
  }
}
