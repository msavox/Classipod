import 'dart:async';

import 'package:classipod/core/controllers/music_scan_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Thin coloured line along the bottom of the screen while the library is
/// being scanned.
///
/// The scan no longer holds the app up, so this is the only thing saying it is
/// running; it stays out of the way of whatever screen is up.
class MusicScanIndicator extends ConsumerStatefulWidget {
  static const double thickness = 3;

  const MusicScanIndicator({super.key});

  @override
  ConsumerState<MusicScanIndicator> createState() => _MusicScanIndicatorState();
}

class _MusicScanIndicatorState extends ConsumerState<MusicScanIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final MusicScanState scanState = ref.watch(musicScanControllerProvider);

    // Nothing to animate once the scan is through, and a ticker left running
    // would keep the whole app repainting.
    if (scanState.isScanning != _controller.isAnimating) {
      if (scanState.isScanning) {
        unawaited(_controller.repeat());
      } else {
        _controller.stop();
      }
    }

    if (!scanState.isScanning) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: SizedBox(
        height: MusicScanIndicator.thickness,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            painter: _ScanLinePainter(
              completedFraction: scanState.completedFraction,
              phase: _controller.value,
            ),
          ),
        ),
      ),
    );
  }
}

class _ScanLinePainter extends CustomPainter {
  /// Repeated as the line scrolls, so the first and last colour have to match
  /// or the loop would show a seam.
  static const List<Color> _colors = [
    CupertinoColors.systemBlue,
    CupertinoColors.systemPurple,
    CupertinoColors.systemPink,
    CupertinoColors.systemOrange,
    CupertinoColors.systemBlue,
  ];

  /// Share of the line taken by the travelling segment while the scan does not
  /// yet know how many files it has to go through.
  static const double _indeterminateSegmentFraction = 0.35;

  final double? completedFraction;
  final double phase;

  const _ScanLinePainter({
    required this.completedFraction,
    required this.phase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }

    final Radius radius = Radius.circular(size.height / 2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, radius),
      Paint()..color = CupertinoColors.white.withValues(alpha: 0.12),
    );

    final double? fraction = completedFraction;
    final Rect fill;
    if (fraction == null) {
      final double segmentWidth = size.width * _indeterminateSegmentFraction;
      final double left = (size.width + segmentWidth) * phase - segmentWidth;
      fill = Rect.fromLTWH(left, 0, segmentWidth, size.height);
    } else {
      fill = Rect.fromLTWH(0, 0, size.width * fraction, size.height);
    }
    if (fill.width <= 0) {
      return;
    }

    // Scrolling the shader rather than the colours keeps the line moving even
    // when the scan sits on the same file for a while.
    final Paint paint = Paint()
      ..shader = const LinearGradient(
        colors: _colors,
        tileMode: TileMode.repeated,
      ).createShader(
        Rect.fromLTWH(-size.width * phase, 0, size.width, size.height),
      );
    canvas.drawRRect(RRect.fromRectAndRadius(fill, radius), paint);
  }

  @override
  bool shouldRepaint(_ScanLinePainter oldDelegate) {
    return oldDelegate.phase != phase ||
        oldDelegate.completedFraction != completedFraction;
  }
}
