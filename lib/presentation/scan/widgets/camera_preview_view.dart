// lib/presentation/scan/widgets/camera_preview_view.dart
//
// Live camera viewfinder.
//
// Replaces a static black placeholder that only *looked* like a camera: the
// old screen showed an icon and handed capture off to the OS camera app, so
// the farmer left CropCare, framed the shot in a different UI with no leaf
// guidance, and came back. A real in-app preview keeps the framing guide and
// the capture flow together, and removes an app switch from the hot path.

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../services/camera_service.dart';
import 'leaf_frame_overlay.dart';

/// What the viewfinder is currently doing, so the host screen can react
/// (e.g. disable the shutter until the preview is live).
enum CameraViewStatus { initializing, ready, unavailable }

class CameraPreviewView extends StatefulWidget {
  final CameraService cameraService;

  /// Instruction rendered under the framing guide.
  final String hint;

  /// Message shown when the device has no usable camera.
  final String unavailableMessage;

  /// Label of the fallback action offered when there is no camera.
  final String galleryActionLabel;

  final VoidCallback onUseGallery;

  /// Receives a capture callback once the preview is live, and null when it
  /// is not — lets the parent own the shutter button while this widget owns
  /// the controller lifecycle.
  final ValueChanged<Future<XFile?> Function()?> onCaptureReady;

  final ValueChanged<CameraViewStatus>? onStatusChanged;

  const CameraPreviewView({
    super.key,
    required this.cameraService,
    required this.hint,
    required this.unavailableMessage,
    required this.galleryActionLabel,
    required this.onUseGallery,
    required this.onCaptureReady,
    this.onStatusChanged,
  });

  @override
  State<CameraPreviewView> createState() => _CameraPreviewViewState();
}

class _CameraPreviewViewState extends State<CameraPreviewView>
    with WidgetsBindingObserver {
  CameraController? _controller;
  CameraDescription? _description;
  CameraViewStatus _status = CameraViewStatus.initializing;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  /// The camera is a single shared hardware resource. Holding it while the app
  /// is backgrounded prevents other apps from using it and, on Android, the
  /// controller is invalidated anyway — so release on pause and rebuild on
  /// resume. Omitting this is the classic source of a black preview after
  /// switching apps.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _teardown();
    } else if (state == AppLifecycleState.resumed) {
      _initialize();
    }
  }

  void _setStatus(CameraViewStatus status) {
    if (_status == status) return;
    _status = status;
    widget.onStatusChanged?.call(status);
  }

  Future<void> _teardown() async {
    final controller = _controller;
    _controller = null;
    widget.onCaptureReady(null);
    await controller?.dispose();
    if (mounted) setState(() {});
  }

  Future<void> _initialize() async {
    _setStatus(CameraViewStatus.initializing);
    if (mounted) setState(() {});

    try {
      final cameras =
          _description == null ? await widget.cameraService.availableCameras() : null;

      if (cameras != null) {
        if (cameras.isEmpty) {
          // Tablet, emulator or a device with no camera. Not an error state —
          // gallery import is a perfectly good path, so offer it plainly.
          _setStatus(CameraViewStatus.unavailable);
          if (mounted) setState(() {});
          return;
        }
        _description = cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
          orElse: () => cameras.first,
        );
      }

      final controller = widget.cameraService.createController(_description!);
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      _controller = controller;
      _setStatus(CameraViewStatus.ready);
      widget.onCaptureReady(_takePicture);
      setState(() {});
    } catch (_) {
      // Initialisation can fail for reasons the user can still route around
      // (camera in use by another app, hardware fault). Degrade to the
      // gallery path rather than showing nothing, which is what the previous
      // blanket `catch (_) {}` effectively did.
      _setStatus(CameraViewStatus.unavailable);
      if (mounted) setState(() {});
    }
  }

  Future<XFile?> _takePicture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return null;
    if (controller.value.isTakingPicture) return null;
    return controller.takePicture();
  }

  @override
  Widget build(BuildContext context) {
    if (_status == CameraViewStatus.unavailable) {
      return _CameraUnavailable(
        message: widget.unavailableMessage,
        actionLabel: widget.galleryActionLabel,
        onAction: widget.onUseGallery,
      );
    }

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return ColoredBox(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // The sensor's aspect ratio rarely matches the viewport. Cover the
          // area rather than letterboxing, so the preview matches what the
          // saved photo will contain.
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: controller.value.previewSize?.height ?? 1,
              height: controller.value.previewSize?.width ?? 1,
              child: CameraPreview(controller),
            ),
          ),
          LeafFrameOverlay(hint: widget.hint),
        ],
      ),
    );
  }
}

class _CameraUnavailable extends StatelessWidget {
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _CameraUnavailable({
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.no_photography_outlined,
                size: 56,
                color: Colors.white70,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                key: const Key('camera_unavailable_gallery_button'),
                onPressed: onAction,
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(actionLabel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
