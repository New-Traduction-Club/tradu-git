import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tradu_git/src/workspace_provider.dart';

class SoraEditorView extends ConsumerStatefulWidget {
  const SoraEditorView({super.key});

  @override
  ConsumerState<SoraEditorView> createState() => _SoraEditorViewState();
}

class _SoraEditorViewState extends ConsumerState<SoraEditorView> with WidgetsBindingObserver {
  static const _channel = MethodChannel('sora_editor');
  String? _loadedFilePath;
  late final FocusNode _focusNode;
  bool _isFocusingFromNative = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFlutterFocusChanged);
    _channel.setMethodCallHandler(_handleMethodCall);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadActiveFile();
    });
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFlutterFocusChanged);
    _focusNode.dispose();
    _channel.setMethodCallHandler(null);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      final activeFile = ref.read(activeFilePathProvider);
      _saveCurrentToDraft(activeFile);
    }
  }

  File _getDraftFile(String originalFilePath) {
    final reposPath = ref.read(internalReposPathProvider);
    if (reposPath == null) {
      throw StateError('reposPath not loaded yet');
    }
    final parentPath = Directory(reposPath).parent.path;
    final draftsDir = Directory('$parentPath/drafts');
    if (!draftsDir.existsSync()) {
      draftsDir.createSync(recursive: true);
    }
    final encoded = Uri.encodeComponent(originalFilePath);
    return File('${draftsDir.path}/$encoded.draft');
  }

  Future<void> _saveCurrentToDraft(String? filePath) async {
    debugPrint('[Dart] _saveCurrentToDraft starting for $filePath');
    if (filePath == null) return;
    final openFiles = ref.read(openFilesProvider);
    if (!openFiles.contains(filePath)) {
      debugPrint('[Dart] _saveCurrentToDraft skipped: file tab is closed');
      return;
    }
    try {
      // Save scroll and cursor state
      final Map<dynamic, dynamic>? stateMap = await _channel.invokeMethod('getEditorState');
      debugPrint('[Dart] _saveCurrentToDraft got getEditorState stateMap: $stateMap');
      if (stateMap != null) {
        final scrollX = stateMap['scrollX'] as int? ?? 0;
        final scrollY = stateMap['scrollY'] as int? ?? 0;
        final cursorLine = stateMap['cursorLine'] as int? ?? 0;
        final cursorColumn = stateMap['cursorColumn'] as int? ?? 0;

        debugPrint('[Dart] _saveCurrentToDraft saving state in provider: scrollX=$scrollX scrollY=$scrollY cursorLine=$cursorLine cursorColumn=$cursorColumn');
        ref.read(fileEditorStatesProvider.notifier).saveState(
          filePath,
          EditorStateInfo(
            scrollX: scrollX,
            scrollY: scrollY,
            cursorLine: cursorLine,
            cursorColumn: cursorColumn,
          ),
        );
      }

      // Save draft content
      final String? text = await _channel.invokeMethod('getText');
      if (text == null) return;

      final originalFile = File(filePath);
      if (!originalFile.existsSync()) {
        return;
      }
      final originalText = await originalFile.readAsString();
      final draftFile = _getDraftFile(filePath);

      if (text != originalText) {
        await draftFile.writeAsString(text);
        ref.read(dirtyFilesProvider.notifier).setDirty(filePath, true);
      } else {
        if (draftFile.existsSync()) {
          await draftFile.delete();
        }
        ref.read(dirtyFilesProvider.notifier).setDirty(filePath, false);
      }
    } catch (e) {
      debugPrint('Error saving draft for $filePath: $e');
    }
  }

  Future<void> _loadActiveFile() async {
    final activeFile = ref.read(activeFilePathProvider);
    debugPrint('[Dart] _loadActiveFile starting for $activeFile');
    if (activeFile != null) {
      try {
        final draftFile = _getDraftFile(activeFile);
        String content;
        if (draftFile.existsSync()) {
          content = await draftFile.readAsString();
          ref.read(dirtyFilesProvider.notifier).setDirty(activeFile, true);
        } else {
          content = await File(activeFile).readAsString();
        }

        // Retrieve scroll and cursor state
        final editorStates = ref.read(fileEditorStatesProvider);
        final stateInfo = editorStates[activeFile];
        final scrollX = stateInfo?.scrollX ?? 0;
        final scrollY = stateInfo?.scrollY ?? 0;
        final cursorLine = stateInfo?.cursorLine ?? 0;
        final cursorColumn = stateInfo?.cursorColumn ?? 0;

        debugPrint('[Dart] _loadActiveFile retrieved state from provider: scrollX=$scrollX scrollY=$scrollY cursorLine=$cursorLine cursorColumn=$cursorColumn');
        await _channel.invokeMethod('setText', {
          'text': content,
          'scrollX': scrollX,
          'scrollY': scrollY,
          'cursorLine': cursorLine,
          'cursorColumn': cursorColumn,
        });
        _loadedFilePath = activeFile;
      } catch (e) {
        debugPrint('Error reading active file: $e');
        await _channel.invokeMethod('setText', {'text': 'Error reading file: $e'});
      }
    } else {
      await _channel.invokeMethod('setText', {
        'text': 'Ahorita voy a quitar esto'
      });
      _loadedFilePath = null;
    }
  }

  void _onFlutterFocusChanged() {
    debugPrint('[Dart] Flutter focus changed: hasFocus=${_focusNode.hasFocus}');
    if (_isFocusingFromNative) return;
    if (_focusNode.hasFocus) {
      _channel.invokeMethod('requestFocus');
    } else {
      _channel.invokeMethod('clearFocus');
    }
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    debugPrint('[Dart] Received method call: ${call.method}');
    switch (call.method) {
      case 'onFocusGained':
        if (!_focusNode.hasFocus) {
          _isFocusingFromNative = true;
          _focusNode.requestFocus();
          _isFocusingFromNative = false;
        }
        break;
      case 'onFocusLost':
        if (_focusNode.hasFocus) {
          _isFocusingFromNative = true;
          _focusNode.unfocus();
          _isFocusingFromNative = false;
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to changes to activeFilePathProvider to reload file dynamically
    ref.listen<String?>(activeFilePathProvider, (previous, next) {
      debugPrint('[Dart] activeFilePathProvider listener triggered: previous=$previous next=$next _loadedFilePath=$_loadedFilePath');
      if (next != _loadedFilePath) {
        _saveCurrentToDraft(previous).then((_) {
          _loadActiveFile();
        });
      }
    });

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: (node, event) {
        final key = event.logicalKey;
        if (key == LogicalKeyboardKey.arrowUp ||
            key == LogicalKeyboardKey.arrowDown ||
            key == LogicalKeyboardKey.arrowLeft ||
            key == LogicalKeyboardKey.arrowRight ||
            key == LogicalKeyboardKey.tab) {
          return KeyEventResult.skipRemainingHandlers;
        }
        return KeyEventResult.ignored;
      },
      child: const AndroidView(
        viewType: 'sora_editor_view',
        layoutDirection: TextDirection.ltr,
      ),
    );
  }
}
