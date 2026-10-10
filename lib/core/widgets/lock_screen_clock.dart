import 'dart:async';

import 'package:classipod/core/services/lock_screen_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

/// Fills the space the device leaves unused with a clock, laid out the way the
/// iOS lock screen lays its own out: the date on a single line above, the time
/// below in large semibold numerals, and no AM/PM marker.
///
/// By default it only appears while the app is standing in for the lock
/// screen, since the system clock is in the status bar otherwise; setting
/// [isAlwaysVisible] shows it in normal use too.
class LockScreenClock extends StatefulWidget {
  /// The system font on Apple platforms, so the clock matches the one it
  /// stands in for. Elsewhere none of these resolve and the platform default
  /// is used, which beats the Helvetica the rest of the device is set in.
  static const String _fontFamily = '.SF Pro Display';
  static const List<String> _fontFamilyFallback = [
    '.SF Pro Text',
    'SF Pro Display',
    'SF Pro Text',
  ];

  final String localeName;
  final bool isAlwaysVisible;

  /// Colour chosen by the user, or null to read one off the background.
  final Color? color;

  /// How far the clock fades into what is behind it.
  final double opacity;

  /// Set when the wallpaper carried up behind the clock is a pale one, which
  /// white numerals would disappear into. Only consulted while [color] is
  /// null.
  final bool isOnLightBackground;

  const LockScreenClock({
    super.key,
    required this.localeName,
    this.isAlwaysVisible = false,
    this.color,
    this.opacity = 1,
    this.isOnLightBackground = false,
  });

  @override
  State<LockScreenClock> createState() => _LockScreenClockState();
}

class _LockScreenClockState extends State<LockScreenClock> {
  static const Duration _tick = Duration(seconds: 1);

  late Timer _timer;
  DateTime _now = DateTime.now();
  bool _isLocked = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_tick, (_) => _update());
    unawaited(_update());
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _update() async {
    // Showing it unconditionally makes asking the platform pointless.
    final bool isLocked = widget.isAlwaysVisible
        ? true
        : await LockScreenService.isKeyguardLocked();
    if (!mounted) {
      return;
    }
    setState(() {
      _now = DateTime.now();
      _isLocked = isLocked;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLocked) {
      return const SizedBox.shrink();
    }

    final bool use24Hours = MediaQuery.alwaysUse24HourFormatOf(context);
    // The lock screen drops the AM/PM marker, the hour alone is unambiguous
    // enough next to the date.
    final DateFormat timeFormat = DateFormat(
      use24Hours ? 'HH:mm' : 'h:mm',
      widget.localeName,
    );
    final DateFormat dateFormat = DateFormat.MMMMEEEEd(widget.localeName);

    final Color baseColor =
        widget.color ??
        (widget.isOnLightBackground
            ? const Color(0xFF1C1C1E)
            : CupertinoColors.white);
    final Color foregroundColor = baseColor.withValues(alpha: widget.opacity);
    // Keeps the numerals readable wherever the wallpaper happens to be busy,
    // without reading as a drop shadow of their own. It fades with the clock,
    // or a barely visible one would still carry a hard outline.
    final List<Shadow> shadows = [
      Shadow(
        color: (baseColor.computeLuminance() > 0.5
                ? CupertinoColors.black
                : CupertinoColors.white)
            .withValues(alpha: 0.25 * widget.opacity),
        blurRadius: 12,
      ),
    ];

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              dateFormat.format(_now),
              style: TextStyle(
                color: foregroundColor,
                fontFamily: LockScreenClock._fontFamily,
                fontFamilyFallback: LockScreenClock._fontFamilyFallback,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
                height: 1.2,
                shadows: shadows,
              ),
            ),
            Text(
              timeFormat.format(_now),
              style: TextStyle(
                color: foregroundColor,
                fontFamily: LockScreenClock._fontFamily,
                fontFamilyFallback: LockScreenClock._fontFamilyFallback,
                fontSize: 88,
                fontWeight: FontWeight.w600,
                letterSpacing: -2,
                height: 1.05,
                // Fixed width digits, so the layout does not jitter every
                // minute as the numerals change.
                fontFeatures: const [FontFeature.tabularFigures()],
                shadows: shadows,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
