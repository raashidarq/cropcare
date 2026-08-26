// lib/presentation/shared/widgets/tutorial_overlay.dart
//
// A guided walkthrough that points at the real screen.
//
// Deliberately NOT another carousel of illustrated slides. Onboarding already
// answers "what is this app for", before the farmer has seen anything. This
// answers "where do I tap", and the honest way to do that is to point at the
// actual button rather than at a drawing of one — a farmer who has just been
// shown four pictures still arrives at a screen they have never seen.
//
// Built for the audience:
//
//  * One idea per step, one short sentence. Anyone who reads slowly can take
//    it at their own pace, and nothing moves on its own.
//  * The spotlight is the explanation. Even skipping every word, the sequence
//    of highlighted controls shows the path through the app.
//  * Skippable from the first step, and replayable from Settings. A tutorial
//    that cannot be dismissed is a hostage situation.
//  * Steps whose target is not on screen are dropped rather than pointing at
//    nothing — the History tab does not exist for a user with no scans yet.

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../onboarding/localization/localization_provider.dart';

/// One stop on the walkthrough.
class TutorialStep {
  /// The widget to spotlight. Attach the same key to the real control.
  final GlobalKey targetKey;
  final String titleKey;
  final String bodyKey;

  /// Extra breathing room around the target, for controls that sit tight
  /// against their own padding.
  final double padding;

  const TutorialStep({
    required this.targetKey,
    required this.titleKey,
    required this.bodyKey,
    this.padding = 8,
  });
}

/// Shows [steps] over the current screen. Completes when the walkthrough is
/// finished or skipped.
Future<void> showTutorial(
  BuildContext context,
  List<TutorialStep> steps,
) async {
  // A target that never laid out has no rect to point at. Rendering a
  // spotlight on empty space would be worse than skipping the step.
  final usable = steps.where((s) {
    final box = s.targetKey.currentContext?.findRenderObject();
    return box is RenderBox && box.hasSize;
  }).toList();
  if (usable.isEmpty) return;

  await Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierDismissible: false,
      // The point of the overlay is that the real screen shows through it.
      barrierColor: Colors.transparent,
      pageBuilder: (_, _, _) => _TutorialView(steps: usable),
    ),
  );
}

class _TutorialView extends StatefulWidget {
  final List<TutorialStep> steps;

  const _TutorialView({required this.steps});

  @override
  State<_TutorialView> createState() => _TutorialViewState();
}

class _TutorialViewState extends State<_TutorialView> {
  int _index = 0;

  TutorialStep get _step => widget.steps[_index];
  bool get _isLast => _index == widget.steps.length - 1;

  Rect? _targetRect() {
    final box = _step.targetKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    final origin = box.localToGlobal(Offset.zero);
    return Rect.fromLTWH(
      origin.dx,
      origin.dy,
      box.size.width,
      box.size.height,
    ).inflate(_step.padding);
  }

  void _next() {
    if (_isLast) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _index++);
  }

  @override
  Widget build(BuildContext context) {
    final rect = _targetRect();
    final screen = MediaQuery.sizeOf(context);

    // Put the caption on whichever side of the spotlight has more room, so it
    // never lands under the thing it is describing.
    final below = rect == null || rect.center.dy < screen.height / 2;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // Absorbs every tap, so a farmer cannot half-follow the tutorial
          // and half-drive the app underneath it.
          Positioned.fill(
            child: GestureDetector(
              onTap: _next,
              child: CustomPaint(
                painter: _SpotlightPainter(rect: rect),
                size: Size.infinite,
              ),
            ),
          ),
          Positioned(
            left: AppSpacing.md,
            right: AppSpacing.md,
            top: below && rect != null ? rect.bottom + AppSpacing.md : null,
            // `below` is already true whenever rect is null, so reaching
            // here means there is a rect to sit above.
            bottom: below ? null : screen.height - rect.top + AppSpacing.md,
            child: _Caption(
              step: _step,
              index: _index,
              total: widget.steps.length,
              isLast: _isLast,
              onNext: _next,
              onSkip: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dims everything except the target.
class _SpotlightPainter extends CustomPainter {
  final Rect? rect;

  const _SpotlightPainter({this.rect});

  @override
  void paint(Canvas canvas, Size size) {
    final scrim = Paint()..color = const Color(0xCC000000);
    final full = Rect.fromLTWH(0, 0, size.width, size.height);

    if (rect == null) {
      canvas.drawRect(full, scrim);
      return;
    }

    // Punch the hole by combining paths rather than blend modes: blend modes
    // need a saveLayer and behave differently across renderers.
    final hole = RRect.fromRectAndRadius(rect!, const Radius.circular(12));
    final path = Path.combine(
      PathOperation.difference,
      Path()..addRect(full),
      Path()..addRRect(hole),
    );
    canvas.drawPath(path, scrim);

    canvas.drawRRect(
      hole,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = AppColors.onPrimary,
    );
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) => old.rect != rect;
}

class _Caption extends StatelessWidget {
  final TutorialStep step;
  final int index;
  final int total;
  final bool isLast;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const _Caption({
    required this.step,
    required this.index,
    required this.total,
    required this.isLast,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr(step.titleKey), style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(context.tr(step.bodyKey), style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              // Dots, not "3 of 5": a count is another thing to read, and the
              // dots say the same thing without words.
              for (var i = 0; i < total; i++)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == index
                          ? AppColors.primary
                          : AppColors.outlineVariant,
                    ),
                  ),
                ),
              const Spacer(),
              // Available from the first step. A tutorial you cannot leave is
              // a hostage situation.
              if (!isLast)
                TextButton(
                  key: const Key('tutorial_skip_button'),
                  onPressed: onSkip,
                  child: Text(context.tr('skip')),
                ),
              const SizedBox(width: AppSpacing.sm),
              ElevatedButton(
                key: const Key('tutorial_next_button'),
                onPressed: onNext,
                child: Text(
                  isLast ? context.tr('tutorial_done') : context.tr('next'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
