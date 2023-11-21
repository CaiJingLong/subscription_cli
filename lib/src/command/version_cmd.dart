import 'dart:async';

import 'package:subscription_cli/src/util/log.dart';
import 'package:subscription_cli/src/version.dart';

import 'base_cmd.dart';

class VersionCommand extends BaseCommond {
  @override
  String get description => 'Print the current version.';

  @override
  String get name => 'version';

  @override
  List<String> get aliases => ['v'];

  @override
  Future<void> runCommand(argResults) async {
    logger.log(Version.version);
  }
}
