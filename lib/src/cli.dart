import 'package:args/command_runner.dart';

class Cli {
  Future<void> main(List<String> arguments) async {
    final CommandRunner<void> runner = CommandRunner<void>(
      'subscription_cli',
      'A command-line interface for managing subscriptions.',
    );

    runner.run(arguments);
  }
}
