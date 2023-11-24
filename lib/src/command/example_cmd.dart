import 'package:subscription_cli/src/command/base_cmd.dart';
import 'package:subscription_cli/subscription_cli.dart';

class ExampleCommand extends BaseCommond {
  @override
  String get description => 'Show example config';

  @override
  String get name => 'example';

  @override
  List<String> get aliases => ['e'];

  @override
  Future<void> runCommand(argResults) async {
    final context = Context(
      basePath: 'output',
      proxy: Proxy(
        proxyHost: 'localhost',
        proxyPort: 7890,
        proxyUsername: null,
        proxyPassword: null,
        proxyScheme: null,
      ),
      yamlDocument: null,
    );

    final config = Config(
      globalConfig: context,
      jobs: Job.examples(context),
    );

    print(config.toYamlText());
  }
}
