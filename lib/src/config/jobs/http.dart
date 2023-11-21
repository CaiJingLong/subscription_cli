import 'job.dart';

class HttpJob extends Jobs {
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
  Future<void> doDownload(config) {
    throw UnimplementedError();
  }
}
