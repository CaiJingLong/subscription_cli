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
  FutureOr<void>? runCommand() {
    logger.log(Version.version);
  }
}
