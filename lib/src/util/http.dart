import 'dart:io';

import 'package:subscription_cli/src/config/config.dart';

class HttpUtils {
  static Future<void> download(
    String url,
    String path,
    Function(int current, int total) downloadBytesCallback, {
    Proxy? proxy,
  }) async {
    HttpClient httpClient = HttpClient();
    if (proxy != null) {
      httpClient.findProxy = (uri) {
        return 'PROXY ${proxy.proxyHost}:${proxy.proxyPort}';
      };
    }

    HttpClientRequest request = await httpClient.getUrl(Uri.parse(url));
    HttpClientResponse response = await request.close();

    int total = response.contentLength;
    int current = 0;

    var file = File(path);
    var sink = file.openWrite();

    response.listen(
      (data) {
        sink.add(data);
        current += data.length;
        downloadBytesCallback(current, total);
      },
      onDone: () {
        sink.close();
      },
    );
  }
}
