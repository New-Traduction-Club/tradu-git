import 'package:flutter_test/flutter_test.dart';
import 'package:tradu_git/src/workspace_provider.dart';

void main() {
  group('Path Conversion Helper Tests', () {
    const repoPath = '/data/user/0/com.tdclub.tradu_git/files/repos/my-repo';

    test('toRelative converts nested absolute path to relative', () {
      const absPath = '$repoPath/lib/main.dart';
      final rel = toRelative(absPath, repoPath);
      expect(rel, 'lib/main.dart');
    });

    test('toRelative preserves path if not matching repo path prefix', () {
      const externalPath = '/some/other/path/lib/main.dart';
      final rel = toRelative(externalPath, repoPath);
      expect(rel, externalPath);
    });

    test('toAbsolute resolves relative path to absolute', () {
      const relPath = 'lib/ui/theme.dart';
      final abs = toAbsolute(relPath, repoPath);
      expect(abs, '$repoPath/lib/ui/theme.dart');
    });

    test('toAbsolute ignores absolute paths and returns them directly', () {
      const absPath = '/another/absolute/path.dart';
      final abs = toAbsolute(absPath, repoPath);
      expect(abs, absPath);
    });
  });
}
