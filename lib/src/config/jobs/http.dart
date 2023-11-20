import 'job.dart';
import '../config.dart';

class HttpJob extends Jobs {
  HttpJob({
    required super.baseConfig,
  });

  @override
  String? analyze() {
    throw UnimplementedError();
  }
}
