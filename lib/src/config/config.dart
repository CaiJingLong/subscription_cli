import 'dart:io';

import 'package:yaml/yaml.dart';

class Proxy {
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

  /// proxy scheme
  ///
  /// Define in the node of `proxy.scheme`.
  final String? proxyScheme;

  Proxy({
    required this.proxyHost,
    required this.proxyPort,
    required this.proxyUsername,
    required this.proxyPassword,
    required this.proxyScheme,
  });

  static Proxy? byMap(Map<String, dynamic>? map) {
    if (map == null) return null;
    return Proxy(
      proxyHost: map['host'],
      proxyPort: map['port'],
      proxyUsername: map['username'],
      proxyPassword: map['password'],
      proxyScheme: map['scheme'],
    );
  }

  static Proxy merge(Proxy? globalProxy, Proxy? localProxy) {
    return Proxy(
      proxyHost: localProxy?.proxyHost ?? globalProxy?.proxyHost,
      proxyPort: localProxy?.proxyPort ?? globalProxy?.proxyPort,
      proxyUsername: localProxy?.proxyUsername ?? globalProxy?.proxyUsername,
      proxyPassword: localProxy?.proxyPassword ?? globalProxy?.proxyPassword,
      proxyScheme: localProxy?.proxyScheme ?? globalProxy?.proxyScheme,
    );
  }
}

/// The context of config
class Context {
  /// The original yaml document.
  final YamlDocument? yamlDocument;

  /// Current base path
  final String basePath;

  /// Current proxy
  final Proxy? proxy;

  Context({
    required this.basePath,
    required this.proxy,
    required this.yamlDocument,
  });
}

class Config {
  /// Current global config
  final Context globalConfig;

  /// Current subscription config
  final List<Subscription> subscriptionConfig;

  Config({
    required this.globalConfig,
    required this.subscriptionConfig,
  });

  factory Config.fromYamlPath(String yamlPath) {
    final YamlDocument doc =
        loadYamlDocument(File(yamlPath).readAsStringSync());

    final YamlMap globalConfigMap = doc.contents.value['config'];
    final YamlMap proxyMap = globalConfigMap['proxy'];

    final context = Context(
      yamlDocument: doc,
      basePath: globalConfigMap['basePath'],
      proxy: Proxy(
        proxyHost: proxyMap['host'],
        proxyPort: proxyMap['port'],
        proxyUsername: proxyMap['username'],
        proxyPassword: proxyMap['password'],
        proxyScheme: proxyMap['scheme'],
      ),
    );

    final YamlList jobsList = doc.contents.value['jobs'];

    final List<Subscription> subscriptionConfig = [];

    for (final jobs in jobsList) {
      subscriptionConfig.add(
        Subscription.byMap(
          config: context,
          map: jobs,
        ),
      );
    }

    return Config(
      globalConfig: context,
      subscriptionConfig: subscriptionConfig,
    );
  }
}

/// Base config of subscription
class BaseConfig {
  /// The global config of subscription, it comes from config.yaml.
  /// Define in the node of `config`.
  final Context globalConfig;

  /// The proxy config of subscription, it comes from config.yaml.
  ///
  /// Define in the node of `config.proxy`.
  final Proxy? proxy;

  /// The type of subscription, it comes from config.yaml.
  ///
  /// Define in the node of `jobs.type`.
  ///
  /// The value will decide how to handle the subscription.
  final String type;

  /// The enable of subscription, it comes from config.yaml.
  ///
  /// Define in the node of `jobs.enable`.
  ///
  /// If the value is false, it will not run.
  final bool enabled;

  /// The overwrite of subscription, it comes from config.yaml.
  ///
  /// Define in the node of `jobs.overwrite`.
  ///
  /// If the value is true, it will overwrite the old file.
  final bool overwrite;

  /// The base config of subscription
  BaseConfig({
    required this.globalConfig,
    required this.proxy,
    required this.type,
    required this.enabled,
    required this.overwrite,
  });
}

abstract class Subscription {
  factory Subscription.byMap({
    required Context config,
    required Map<String, dynamic> map,
  }) {
    final proxy = Proxy.byMap(map['proxy']);
    final globalProxy = config.proxy;
    final mergedProxy = Proxy.merge(globalProxy, proxy);
    final type = map['type'];

    final baseConfig = BaseConfig(
      globalConfig: config,
      proxy: mergedProxy,
      type: type,
      enabled: map['enable'] ?? true,
      overwrite: map['overwrite'] ?? false,
    );

    if (type == 'github-release') {
      return GithubReleaseSubscription(
        baseConfig: baseConfig,
        owner: map['owner'],
        repo: map['repo'],
        includePrerelease: map['includePrerelease'] ?? false,
      );
    }

    throw UnimplementedError('The type of subscription is not supported.');
  }

  Subscription({
    required this.baseConfig,
  });

  final BaseConfig baseConfig;

  Context get globalConfig => baseConfig.globalConfig;
  bool get enabled => baseConfig.enabled;
  Proxy? get proxy => baseConfig.proxy;
}

class GithubReleaseSubscription extends Subscription {
  GithubReleaseSubscription({
    required super.baseConfig,
    required this.owner,
    required this.repo,
    required this.includePrerelease,
  });

  final String owner;
  final String repo;
  final bool includePrerelease;
}
