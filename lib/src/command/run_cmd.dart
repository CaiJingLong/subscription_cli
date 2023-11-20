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
  FutureOr<void>? runCommand() {}
}
