import 'dart:async';

import 'package:args/command_runner.dart';

abstract class BaseCommond extends Command<void> {
  @override
  FutureOr<void>? run() {
    // Implement global options here

    return runCommand();
  }

  FutureOr<void>? runCommand();
}
