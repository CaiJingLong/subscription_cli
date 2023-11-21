import 'dart:io';

import 'package:subscription_cli/src/core/config.dart';
import 'package:subscription_cli/src/core/job/job.dart';

class PostHandler {
  Future<void> handleAfterDownload(
    Job job,
    Config config,
    File file,
  ) async {
    throw UnimplementedError();
  }
}
