import 'dart:async';

import 'package:subscription_cli/src/command/base_cmd.dart';

class RunCommand extends BaseCommond {
  @override
  String get description => 'Run the subscription.';

  @override
  String get name => 'run';

  @override
  List<String> get aliases => ['r'];

  @override
  Future<void> runCommand(argResults) async {
    final config = readConfig();

    for (final job in config.jobs) {
      await job.run(config);
    }
  }
}
