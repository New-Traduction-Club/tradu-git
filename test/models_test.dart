import 'package:flutter_test/flutter_test.dart';
import 'package:tradu_git/src/workspace_provider.dart';

void main() {
  group('EditorStateInfo JSON Serialization Tests', () {
    test('toJson produces correct structure', () {
      const info = EditorStateInfo(
        scrollX: 120,
        scrollY: 340,
        cursorLine: 12,
        cursorColumn: 5,
      );
      final json = info.toJson();
      expect(json['scrollX'], 120);
      expect(json['scrollY'], 340);
      expect(json['cursorLine'], 12);
      expect(json['cursorColumn'], 5);
    });

    test('fromJson restores correct state', () {
      final json = {
        'scrollX': 80,
        'scrollY': 250,
        'cursorLine': 4,
        'cursorColumn': 10,
      };
      final info = EditorStateInfo.fromJson(json);
      expect(info.scrollX, 80);
      expect(info.scrollY, 250);
      expect(info.cursorLine, 4);
      expect(info.cursorColumn, 10);
    });

    test('fromJson handles null values with fallback defaults', () {
      final info = EditorStateInfo.fromJson({});
      expect(info.scrollX, 0);
      expect(info.scrollY, 0);
      expect(info.cursorLine, 0);
      expect(info.cursorColumn, 0);
    });
  });

  group('AppSettings JSON Serialization Tests', () {
    test('toJson and fromJson correctly convert models', () {
      const settings = AppSettings(
        wordWrap: true,
        theme: 'darcula',
        simpleMode: true,
      );
      final json = settings.toJson();
      expect(json['wordWrap'], true);
      expect(json['theme'], 'darcula');
      expect(json['simpleMode'], true);

      final restored = AppSettings.fromJson(json);
      expect(restored.wordWrap, true);
      expect(restored.theme, 'darcula');
      expect(restored.simpleMode, true);
    });

    test('fromJson handles null values with defaults', () {
      final restored = AppSettings.fromJson({});
      expect(restored.wordWrap, false);
      expect(restored.theme, 'darcula');
      expect(restored.simpleMode, false);
    });

    test('copyWith copies state with selective modifications', () {
      const base = AppSettings(
        wordWrap: false,
        theme: 'light',
        simpleMode: false,
      );
      final updated = base.copyWith(wordWrap: true, theme: 'darcula');
      expect(updated.wordWrap, true);
      expect(updated.theme, 'darcula');
      expect(updated.simpleMode, false);
    });
  });
}
