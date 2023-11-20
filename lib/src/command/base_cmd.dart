import 'dart:async';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';

abstract class BaseCommond extends Command<void> {
  BaseCommond() {
    initialize(argParser);
  }

  @override
  FutureOr<void>? run() {
    // Implement global options here

    return runCommand(argResults);
  }

  FutureOr<void>? runCommand(ArgResults? argResults);

  void initialize(ArgParser argParser) {}

  void throwException(String message) {
    throw UsageException(message, usage);
  }
}
