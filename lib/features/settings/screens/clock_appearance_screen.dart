import 'dart:async';

import 'package:classipod/core/extensions/build_context_extensions.dart';
import 'package:classipod/core/navigation/routes.dart';
import 'package:classipod/features/custom_screen_elements/custom_screen.dart';
import 'package:classipod/features/settings/controller/settings_preferences_controller.dart';
import 'package:classipod/features/settings/models/settings_preferences_model.dart';
import 'package:classipod/features/settings/widgets/color_channel_tile.dart';
import 'package:classipod/features/settings/widgets/selection_list_tile.dart';
import 'package:classipod/features/status_bar/widgets/status_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum _ClockChannel { hue, saturation, brightness, opacity }

/// Picks the colour the clock is drawn in and how far it fades into the
/// wallpaper behind it.
///
/// Built the same way as the custom device colour screen: the wheel moves
/// between the rows, select starts adjusting one, and the wheel then changes
/// its value until select or menu is pressed again.
class ClockAppearanceScreen extends ConsumerStatefulWidget {
  const ClockAppearanceScreen({super.key});

  @override
  ConsumerState createState() => _ClockAppearanceScreenState();
}

class _ClockAppearanceScreenState extends ConsumerState with CustomScreen {
  static const double _hueStep = 4;
  static const double _unitStep = 0.02;

  /// Marks the row that hands the colour back to the clock, which has no
  /// channel of its own.
  static const String _automaticRow = 'automatic';

  late HSVColor _color;
  late double _opacity;
  bool _isAdjusting = false;

  @override
  String get routeName => Routes.clockAppearance.name;

  @override
  List<Object> get displayItems => [..._ClockChannel.values, _automaticRow];

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsPreferencesControllerProvider);
    final int? storedValue = settings.clockColorValue;
    _color = HSVColor.fromColor(
      storedValue == null ? CupertinoColors.white : Color(storedValue),
    );
    _opacity = settings.clockOpacity;
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
    if (displayItems[selectedDisplayItem] == _automaticRow) {
      await _useAutomaticColor();
      return;
    }
    setState(() => _isAdjusting = !_isAdjusting);
  }

  void _changeSelectedChannel(int direction) {
    final Object item = displayItems[selectedDisplayItem];
    if (item is! _ClockChannel) {
      return;
    }
    setState(() {
      switch (item) {
        case _ClockChannel.hue:
          _color = _color.withHue((_color.hue + (direction * _hueStep)) % 360);
        case _ClockChannel.saturation:
          _color = _color.withSaturation(
            (_color.saturation + (direction * _unitStep)).clamp(0.0, 1.0),
          );
        case _ClockChannel.brightness:
          _color = _color.withValue(
            (_color.value + (direction * _unitStep)).clamp(0.0, 1.0),
          );
        case _ClockChannel.opacity:
          _opacity = (_opacity + (direction * _unitStep)).clamp(
            SettingsPreferencesModel.minimumClockOpacity,
            1.0,
          );
      }
    });
    _apply(item);
  }

  void _apply(_ClockChannel channel) {
    final notifier = ref.read(settingsPreferencesControllerProvider.notifier);
    unawaited(
      channel == _ClockChannel.opacity
          ? notifier.setClockOpacity(_opacity)
          : notifier.setClockColor(_color.toColor()),
    );
  }

  Future<void> _useAutomaticColor() async {
    setState(() => _isAdjusting = false);
    await ref
        .read(settingsPreferencesControllerProvider.notifier)
        .setClockColor(null);
  }

  void _setFromDrag(_ClockChannel channel, double fraction) {
    setState(() {
      switch (channel) {
        case _ClockChannel.hue:
          _color = _color.withHue((fraction * 360).clamp(0.0, 359.9));
        case _ClockChannel.saturation:
          _color = _color.withSaturation(fraction.clamp(0.0, 1.0));
        case _ClockChannel.brightness:
          _color = _color.withValue(fraction.clamp(0.0, 1.0));
        case _ClockChannel.opacity:
          _opacity = fraction.clamp(
            SettingsPreferencesModel.minimumClockOpacity,
            1.0,
          );
      }
    });
    _apply(channel);
  }

  double _fractionOf(_ClockChannel channel) {
    switch (channel) {
      case _ClockChannel.hue:
        return _color.hue / 360;
      case _ClockChannel.saturation:
        return _color.saturation;
      case _ClockChannel.brightness:
        return _color.value;
      case _ClockChannel.opacity:
        return _opacity;
    }
  }

  String _titleOf(_ClockChannel channel) {
    switch (channel) {
      case _ClockChannel.hue:
        return context.localization.customDeviceColorHue;
      case _ClockChannel.saturation:
        return context.localization.customDeviceColorSaturation;
      case _ClockChannel.brightness:
        return context.localization.customDeviceColorBrightness;
      case _ClockChannel.opacity:
        return context.localization.clockOpacityTitle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isAutomatic =
        ref.watch(
          settingsPreferencesControllerProvider.select(
            (settings) => settings.clockColorValue,
          ),
        ) ==
        null;

    return CupertinoPageScaffold(
      child: Column(
        children: [
          StatusBar(title: Routes.clockAppearance.title(context)),
          Flexible(
            child: ListView(
              controller: scrollController,
              children: [
                for (int index = 0; index < displayItems.length; index++)
                  if (displayItems[index] case final _ClockChannel channel)
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
                      text: context.localization.useAutomaticClockColor,
                      isSelected: selectedDisplayItem == index,
                      isActive: isAutomatic,
                      onTap: _useAutomaticColor,
                    ),
                ColorPreviewTile(
                  color: _color.toColor().withValues(alpha: _opacity),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
