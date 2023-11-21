import 'dart:convert';

import 'package:yaml_edit/yaml_edit.dart';

mixin Mappable {
  Map toMap();

  String toJsonText([int indent = 0]) {
    if (indent == 0) {
      return json.encode(toMap());
    }
    return JsonEncoder.withIndent(' ' * indent).convert(toMap());
  }

  String toYamlText([int indent = 2]) {
    final map = toMap();
    final yamlEditor = YamlEditor('');
    yamlEditor.update([], map);
    return yamlEditor.toString();
  }
}
