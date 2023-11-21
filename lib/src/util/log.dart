import 'dart:io';

final logger = Logger._();

class Logger {
  Logger._();

  bool showDebug = false;

  void debug(String message) {
    if (showDebug) {
      print(message);
    }
  }

  void log(String message) {
    print(message);
  }

  void write(String message) {
    stdout.write(message);
  }
}
