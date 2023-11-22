import 'dart:io';

import 'package:path/path.dart';
import 'package:subscription_cli/src/core/config.dart';
import 'package:subscription_cli/src/core/job/job.dart';
import 'package:archive/archive_io.dart';
import 'package:subscription_cli/src/util/log.dart';

/// Handler for after download.
class PostHandler {
  Archive createArchive(File file) {
    final path = file.path;

    final inputStream = InputFileStream(path);

    // tar.gz or tgz
    if (path.endsWith('.tar.gz') || path.endsWith('.tgz')) {
      final GZipDecoder gzipDecoder = GZipDecoder();
      final bytes = gzipDecoder.decodeBuffer(inputStream);
      final TarDecoder tarDecoder = TarDecoder();
      return tarDecoder.decodeBytes(bytes);
    }

    // tar
    if (path.endsWith('.tar')) {
      return TarDecoder().decodeBuffer(inputStream);
    }

    // zip
    if (path.endsWith('.zip')) {
      return ZipDecoder().decodeBuffer(inputStream);
    }

    // bz
    if (path.endsWith('.tar.bz') || path.endsWith('.tbz')) {
      final BZip2Decoder bZip2Decoder = BZip2Decoder();
      final bytes = bZip2Decoder.decodeBuffer(inputStream);
      final TarDecoder tarDecoder = TarDecoder();
      return tarDecoder.decodeBytes(bytes);
    }

    // xz
    if (path.endsWith('.tar.xz') || path.endsWith('.txz')) {
      final XZDecoder xzDecoder = XZDecoder();
      final bytes = xzDecoder.decodeBuffer(inputStream);
      final TarDecoder tarDecoder = TarDecoder();
      return tarDecoder.decodeBytes(bytes);
    }

    // zlib
    // if (path.endsWith('.tar.z') || path.endsWith('.tz')) {
    //   final ZLibDecoder zlibDecoder = ZLibDecoder();
    //   final bytes = zlibDecoder.decodeBuffer(inputStream);
    //   final TarDecoder tarDecoder = TarDecoder();
    //   return tarDecoder.decodeBytes(bytes);
    // }

    throw ArgumentError('Unsupported archive type.');
  }

  void changeFileMode(File file, String? mode) {
    if (mode == null) {
      return;
    }

    logger.log('change ${file.path} mode to $mode');

    if (Platform.isLinux || Platform.isMacOS) {
      final result = Process.runSync('chmod', [mode, file.path]);
      if (result.exitCode != 0) {
        logger.log('Failed to change file mode, exit code: ${result.exitCode}');
      }
    }
  }

  void copyFileToDisk(Job job, File file, String outputPath) {
    final outputFile = File(outputPath);
    if (outputFile.existsSync() && !job.baseConfig.overwrite) {
      logger.log('The file $outputPath is already exists, skip.');
      return;
    }

    outputFile.createSync(recursive: true);
    file.copySync(outputPath);

    final mode = job.baseConfig.postMode;

    changeFileMode(file, mode);
  }

  Future<void> handleAfterDownload(
    Job job,
    Config config,
    File file,
  ) async {
    logger.log('prepare to extract file to disk.');

    final dt = DateTime.now().millisecondsSinceEpoch;
    final tmpOutputPath = join(Directory.systemTemp.path, '$dt');
    await extractFileToDisk(file.path, tmpOutputPath);

    logger.debug('extract file to $tmpOutputPath.');

    final input = join(tmpOutputPath, job.baseConfig.postSrc ?? '.');
    final output = join(job.outputPath, job.baseConfig.postTarget ?? '.');

    logger.log('input: $input');
    logger.log('output: $output');

    final type = FileSystemEntity.typeSync(input);

    if (type == FileSystemEntityType.notFound) {
      throw ArgumentError('The input path is not found.');
    }

    final outputType = FileSystemEntity.typeSync(output);

    if (type == FileSystemEntityType.file) {
      final file = File(input);

      if (outputType == FileSystemEntityType.notFound) {
        copyFileToDisk(job, file, output);
        return;
      }

      if (outputType == FileSystemEntityType.directory) {
        final name = basename(input);
        final newPath = join(output, name);
        copyFileToDisk(job, file, newPath);
      } else {
        file.copySync(output);
        copyFileToDisk(job, file, output);
      }

      return;
    }

    if (type == FileSystemEntityType.directory) {
      final dir = Directory(input);

      if (outputType == FileSystemEntityType.notFound) {
        dir.renameSync(output);
        return;
      }

      if (outputType == FileSystemEntityType.directory) {
        logger.debug('The input: $input');
        logger.debug('The inputType: $type');

        logger.debug('The output: $output');
        logger.debug('The outputType: $outputType');
        throw ArgumentError(
            'The output path is a directory, and source path is a directory, cannot overwrite.');
      } else if (outputType == FileSystemEntityType.file) {
        throw ArgumentError(
            'The output path is a file, and source path is a directory, cannot overwrite.');
      } else {
        logger.log('The target path is found, and the type is $outputType');
      }

      return;
    }
  }
}
