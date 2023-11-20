import 'package:subscription_cli/src/config/config.dart';
import 'package:subscription_cli/src/util/buffer.dart';

import 'github_release.dart';

/// The base class of job
abstract class Jobs {
  const Jobs({
    required this.baseConfig,
  });

  /// Create a job by [map].
  factory Jobs.byMap({
    required Context config,
    required Map map,
  }) {
    final proxy = Proxy.byMap(map['proxy']);
    final globalProxy = config.proxy;
    final mergedProxy = Proxy.merge(globalProxy, proxy);
    final type = map['type'];

    final name = map['name'];

    if (name == null) {
      throw ArgumentError('The name of job is required, '
          'but it is not defined.');
    }

    if (type == null) {
      throw ArgumentError('The type of job is required, '
          'but it is not defined.');
    }

    final baseConfig = BaseConfig(
      globalConfig: config,
      proxy: mergedProxy,
      type: type,
      enabled: map['enable'] ?? true,
      overwrite: map['overwrite'] ?? false,
      name: map.required('name'),
      description: map['description'],
    );

    // Use the type to decide which job to create.
    if (type == 'github-release') {
      return GithubReleaseJob(
        baseConfig: baseConfig,
        owner: map.required('owner'),
        repo: map.required('repo'),
        includePrerelease: map['includePrerelease'] ?? false,
      );
    }

    throw UnimplementedError('The type of job is not supported.');
  }

  final BaseConfig baseConfig;

  Context get globalConfig => baseConfig.globalConfig;
  bool get enabled => baseConfig.enabled;
  bool get overwrite => baseConfig.overwrite;
  Proxy? get proxy => baseConfig.proxy;
  String get type => baseConfig.type;
  String? get name => baseConfig.name;
  String? get description => baseConfig.description;

  String baseConfigAnalyze() {
    LogBuffer buffer = LogBuffer();

    if (name != null) {
      buffer.writeln('name: $name');
    }

    if (description != null) {
      buffer.writeln('description: $description');
    }

    buffer.writeln('type: $type');
    buffer.writeln('enabled: $enabled');
    buffer.writeln('overwrite: $overwrite');
    return buffer.toString();
  }

  String? analyze();
}

extension _JobsMap on Map {
  dynamic required(String key) {
    final value = this[key];
    if (value == null) {
      throw ArgumentError('The value of $key is required in job, '
          'but it is not defined.');
    }
    return value;
  }
}
