import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:subscription_cli/subscription_cli.dart';

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
    final typeString = map['type'];

    final name = map['name'];

    if (name == null) {
      throw ArgumentError('The name of job is required, '
          'but it is not defined.');
    }

    if (typeString == null) {
      throw ArgumentError('The type of job is required, '
          'but it is not defined.');
    }

    final type = JobType.fromString(typeString);

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
    if (type == JobType.githubRelease) {
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

    if (type == JobType.http) {
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

  Directory getDownloadPath() {
    return Directory(path.join(getTempPath(), 'download'));
  }

  HttpUtils getHttpClient() {
    return HttpUtils(proxy: baseConfig.proxy);
  }

  Future<void> download({
    required String url,
    required String path,
    int? totalSize,
  }) async {
    final httpClient = getHttpClient();

    await httpClient.download(
      url: url,
      path: path,
      totalSize: totalSize,
      downloadBytesCallback: (current, total) {
        final progress = (current / total * 100).toStringAsFixed(2);
        logger.write('\rDownload progress: $progress%');
      },
      doneCallback: () {
        logger.write('\n');
      },
    );
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
