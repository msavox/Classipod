import 'dart:collection';

import 'package:classipod/core/models/music_metadata.dart';
import 'package:classipod/core/services/audio_files_service.dart';
import 'package:classipod/features/settings/controller/settings_preferences_controller.dart';
import 'package:classipod/features/settings/models/music_folder_node.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final filteredAudioFilesProvider =
    FutureProvider<UnmodifiableListView<MusicMetadata>>((ref) async {
      // Watched before the first await, since Riverpod only allows reading
      // dependencies while the provider body is running synchronously.
      final String? musicRootPath = ref.watch(
        settingsPreferencesControllerProvider.select(
          (settings) => settings.musicRootPath,
        ),
      );

      // Load the audio files metadata
      final audioFilesMetadata = await ref.refresh(
        audioFilesServiceProvider.future,
      );

      final List<MusicMetadata> filteredList = [];
      for (final audioFileMetadata in audioFilesMetadata) {
        final String? parentDirectoryPath =
            audioFileMetadata.parentDirectoryPath;
        // The chosen root applies to everything below it.
        if (musicRootPath != null &&
            (parentDirectoryPath == null ||
                !MusicFolderNode.isUnder(
                  filePath: parentDirectoryPath,
                  rootPath: musicRootPath,
                ))) {
          continue;
        }
        filteredList.add(audioFileMetadata);
      }

      return UnmodifiableListView(filteredList);
    });
