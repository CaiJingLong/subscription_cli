import 'dart:io';

import 'package:subscription_cli/src/util/env_util.dart';
import 'package:yaml/yaml.dart';

import '../util/buffer.dart';
import 'jobs/job.dart';

/// The context of config
class Context {
  const Context({
    required this.basePath,
    required this.proxy,
    required this.yamlDocument,
    this.githubToken,
  });

  /// The original yaml document.
  final YamlDocument? yamlDocument;

  /// Current base path
  final String? basePath;

  /// Current proxy
  final Proxy? proxy;

  final String? githubToken;

  String get workingDirectory => Directory.current.path;

  String analyze() {
    LogBuffer buffer = LogBuffer();

    if (basePath != null) {
      buffer.writeln('basePath: $basePath');
    } else {
      buffer.writeln('basePath is not defined.');
    }

    if (proxy == null) {
      buffer.writeln('proxy is not defined.');
    } else {
      buffer.writeMultiLine(proxy?.analyze(), indent: 2);
    }

    if (githubToken == null) {
      buffer.writeln('githubToken is not defined.');
    } else {
      buffer.writeln('githubToken: ${githubToken!.substring(0, 4)}****');
    }

    return buffer.toString();
  }
}

class Proxy {
  const Proxy({
    required this.proxyHost,
    required this.proxyPort,
    required this.proxyUsername,
    required this.proxyPassword,
    required this.proxyScheme,
  });

  /// proxy scheme
  ///
  /// Define in the node of `proxy.scheme`.
  ///
  /// If the value is not null, it's maybe `http`, `https` or `socks5`.
  final String? proxyScheme;

  /// proxy host
  ///
  /// Define in the node of `proxy.host`.
  final String? proxyHost;

  /// proxy port
  ///
  /// Define in the node of `proxy.port`.
  final int? proxyPort;

  /// proxy username
  ///
  /// Define in the node of `proxy.username`.
  final String? proxyUsername;

  /// proxy password
  ///
  /// Define in the node of `proxy.password`.
  final String? proxyPassword;

  /// Create a proxy by [map].
  static Proxy? byMap(Map? map) {
    if (map == null) return null;
    return Proxy(
      proxyHost: map['host'],
      proxyPort: map['port'],
      proxyUsername: map['username'],
      proxyPassword: map['password'],
      proxyScheme: map['scheme'],
    );
  }

  /// Merge the global proxy and local proxy.
  static Proxy merge(Proxy? globalProxy, Proxy? localProxy) {
    return Proxy(
      proxyHost: localProxy?.proxyHost ?? globalProxy?.proxyHost,
      proxyPort: localProxy?.proxyPort ?? globalProxy?.proxyPort,
      proxyUsername: localProxy?.proxyUsername ?? globalProxy?.proxyUsername,
      proxyPassword: localProxy?.proxyPassword ?? globalProxy?.proxyPassword,
      proxyScheme: localProxy?.proxyScheme ?? globalProxy?.proxyScheme,
    );
  }

  String analyze() {
    LogBuffer buffer = LogBuffer();

    void write(String key, String? value) {
      if (value == null) {
        buffer.writeln('$key is not defined.');
        return;
      }
      buffer.writeln('$key: $value');
    }

    write('scheme', proxyScheme);
    write('host', proxyHost);
    write('port', proxyPort?.toString());
    write('username', proxyUsername);
    write('password', proxyPassword);

    return buffer.toString();
  }
}

class Config {
  const Config({
    required this.globalConfig,
    required this.jobs,
  });

  /// Current global config
  final Context globalConfig;

  /// Current job config
  final List<Jobs> jobs;

  factory Config.fromYamlText(String yamlText) {
    yamlText = EnvUtil.replaceEnv(yamlText);

    final YamlDocument doc = loadYamlDocument(yamlText);

    final Map? globalConfigMap = doc.contents.value['config'];
    final Map? proxyMap = globalConfigMap?['proxy'];

    final context = Context(
      yamlDocument: doc,
      basePath: globalConfigMap?['basePath'],
      proxy: Proxy.byMap(proxyMap),
      githubToken: globalConfigMap?['githubToken'],
    );

    final List? jobsList = doc.contents.value?['jobs'];

    final List<Jobs> jobs = [];

    for (final job in jobsList ?? []) {
      jobs.add(
        Jobs.byMap(
          context: context,
          map: job,
        ),
      );
    }

    return Config(
      globalConfig: context,
      jobs: jobs,
    );
  }

  factory Config.fromYamlFile(File yamlFile) {
    return Config.fromYamlText(yamlFile.readAsStringSync());
  }

  String analyze() {
    LogBuffer buffer = LogBuffer();

    // 1. Add global config
    buffer.writeln('Global config:');
    buffer.writeMultiLine(globalConfig.analyze(), indent: 2);

    // 2. jobs
    buffer.writeln('Jobs:');
    if (jobs.isEmpty) {
      buffer.writeln('Jobs is empty.', indent: 2);
    } else {
      for (int i = 0; i < jobs.length; i++) {
        final job = jobs[i];
        buffer.writeln('\n');

        buffer.write('=' * 30);
        buffer.write(' #${i + 1} ');
        buffer.writeln('=' * 30);
        buffer.newLine();

        buffer.writeMultiLine(job.baseConfigAnalyze(), indent: 4);
        buffer.writeMultiLine(job.analyze(), indent: 4);
      }
    }

    return buffer.toString();
  }

  String analyzeJson() {
    return 'json';
  }
}

/// Base config of job
class BaseConfig {
  /// The base config of job
  const BaseConfig({
    required this.context,
    required this.proxy,
    required this.map,
    required this.type,
    required this.enabled,
    required this.overwrite,
    required this.name,
    this.description,
    this.output,
    this.workingDirectory,
  });

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

  /// The type of job, it comes from config.yaml.
  ///
  /// Define in the node of `jobs.type`.
  ///
  /// The value will decide how to handle the job.
  final String type;

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
}
