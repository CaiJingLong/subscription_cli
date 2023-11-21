import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;

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
  String? analyze() {
    LogBuffer buffer = LogBuffer();

    buffer.writeln('owner: $owner');
    buffer.writeln('repo: $repo');
    buffer.writeln('includePrerelease: $includePrerelease');

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

  @override
  Future<File> doDownload(config) async {
    final httpClient = HttpUtils(proxy: baseConfig.proxy);
    final url = 'https://api.github.com/repos/$owner/$repo/releases';

    final response = await httpClient.get(url);
    final releaseList = json.decode(response);
    final latestRelease = releaseList[0];
    logger.debug('latest release: ${prettyJsonFofObj(latestRelease)}');

    final tagName = latestRelease['tag_name'];

    final params = makeParams(tagName);
    final needAssetName = EnvUtil.replaceParams(this.asset, params);

    logger.log('need asset name: $needAssetName');

    final assets = latestRelease['assets'];
    logger.debug('assets: ${prettyJsonFofObj(assets)}');

    final asset = assets.firstWhere((element) {
      final name = element['name'];
      return name == needAssetName;
    });

    logger.debug('asset: ${prettyJsonFofObj(asset)}');
    final String downloadUrl = asset['browser_download_url'];

    logger.log('download url: $downloadUrl');

    final tmpDir = Directory.systemTemp.createTempSync();
    final outputFile = File(path.join(tmpDir.path, needAssetName));

    if (outputFile.existsSync()) {
      logger.log('Target file exists, delete it.');
      outputFile.deleteSync();
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
  Map configMap() {
    return {
      'owner': owner,
      'repo': repo,
      'includePrerelease': includePrerelease,
      'asset': asset,
    };
  }
}
