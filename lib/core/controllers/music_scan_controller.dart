import 'dart:io';

import 'package:classipod/core/constants/constants.dart';
import 'package:classipod/core/models/music_metadata.dart';
import 'package:classipod/core/providers/device_directory_provider.dart';
import 'package:classipod/core/repositories/metadata_reader_repository.dart';
import 'package:classipod/core/services/music_scan_service.dart';
import 'package:classipod/features/settings/controller/settings_preferences_controller.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:on_audio_query/on_audio_query.dart';

final musicScanControllerProvider =
    NotifierProvider<MusicScanNotifier, MusicScanState>(MusicScanNotifier.new);

@immutable
class MusicScanState {
  final bool isScanning;
  final int scannedFilesCount;
  final int totalFilesCount;

  const MusicScanState({
    this.isScanning = false,
    this.scannedFilesCount = 0,
    this.totalFilesCount = 0,
  });

  /// Null while the scan is still listing folders and does not yet know how
  /// many files it is going through.
  double? get completedFraction {
    if (totalFilesCount <= 0) {
      return null;
    }
    return (scannedFilesCount / totalFilesCount).clamp(0.0, 1.0);
  }
}

/// Reads the music library on a background isolate.
///
/// Nothing waits for it: the app carries on with whatever is already in the
/// metadata box and picks the new tracks up once the scan is through, so a
/// library of a few thousand files no longer holds the splash screen for
/// minutes on end.
class MusicScanNotifier extends Notifier<MusicScanState> {
  /// A folder without any playable file leaves the metadata box empty, which
  /// is the very condition that asks for a scan. Remembering that one already
  /// ran is what stops that from looping.
  bool _hasScanned = false;

  @override
  MusicScanState build() {
    // The flag above has to outlive the screens that happen to be watching.
    ref.keepAlive();
    return const MusicScanState();
  }

  /// Starts a scan unless one already ran or is still running.
  Future<void> scanIfNeeded() async {
    if (_hasScanned || state.isScanning) {
      return;
    }
    await scan();
  }

  /// Lets the next [scanIfNeeded] scan again, after the metadata box was
  /// emptied on purpose.
  void forgetPreviousScan() {
    _hasScanned = false;
  }

  Future<void> scan() async {
    if (state.isScanning) {
      return;
    }
    _hasScanned = true;
    state = const MusicScanState(isScanning: true);

    try {
      final MusicScanSource? source = await _resolveSource();
      if (source == null) {
        state = const MusicScanState();
        return;
      }

      final List<MusicMetadata> result = await MusicScanService.scan(
        source: source,
        thumbnailsDirectoryPath: ref
            .read(metadataReaderRepositoryProvider)
            .thumbnailsDirectoryPath,
        onProgress: (progress) {
          state = MusicScanState(
            isScanning: true,
            scannedFilesCount: progress.scannedFilesCount,
            totalFilesCount: progress.totalFilesCount,
          );
        },
      );

      final Box<MusicMetadata> metadataBox = Hive.box<MusicMetadata>(
        Constants.metadataBoxName,
      );
      await metadataBox.clear();
      await metadataBox.addAll(result);
      state = const MusicScanState();

      // Reloading an empty result would only ask for the scan that just came
      // up empty all over again.
      if (result.isNotEmpty) {
        await ref
            .read(settingsPreferencesControllerProvider.notifier)
            .reloadLibrary();
      }
    } on Object catch (error) {
      debugPrint('Music scan failed: $error');
      state = const MusicScanState();
    }
  }

  /// Asks the platform what to scan. Desktop and iOS put a picker in front of
  /// the user, so this has to stay on the main isolate.
  Future<MusicScanSource?> _resolveSource() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final String? directoryPath = await FilePicker.getDirectoryPath(
        dialogTitle: "Select Music Directory",
        lockParentWindow: true,
        initialDirectory: ref
            .read(deviceDirectoryProvider)
            .requireValue
            .musicFolderPath,
      );
      return directoryPath == null
          ? null
          : MusicScanSource.directory(directoryPath);
    }

    if (Platform.isIOS) {
      final FilePickerResult? pickedFiles = await FilePicker.pickFiles(
        allowMultiple: true,
        dialogTitle: "Pick Song Files",
      );
      if (pickedFiles == null || pickedFiles.files.isEmpty) {
        return null;
      }
      return MusicScanSource.files(
        pickedFiles.files.map((file) => file.path!).toList(),
      );
    }

    // Android hands over the files it already indexed, no picker needed.
    final List<SongModel> queriedSongs = await OnAudioQuery().querySongs();
    return MusicScanSource.files(
      queriedSongs.map((song) => song.data).toList(growable: false),
    );
  }
}
