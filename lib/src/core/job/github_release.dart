import 'dart:convert';
import 'dart:io';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as path;
import 'package:path/path.dart';

import 'package:subscription_cli/subscription_cli.dart';

class GithubReleaseJob extends Job {
  const GithubReleaseJob({
    required super.baseConfig,
    required this.owner,
    required this.repo,
    required this.includePrerelease,
    required this.asset,
  });

  final String owner;
  final String repo;
  final bool includePrerelease;
  final String asset;

  @override
  JobType get typeEnum => JobType.githubRelease;

  @override
  String? analyze() {
    LogBuffer buffer = LogBuffer();

    buffer.writeln('owner: $owner');
    buffer.writeln('repo: $repo');
    buffer.writeln('includePrerelease: $includePrerelease');
    buffer.writeln('asset pattern: $asset');

    final url = 'https://api.github.com/repos/$owner/$repo/releases';
    buffer.writeln('release api url: $url');

    return buffer.toString();
  }

  Map makeParams(String tag) {
    return {
      ...params,
      'version': tag,
    };
  }

  Future findAsset(HttpUtils httpClient) async {
    final url = 'https://api.github.com/repos/$owner/$repo/releases';

    final response = await httpClient.get(url);
    final List releaseList = json.decode(response);

    if (releaseList.isEmpty) {
      throw Exception('Not found release.');
    }

    var latestRelease = releaseList[0];

    if (!includePrerelease) {
      logger.log('include prerelease.');

      for (final release in releaseList) {
        final isPrerelease = release['prerelease'];
        if (!isPrerelease) {
          latestRelease = release;
          break;
        }
      }
    }

    logger.debug('latest release: ${prettyJsonFofObj(latestRelease)}');

    final tagName = latestRelease['tag_name'];

    final params = makeParams(tagName);
    final needAssetName = EnvUtil.replaceParams(asset, params);

    logger.log('need asset name: $needAssetName');

    final List assets = latestRelease['assets'];
    logger.debug('assets: ${prettyJsonFofObj(assets)}');

    for (final asset in assets) {
      final name = asset['name'];
      if (name == needAssetName) {
        return asset;
      }
    }

    // use glob pattern
    for (final asset in assets) {
      final name = asset['name'];
      if (Glob(needAssetName).matches(name)) {
        return asset;
      }
    }

    throw Exception('Asset not found.');
  }

  @override
  Future<File> doDownload(config) async {
    final httpClient = HttpUtils(proxy: baseConfig.proxy);
    final asset = await findAsset(httpClient);

    final needAssetName = asset['name'];

    logger.debug('asset: ${prettyJsonFofObj(asset)}');
    final String downloadUrl = asset['browser_download_url'];

    logger.log('download url: $downloadUrl');

    final tmpDir = Directory(join(getTempPath(), 'download'));
    final outputFile = File(path.join(tmpDir.path, needAssetName));

    if (outputFile.existsSync()) {
      logger.log('Target file exists, delete it.');
      outputFile.deleteSync();
    } else {
      outputFile.parent.createSync(recursive: true);
    }

    logger.log('output file: ${outputFile.path}');

    await httpClient.download(
      url: downloadUrl,
      path: outputFile.path,
      totalSize: asset['size'],
      downloadBytesCallback: (current, total) {
        final progress = (current / total * 100).toStringAsFixed(2);
        logger.write('\rDownload progress: $progress%');
      },
      doneCallback: () {
        logger.write('\n');
      },
    );

    logger.log('Download done.');

    return outputFile;
  }

  @override
  Map jobMap() {
    return {
      'owner': owner,
      'repo': repo,
      'includePrerelease': includePrerelease,
      'asset': asset,
    };
  }

  static GithubReleaseJob example(BaseConfig baseConfig) {
    return GithubReleaseJob(
      baseConfig: baseConfig,
      owner: 'caijinglong',
      repo: 'subscription_cli',
      asset: 'mac*.tar.gz',
      includePrerelease: false,
    );
  }
}
