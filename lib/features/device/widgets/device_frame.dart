import 'package:classipod/core/constants/keys.dart';
import 'package:classipod/core/providers/device_appearance_provider.dart';
import 'package:classipod/core/widgets/device_background_scope.dart';
import 'package:classipod/features/device/widgets/device_controls.dart';
import 'package:classipod/features/device/widgets/device_frame_edge_shadows.dart';
import 'package:classipod/features/device/widgets/device_screen.dart';
import 'package:classipod/features/settings/models/device_appearance.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DeviceFrame extends ConsumerWidget {
  final Widget child;

  const DeviceFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DeviceAppearance appearance = ref.watch(deviceAppearanceProvider);
    // An ancestor painting the background spans the area above the frame too,
    // so repainting it here would cut the wallpaper in two.
    final bool isBackgroundPainted = DeviceBackgroundScope.isPaintedByAncestorOf(
      context,
    );

    return DecoratedBox(
      decoration: isBackgroundPainted
          ? const BoxDecoration()
          : appearance.frameDecoration,
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          if (!isBackgroundPainted) const DeviceFrameEdgeShadows(),
          SafeArea(
            minimum: const EdgeInsets.fromLTRB(20, 30, 20, 20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 960,
                  maxWidth: 450,
                ),
                child: Column(
                  children: [
                    DeviceScreen(key: deviceScreenGlobalKey, child: child),
                    const Spacer(flex: 2),
                    DeviceControls(key: deviceControlsGlobalKey),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
