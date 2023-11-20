import 'dart:io';

import 'package:yaml/yaml.dart';

/// The context of config
class Context {
  const Context({
    required this.basePath,
    required this.proxy,
    required this.yamlDocument,
  });

  /// The original yaml document.
  final YamlDocument? yamlDocument;

  /// Current base path
  final String? basePath;

  /// Current proxy
  final Proxy? proxy;
}

class Proxy {
  const Proxy({
    required this.proxyHost,
    required this.proxyPort,
    required this.proxyUsername,
    required this.proxyPassword,
    required this.proxyScheme,
  });

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

  /// Create a proxy by [map].
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
}

class Config {
  const Config({
    required this.globalConfig,
    required this.subscriptionConfig,
  });

  /// Current global config
  final Context globalConfig;

  /// Current subscription config
  final List<Subscription> subscriptionConfig;

  factory Config.fromYamlText(String yamlText) {
    final YamlDocument doc = loadYamlDocument(yamlText);

    final Map? globalConfigMap = doc.contents.value['config'];
    final Map? proxyMap = globalConfigMap?['proxy'];

    final context = Context(
      yamlDocument: doc,
      basePath: globalConfigMap?['basePath'],
      proxy: Proxy(
        proxyHost: proxyMap?['host'],
        proxyPort: proxyMap?['port'],
        proxyUsername: proxyMap?['username'],
        proxyPassword: proxyMap?['password'],
        proxyScheme: proxyMap?['scheme'],
      ),
    );

    final List? jobsList = doc.contents.value?['jobs'];

    final List<Subscription> subscriptionConfig = [];

    for (final jobs in jobsList ?? []) {
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

  factory Config.fromYamlFile(File yamlFile) {
    return Config.fromYamlText(yamlFile.readAsStringSync());
  }

  String analyze() {
    return 'text';
  }

  String analyzeJson() {
    return 'json';
  }
}

/// Base config of subscription
class BaseConfig {
  /// The base config of subscription
  const BaseConfig({
    required this.globalConfig,
    required this.proxy,
    required this.type,
    required this.enabled,
    required this.overwrite,
  });

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
}

/// The base class of subscription
abstract class Subscription {
  const Subscription({
    required this.baseConfig,
  });

  /// Create a subscription by [map].
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

    // Use the type to decide which subscription to create.
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

  final BaseConfig baseConfig;

  Context get globalConfig => baseConfig.globalConfig;
  bool get enabled => baseConfig.enabled;
  Proxy? get proxy => baseConfig.proxy;
}

class GithubReleaseSubscription extends Subscription {
  const GithubReleaseSubscription({
    required super.baseConfig,
    required this.owner,
    required this.repo,
    required this.includePrerelease,
  });

  final String owner;
  final String repo;
  final bool includePrerelease;
}
