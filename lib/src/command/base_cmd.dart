import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:subscription_cli/subscription_cli.dart';

abstract class BaseCommond extends Command<void> {
  BaseCommond() {
    argParser.addFlag(
      'verbose',
      abbr: 'v',
      defaultsTo: false,
      negatable: false,
      help: 'Show extra logging information.',
    );
    initialize(argParser);
  }

  @override
  FutureOr<void>? run() {
    // Implement global options here
    if (argResults!['verbose'] as bool) {
      logger.showDebug = true;
    }

    return runCommand(argResults);
  }

  Future<void> runCommand(ArgResults? argResults);

  void initialize(ArgParser argParser) {}

  void throwException(String message) {
    throw UsageException(message, usage);
  }

  Config readConfig() {
    final configFile = File('scli.yaml');

    if (!configFile.existsSync()) {
      logger.debug('Config file not found.');
      throwException('Config file not found.');
    }

    logger.debug('Config file found.');

    final config = Config.fromYamlFile(configFile);
    return config;
  }
}
