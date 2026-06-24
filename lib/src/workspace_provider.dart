import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tradu_git/src/rust/api/simple.dart';

/// Provider to store the selected local storage path (external backup workspace).
final workspacePathProvider = StateNotifierProvider<WorkspacePathNotifier, String?>((ref) {
  return WorkspacePathNotifier();
});

class WorkspacePathNotifier extends StateNotifier<String?> {
  WorkspacePathNotifier() : super(null);

  void setPath(String? path) {
    state = path;
  }
}

/// Provider to store the app's internal repositories storage path (where Git clones and edits run natively).
final internalReposPathProvider = StateNotifierProvider<InternalReposPathNotifier, String?>((ref) {
  return InternalReposPathNotifier();
});

class InternalReposPathNotifier extends StateNotifier<String?> {
  InternalReposPathNotifier() : super(null);

  void setPath(String? path) {
    state = path;
  }
}

/// Provider to store the active repository path.
final activeRepoPathProvider = StateNotifierProvider<ActiveRepoPathNotifier, String?>((ref) {
  return ActiveRepoPathNotifier();
});

class ActiveRepoPathNotifier extends StateNotifier<String?> {
  ActiveRepoPathNotifier() : super(null);

  void setPath(String? path) {
    state = path;
  }
}

/// Provider to store the active file path open in the editor.
final activeFilePathProvider = StateNotifierProvider<ActiveFilePathNotifier, String?>((ref) {
  return ActiveFilePathNotifier();
});

class ActiveFilePathNotifier extends StateNotifier<String?> {
  ActiveFilePathNotifier() : super(null);

  void setPath(String? path) {
    state = path;
  }
}

/// Provider to track open files in the tabs.
final openFilesProvider = StateNotifierProvider<OpenFilesNotifier, List<String>>((ref) {
  return OpenFilesNotifier();
});

class OpenFilesNotifier extends StateNotifier<List<String>> {
  OpenFilesNotifier() : super([]);

  void openFile(String path) {
    if (!state.contains(path)) {
      state = [...state, path];
    }
  }

  void closeFile(String path) {
    state = state.where((p) => p != path).toList();
  }

  void clear() {
    state = [];
  }
}

/// Provider to track expanded directories in the file explorer.
final expandedDirsProvider = StateNotifierProvider<ExpandedDirsNotifier, Set<String>>((ref) {
  return ExpandedDirsNotifier();
});

class ExpandedDirsNotifier extends StateNotifier<Set<String>> {
  ExpandedDirsNotifier() : super({});

  void toggle(String path) {
    if (state.contains(path)) {
      state = state.where((p) => p != path).toSet();
    } else {
      state = {...state, path};
    }
  }

  void clear() {
    state = {};
  }
}

/// Provider to track which files have unsaved changes (dirty drafts).
final dirtyFilesProvider = StateNotifierProvider<DirtyFilesNotifier, Set<String>>((ref) {
  return DirtyFilesNotifier();
});

class DirtyFilesNotifier extends StateNotifier<Set<String>> {
  DirtyFilesNotifier() : super({});

  void setDirty(String path, bool isDirty) {
    if (isDirty) {
      if (!state.contains(path)) {
        state = {...state, path};
      }
    } else {
      if (state.contains(path)) {
        state = state.where((p) => p != path).toSet();
      }
    }
  }

  void clear() {
    state = {};
  }
}

class EditorStateInfo {
  final int scrollX;
  final int scrollY;
  final int cursorLine;
  final int cursorColumn;

  const EditorStateInfo({
    required this.scrollX,
    required this.scrollY,
    required this.cursorLine,
    required this.cursorColumn,
  });
}

final fileEditorStatesProvider = StateNotifierProvider<FileEditorStatesNotifier, Map<String, EditorStateInfo>>((ref) {
  return FileEditorStatesNotifier();
});

class FileEditorStatesNotifier extends StateNotifier<Map<String, EditorStateInfo>> {
  FileEditorStatesNotifier() : super({});

  void saveState(String path, EditorStateInfo info) {
    state = {
      ...state,
      path: info,
    };
  }

  void removeState(String path) {
    state = Map.from(state)..remove(path);
  }

  void clear() {
    state = {};
  }
}

/// Provider to reactively rebuild the file explorer when new files or folders are created.
final fileExplorerRefreshProvider = StateProvider.autoDispose<int>((ref) => 0);

class GitStatusNotifier extends StateNotifier<AsyncValue<String>> {
  GitStatusNotifier(this._ref) : super(const AsyncValue.loading()) {
    _ref.listen<String?>(activeRepoPathProvider, (prev, next) {
      refresh();
    });
  }

  final Ref _ref;

  Future<void> refresh() async {
    final repoPath = _ref.read(activeRepoPathProvider);
    if (repoPath == null) {
      state = const AsyncValue.data('Sin repositorio seleccionado.');
      return;
    }
    state = const AsyncValue.loading();
    try {
      final status = await gitStatus(path: repoPath);
      state = AsyncValue.data(status);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final gitStatusProvider = StateNotifierProvider<GitStatusNotifier, AsyncValue<String>>((ref) {
  return GitStatusNotifier(ref)..refresh();
});

class GithubTokenNotifier extends StateNotifier<String?> {
  final Ref _ref;

  GithubTokenNotifier(this._ref) : super(null) {
    _ref.listen<String?>(internalReposPathProvider, (prev, next) {
      _loadToken();
    });
    _loadToken();
  }

  void _loadToken() {
    final reposPath = _ref.read(internalReposPathProvider);
    if (reposPath == null) return;
    final file = File('$reposPath/../github_token.txt');
    if (file.existsSync()) {
      try {
        state = file.readAsStringSync().trim();
      } catch (e) {
        state = null;
      }
    } else {
      state = null;
    }
  }

  Future<void> saveToken(String? token) async {
    final reposPath = _ref.read(internalReposPathProvider);
    if (reposPath == null) return;
    final file = File('$reposPath/../github_token.txt');
    if (token == null || token.isEmpty) {
      if (file.existsSync()) {
        await file.delete();
      }
      state = null;
    } else {
      await file.writeAsString(token.trim());
      state = token.trim();
    }
  }
}

final githubTokenProvider = StateNotifierProvider<GithubTokenNotifier, String?>((ref) {
  return GithubTokenNotifier(ref);
});

class GithubUserInfo {
  final String username;
  final String email;

  GithubUserInfo({required this.username, required this.email});

  factory GithubUserInfo.fromJson(Map<String, dynamic> json) {
    return GithubUserInfo(
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'username': username,
    'email': email,
  };
}

class GithubUserNotifier extends StateNotifier<GithubUserInfo?> {
  final Ref _ref;

  GithubUserNotifier(this._ref) : super(null) {
    _ref.listen<String?>(internalReposPathProvider, (prev, next) {
      _loadUserInfo();
    });
    _loadUserInfo();
  }

  void _loadUserInfo() {
    final reposPath = _ref.read(internalReposPathProvider);
    if (reposPath == null) return;
    final file = File('$reposPath/../github_user_info.json');
    if (file.existsSync()) {
      try {
        final content = file.readAsStringSync();
        final json = jsonDecode(content) as Map<String, dynamic>;
        state = GithubUserInfo.fromJson(json);
      } catch (e) {
        state = null;
      }
    } else {
      state = null;
    }
  }

  Future<void> saveUserInfo(GithubUserInfo? info) async {
    final reposPath = _ref.read(internalReposPathProvider);
    if (reposPath == null) return;
    final file = File('$reposPath/../github_user_info.json');
    if (info == null) {
      if (file.existsSync()) {
        await file.delete();
      }
      state = null;
    } else {
      await file.writeAsString(jsonEncode(info.toJson()));
      state = info;
    }
  }
}

final githubUserProvider = StateNotifierProvider<GithubUserNotifier, GithubUserInfo?>((ref) {
  return GithubUserNotifier(ref);
});

Future<GithubUserInfo?> fetchGithubUserProfile(String token) async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(Uri.parse('https://api.github.com/user'));
    request.headers.set('Authorization', 'Bearer $token');
    request.headers.set('Accept', 'application/vnd.github+json');
    request.headers.set('User-Agent', 'Tradu-Git-App');
    
    final response = await request.close();
    if (response.statusCode == 200) {
      final responseBody = await response.transform(utf8.decoder).join();
      final data = jsonDecode(responseBody) as Map<String, dynamic>;
      
      final username = data['login'] as String? ?? '';
      var email = data['email'] as String?;
      if (email == null || email.isEmpty) {
        email = '$username@users.noreply.github.com';
      }
      return GithubUserInfo(username: username, email: email);
    }
  } catch (e) {
    debugPrint('Error fetching user profile: $e');
  } finally {
    client.close();
  }
  return null;
}

final gitHistoryProvider = FutureProvider.autoDispose<List<GitCommitInfo>>((ref) async {
  final repoPath = ref.watch(activeRepoPathProvider);
  if (repoPath == null) {
    return [];
  }
  return gitLog(path: repoPath, maxCount: BigInt.from(50));
});

final gitCompareProvider = FutureProvider.autoDispose<GitCompareInfo?>((ref) async {
  final repoPath = ref.watch(activeRepoPathProvider);
  if (repoPath == null) return null;

  final statusVal = ref.watch(gitStatusProvider);
  final statusText = statusVal.valueOrNull;
  if (statusText == null || statusText.isEmpty) return null;

  String branchName = 'main';
  final lines = statusText.split('\n');
  for (var line in lines) {
    if (line.startsWith('On branch ')) {
      branchName = line.replaceFirst('On branch ', '').trim();
      break;
    }
  }

  try {
    return await gitCompareBranches(
      path: repoPath,
      localBranch: branchName,
      remoteName: 'origin',
    );
  } catch (e) {
    debugPrint('Error comparing branches: $e');
    return null;
  }
});

class GithubRepositoryInfo {
  final String name;
  final String fullName;
  final String cloneUrl;
  final bool isPrivate;

  GithubRepositoryInfo({
    required this.name,
    required this.fullName,
    required this.cloneUrl,
    required this.isPrivate,
  });

  factory GithubRepositoryInfo.fromJson(Map<String, dynamic> json) {
    return GithubRepositoryInfo(
      name: json['name'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      cloneUrl: json['clone_url'] as String? ?? '',
      isPrivate: json['private'] as bool? ?? false,
    );
  }
}

Future<List<GithubRepositoryInfo>> fetchGithubRepositories(String token) async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(Uri.parse('https://api.github.com/user/repos?per_page=100&sort=updated'));
    request.headers.set('Authorization', 'Bearer $token');
    request.headers.set('Accept', 'application/vnd.github+json');
    request.headers.set('User-Agent', 'Tradu-Git-App');
    
    final response = await request.close();
    if (response.statusCode == 200) {
      final responseBody = await response.transform(utf8.decoder).join();
      final list = jsonDecode(responseBody) as List<dynamic>;
      return list
          .map((item) => GithubRepositoryInfo.fromJson(item as Map<String, dynamic>))
          .toList();
    }
  } catch (e) {
    debugPrint('Error fetching repositories: $e');
  } finally {
    client.close();
  }
  return [];
}

/// Provider to track active search state in the editor view.
final isSearchingProvider = StateProvider.autoDispose<bool>((ref) => false);

class AppSettings {
  final bool wordWrap;
  final String theme;
  final bool simpleMode;

  const AppSettings({
    this.wordWrap = false,
    this.theme = 'darcula',
    this.simpleMode = false,
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      wordWrap: json['wordWrap'] as bool? ?? false,
      theme: json['theme'] as String? ?? 'darcula',
      simpleMode: json['simpleMode'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'wordWrap': wordWrap,
    'theme': theme,
    'simpleMode': simpleMode,
  };

  AppSettings copyWith({
    bool? wordWrap,
    String? theme,
    bool? simpleMode,
  }) {
    return AppSettings(
      wordWrap: wordWrap ?? this.wordWrap,
      theme: theme ?? this.theme,
      simpleMode: simpleMode ?? this.simpleMode,
    );
  }
}

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  final Ref _ref;

  AppSettingsNotifier(this._ref)
      : super(const AppSettings(wordWrap: false, theme: 'darcula', simpleMode: false)) {
    _ref.listen<String?>(internalReposPathProvider, (prev, next) {
      _loadSettings();
    });
    _loadSettings();
  }

  void _loadSettings() {
    final reposPath = _ref.read(internalReposPathProvider);
    if (reposPath == null) return;
    final file = File('$reposPath/../settings.json');
    if (file.existsSync()) {
      try {
        final content = file.readAsStringSync();
        final json = jsonDecode(content) as Map<String, dynamic>;
        state = AppSettings.fromJson(json);
      } catch (e) {
        debugPrint('Error loading settings: $e');
      }
    }
  }

  Future<void> updateWordWrap(bool enabled) async {
    state = state.copyWith(wordWrap: enabled);
    await _saveSettings();
  }

  Future<void> updateTheme(String themeName) async {
    state = state.copyWith(theme: themeName);
    await _saveSettings();
  }

  Future<void> updateSimpleMode(bool enabled) async {
    state = state.copyWith(simpleMode: enabled);
    await _saveSettings();
  }

  Future<void> _saveSettings() async {
    final reposPath = _ref.read(internalReposPathProvider);
    if (reposPath == null) return;
    final file = File('$reposPath/../settings.json');
    try {
      await file.writeAsString(jsonEncode(state.toJson()));
    } catch (e) {
      debugPrint('Error saving settings: $e');
    }
  }
}

final appSettingsProvider = StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) {
  return AppSettingsNotifier(ref);
});


