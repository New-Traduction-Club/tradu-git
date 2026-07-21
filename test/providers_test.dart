import 'package:flutter_test/flutter_test.dart';
import 'package:tradu_git/src/workspace_provider.dart';

void main() {
  group('OpenFilesNotifier Tests', () {
    test('starts with empty list', () {
      final notifier = OpenFilesNotifier();
      expect(notifier.state, isEmpty);
    });

    test('openFile adds unique file paths', () {
      final notifier = OpenFilesNotifier();
      notifier.openFile('/path/to/a.dart');
      notifier.openFile('/path/to/b.dart');
      notifier.openFile('/path/to/a.dart');

      expect(notifier.state, ['/path/to/a.dart', '/path/to/b.dart']);
    });

    test('closeFile removes specified path', () {
      final notifier = OpenFilesNotifier();
      notifier.openFile('/path/to/a.dart');
      notifier.openFile('/path/to/b.dart');
      notifier.closeFile('/path/to/a.dart');

      expect(notifier.state, ['/path/to/b.dart']);
    });

    test('clear resets state to empty', () {
      final notifier = OpenFilesNotifier();
      notifier.openFile('/path/to/a.dart');
      notifier.clear();
      expect(notifier.state, isEmpty);
    });
  });

  group('DirtyFilesNotifier Tests', () {
    test('starts with empty set', () {
      final notifier = DirtyFilesNotifier();
      expect(notifier.state, isEmpty);
    });

    test('setDirty updates dirty files set correctly', () {
      final notifier = DirtyFilesNotifier();
      notifier.setDirty('/path/to/a.dart', true);
      notifier.setDirty('/path/to/b.dart', true);
      notifier.setDirty('/path/to/a.dart', true);

      expect(notifier.state, {'/path/to/a.dart', '/path/to/b.dart'});

      notifier.setDirty('/path/to/a.dart', false);
      expect(notifier.state, {'/path/to/b.dart'});
    });

    test('clear empties set', () {
      final notifier = DirtyFilesNotifier();
      notifier.setDirty('/path/to/a.dart', true);
      notifier.clear();
      expect(notifier.state, isEmpty);
    });
  });

  group('FileEditorStatesNotifier Tests', () {
    test('starts with empty map', () {
      final notifier = FileEditorStatesNotifier();
      expect(notifier.state, isEmpty);
    });

    test('saveState saves state coordinates', () {
      final notifier = FileEditorStatesNotifier();
      const info1 = EditorStateInfo(
        scrollX: 10,
        scrollY: 20,
        cursorLine: 1,
        cursorColumn: 2,
      );
      const info2 = EditorStateInfo(
        scrollX: 50,
        scrollY: 60,
        cursorLine: 3,
        cursorColumn: 4,
      );

      notifier.saveState('/path/to/a.dart', info1);
      notifier.saveState('/path/to/b.dart', info2);

      expect(notifier.state['/path/to/a.dart'], info1);
      expect(notifier.state['/path/to/b.dart'], info2);
    });

    test('removeState deletes coordinates for path', () {
      final notifier = FileEditorStatesNotifier();
      const info = EditorStateInfo(
        scrollX: 10,
        scrollY: 20,
        cursorLine: 1,
        cursorColumn: 2,
      );

      notifier.saveState('/path/to/a.dart', info);
      notifier.removeState('/path/to/a.dart');

      expect(notifier.state.containsKey('/path/to/a.dart'), isFalse);
    });

    test('clear empties coordinates map', () {
      final notifier = FileEditorStatesNotifier();
      const info = EditorStateInfo(
        scrollX: 10,
        scrollY: 20,
        cursorLine: 1,
        cursorColumn: 2,
      );

      notifier.saveState('/path/to/a.dart', info);
      notifier.clear();

      expect(notifier.state, isEmpty);
    });
  });
}
