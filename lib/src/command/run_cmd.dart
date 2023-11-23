import 'dart:async';

import 'package:subscription_cli/src/command/base_cmd.dart';
import 'package:subscription_cli/src/util/log.dart';

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

    final jobs = config.jobs;
    logger.log('Start to run jobs, total ${jobs.length} jobs.');

    for (var i = 0; i < config.jobs.length; i++) {
      final job = config.jobs[i];

      logger.write('=' * 30);
      logger.write(' Job ${i + 1} of ${jobs.length}: ${job.name} ');
      logger.write('=' * 30);
      logger.write('\n');

      if (job.enabled == false) {
        logger.log('Job ${job.name} is disabled. Skip it.');
        logger.log('=' * 60);
        continue;
      }
      await job.run(config);

      logger.log('=' * 60);
      logger.write('\n');
    }
  }
}
