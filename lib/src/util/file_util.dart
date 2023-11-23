import 'dart:io';

import 'package:path/path.dart';

class FileUtils {
  static String getTempPath() {
    if (Platform.isMacOS || Platform.isLinux) {
      return '/tmp/scli';
    }

    return join(Directory.systemTemp.path, 'scli');
  }
}
