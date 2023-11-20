class LogBuffer {
  final StringBuffer sb = StringBuffer();

  void write(
    String message, {
    int indent = 0,
  }) {
    sb.write(' ' * indent);
    sb.write(message);
  }

  void writeln(
    String message, {
    int indent = 0,
  }) {
    sb.write(' ' * indent);
    sb.writeln(message);
  }

  void newLine([int count = 1]) => sb.write('\n' * count);

  void writeMultiLine(
    String? message, {
    int indent = 0,
  }) {
    if (message == null) return;

    final lines = message.split('\n');
    for (var line in lines) {
      sb.write(' ' * indent);
      sb.writeln(line);
    }
  }

  @override
  String toString() => sb.toString();
}
