import 'package:subscription_cli/subscription_cli.dart';

/// Base config of job
class BaseConfig with Mappable {
  /// The base config of job
  const BaseConfig({
    required this.name,
    required this.type,
    required this.context,
    required this.proxy,
    required this.map,
    required this.enabled,
    required this.overwrite,
    required this.datetime,
    this.description,
    this.output,
    this.workingDirectory,
  });

  /// The create time of job config.
  ///
  /// It will be set when the job is created.
  final DateTime datetime;

  /// The global config of job, it comes from config.yaml.
  /// Define in the node of `config`.
  final Context context;

  /// The proxy config of job, it comes from config.yaml.
  ///
  /// Define in the node of `config.proxy`.
  final Proxy? proxy;

  /// The map of job, it comes from config.yaml.
  ///
  /// Define in the node of `jobs`.
  ///
  /// Contains all the config of job.
  final Map map;

  /// The enable of job, it comes from config.yaml.
  ///
  /// Define in the node of `jobs.enable`.
  ///
  /// If the value is false, it will not run.
  final bool enabled;

  /// The overwrite of job, it comes from config.yaml.
  ///
  /// Define in the node of `jobs.overwrite`.
  ///
  /// If the value is true, it will overwrite the old file.
  final bool overwrite;

  /// The name of job, it comes from config.yaml.
  ///
  /// Define in the node of `jobs.name`.
  final String name;

  final JobType type;

  /// The description of job, it comes from config.yaml.
  ///
  /// Define in the node of `jobs.description`.
  final String? description;

  /// The output of job, it comes from config.yaml.
  ///
  /// Define in the node of `jobs.output`.
  ///
  /// If the value is null, it will output to global basePath.
  /// If the basePath of global config is null, it will output to current path.
  ///
  /// The value support relative path and absolute path.
  /// If the value is relative path, it will be relative to basePath of global config, or current path (if the global basePath is null).
  ///
  /// The absolute path is must be start with `/`(Unix like) or `X:\`(Windows).
  final String? output;

  /// The output path of job, it comes from config.yaml.
  ///
  /// Define in the node of `jobs.workingDir`.
  final String? workingDirectory;

  String? get postSrc {
    return map['post']?['src'];
  }

  String? get postTarget {
    return map['post']?['target'];
  }

  String? get postMode {
    return map['post']?['mode'];
  }

  BaseConfig copyWith({
    Context? context,
    Proxy? proxy,
    Map? map,
    bool? enabled,
    bool? overwrite,
    String? name,
    JobType? type,
    String? description,
    String? output,
    String? workingDirectory,
  }) {
    return BaseConfig(
      context: context ?? this.context,
      proxy: proxy ?? this.proxy,
      map: map ?? this.map,
      enabled: enabled ?? this.enabled,
      overwrite: overwrite ?? this.overwrite,
      name: name ?? this.name,
      description: description ?? this.description,
      output: output ?? this.output,
      workingDirectory: workingDirectory ?? this.workingDirectory,
      datetime: datetime,
      type: type ?? this.type,
    );
  }

  @override
  Map toMap() {
    return {
      'name': name,
      'type': type.toStringValue(),
      'description': description,
      'enabled': enabled,
      'overwrite': overwrite,
      'output': output,
      'workingDir': workingDirectory,
      'params': map['params'],
      'post': map['post'],
    };
  }
}
