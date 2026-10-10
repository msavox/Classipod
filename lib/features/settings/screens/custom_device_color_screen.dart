import 'dart:async';

import 'package:classipod/core/extensions/build_context_extensions.dart';
import 'package:classipod/core/navigation/routes.dart';
import 'package:classipod/features/custom_screen_elements/custom_screen.dart';
import 'package:classipod/features/settings/controller/settings_preferences_controller.dart';
import 'package:classipod/features/settings/widgets/color_channel_tile.dart';
import 'package:classipod/features/settings/widgets/selection_list_tile.dart';
import 'package:classipod/features/status_bar/widgets/status_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum _ColorChannel { hue, saturation, brightness }

/// Picks an arbitrary device colour with three sliders.
///
/// The click wheel moves between the rows as everywhere else; pressing select
/// on a slider starts adjusting it, and then the wheel changes its value until
/// select or menu is pressed again.
class CustomDeviceColorScreen extends ConsumerStatefulWidget {
  const CustomDeviceColorScreen({super.key});

  @override
  ConsumerState createState() => _CustomDeviceColorScreenState();
}

class _CustomDeviceColorScreenState extends ConsumerState with CustomScreen {
  static const double _hueStep = 4;
  static const double _unitStep = 0.02;

  /// Marks the row that clears the custom colour, which has no channel.
  static const String _presetRow = 'preset';

  late HSVColor _color;
  bool _isAdjusting = false;

  @override
  String get routeName => Routes.customDeviceColor.name;

  @override
  List<Object> get displayItems => [..._ColorChannel.values, _presetRow];

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsPreferencesControllerProvider);
    final int? storedValue = settings.customDeviceColorValue;
    _color = HSVColor.fromColor(
      storedValue != null
          ? Color(storedValue)
          : settings.deviceColor.style.frameGradientColors.last,
    );
  }

  @override
  void scrollForward() {
    if (_isAdjusting) {
      _changeSelectedChannel(1);
      return;
    }
    super.scrollForward();
  }

  @override
  void scrollBackward() {
    if (_isAdjusting) {
      _changeSelectedChannel(-1);
      return;
    }
    super.scrollBackward();
  }

  @override
  void onMenuButtonPressed() {
    if (_isAdjusting) {
      setState(() => _isAdjusting = false);
      return;
    }
    super.onMenuButtonPressed();
  }

  @override
  Future<void> onSelectPressed() async {
    if (displayItems[selectedDisplayItem] == _presetRow) {
      await _usePresetColor();
      return;
    }
    setState(() => _isAdjusting = !_isAdjusting);
  }

  void _changeSelectedChannel(int direction) {
    final Object item = displayItems[selectedDisplayItem];
    if (item is! _ColorChannel) {
      return;
    }
    setState(() {
      switch (item) {
        case _ColorChannel.hue:
          _color = _color.withHue((_color.hue + (direction * _hueStep)) % 360);
        case _ColorChannel.saturation:
          _color = _color.withSaturation(
            (_color.saturation + (direction * _unitStep)).clamp(0.0, 1.0),
          );
        case _ColorChannel.brightness:
          _color = _color.withValue(
            (_color.value + (direction * _unitStep)).clamp(0.0, 1.0),
          );
      }
    });
    _applyColor();
  }

  void _applyColor() {
    unawaited(
      ref
          .read(settingsPreferencesControllerProvider.notifier)
          .setCustomDeviceColor(_color.toColor()),
    );
  }

  Future<void> _usePresetColor() async {
    setState(() => _isAdjusting = false);
    await ref
        .read(settingsPreferencesControllerProvider.notifier)
        .setCustomDeviceColor(null);
  }

  void _setFromDrag(_ColorChannel channel, double fraction) {
    setState(() {
      switch (channel) {
        case _ColorChannel.hue:
          _color = _color.withHue((fraction * 360).clamp(0.0, 359.9));
        case _ColorChannel.saturation:
          _color = _color.withSaturation(fraction.clamp(0.0, 1.0));
        case _ColorChannel.brightness:
          _color = _color.withValue(fraction.clamp(0.0, 1.0));
      }
    });
    _applyColor();
  }

  double _fractionOf(_ColorChannel channel) {
    switch (channel) {
      case _ColorChannel.hue:
        return _color.hue / 360;
      case _ColorChannel.saturation:
        return _color.saturation;
      case _ColorChannel.brightness:
        return _color.value;
    }
  }

  String _titleOf(_ColorChannel channel) {
    switch (channel) {
      case _ColorChannel.hue:
        return context.localization.customDeviceColorHue;
      case _ColorChannel.saturation:
        return context.localization.customDeviceColorSaturation;
      case _ColorChannel.brightness:
        return context.localization.customDeviceColorBrightness;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasCustomColor =
        ref.watch(
          settingsPreferencesControllerProvider.select(
            (settings) => settings.customDeviceColorValue,
          ),
        ) !=
        null;

    return CupertinoPageScaffold(
      child: Column(
        children: [
          StatusBar(title: Routes.customDeviceColor.title(context)),
          Flexible(
            child: ListView(
              controller: scrollController,
              children: [
                for (int index = 0; index < displayItems.length; index++)
                  if (displayItems[index] case final _ColorChannel channel)
                    ColorChannelTile(
                      title: _titleOf(channel),
                      fraction: _fractionOf(channel),
                      isSelected: selectedDisplayItem == index,
                      isAdjusting: _isAdjusting && selectedDisplayItem == index,
                      onTap: () => setState(() {
                        if (selectedDisplayItem == index) {
                          _isAdjusting = !_isAdjusting;
                        } else {
                          selectedDisplayItem = index;
                          _isAdjusting = false;
                        }
                      }),
                      onDrag: (fraction) => _setFromDrag(channel, fraction),
                    )
                  else
                    SelectionListTile(
                      text: context.localization.usePresetDeviceColor,
                      isSelected: selectedDisplayItem == index,
                      isActive: !hasCustomColor,
                      onTap: _usePresetColor,
                    ),
                ColorPreviewTile(color: _color.toColor()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
