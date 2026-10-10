import 'dart:math' as math;

import 'package:classipod/core/providers/device_appearance_provider.dart';
import 'package:classipod/core/services/lock_screen_service.dart';
import 'package:classipod/core/widgets/device_background_scope.dart';
import 'package:classipod/core/widgets/lock_screen_clock.dart';
import 'package:classipod/features/device/widgets/device_frame_edge_shadows.dart';
import 'package:classipod/features/settings/controller/settings_preferences_controller.dart';
import 'package:classipod/features/settings/models/click_wheel_size.dart';
import 'package:classipod/features/settings/models/device_appearance.dart';
import 'package:classipod/features/settings/models/screen_usage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Restricts the app to the bottom `screenUsagePercentage` of the available
/// height and fills the unused area at the top, either solid black or with the
/// device wallpaper carried on upwards.
///
/// While the device stands in for the lock screen, that area shows a clock,
/// since the system one is not on screen then.
class ScreenUsageWrapper extends ConsumerWidget {
  final Widget child;

  const ScreenUsageWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int screenUsagePercentage = ref.watch(
      settingsPreferencesControllerProvider.select(
        (settings) => settings.screenUsagePercentage,
      ),
    );
    final ClickWheelSize clickWheelSize = ref.watch(
      settingsPreferencesControllerProvider.select(
        (settings) => settings.clickWheelSize,
      ),
    );

    // The click wheel has to stay reachable, so it caps how far the device is
    // allowed to shrink, whatever was stored in the preferences.
    final int effectivePercentage = math.max(
      screenUsagePercentage,
      ScreenUsage.minimumUsagePercentage(context, clickWheelSize),
    );

    if (effectivePercentage >= ScreenUsage.fullUsagePercentage) {
      return child;
    }

    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final double fullHeight = mediaQuery.size.height;
    final double usedHeight =
        fullHeight * effectivePercentage / ScreenUsage.fullUsagePercentage;
    final double blackedOutHeight = fullHeight - usedHeight;

    // The blacked out area already covers the status bar and any notch, so the
    // insets it was compensating for have to be removed from the child.
    double shrinkTop(double inset) => math.max(0, inset - blackedOutHeight);

    final bool alwaysShowClock = ref.watch(
      settingsPreferencesControllerProvider.select(
        (settings) => settings.alwaysShowClock,
      ),
    );
    final bool showOnLockScreen = ref.watch(
      settingsPreferencesControllerProvider.select(
        (settings) => settings.showOnLockScreen,
      ),
    );
    final String languageLocaleCode = ref.watch(
      settingsPreferencesControllerProvider.select(
        (settings) => settings.languageLocaleCode,
      ),
    );
    final bool keepsWallpaper = ref.watch(
      settingsPreferencesControllerProvider.select(
        (settings) => settings.screenUsageKeepsWallpaper,
      ),
    );
    final int? clockColorValue = ref.watch(
      settingsPreferencesControllerProvider.select(
        (settings) => settings.clockColorValue,
      ),
    );
    final double clockOpacity = ref.watch(
      settingsPreferencesControllerProvider.select(
        (settings) => settings.clockOpacity,
      ),
    );
    final DeviceAppearance appearance = ref.watch(deviceAppearanceProvider);

    final Widget body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: blackedOutHeight,
          child:
              alwaysShowClock ||
                  (showOnLockScreen && LockScreenService.isSupported)
              ? SafeArea(
                  bottom: false,
                  child: LockScreenClock(
                    localeName: languageLocaleCode,
                    isAlwaysVisible: alwaysShowClock,
                    color: clockColorValue == null
                        ? null
                        : Color(clockColorValue),
                    opacity: clockOpacity,
                    // Only a pale wallpaper carried upwards needs dark hands;
                    // the blacked out area never does.
                    isOnLightBackground:
                        keepsWallpaper && !appearance.style.isDark,
                  ),
                )
              : null,
        ),
        SizedBox(
          height: usedHeight,
          child: MediaQuery(
            data: mediaQuery.copyWith(
              size: Size(mediaQuery.size.width, usedHeight),
              padding: mediaQuery.padding.copyWith(
                top: shrinkTop(mediaQuery.padding.top),
              ),
              viewPadding: mediaQuery.viewPadding.copyWith(
                top: shrinkTop(mediaQuery.viewPadding.top),
              ),
              viewInsets: mediaQuery.viewInsets.copyWith(
                top: shrinkTop(mediaQuery.viewInsets.top),
              ),
            ),
            child: child,
          ),
        ),
      ],
    );

    if (!keepsWallpaper) {
      return DeviceBackgroundScope(
        isPaintedByAncestor: false,
        child: ColoredBox(color: CupertinoColors.black, child: body),
      );
    }

    // Painted once over the full height, edge shadows included, so the frame
    // below carries on the same gradient and texture instead of starting over.
    return DeviceBackgroundScope(
      isPaintedByAncestor: true,
      child: DecoratedBox(
        decoration: appearance.frameDecoration,
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [const DeviceFrameEdgeShadows(), body],
        ),
      ),
    );
  }
}
