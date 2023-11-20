import 'package:subscription_cli/src/util/buffer.dart';

import 'job.dart';

class GithubReleaseJob extends Jobs {
  const GithubReleaseJob({
    required super.baseConfig,
    required this.owner,
    required this.repo,
    required this.includePrerelease,
  });

  final String owner;
  final String repo;
  final bool includePrerelease;

  @override
  String? analyze() {
    LogBuffer buffer = LogBuffer();

    buffer.writeln('owner: $owner');
    buffer.writeln('repo: $repo');
    buffer.writeln('includePrerelease: $includePrerelease');

    return buffer.toString();
  }
}
