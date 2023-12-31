import 'dart:io';

import 'package:path/path.dart';
import 'package:subscription_cli/src/core/config.dart';
import 'package:subscription_cli/src/core/job/job.dart';
import 'package:archive/archive_io.dart';
import 'package:subscription_cli/src/util/log.dart';

import 'dmg.dart';

/// Handler for after download.
class PostHandler {
  final List<FileSystemEntity> _tempFiles = [];

  late DmgHelper _dmgHelper;

  bool keepOriginal = false;

  Future<void> _prepareHandle(File file, String tmpOutputPath) async {
    // check file is dmg
    if (file.path.endsWith('.dmg')) {
      if (!Platform.isMacOS) {
        throw Exception('The file is dmg, but the platform is not macOS.');
      }
      _dmgHelper = DmgHelper(
        dmgFile: file,
        mountPoint: tmpOutputPath,
      );
      await _dmgHelper.mount();
      return;
    }

    try {
      await extractFileToDisk(file.path, tmpOutputPath);
      logger.debug('extract file to $tmpOutputPath.');
      _tempFiles.add(Directory(tmpOutputPath));
    } catch (e) {
      keepOriginal = true;
      // copy apk to tmp dir
      file.copySync(tmpOutputPath);
    }
  }

  Future<void> _afterHandle(Job job, Config config, File file) async {
    if (file.path.endsWith('.dmg')) {
      await _dmgHelper.unmount();
    }

    for (final file in _tempFiles) {
      if (file.existsSync()) {
        file.deleteSync(recursive: true);
      }
    }
  }

  void _changeFileMode(File file, String? mode) {
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

  void _copyFileToDisk(Job job, File file, String outputPath) {
    final outputFile = File(outputPath);
    if (outputFile.existsSync() && !job.baseConfig.overwrite) {
      logger.log('The file $outputPath is already exists, skip.');
      return;
    }

    outputFile.createSync(recursive: true);
    file.copySync(outputPath);

    final mode = job.baseConfig.postMode;

    _changeFileMode(outputFile, mode);
  }

  void _copyDirToDisk(Job job, Directory dir, String outputPath) {
    final outputDir = Directory(outputPath);
    if (outputDir.existsSync() && !job.baseConfig.overwrite) {
      logger.log('The directory $outputPath is already exists, skip.');
      return;
    }

    // copy dir recursively
    void copyDir(Directory dir, String outputPath) {
      Directory(outputPath).createSync(recursive: true);

      final files = dir.listSync();
      for (final fileEntry in files) {
        final file = fileEntry;
        final name = basename(file.path);
        final newPath = join(outputPath, name);
        if (FileSystemEntity.isLinkSync(file.path)) {
          // create link
          final srcLink = Link(file.path);
          final targetLink = srcLink.targetSync();
          Link(newPath).createSync(targetLink);
          continue;
        }
        if (file is File) {
          file.copySync(newPath);
        } else if (file is Directory) {
          copyDir(file, newPath);
        }
      }
    }

    copyDir(dir, outputPath);
  }

  Future<void> handleAfterDownload(
    Job job,
    Config config,
    File file,
  ) async {
    logger.log('prepare to extract file to disk.');

    final tmpOutputPath = join(job.getTempPath(), 'tmp-output');

    _tempFiles.add(Directory(tmpOutputPath));
    await _prepareHandle(file, tmpOutputPath);

    try {
      final inputPath =
          normalize(join(tmpOutputPath, job.baseConfig.postSrc ?? '.'));
      var outputPath =
          normalize(join(job.outputPath, job.baseConfig.postTarget ?? '.'));

      if (keepOriginal && job.baseConfig.postTarget == null) {
        outputPath = join(outputPath, basename(file.path));
      }

      logger.log('input: $inputPath');
      logger.log('output: $outputPath');

      final type = FileSystemEntity.typeSync(inputPath);

      if (type == FileSystemEntityType.notFound) {
        throw ArgumentError('The input path is not found.');
      }

      final outputType = FileSystemEntity.typeSync(outputPath);

      if (type == FileSystemEntityType.file) {
        final file = File(inputPath);

        if (outputType == FileSystemEntityType.notFound) {
          _copyFileToDisk(job, file, outputPath);
          return;
        }

        if (outputType == FileSystemEntityType.directory) {
          final name = basename(inputPath);
          final newPath = join(outputPath, name);
          _copyFileToDisk(job, file, newPath);
        } else {
          file.copySync(outputPath);
          _copyFileToDisk(job, file, outputPath);
        }

        return;
      }

      if (type == FileSystemEntityType.directory) {
        final inputDir = Directory(inputPath);

        if (outputType == FileSystemEntityType.notFound) {
          final outputParentPath = File(outputPath).parent.path;
          if (!Directory(outputParentPath).existsSync()) {
            Directory(outputParentPath).createSync(recursive: true);
          }
          logger.debug('The input: $inputPath');
          logger.debug('The output: $outputPath');
          _copyDirToDisk(job, inputDir, outputPath);
          return;
        }

        if (outputType == FileSystemEntityType.directory) {
          logger.debug('The input: $inputPath');
          logger.debug('The inputType: $type');

          logger.debug('The output: $outputPath');
          logger.debug('The outputType: $outputType');
          // throw ArgumentError(
          //     'The output path is a directory, and source path is a directory, cannot overwrite.');

          // check target dir is empty
          final files = inputDir.listSync();
          if (files.isNotEmpty && !job.baseConfig.overwrite) {
            throw ArgumentError(
                'The output path is a directory, and source path is a directory, cannot overwrite.');
          }

          // overwrite
          _copyDirToDisk(job, inputDir, outputPath);
        } else if (outputType == FileSystemEntityType.file) {
          throw ArgumentError(
              'The output path is a file, and source path is a directory, cannot overwrite.');
        } else {
          logger.log('The target path is found, and the type is $outputType');
        }

        return;
      }
    } finally {
      await _afterHandle(job, config, file);
    }
  }
}
