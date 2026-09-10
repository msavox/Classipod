import 'dart:async';

import 'package:classipod/core/services/lock_screen_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

/// Fills the space the device leaves unused with a clock.
///
/// By default it only appears while the app is standing in for the lock
/// screen, since the system clock is in the status bar otherwise; setting
/// [isAlwaysVisible] shows it in normal use too.
class LockScreenClock extends StatefulWidget {
  /// Kept slightly transparent so it reads as part of the unused area rather
  /// than as another screen of the device.
  static const double opacity = 0.9;

  final String localeName;
  final bool isAlwaysVisible;

  const LockScreenClock({
    super.key,
    required this.localeName,
    this.isAlwaysVisible = false,
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
    final DateFormat timeFormat = DateFormat(
      use24Hours ? 'HH:mm' : 'h:mm a',
      widget.localeName,
    );
    final DateFormat dateFormat = DateFormat.MMMMEEEEd(widget.localeName);

    return Opacity(
      opacity: LockScreenClock.opacity,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                timeFormat.format(_now),
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 68,
                  fontWeight: FontWeight.w200,
                  letterSpacing: -1,
                ),
              ),
              Text(
                dateFormat.format(_now),
                style: const TextStyle(
                  color: CupertinoColors.systemGrey,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
