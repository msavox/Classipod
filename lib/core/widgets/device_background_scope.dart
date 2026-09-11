import 'package:flutter/widgets.dart';

/// Tells the device widgets that an ancestor already painted the device
/// background, edge shadows included, across the whole screen.
///
/// [ScreenUsageWrapper] does that when the area left unused keeps the
/// wallpaper: a frame painting its own background underneath would restart the
/// gradient and lay its top edge shadow right below the clock, which reads as a
/// seam across the wallpaper.
class DeviceBackgroundScope extends InheritedWidget {
  final bool isPaintedByAncestor;

  const DeviceBackgroundScope({
    super.key,
    required this.isPaintedByAncestor,
    required super.child,
  });

  static bool isPaintedByAncestorOf(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<DeviceBackgroundScope>()
            ?.isPaintedByAncestor ??
        false;
  }

  @override
  bool updateShouldNotify(DeviceBackgroundScope oldWidget) =>
      oldWidget.isPaintedByAncestor != isPaintedByAncestor;
}
