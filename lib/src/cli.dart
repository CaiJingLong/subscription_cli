import 'package:args/command_runner.dart';
import 'package:subscription_cli/src/command/analyze_cmd.dart';
import 'package:subscription_cli/src/command/base_cmd.dart';
import 'package:subscription_cli/src/command/run_cmd.dart';

import 'command/version_cmd.dart';

class Cli {
  Future<void> main(List<String> arguments) async {
    final CommandRunner<void> runner = CommandRunner<void>(
      'subscription_cli',
      'A command-line interface for managing subscriptions.',
    );

    runner.argParser.addFlag(
      'verbose',
      abbr: 'v',
      defaultsTo: false,
      negatable: false,
      help: 'Show extra logging information.',
    );

    void addCommand(BaseCommond command) => runner.addCommand(command);

    addCommand(RunCommand());
    addCommand(AnalyzeCommand());
    addCommand(VersionCommand());

    runner.run(arguments);
  }
}
