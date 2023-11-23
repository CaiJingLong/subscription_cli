import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:subscription_cli/src/command/analyze_cmd.dart';
import 'package:subscription_cli/src/command/base_cmd.dart';
import 'package:subscription_cli/src/command/example_cmd.dart';
import 'package:subscription_cli/src/command/run_cmd.dart';

import 'command/choice_job_cmd.dart';
import 'command/version_cmd.dart';
import 'util/log.dart';

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
    addCommand(ExampleCommand());
    addCommand(ChoiceJobCommand());

    try {
      await runner.run(arguments);
    } catch (e, st) {
      logger.log(e.toString());

      logger.debug(st.toString());

      if (e is ArgumentError) {
        exit(10);
      }

      if (e is UnimplementedError) {
        exit(11);
      }

      exit(-1);
    }
  }
}
