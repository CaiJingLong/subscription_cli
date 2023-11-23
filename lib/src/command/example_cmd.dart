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
    final baseConfig = BaseConfig(
      context: context,
      datetime: DateTime.now(),
      description: 'Download m3u8 files from github release.',
      proxy: null,
      map: {},
      type: 'github-release',
      enabled: true,
      overwrite: false,
      name: name,
    );

    final config = Config(
      globalConfig: context,
      jobs: [
        GithubReleaseJob(
          baseConfig: baseConfig,
          owner: 'caijinglong',
          repo: 'm3u8_download',
          includePrerelease: false,
          asset: 'macos_#{version}.tar.gz',
        ),
      ],
    );

    print(config.toYamlText());
  }
}
