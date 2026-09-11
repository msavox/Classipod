import 'dart:async';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:classipod/core/models/music_metadata.dart';
import 'package:classipod/core/repositories/metadata_reader_repository.dart';
import 'package:flutter/foundation.dart';

/// How far a library scan has got.
@immutable
class MusicScanProgress {
  final int scannedFilesCount;

  /// Zero until the scan has finished listing what it has to go through, which
  /// the indicator shows as an indeterminate line.
  final int totalFilesCount;

  const MusicScanProgress({
    required this.scannedFilesCount,
    required this.totalFilesCount,
  });
}

class MusicScanException implements Exception {
  final String message;

  const MusicScanException(this.message);

  @override
  String toString() => 'MusicScanException: $message';
}

/// What a scan has to go through: either every supported file below a folder,
/// or the exact files the platform handed over.
@immutable
class MusicScanSource {
  final String? directoryPath;
  final List<String>? filePaths;

  const MusicScanSource.directory(String this.directoryPath) : filePaths = null;
  const MusicScanSource.files(List<String> this.filePaths)
    : directoryPath = null;
}

/// Reads the metadata of a music library on an isolate of its own, reporting
/// how far along it is, so the device stays usable while it runs.
class MusicScanService {
  /// Sending a message per file would cost more than reading one, so progress
  /// is reported at most this many times over a whole scan.
  static const int _maxProgressReports = 100;

  const MusicScanService._();

  static Future<List<MusicMetadata>> scan({
    required MusicScanSource source,
    required String thumbnailsDirectoryPath,
    required void Function(MusicScanProgress progress) onProgress,
  }) async {
    final ReceivePort messagePort = ReceivePort();
    final ReceivePort errorPort = ReceivePort();
    final ReceivePort exitPort = ReceivePort();
    final Completer<List<MusicMetadata>> completer =
        Completer<List<MusicMetadata>>();

    messagePort.listen((message) {
      if (message is MusicScanProgress) {
        onProgress(message);
      } else if (message is List<MusicMetadata> && !completer.isCompleted) {
        completer.complete(message);
      }
    });
    errorPort.listen((message) {
      if (!completer.isCompleted) {
        completer.completeError(MusicScanException('$message'));
      }
    });
    exitPort.listen((_) {
      // An isolate dying without an answer would otherwise leave the scan
      // pending forever, and the indicator on screen with it.
      if (!completer.isCompleted) {
        completer.completeError(
          const MusicScanException('The scan stopped before it finished'),
        );
      }
    });

    final Isolate isolate = await Isolate.spawn(
      _runScan,
      _ScanRequest(
        sendPort: messagePort.sendPort,
        thumbnailsDirectoryPath: thumbnailsDirectoryPath,
        directoryPath: source.directoryPath,
        filePaths: source.filePaths,
      ),
      onError: errorPort.sendPort,
      onExit: exitPort.sendPort,
      debugName: 'music-scan',
    );

    try {
      return await completer.future;
    } finally {
      isolate.kill(priority: Isolate.immediate);
      messagePort.close();
      errorPort.close();
      exitPort.close();
    }
  }

  /// Runs on the spawned isolate.
  static void _runScan(_ScanRequest request) {
    final MetadataReaderRepository repository = MetadataReaderRepository(
      request.thumbnailsDirectoryPath,
    );
    final String? directoryPath = request.directoryPath;
    final List<String> filePaths = directoryPath == null
        ? request.filePaths!
        : repository.listAudioFilePaths(directoryPath);

    final int reportEvery = math.max(
      1,
      (filePaths.length / _maxProgressReports).ceil(),
    );

    request.sendPort.send(
      MusicScanProgress(scannedFilesCount: 0, totalFilesCount: filePaths.length),
    );

    final List<MusicMetadata> metadataList = [];
    for (int index = 0; index < filePaths.length; index++) {
      final MusicMetadata? metadata = repository.extractMetadataFromFile(
        filePaths[index],
        metadataList.length,
      );
      if (metadata != null) {
        metadataList.add(metadata);
      }
      final int scanned = index + 1;
      if (scanned % reportEvery == 0 || scanned == filePaths.length) {
        request.sendPort.send(
          MusicScanProgress(
            scannedFilesCount: scanned,
            totalFilesCount: filePaths.length,
          ),
        );
      }
    }

    request.sendPort.send(metadataList);
  }
}

@immutable
class _ScanRequest {
  final SendPort sendPort;
  final String thumbnailsDirectoryPath;
  final String? directoryPath;
  final List<String>? filePaths;

  const _ScanRequest({
    required this.sendPort,
    required this.thumbnailsDirectoryPath,
    required this.directoryPath,
    required this.filePaths,
  });
}
