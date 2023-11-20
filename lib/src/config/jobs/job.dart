import 'package:subscription_cli/src/config/config.dart';
import 'package:subscription_cli/src/util/buffer.dart';
import 'package:path/path.dart' as path;

import 'github_release.dart';

/// The base class of job
abstract class Jobs {
  const Jobs({
    required this.baseConfig,
  });

  /// Create a job by [map].
  factory Jobs.byMap({
    required Context context,
    required Map map,
  }) {
    final proxy = Proxy.byMap(map['proxy']);
    final globalProxy = context.proxy;
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
      context: context,
      proxy: mergedProxy,
      type: type,
      enabled: map['enable'] ?? true,
      overwrite: map['overwrite'] ?? false,
      name: map.required('name'),
      description: map['description'],
      output: map['output'],
      workingDirectory: map['workingDir'],
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

  Context get context => baseConfig.context;
  bool get enabled => baseConfig.enabled;
  bool get overwrite => baseConfig.overwrite;
  Proxy? get proxy => baseConfig.proxy;
  String get type => baseConfig.type;
  String get name => baseConfig.name;
  String? get description => baseConfig.description;

  String get outputPath {
    final workingDir = baseConfig.workingDirectory ?? context.workingDirectory;
    final name = baseConfig.output ?? this.name;
    final result = path.join(workingDir, name);
    return result;
  }

  String baseConfigAnalyze() {
    LogBuffer buffer = LogBuffer();

    buffer.writeln('name: $name');

    if (description != null) {
      buffer.writeln('description: $description');
    }

    if (proxy != null) {
      buffer.writeln('Use proxy:');
      buffer.writeMultiLine(proxy!.analyze(), indent: 2);
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
