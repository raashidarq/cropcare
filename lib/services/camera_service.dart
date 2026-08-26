// lib/services/camera_service.dart
//
// Thin seam over the `camera` plugin's top-level functions.
//
// Exists so the capture screen can be tested without camera hardware — the
// plugin's `availableCameras()` is a bare top-level function, which is
// untestable and, on a device with no camera, throws. Mirrors the existing
// CameraPermissionService pattern in ScanCubit rather than inventing a new
// dependency-injection style.

import 'package:camera/camera.dart';

abstract class CameraService {
  /// Cameras available on this device. Returns an empty list — rather than
  /// throwing — when there are none, so callers have one path to handle.
  Future<List<CameraDescription>> availableCameras();

  /// Builds a controller for [description]. Separate from construction so
  /// tests can supply a fake without a real camera.
  CameraController createController(
    CameraDescription description, {
    ResolutionPreset resolution,
  });
}

class DefaultCameraService implements CameraService {
  const DefaultCameraService();

  @override
  Future<List<CameraDescription>> availableCameras() async {
    try {
      return await availableCamerasFn();
    } catch (_) {
      // No camera hardware, or no platform channel at all. Deliberately
      // catches everything, not just CameraException: a device without the
      // plugin registered throws MissingPluginException, which is the exact
      // case this fallback exists for. Treated as "no cameras" so the UI can
      // offer the gallery instead of hanging on a spinner.
      return const [];
    }
  }

  @override
  CameraController createController(
    CameraDescription description, {
    ResolutionPreset resolution = ResolutionPreset.high,
  }) {
    return CameraController(
      description,
      resolution,
      // The classifier only needs RGB stills; audio permission would be an
      // unnecessary (and alarming) thing to ask a farmer for.
      enableAudio: false,
    );
  }
}

/// Indirection so [DefaultCameraService] can be unit-tested and so the
/// top-level plugin call appears exactly once in the codebase.
Future<List<CameraDescription>> Function() availableCamerasFn = availableCameras;
