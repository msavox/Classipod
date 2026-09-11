import 'dart:async';
import 'dart:collection';

import 'package:classipod/core/constants/constants.dart';
import 'package:classipod/core/constants/online_audio_files_metadata.dart';
import 'package:classipod/core/controllers/music_scan_controller.dart';
import 'package:classipod/core/models/music_metadata.dart';
import 'package:classipod/features/settings/controller/settings_preferences_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

final audioFilesServiceProvider =
    AsyncNotifierProvider<
      AudioFilesServiceNotifier,
      UnmodifiableListView<MusicMetadata>
    >(AudioFilesServiceNotifier.new);

class AudioFilesServiceNotifier
    extends AsyncNotifier<UnmodifiableListView<MusicMetadata>> {
  @override
  Future<UnmodifiableListView<MusicMetadata>> build() async {
    return getAudioFilesMetadata();
  }

  Future<UnmodifiableListView<MusicMetadata>> getAudioFilesMetadata() async {
    state = const AsyncLoading();
    try {
      if (ref.read(settingsPreferencesControllerProvider).fetchOnlineMusic) {
        return UnmodifiableListView(onlineDemoAudioFilesMetaData);
      }

      final Box<MusicMetadata> metadataBox = Hive.box<MusicMetadata>(
        Constants.metadataBoxName,
      );
      if (metadataBox.isEmpty) {
        // Reading a whole library takes minutes, so the scan runs on an
        // isolate of its own and fills the box in the background. Waiting for
        // it here is what used to look like the app hanging.
        //
        // Started off this build, since Riverpod does not let a provider
        // change another one while it is still initialising.
        unawaited(
          Future<void>.microtask(
            () => ref.read(musicScanControllerProvider.notifier).scanIfNeeded(),
          ),
        );
      }
      return UnmodifiableListView(metadataBox.values);
    } catch (e) {
      return UnmodifiableListView([]);
    }
  }
}
