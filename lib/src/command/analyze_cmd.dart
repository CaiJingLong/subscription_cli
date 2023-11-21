import 'dart:async';

import 'package:args/args.dart';
import 'package:subscription_cli/src/command/base_cmd.dart';
import 'package:subscription_cli/subscription_cli.dart';

class AnalyzeCommand extends BaseCommond {
  @override
  String get description => 'Analyze the config file.';

  @override
  String get name => 'analyze';

  @override
  List<String> get aliases => ['a'];

  @override
  void initialize(ArgParser argParser) {
    super.initialize(argParser);
    argParser.addFlag(
      'json',
      abbr: 'j',
      help: 'Output as JSON.',
    );
  }

  @override
  Future<void> runCommand(ArgResults? argResults) async {
    final config = readConfig();

    if (argResults!['json'] as bool) {
      logger.log(config.analyzeJson());
      return;
    }

    logger.log(config.analyze());
  }
}
