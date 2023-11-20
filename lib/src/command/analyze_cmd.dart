import 'dart:async';

import 'package:subscription_cli/src/command/base_cmd.dart';

class AnalyzeCommand extends BaseCommond {
  @override
  String get description => 'Analyze the config file.';

  @override
  String get name => 'analyze';

  @override
  List<String> get aliases => ['a'];

  @override
  FutureOr<void>? runCommand() {}
}
