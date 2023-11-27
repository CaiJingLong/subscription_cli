import 'dart:io';

import 'package:path/path.dart';

import 'job.dart';
import 'job_base_config.dart';

class HttpJob extends Job {
  HttpJob({
    required super.baseConfig,
    required this.url,
  });

  final String url;

  @override
  JobType get typeEnum => JobType.http;

  @override
  String? analyze() {
    return 'url: $url';
  }

  @override
  Future<File> doDownload(config) async {
    final httpClient = getHttpClient();
    final dlDir = getDownloadPath();

    final uri = Uri.parse(url);
    final filename = uri.pathSegments.last;
    final outputPath = join(dlDir.path, filename);
    await httpClient.download(url: url, path: outputPath);

    return File(outputPath);
  }

  @override
  Map jobMap() {
    return {
      'url': url,
    };
  }

  static Job example(BaseConfig baseConfig) {
    return HttpJob(
      baseConfig: baseConfig,
      url: '',
    );
  }
}
