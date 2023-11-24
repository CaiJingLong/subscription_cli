import 'dart:io';

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
  Future<File> doDownload(config) {
    throw UnimplementedError();
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
