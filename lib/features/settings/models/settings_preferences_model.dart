import 'package:classipod/features/settings/models/app_theme.dart';
import 'package:classipod/features/settings/models/click_wheel_sensitivity.dart';
import 'package:classipod/features/settings/models/click_wheel_size.dart';
import 'package:classipod/features/settings/models/device_color.dart';
import 'package:classipod/features/settings/models/device_finish.dart';
import 'package:classipod/features/settings/models/repeat_mode.dart';
import 'package:classipod/features/settings/models/volume_mode.dart';

class SettingsPreferencesModel {
  final String languageLocaleCode;
  final DeviceColor deviceColor;
  final ClickWheelSize clickWheelSize;
  final ClickWheelSensitivity clickWheelSensitivity;
  final bool isTouchScreenEnabled;
  final RepeatMode repeatMode;
  final bool vibrate;
  final bool clickWheelSound;
  final VolumeMode volumeMode;
  final bool splitScreenEnabled;
  final bool immersiveMode;
  final String? musicRootPath;
  final DeviceFinish deviceFinish;
  final int? customDeviceColorValue;
  final String? deviceTexture;
  final bool screenUsageKeepsWallpaper;
  final bool alwaysShowClock;
  final int screenUsagePercentage;
  final bool showOnLockScreen;
  final bool fetchOnlineMusic;
  final AppTheme appTheme;

  SettingsPreferencesModel({
    required this.languageLocaleCode,
    required this.deviceColor,
    required this.clickWheelSize,
    required this.clickWheelSensitivity,
    required this.isTouchScreenEnabled,
    required this.repeatMode,
    required this.vibrate,
    required this.clickWheelSound,
    required this.volumeMode,
    required this.splitScreenEnabled,
    required this.immersiveMode,
    this.musicRootPath,
    this.deviceFinish = DeviceFinish.classic,
    this.customDeviceColorValue,
    this.deviceTexture,
    this.screenUsageKeepsWallpaper = false,
    this.alwaysShowClock = false,
    required this.screenUsagePercentage,
    required this.showOnLockScreen,
    required this.appTheme,
    this.fetchOnlineMusic = false,
  });

  SettingsPreferencesModel copyWith({
    String? languageLocaleCode,
    DeviceColor? deviceColor,
    ClickWheelSize? clickWheelSize,
    ClickWheelSensitivity? clickWheelSensitivity,
    bool? isTouchScreenEnabled,
    RepeatMode? repeatMode,
    bool? vibrate,
    bool? clickWheelSound,
    VolumeMode? volumeMode,
    bool? splitScreenEnabled,
    bool? immersiveMode,
    String? musicRootPath,
    bool clearMusicRootPath = false,
    DeviceFinish? deviceFinish,
    int? customDeviceColorValue,
    bool clearCustomDeviceColor = false,
    String? deviceTexture,
    bool clearDeviceTexture = false,
    bool? screenUsageKeepsWallpaper,
    bool? alwaysShowClock,
    int? screenUsagePercentage,
    bool? showOnLockScreen,
    bool? fetchOnlineMusic,
    AppTheme? appTheme,
  }) {
    return SettingsPreferencesModel(
      languageLocaleCode: languageLocaleCode ?? this.languageLocaleCode,
      deviceColor: deviceColor ?? this.deviceColor,
      clickWheelSize: clickWheelSize ?? this.clickWheelSize,
      clickWheelSensitivity:
          clickWheelSensitivity ?? this.clickWheelSensitivity,
      isTouchScreenEnabled: isTouchScreenEnabled ?? this.isTouchScreenEnabled,
      repeatMode: repeatMode ?? this.repeatMode,
      vibrate: vibrate ?? this.vibrate,
      clickWheelSound: clickWheelSound ?? this.clickWheelSound,
      volumeMode: volumeMode ?? this.volumeMode,
      splitScreenEnabled: splitScreenEnabled ?? this.splitScreenEnabled,
      immersiveMode: immersiveMode ?? this.immersiveMode,
      musicRootPath: clearMusicRootPath
          ? null
          : (musicRootPath ?? this.musicRootPath),
      deviceFinish: deviceFinish ?? this.deviceFinish,
      customDeviceColorValue: clearCustomDeviceColor
          ? null
          : (customDeviceColorValue ?? this.customDeviceColorValue),
      deviceTexture: clearDeviceTexture
          ? null
          : (deviceTexture ?? this.deviceTexture),
      screenUsageKeepsWallpaper:
          screenUsageKeepsWallpaper ?? this.screenUsageKeepsWallpaper,
      alwaysShowClock: alwaysShowClock ?? this.alwaysShowClock,
      screenUsagePercentage:
          screenUsagePercentage ?? this.screenUsagePercentage,
      showOnLockScreen: showOnLockScreen ?? this.showOnLockScreen,
      appTheme: appTheme ?? this.appTheme,
      fetchOnlineMusic: fetchOnlineMusic ?? this.fetchOnlineMusic,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SettingsPreferencesModel &&
        other.languageLocaleCode == languageLocaleCode &&
        other.deviceColor == deviceColor &&
        other.clickWheelSize == clickWheelSize &&
        other.clickWheelSensitivity == clickWheelSensitivity &&
        other.isTouchScreenEnabled == isTouchScreenEnabled &&
        other.repeatMode == repeatMode &&
        other.vibrate == vibrate &&
        other.clickWheelSound == clickWheelSound &&
        other.volumeMode == volumeMode &&
        other.splitScreenEnabled == splitScreenEnabled &&
        other.immersiveMode == immersiveMode &&
        other.musicRootPath == musicRootPath &&
        other.deviceFinish == deviceFinish &&
        other.customDeviceColorValue == customDeviceColorValue &&
        other.deviceTexture == deviceTexture &&
        other.screenUsageKeepsWallpaper == screenUsageKeepsWallpaper &&
        other.alwaysShowClock == alwaysShowClock &&
        other.screenUsagePercentage == screenUsagePercentage &&
        other.showOnLockScreen == showOnLockScreen &&
        other.fetchOnlineMusic == fetchOnlineMusic &&
        other.appTheme == appTheme;
  }

  @override
  int get hashCode => Object.hashAll([
    languageLocaleCode,
    deviceColor,
    clickWheelSize,
    clickWheelSensitivity,
    isTouchScreenEnabled,
    repeatMode,
    vibrate,
    clickWheelSound,
    volumeMode,
    splitScreenEnabled,
    immersiveMode,
    musicRootPath,
    deviceFinish,
    customDeviceColorValue,
    deviceTexture,
    screenUsageKeepsWallpaper,
    alwaysShowClock,
    screenUsagePercentage,
    showOnLockScreen,
    appTheme,
    fetchOnlineMusic,
  ]);
}
