import 'dart:async';

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

  FutureOr<void>? runCommand(ArgResults? argResults);

  void initialize(ArgParser argParser) {}

  void throwException(String message) {
    throw UsageException(message, usage);
  }
}
