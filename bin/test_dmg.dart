import 'dart:io';

import 'package:subscription_cli/subscription_cli.dart';

void _showFileList(String tag, String dirPath) {
  print('=' * 30 + tag + '=' * 30);

  final dir = Directory(dirPath);
  final files = dir.listSync();

  for (final file in files) {
    print(file.path);
  }

  print('=' * 30 + tag + '=' * 30);
  print('\n');
}

Future<void> main(List<String> args) async {
  final dmgPath =
      '/Users/jinglongcai/Downloads/OBS-Studio-30.0.0-macOS-Intel.dmg';

  final file = File(dmgPath);
  final tmpOutputPath = '/tmp/obs';

  final dir = Directory(tmpOutputPath);

  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }

  _showFileList('before', tmpOutputPath);

  final helper = DmgHelper(dmgFile: file, mountPoint: tmpOutputPath);

  await helper.mount();

  _showFileList('mounted', tmpOutputPath);

  await helper.unmount();

  _showFileList('unmounted', tmpOutputPath);
}
