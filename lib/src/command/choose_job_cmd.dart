import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';

import 'base_cmd.dart';

class ChooseJobCommand extends BaseCommond {
  @override
  String get description => 'Choose a job to run.';

  @override
  String get name => 'choose';

  @override
  List<String> get aliases => ['c'];

  @override
  Future<void> runCommand(ArgResults? argResults) async {
    final config = readConfig();

    while (true) {
      print('There are ${config.jobs.length} jobs to choose from:');

      for (var i = 0; i < config.jobs.length; i++) {
        final job = config.jobs[i];
        print('  ${i + 1}. ${job.name}');
      }

      print('\n  q. Quit');

      print('Please enter the number of the job you want to run:');

      final line = stdin.readLineSync(encoding: utf8);

      if (line == null) {
        print('The input is empty, please re-enter.');
        continue;
      }

      if (line == 'q') {
        print('Bye.');
        break;
      }

      final index = int.tryParse(line);

      if (index == null) {
        print('The input is not a number, please re-enter.');
        continue;
      }

      if (index < 1 || index > config.jobs.length) {
        print('The input is out of range, please re-enter.');
        continue;
      }

      final job = config.jobs[index - 1];

      print('Start to run job ${job.name}.');

      await job.run(config);
    }
  }
}
