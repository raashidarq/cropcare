// lib/presentation/scan/widgets/leaf_frame_overlay.dart
//
// Framing guide drawn over the live camera preview.
//
// Why this exists: the model is trained on PlantVillage, which is close-up,
// single-leaf, centre-framed imagery. A farmer photographing a whole plant
// from two metres away is feeding it something quite unlike its training set,
// which is one of the ways it produces confident nonsense. A visible target
// is the cheapest way to nudge capture toward what the model can actually
// read — it guides framing, it does not crop or enforce anything.

import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

class LeafFrameOverlay extends StatelessWidget {
  /// Short instruction shown under the frame, e.g. "Fill the frame with one leaf".
  final String hint;

  const LeafFrameOverlay({super.key, required this.hint});

  @override
  Widget build(BuildContext context) {
    // Decorative: the hint text below is the accessible version of this, so
    // don't announce the painted frame separately.
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.biggest.shortestSide * 0.72;
        return Stack(
          alignment: Alignment.center,
          children: [
            ExcludeSemantics(
              child: CustomPaint(
                size: Size(constraints.maxWidth, constraints.maxHeight),
                painter: _FramePainter(side: side),
              ),
            ),
            Positioned(
              bottom: constraints.maxHeight / 2 - side / 2 - 56,
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              child: _HintPill(text: hint),
            ),
          ],
        );
      },
    );
  }
}

class _HintPill extends StatelessWidget {
  final String text;

  const _HintPill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          // Solid-ish scrim: this sits over an unpredictable camera image, so
          // the text needs its own dependable background to stay readable.
          color: Colors.black.withValues(alpha: 0.62),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white,
              ),
        ),
      ),
    );
  }
}

class _FramePainter extends CustomPainter {
  final double side;

  const _FramePainter({required this.side});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: side,
      height: side,
    );
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(24));

    // Dim everything outside the target so the eye goes to the centre.
    final scrim = Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      Path()..addRRect(rrect),
    );
    canvas.drawPath(scrim, Paint()..color = Colors.black.withValues(alpha: 0.42));

    // Corner brackets rather than a full outline: less visual noise over a
    // busy leaf, and a familiar "aim here" convention from camera UIs.
    final stroke = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const armLength = 28.0;
    const r = 24.0;

    void corner(Offset start, Offset joint, Offset end) {
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..lineTo(joint.dx, joint.dy)
        ..lineTo(end.dx, end.dy);
      canvas.drawPath(path, stroke);
    }

    // Top-left
    corner(
      Offset(rect.left, rect.top + r + armLength),
      Offset(rect.left, rect.top + r),
      Offset(rect.left + r + armLength - r, rect.top),
    );
    // Top-right
    corner(
      Offset(rect.right - r - armLength + r, rect.top),
      Offset(rect.right, rect.top + r),
      Offset(rect.right, rect.top + r + armLength),
    );
    // Bottom-right
    corner(
      Offset(rect.right, rect.bottom - r - armLength),
      Offset(rect.right, rect.bottom - r),
      Offset(rect.right - r - armLength + r, rect.bottom),
    );
    // Bottom-left
    corner(
      Offset(rect.left + r + armLength - r, rect.bottom),
      Offset(rect.left, rect.bottom - r),
      Offset(rect.left, rect.bottom - r - armLength),
    );
  }

  @override
  bool shouldRepaint(covariant _FramePainter oldDelegate) =>
      oldDelegate.side != side;
}
