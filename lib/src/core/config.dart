import 'dart:io';

import 'package:subscription_cli/src/util/env_util.dart';
import 'package:subscription_cli/src/util/log.dart';
import 'package:yaml/yaml.dart';

import '../util/buffer.dart';
import 'job/job.dart';
import 'mappable.dart';

/// The context of config
class Context with Mappable {
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

  @override
  Map toMap() {
    return {
      'basePath': basePath,
      'proxy': proxy?.toMap(),
      'githubToken': githubToken,
    };
  }
}

class Proxy with Mappable {
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

  @override
  Map toMap() {
    return {
      'scheme': proxyScheme,
      'host': proxyHost,
      'port': proxyPort,
      'username': proxyUsername,
      'password': proxyPassword,
    };
  }
}

class Config with Mappable {
  const Config({
    required this.globalConfig,
    required this.jobs,
  });

  /// Current global config
  final Context globalConfig;

  /// Current job config
  final List<Job> jobs;

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

    final List jobsList = doc.contents.value?['jobs'] ?? [];

    final List<Job> jobs = [];

    final datetime = DateTime.now();

    for (var i = 0; i < jobsList.length; i++) {
      final job = jobsList[i];
      try {
        jobs.add(
          Job.byMap(
            context: context,
            index: i,
            datetime: datetime,
            map: job,
          ),
        );
      } catch (e) {
        logger.log('The ${i + 1} job happen error:');
        logger.write('  ');
        rethrow;
      }
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

  @override
  Map toMap() {
    return {
      'config': globalConfig.toMap(),
      'jobs': jobs.map((e) => e.toMap()).toList(),
    };
  }
}
