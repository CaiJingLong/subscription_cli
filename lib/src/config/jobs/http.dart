import 'dart:io';

import 'job.dart';

class HttpJob extends Job {
  HttpJob({
    required super.baseConfig,
    required this.url,
  });

  final String url;

  @override
  String? analyze() {
    return 'url: $url';
  }

  @override
  Future<File> doDownload(config) {
    throw UnimplementedError();
  }
}
