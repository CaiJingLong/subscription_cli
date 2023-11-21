import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:subscription_cli/src/core/config.dart';
import 'package:subscription_cli/src/defs.dart';

typedef Decoder = Converter<List<int>, String>;

class HttpUtils {
  final Proxy? proxy;
  final String? githubToken;

  HttpUtils({
    this.proxy,
    this.githubToken,
  });

  HttpClient _createClient() {
    HttpClient httpClient = HttpClient();
    final proxy = this.proxy;
    if (proxy != null) {
      httpClient.findProxy = (uri) {
        return 'PROXY ${proxy.proxyHost}:${proxy.proxyPort}';
      };
    }
    return httpClient;
  }

  void _checkAddGithubToken(Uri uri, HttpHeaders headers) {
    if (uri.host == 'github.com' || uri.host.endsWith('.github.com')) {
      if (githubToken != null) {
        headers.add('Authorization', 'Bearer $githubToken');
      }
    }
  }

  Future<void> download({
    required String url,
    required String path,
    int? totalSize,
    Function(int current, int total)? downloadBytesCallback,
    VoidCallback? doneCallback,
  }) async {
    final Completer<void> completer = Completer<void>();
    final httpClient = _createClient();
    final uri = Uri.parse(url);

    HttpClientRequest request = await httpClient.getUrl(uri);
    _checkAddGithubToken(uri, request.headers);
    HttpClientResponse response = await request.close();

    int total = totalSize ?? response.contentLength;
    int current = 0;

    var file = File(path);
    var sink = file.openWrite();

    response.listen(
      (data) {
        sink.add(data);
        current += data.length;
        downloadBytesCallback?.call(current, total);
      },
      onDone: () {
        sink.close();
        httpClient.close();
        doneCallback?.call();
        completer.complete();
      },
    );

    return completer.future;
  }

  Future<String> get(
    String url, {
    Proxy? proxy,
    Decoder? decoder,
  }) async {
    decoder ??= utf8.decoder;
    final httpClient = _createClient();

    final uri = Uri.parse(url);
    HttpClientRequest request = await httpClient.getUrl(uri);
    _checkAddGithubToken(uri, request.headers);
    HttpClientResponse response = await request.close();
    var result = await response.transform(decoder).join();
    httpClient.close();
    return result;
  }
}
