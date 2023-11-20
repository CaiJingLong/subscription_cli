# 逐级向上找，找到 pubspec.yaml

import os


current_dir = os.path.dirname(os.path.abspath(__file__))


def find_pubspec_yaml(path):
    if path == "/":
        return None
    if os.path.exists(os.path.join(path, "pubspec.yaml")):
        return os.path.join(path, "pubspec.yaml")
    return find_pubspec_yaml(os.path.dirname(path))


spec_path = find_pubspec_yaml(current_dir)

spec_dir = os.path.dirname(spec_path)

if spec_path is None:
    raise Exception("pubspec.yaml not found")

with open(spec_path, "r") as f:
    lines = f.readlines()

version_line = None
for i, line in enumerate(lines):
    if line.startswith("version"):
        version_line = line
        break

if version_line is None:
    raise Exception("version not found")


# Get version
version = version_line.split(":")[1].strip()

dart_code = """
class Version {
  static const String version = '%s';
}
""" % (
    version
)

dart_code = dart_code.lstrip()

with open(os.path.join(spec_dir, "lib", "src", "version.dart"), "w") as f:
    f.write(dart_code)
