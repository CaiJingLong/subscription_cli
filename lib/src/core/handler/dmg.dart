import 'dart:io';

class DmgHelper {
  final File dmgFile;

  final String mountPoint;

  DmgHelper({
    required this.dmgFile,
    required this.mountPoint,
  });

  Future<void> findMountPoint() async {
    final result = await Process.run('hdiutil', [
      'info',
    ]);
    if (result.exitCode != 0) {
      throw Exception(
          'Failed to find mount point, exit code: ${result.exitCode}');
    }
  }

  Future<void> mount() async {
    final result = await Process.run('hdiutil', [
      'attach',
      '-mountpoint',
      mountPoint,
      dmgFile.path,
    ]);

    if (result.exitCode != 0) {
      throw Exception(
          'Failed to mount dmg file, exit code: ${result.exitCode}');
    }
  }

  Future<void> unmount() async {
    await mount();

    final result = await Process.run('hdiutil', [
      'detach',
      mountPoint,
    ]);
    if (result.exitCode != 0) {
      throw Exception(
          'Failed to unmount dmg file, exit code: ${result.exitCode}');
    }
  }
}
