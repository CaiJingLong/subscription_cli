import 'dart:io';

class EnvUtil {
  static String replaceEnv(String srcText) {
    final RegExp regExp = RegExp(r'\$\{(\w+)\}');
    final StringBuffer buffer = StringBuffer();

    for (final line in srcText.split('\n')) {
      if (line.trim().startsWith('#')) {
        continue;
      }

      int start = 0;
      for (final match in regExp.allMatches(line)) {
        final String key = match.group(1)!;
        final String value = _getEnv(key);
        buffer.write(line.substring(start, match.start));
        buffer.write(value);
        start = match.end;
      }
      buffer.write(line.substring(start));

      buffer.write('\n');
    }

    print('buffer: \n$buffer');

    return buffer.toString();
  }

  static String _getEnv(String key) {
    final String? value = Platform.environment[key];
    if (value == null) {
      throw ArgumentError('The environment variable $key is not defined.');
    }
    return value;
  }

  static String replaceParams(String text, Map env) {
    // #{} is used to replace the value of the variable.
    final RegExp regExp = RegExp(r'\#\{(\w+)\}');
    final StringBuffer buffer = StringBuffer();
    int start = 0;
    for (final match in regExp.allMatches(text)) {
      final String key = match.group(1)!;
      final String? value = env[key];
      if (value == null) {
        throw ArgumentError('The value of $key is required in job, '
            'but it is not defined.');
      }
      buffer.write(text.substring(start, match.start));
      buffer.write(value);
      start = match.end;
    }

    buffer.write(text.substring(start));

    return buffer.toString();
  }
}
