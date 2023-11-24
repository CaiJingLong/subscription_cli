import 'dart:convert';
import 'dart:io';

import 'package:subscription_cli/src/core/config.dart';
import 'package:subscription_cli/src/core/handler/handler.dart';
import 'package:subscription_cli/src/core/mappable.dart';
import 'package:subscription_cli/src/util/buffer.dart';
import 'package:path/path.dart' as path;
import 'package:subscription_cli/src/util/file_util.dart';

import 'github_release.dart';
import 'http.dart';
import 'job_base_config.dart';

/// The base class of job
abstract class Job with JobMixin, Mappable {
  const Job({
    required this.baseConfig,
  });

  /// Create a job by [map].
  factory Job.byMap({
    required Context context,
    required int index,
    required Map map,
    required DateTime datetime,
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
      map: map,
      type: type,
      datetime: datetime,
      enabled: map['enabled'] ?? true,
      overwrite: map['overwrite'] ?? false,
      name: map.required('name'),
      description: map['description'],
      output: map['output'],
      workingDirectory: map['workingDir'],
    );

    // Use the type to decide which job to create.
    final githubTypes = [
      'github-release',
      'gr',
    ];
    if (githubTypes.contains(type)) {
      String? owner = map.optional('owner');
      String? repo = map.optional('repo');

      if (owner == null || repo == null) {
        final regex = RegExp(r'github\.com/([^/]+)/([^/]+)');
        final url = map.optional('url');
        final match = regex.firstMatch(url);
        if (match != null) {
          owner = match.group(1);
          repo = match.group(2);
        } else {
          throw ArgumentError(
              'The owner and repo of github-release job is required, '
              'please set owner/repo or url.');
        }
      }

      return GithubReleaseJob(
        baseConfig: baseConfig,
        owner: owner!,
        repo: repo!,
        asset: map.required('asset'),
        includePrerelease: map.requiredDefault('includePrerelease', false),
      );
    }

    final httpTypes = [
      'http',
    ];

    if (httpTypes.contains(type)) {
      return HttpJob(
        baseConfig: baseConfig,
        url: map.required('url'),
      );
    }

    throw UnimplementedError('The type of job is not supported.');
  }

  final BaseConfig baseConfig;

  JobType get typeEnum;

  Context get context => baseConfig.context;
  Map get map => baseConfig.map;

  bool get enabled => baseConfig.enabled;
  bool get overwrite => baseConfig.overwrite;
  Proxy? get proxy => baseConfig.proxy;
  String get type => typeEnum.toString();
  String get name => baseConfig.name;
  String? get description => baseConfig.description;
  @override
  Map<dynamic, dynamic> get params => baseConfig.map['params'] ?? {};

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

  String getTempPath() {
    final dt = baseConfig.datetime.millisecondsSinceEpoch;
    return path.join(FileUtils.getTempPath(), '$dt-$name');
  }

  Future<void> run(Config config) async {
    final file = await doDownload(config);
    await PostHandler().handleAfterDownload(this, config, file);
  }

  Future<File> doDownload(Config config);

  String prettyJsonForString(String text) {
    return prettyJsonFofObj(json.decode(text));
  }

  String prettyJsonFofObj(Object obj) {
    final encoder = JsonEncoder.withIndent('  ');
    final result = encoder.convert(obj);
    return result;
  }

  @override
  Map toMap() {
    return {
      ...baseConfig.toMap().where((key, value) => value != null),
      ...jobMap().where((key, value) => value != null)
    };
  }

  Map jobMap();

  static List<Job> examples(Context context) {
    final result = <Job>[];

    final types = ['github-release', 'http'];

    for (final type in types) {
      final typeEnum = JobType.fromString(type);
      final baseConfig = BaseConfig(
        context: context,
        datetime: DateTime.now(),
        description: 'Download m3u8 files from github release.',
        proxy: null,
        map: {},
        type: typeEnum,
        enabled: true,
        overwrite: false,
        name: '$type-example',
      );

      if (type == 'github-release') {
        result.add(GithubReleaseJob.example(baseConfig));
      } else if (type == 'http') {
        result.add(HttpJob.example(baseConfig));
      }
    }

    return result;
  }
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

  dynamic requiredDefault(String key, dynamic defaultValue) {
    final value = this[key];
    if (value == null) {
      return defaultValue;
    }
    return value;
  }

  dynamic optional(String key) {
    return this[key];
  }

  Map where(bool Function(dynamic key, dynamic value) test) {
    final result = <String, dynamic>{};
    for (final entry in entries) {
      final key = entry.key;
      final value = entry.value;
      if (test(key, value)) {
        result[key] = value;
      }
    }
    return result;
  }
}

mixin JobMixin {
  Map<dynamic, dynamic> get params;

  Future<void> handleAfterDownload(File asset) async {}
}

enum JobType {
  githubRelease,
  http;

  static JobType fromString(String type) {
    switch (type) {
      case 'github-release' || 'gr':
        return JobType.githubRelease;
      case 'http':
        return JobType.http;
      default:
        throw ArgumentError('The type of job is not supported.');
    }
  }

  String toStringValue() {
    switch (this) {
      case JobType.githubRelease:
        return 'github-release';
      case JobType.http:
        return 'http';
    }
  }
}
