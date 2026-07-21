import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tradu_git/l10n/app_localizations.dart';
import 'package:tradu_git/ui/app_theme.dart';
import 'package:tradu_git/ui/widgets/sora_editor_view.dart';
import 'package:tradu_git/src/workspace_provider.dart';
import 'package:tradu_git/src/rust/api/simple.dart';
import 'package:tradu_git/src/github_config.dart';

class WorkspaceScreen extends ConsumerStatefulWidget {
  const WorkspaceScreen({super.key});

  @override
  ConsumerState<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends ConsumerState<WorkspaceScreen> {
  int _navIndex = 0;
  static const double _toolbarHeight = 44;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoSyncOnOpen();
    });
  }

  Future<void> _autoSyncOnOpen() async {
    final simpleMode = ref.read(appSettingsProvider).simpleMode;
    if (!simpleMode) return;

    final repoPath = ref.read(activeRepoPathProvider);
    if (repoPath == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sincronizando repositorio...'),
        duration: Duration(milliseconds: 1000),
      ),
    );

    try {
      final branch = await gitCurrentBranch(path: repoPath);
      final token = ref.read(githubTokenProvider);
      final passwordOpt = (token != null && token.isNotEmpty) ? token : null;
      final usernameOpt = passwordOpt != null ? 'oauth2' : null;

      final user = ref.read(githubUserProvider);
      final authorName = user?.username;
      final authorEmail = user?.email;

      await gitFetch(
        path: repoPath,
        remoteName: 'origin',
        branchName: branch,
        username: usernameOpt,
        password: passwordOpt,
      );

      await gitPull(
        path: repoPath,
        remoteName: 'origin',
        branchName: branch,
        username: usernameOpt,
        password: passwordOpt,
        authorName: authorName,
        authorEmail: authorEmail,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Repositorio sincronizado.'),
            duration: Duration(milliseconds: 1000),
          ),
        );
        ref.read(gitStatusProvider.notifier).refresh();
        ref.invalidate(gitCompareProvider);
        ref.invalidate(gitHistoryProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al sincronizar: $e'),
            duration: const Duration(milliseconds: 2000),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeRepoPath = ref.watch(activeRepoPathProvider);
    final repoName = activeRepoPath?.split('/').last ?? 'Workspace';
    final activeFile = ref.watch(activeFilePathProvider);
    final showToolbar = _navIndex == 0 && activeFile != null;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(repoName),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.view_list),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Explorador',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.note_add, size: 20),
                      tooltip: 'Crear Archivo',
                      onPressed: () {
                        if (activeRepoPath != null) {
                          _showCreateEntityDialog(context, ref, activeRepoPath, true);
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.create_new_folder, size: 20),
                      tooltip: 'Crear Carpeta',
                      onPressed: () {
                        if (activeRepoPath != null) {
                          _showCreateEntityDialog(context, ref, activeRepoPath, false);
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.folder_open, size: 20),
                      tooltip: 'Abrir Carpeta',
                      onPressed: () => _openDocumentsProvider(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: activeRepoPath == null
                    ? const Center(child: Text('Repositorio no seleccionado'))
                    : Consumer(
                        builder: (context, ref, child) {
                          ref.watch(fileExplorerRefreshProvider);
                          final dir = Directory(activeRepoPath);
                          if (!dir.existsSync()) {
                            return const Center(child: Text('Directorio no encontrado.'));
                          }
                          List<FileSystemEntity> rootEntities = [];
                          try {
                            rootEntities = dir.listSync();
                            rootEntities.sort((a, b) {
                              if (a is Directory && b is! Directory) return -1;
                              if (a is! Directory && b is Directory) return 1;
                              return a.path.split('/').last.toLowerCase().compareTo(b.path.split('/').last.toLowerCase());
                            });
                          } catch (e) {
                            return Center(child: Text('Error al leer archivos: $e'));
                          }

                          return ListView(
                            key: const PageStorageKey('explorer_list'),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            children: rootEntities
                                .map((entity) => _FileTreeNode(
                                      fileSystemEntity: entity,
                                      depth: 0,
                                    ))
                                .toList(),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      endDrawer: _ViewDrawer(
        currentIndex: _navIndex,
        onSelect: (index) {
          setState(() => _navIndex = index);
          Navigator.of(context).pop();
        },
      ),
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(
              bottom: (showToolbar ? _toolbarHeight : 0.0) + MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              children: [
                if (_navIndex == 0) _TabBar(),
                Expanded(
                  child: IndexedStack(
                    index: _navIndex,
                    children: [
                      const _EditorView(),
                      const _GitPanel(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (showToolbar)
            Align(
              alignment: Alignment.bottomCenter,
              child: _BottomToolbar(height: _toolbarHeight),
            ),
        ],
      ),
    );
  }
}

class _FileTreeNode extends ConsumerWidget {
  const _FileTreeNode({
    super.key,
    required this.fileSystemEntity,
    required this.depth,
  });

  final FileSystemEntity fileSystemEntity;
  final int depth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(fileExplorerRefreshProvider);
    final entity = fileSystemEntity;
    final name = entity.path.split('/').last;

    // Ignore hidden Git config files and metadata
    if (name.startsWith('.')) {
      return const SizedBox.shrink();
    }

    if (entity is Directory) {
      final expandedDirs = ref.watch(expandedDirsProvider);
      final isExpanded = expandedDirs.contains(entity.path);
      List<FileSystemEntity> children = [];
      if (isExpanded) {
        try {
          children = entity.listSync();
          children.sort((a, b) {
            if (a is Directory && b is! Directory) return -1;
            if (a is! Directory && b is Directory) return 1;
            return a.path.split('/').last.toLowerCase().compareTo(b.path.split('/').last.toLowerCase());
          });
        } catch (_) {}
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              ref.read(expandedDirsProvider.notifier).toggle(entity.path);
            },
            onLongPress: () {
              showModalBottomSheet<void>(
                context: context,
                builder: (ctx) => SafeArea(
                  child: Wrap(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.note_add),
                        title: Text('Crear archivo en $name'),
                        onTap: () {
                          Navigator.of(ctx).pop();
                          _showCreateEntityDialog(context, ref, entity.path, true);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.create_new_folder),
                        title: Text('Crear carpeta en $name'),
                        onTap: () {
                          Navigator.of(ctx).pop();
                          _showCreateEntityDialog(context, ref, entity.path, false);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
            child: Padding(
              padding: EdgeInsets.only(
                left: depth * 12.0 + 4,
                top: 6,
                bottom: 6,
                right: 8,
              ),
              child: Row(
                children: [
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                    size: 16,
                    color: AppTheme.muted,
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.folder, size: 16, color: AppTheme.accent),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      name,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.ink,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Column(
              children: children
                  .map((child) => _FileTreeNode(
                        fileSystemEntity: child,
                        depth: depth + 1,
                      ))
                  .toList(),
            ),
        ],
      );
    } else if (entity is File) {
      final activeFile = ref.watch(activeFilePathProvider);
      final isActive = activeFile == entity.path;

      return InkWell(
        onTap: () {
          ref.read(activeFilePathProvider.notifier).setPath(entity.path);
          ref.read(openFilesProvider.notifier).openFile(entity.path);
          Navigator.of(context).pop(); // Close explorer drawer
        },
        child: Padding(
          padding: EdgeInsets.only(
            left: depth * 12.0 + 20,
            top: 6,
            bottom: 6,
            right: 8,
          ),
          child: Row(
            children: [
              Icon(
                Icons.insert_drive_file,
                size: 16,
                color: isActive ? AppTheme.accent : AppTheme.muted,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  name,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isActive ? AppTheme.accent : AppTheme.ink,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}

class _TabBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final openFiles = ref.watch(openFilesProvider);
    final activeFile = ref.watch(activeFilePathProvider);
    final dirtyFiles = ref.watch(dirtyFilesProvider);

    if (openFiles.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          bottom: BorderSide(color: AppTheme.border),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: openFiles.length,
        itemBuilder: (context, index) {
          final filePath = openFiles[index];
          final fileName = filePath.split('/').last;
          final isActive = filePath == activeFile;
          final isDirty = dirtyFiles.contains(filePath);
          
          return GestureDetector(
            onTap: () {
              ref.read(activeFilePathProvider.notifier).setPath(filePath);
            },
            child: _TabChip(
              title: fileName,
              dirty: isDirty,
              active: isActive,
              onClose: () async {
                bool isDirty = dirtyFiles.contains(filePath);
                if (isActive) {
                  try {
                    const channel = MethodChannel('sora_editor');
                    final String? currentEditorText = await channel.invokeMethod('getText');
                    if (currentEditorText != null) {
                      final originalFile = File(filePath);
                      if (originalFile.existsSync()) {
                        final originalText = await originalFile.readAsString();
                        if (currentEditorText != originalText) {
                          isDirty = true;
                        }
                      }
                    }
                  } catch (e) {
                    debugPrint('Error checking active file dirty status: $e');
                  }
                }

                if (isDirty) {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('¿Descartar cambios?'),
                      content: Text('Si cierras esta pestaña, se perderán todos los cambios no guardados en $fileName.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Descartar', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                  if (confirm != true) {
                    return;
                  }
                }

                final reposPath = ref.read(internalReposPathProvider);
                if (reposPath != null) {
                  final parentPath = Directory(reposPath).parent.path;
                  final encoded = Uri.encodeComponent(filePath);
                  final draftFile = File('$parentPath/drafts/$encoded.draft');
                  if (draftFile.existsSync()) {
                    try {
                      await draftFile.delete();
                    } catch (e) {
                      debugPrint('Error deleting draft file on close: $e');
                    }
                  }
                }

                ref.read(dirtyFilesProvider.notifier).setDirty(filePath, false);
                ref.read(fileEditorStatesProvider.notifier).removeState(filePath);
                ref.read(openFilesProvider.notifier).closeFile(filePath);

                if (isActive) {
                  final remaining = ref.read(openFilesProvider);
                  if (remaining.isNotEmpty) {
                    ref.read(activeFilePathProvider.notifier).setPath(remaining.last);
                  } else {
                    ref.read(activeFilePathProvider.notifier).setPath(null);
                  }
                }
              },
            ),
          );
        },
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.title,
    this.dirty = false,
    this.active = false,
    required this.onClose,
  });

  final String title;
  final bool dirty;
  final bool active;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final displayTitle = dirty ? '$title *' : title;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppTheme.accentSoft : AppTheme.panel,
          borderRadius: BorderRadius.zero,
          border: Border.all(
            color: active ? AppTheme.accent : AppTheme.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              displayTitle,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppTheme.ink,
                  ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onClose,
              child: const Icon(Icons.close, size: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditorView extends ConsumerWidget {
  const _EditorView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeFile = ref.watch(activeFilePathProvider);
    if (activeFile == null) {
      return Container(
        color: AppTheme.surface,
      );
    }

    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.all(6),
      child: const SoraEditorView(),
    );
  }
}

class ParsedGitStatus {
  final String branch;
  final List<String> staged;
  final List<String> unstaged;
  final List<String> untracked;

  ParsedGitStatus({
    required this.branch,
    required this.staged,
    required this.unstaged,
    required this.untracked,
  });

  factory ParsedGitStatus.parse(String statusText) {
    String branch = 'unknown';
    List<String> staged = [];
    List<String> unstaged = [];
    List<String> untracked = [];

    final lines = statusText.split('\n');
    String currentSection = '';

    for (var line in lines) {
      if (line.startsWith('On branch ')) {
        branch = line.replaceFirst('On branch ', '').trim();
      } else if (line.contains('Changes to be committed:')) {
        currentSection = 'staged';
      } else if (line.contains('Changes not staged for commit:')) {
        currentSection = 'unstaged';
      } else if (line.contains('Untracked files:')) {
        currentSection = 'untracked';
      } else if (line.trim().isEmpty) {
        if (currentSection != 'untracked' && currentSection != 'staged' && currentSection != 'unstaged') {
          currentSection = '';
        }
      } else if (currentSection.isNotEmpty && line.startsWith('  ')) {
        final content = line.trim();
        if (currentSection == 'staged') {
          staged.add(content);
        } else if (currentSection == 'unstaged') {
          unstaged.add(content);
        } else if (currentSection == 'untracked') {
          if (!content.startsWith('(use "git add"') && !content.startsWith('no changes added to commit')) {
            untracked.add(content);
          }
        }
      }
    }

    return ParsedGitStatus(
      branch: branch,
      staged: staged,
      unstaged: unstaged,
      untracked: untracked,
    );
  }
}

class _GitPanel extends ConsumerStatefulWidget {
  const _GitPanel();

  @override
  ConsumerState<_GitPanel> createState() => _GitPanelState();
}

class _GitPanelState extends ConsumerState<_GitPanel> {
  final _commitMessageController = TextEditingController();
  bool _isCommitting = false;
  bool _isSyncing = false;
  bool _isFetching = false;
  int _visibleCommits = 10;

  static const _oauthChannel = MethodChannel('com.tdclub.tradu_git/oauth');
  static const _browserChannel = MethodChannel('com.tdclub.tradu_git/browser');

  @override
  void initState() {
    super.initState();
    _initOAuthListener();
  }

  @override
  void dispose() {
    _oauthChannel.setMethodCallHandler(null);
    _commitMessageController.dispose();
    super.dispose();
  }

  void _initOAuthListener() {
    _oauthChannel.setMethodCallHandler((call) async {
      if (call.method == 'onOAuthCallback') {
        final String? url = call.arguments as String?;
        if (url != null) {
          _handleOAuthRedirect(url);
        }
      }
    });

    _oauthChannel.invokeMethod<String>('getInitialLink').then((url) {
      if (url != null) {
        _handleOAuthRedirect(url);
      }
    });
  }

  Future<void> _handleOAuthRedirect(String url) async {
    final uri = Uri.parse(url);
    final code = uri.queryParameters['code'];
    if (code == null) return;

    if (githubClientId == 'YOUR_CLIENT_ID' || githubClientSecret == 'YOUR_CLIENT_SECRET') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('debug')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Código de autorización...')),
    );

    final token = await _exchangeCodeForToken(
      clientId: githubClientId,
      clientSecret: githubClientSecret,
      code: code,
    );

    if (token != null) {
      final userInfo = await fetchGithubUserProfile(token);
      if (userInfo != null) {
        await ref.read(githubUserProvider.notifier).saveUserInfo(userInfo);
      }
      await ref.read(githubTokenProvider.notifier).saveToken(token);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesión iniciada en GitHub.')),
      );
      ref.invalidate(gitHistoryProvider);
      ref.invalidate(gitCompareProvider);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al intercambiar el código por token.')),
      );
    }
  }

  Future<String?> _exchangeCodeForToken({
    required String clientId,
    required String clientSecret,
    required String code,
  }) async {
    final client = HttpClient();
    try {
      final request = await client.postUrl(Uri.parse('https://github.com/login/oauth/access_token'));
      request.headers.set('Accept', 'application/json');
      request.headers.set('Content-Type', 'application/json');
      
      final payload = {
        'client_id': clientId,
        'client_secret': clientSecret,
        'code': code,
        'redirect_uri': 'tradu-git://oauth',
      };
      
      request.write(jsonEncode(payload));
      final response = await request.close();
      
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final data = jsonDecode(responseBody) as Map<String, dynamic>;
        return data['access_token'] as String?;
      }
    } catch (e) {
      debugPrint('Error exchanging code: $e');
    } finally {
      client.close();
    }
    return null;
  }

  Future<void> _startOAuthFlow() async {
    if (githubClientId == 'YOUR_CLIENT_ID' || githubClientSecret == 'YOUR_CLIENT_SECRET') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('debug')),
      );
      return;
    }

    final authUrl =
        'https://github.com/login/oauth/authorize?client_id=$githubClientId&redirect_uri=tradu-git://oauth&scope=repo,user';
    try {
      await _browserChannel.invokeMethod('launchBrowser', {'url': authUrl});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al abrir el navegador: $e')),
      );
    }
  }

  Widget _buildGitHubOAuthSection() {
    final token = ref.watch(githubTokenProvider);
    final user = ref.watch(githubUserProvider);
    final reposPath = ref.watch(internalReposPathProvider);

    if (reposPath == null) return const SizedBox.shrink();

    final hasToken = token != null && token.isNotEmpty;

    return Card(
      color: const Color(0xFF1E2624),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFF2C3E3B)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.security, color: Color(0xFF91CABB)),
                const SizedBox(width: 8),
                Text(
                  'Autenticación de GitHub',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFD1EBE4),
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (hasToken) ...[
              Text(
                'Estado: Conectado como ${user?.username ?? "usuario"} (${user?.email ?? ""})',
                style: const TextStyle(color: Colors.green, fontSize: 13),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () async {
                  await ref.read(githubUserProvider.notifier).saveUserInfo(null);
                  await ref.read(githubTokenProvider.notifier).saveToken(null);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sesión de GitHub cerrada.')),
                  );
                },
                child: const Text('Cerrar Sesión'),
              ),
            ] else ...[
              const Text(
                'Para autorizar operaciones Git push/pull de forma segura, inicia sesión con GitHub OAuth.',
                style: TextStyle(color: Color(0xFF91CABB), fontSize: 12),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _startOAuthFlow,
                  child: const Text('Iniciar Sesión con GitHub'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAndRollback(String repoPath, String fileLine) async {
    final relPath = _extractFilePath(fileLine);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Descartar cambios?'),
        content: Text('Esto revertirá todos los cambios locales en "$relPath" y no se pueden recuperar.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await gitDiscardChanges(path: repoPath, filePath: relPath);
        ref.read(gitStatusProvider.notifier).refresh();
        ref.invalidate(gitHistoryProvider);
        ref.invalidate(gitCompareProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cambios descartados en $relPath')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al descartar cambios: $e')),
        );
      }
    }
  }

  Future<void> _runVSCodeSync(String repoPath, String branch, int ahead, int behind) async {
    setState(() => _isSyncing = true);
    final token = ref.read(githubTokenProvider);
    final passwordOpt = (token != null && token.isNotEmpty) ? token : null;
    final usernameOpt = passwordOpt != null ? 'oauth2' : null;

    final user = ref.read(githubUserProvider);
    final authorName = user?.username;
    final authorEmail = user?.email;

    try {
      if (behind > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sincronizando: Haciendo Pull...')),
        );
        await gitPull(
          path: repoPath,
          remoteName: 'origin',
          branchName: branch,
          username: usernameOpt,
          password: passwordOpt,
          authorName: authorName,
          authorEmail: authorEmail,
        );
      }
      if (ahead > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sincronizando: Haciendo Push...')),
        );
        await gitPush(
          path: repoPath,
          remoteName: 'origin',
          branchName: branch,
          username: usernameOpt,
          password: passwordOpt,
        );
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sincronización finalizada con éxito.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al sincronizar: $e')),
      );
    } finally {
      setState(() => _isSyncing = false);
      ref.read(gitStatusProvider.notifier).refresh();
      ref.invalidate(gitCompareProvider);
      ref.invalidate(gitHistoryProvider);
    }
  }

  Future<void> _runFetch(String repoPath, String branch) async {
    setState(() => _isFetching = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Buscando cambios (Fetch)...')),
    );

    final token = ref.read(githubTokenProvider);
    final passwordOpt = (token != null && token.isNotEmpty) ? token : null;
    final usernameOpt = passwordOpt != null ? 'oauth2' : null;

    try {
      await gitFetch(
        path: repoPath,
        remoteName: 'origin',
        branchName: branch,
        username: usernameOpt,
        password: passwordOpt,
      );
      ref.invalidate(gitCompareProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Listo.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al buscar cambios: $e')),
      );
    } finally {
      setState(() => _isFetching = false);
    }
  }

  void _showBranchSelector(BuildContext context, String repoPath, String currentBranch) async {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.zero,
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Cambiar Rama',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.add, color: AppTheme.accent),
                title: const Text('Crear nueva rama...'),
                onTap: () {
                  Navigator.pop(context);
                  _showCreateBranchDialog(context, repoPath);
                },
              ),
              const Divider(),
              Expanded(
                child: FutureBuilder<List<String>>(
                  future: gitListBranches(path: repoPath),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    final branches = snapshot.data ?? [];
                    if (branches.isEmpty) {
                      return const Center(child: Text('No se encontraron ramas locales.'));
                    }
                    return ListView.builder(
                      itemCount: branches.length,
                      itemBuilder: (context, index) {
                        final b = branches[index];
                        final isCurrent = b == currentBranch;
                        return ListTile(
                          leading: Icon(
                            isCurrent ? Icons.check : Icons.call_split,
                            color: isCurrent ? Colors.green : AppTheme.ink.withOpacity(0.5),
                          ),
                          title: Text(
                            b,
                            style: TextStyle(
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                              color: isCurrent ? Colors.green : AppTheme.ink,
                            ),
                          ),
                          trailing: isCurrent
                              ? const Chip(
                                  label: Text('Activa', style: TextStyle(fontSize: 10, color: Colors.white)),
                                  backgroundColor: Colors.green,
                                  visualDensity: VisualDensity.compact,
                                )
                              : null,
                          onTap: isCurrent
                              ? null
                              : () async {
                                  Navigator.pop(context);
                                  _checkoutBranch(context, repoPath, b);
                                },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _checkoutBranch(BuildContext context, String repoPath, String branchName) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final res = await gitCheckoutBranch(path: repoPath, branchName: branchName);
      if (context.mounted) {
        Navigator.pop(context); // Close loading indicator
        if (res == "Success") {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Cargada rama: $branchName')),
          );
          ref.read(gitStatusProvider.notifier).refresh();
          ref.invalidate(gitCompareProvider);
          ref.invalidate(gitHistoryProvider);
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading indicator
        showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.surface,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            title: const Text('Error al cambiar de rama'),
            content: Text(e.toString().replaceAll("Exception: ", "")),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  void _showCreateBranchDialog(BuildContext context, String repoPath) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          title: const Text('Crear nueva rama'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Nombre de la rama',
              hintText: 'feature-branch',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isEmpty) return;
                Navigator.pop(context);
                _createBranch(context, repoPath, name);
              },
              child: const Text('Crear'),
            ),
          ],
        );
      },
    );
  }

  void _createBranch(BuildContext context, String repoPath, String branchName) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final res = await gitCreateBranch(path: repoPath, branchName: branchName);
      if (context.mounted) {
        Navigator.pop(context); // Close loading indicator
        if (res == "Success") {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Creada y cargada rama: $branchName')),
          );
          ref.read(gitStatusProvider.notifier).refresh();
          ref.invalidate(gitCompareProvider);
          ref.invalidate(gitHistoryProvider);
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading indicator
        showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.surface,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            title: const Text('Error al crear rama'),
            content: Text(e.toString().replaceAll("Exception: ", "")),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  Widget _buildSyncBanner(String repoPath, ParsedGitStatus parsed) {
    final compareAsync = ref.watch(gitCompareProvider);

    return compareAsync.when(
      data: (info) {
        if (info == null) return const SizedBox.shrink();

        final ahead = info.ahead.toInt();
        final behind = info.behind.toInt();

        if (ahead == 0 && behind == 0) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2624),
            border: Border.all(color: const Color(0xFF2C3E3B)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              const Icon(Icons.sync_alt, color: Color(0xFF91CABB), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$ahead ↑ • $behind ↓',
                  style: const TextStyle(color: Color(0xFFD1EBE4), fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                  backgroundColor: AppTheme.accent,
                ),
                onPressed: _isSyncing
                    ? null
                    : () => _runVSCodeSync(repoPath, parsed.branch, ahead, behind),
                icon: _isSyncing
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.black),
                      )
                    : const Icon(Icons.sync, size: 14),
                label: const Text('Sincronizar', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final statusAsync = ref.watch(gitStatusProvider);
    final repoPath = ref.watch(activeRepoPathProvider);

    if (repoPath == null) {
      return Center(child: Text(l10n.noSelectedRepo));
    }

    return statusAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error al cargar Status: $err', style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.read(gitStatusProvider.notifier).refresh(),
                child: const Text('Reintentar'),
              )
            ],
          ),
        ),
      ),
      data: (statusText) {
        final parsed = ParsedGitStatus.parse(statusText);
        final hasChanges = parsed.staged.isNotEmpty || parsed.unstaged.isNotEmpty || parsed.untracked.isNotEmpty;

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showBranchSelector(context, repoPath, parsed.branch),
                  icon: const Icon(Icons.call_split, size: 16, color: AppTheme.accent),
                  label: Text(
                    'Rama: ${parsed.branch}',
                    style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.border),
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  onPressed: () {
                    ref.read(gitStatusProvider.notifier).refresh();
                    ref.invalidate(gitHistoryProvider);
                    ref.invalidate(gitCompareProvider);
                  },
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 12),
            _buildSyncBanner(repoPath, parsed),
            if (!hasChanges) ...[
              const SizedBox(height: 40),
              const Center(
                child: Column(
                  children: [
                    Text(
                      'Sin cambios.',
                      style: TextStyle(color: AppTheme.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
            if (parsed.unstaged.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Cambios sin confirmar (${parsed.unstaged.length})',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              ...parsed.unstaged.map((file) => _GitFileTile(
                    name: file,
                    staged: false,
                    onTapAction: () async {
                      final relPath = _extractFilePath(file);
                      await gitAdd(path: repoPath, filePath: relPath);
                      ref.read(gitStatusProvider.notifier).refresh();
                    },
                    onRollback: () => _confirmAndRollback(repoPath, file),
                  )),
            ],
            if (parsed.untracked.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Cambios',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              ...parsed.untracked.map((file) => _GitFileTile(
                    name: file,
                    staged: false,
                    onTapAction: () async {
                      final relPath = _extractFilePath(file);
                      await gitAdd(path: repoPath, filePath: relPath);
                      ref.read(gitStatusProvider.notifier).refresh();
                    },
                    onRollback: () => _confirmAndRollback(repoPath, file),
                  )),
            ],
            if (parsed.staged.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Cambios confirmados (${parsed.staged.length})',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              ...parsed.staged.map((file) => _GitFileTile(
                    name: file,
                    staged: true,
                    onTapAction: () async {
                      final relPath = _extractFilePath(file);
                      await gitReset(path: repoPath, filePath: relPath);
                      ref.read(gitStatusProvider.notifier).refresh();
                    },
                  )),
            ],
            if (parsed.staged.isNotEmpty) ...[
              const SizedBox(height: 24),
              TextField(
                controller: _commitMessageController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Mensaje de commit',
                  hintText: '',
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isCommitting
                      ? null
                      : () async {
                          final msg = _commitMessageController.text.trim();
                          if (msg.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Escribe un mensaje.')),
                            );
                            return;
                          }
                          setState(() => _isCommitting = true);
                          
                          final user = ref.read(githubUserProvider);
                          final authorName = user?.username ?? 'Tradu-Git';
                          final authorEmail = user?.email ?? 'user@tradu-git.internal';

                          try {
                            await gitCommit(
                              path: repoPath,
                              message: msg,
                              authorName: authorName,
                              authorEmail: authorEmail,
                            );
                            _commitMessageController.clear();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Commit hecho.')),
                            );
                            ref.invalidate(gitHistoryProvider);
                            ref.invalidate(gitCompareProvider);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error al hacer commit: $e')),
                            );
                          } finally {
                            setState(() => _isCommitting = false);
                            ref.read(gitStatusProvider.notifier).refresh();
                          }
                        },
                  child: _isCommitting
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Hacer commit'),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => _SyncDialog(repoPath: repoPath),
                      ).then((_) {
                        ref.read(gitStatusProvider.notifier).refresh();
                        ref.invalidate(gitCompareProvider);
                        ref.invalidate(gitHistoryProvider);
                      });
                    },
                    icon: const Icon(Icons.sync),
                    label: const Text('Sync manual'),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  tooltip: 'Buscar cambios remotos (Fetch)',
                  icon: _isFetching
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 1.5),
                        )
                      : const Icon(Icons.download),
                  onPressed: _isFetching ? null : () => _runFetch(repoPath, parsed.branch),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Historial de cambios',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            ref.watch(gitHistoryProvider).when(
              data: (commits) {
                if (commits.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'Sin cambios.',
                        style: TextStyle(color: AppTheme.muted, fontSize: 13),
                      ),
                    ),
                  );
                }

                final visibleList = commits.take(_visibleCommits).toList();
                final hasMore = commits.length > _visibleCommits;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 250,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B0F0E),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Scrollbar(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          itemCount: visibleList.length,
                          itemBuilder: (context, index) {
                            final commit = visibleList[index];
                            final shortHash = commit.hash.length > 7 ? commit.hash.substring(0, 7) : commit.hash;
                            final message = commit.message.trim();
                            final author = commit.author;
                            final date = DateTime.fromMillisecondsSinceEpoch(commit.time.toInt() * 1000);
                            final formattedDate = '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                message,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                              subtitle: Text(
                                '$author • $formattedDate',
                                style: const TextStyle(fontSize: 11, color: AppTheme.muted),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E2624),
                                  border: Border.all(color: const Color(0xFF2C3E3B)),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  shortHash,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 11,
                                    color: Color(0xFF91CABB),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    if (hasMore) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          onPressed: () {
                            setState(() {
                              _visibleCommits += 10;
                            });
                          },
                          child: const Text('Cargar más'),
                        ),
                      ),
                    ],
                  ],
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, stack) => Text(
                'Error al cargar el historial: $err',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          ],
        );
      },
    );
  }

  String _extractFilePath(String line) {
    final idx = line.indexOf(':');
    if (idx != -1) {
      return line.substring(idx + 1).trim();
    }
    return line.trim();
  }
}

class _GitFileTile extends StatelessWidget {
  const _GitFileTile({
    required this.name,
    required this.staged,
    required this.onTapAction,
    this.onRollback,
  });

  final String name;
  final bool staged;
  final VoidCallback onTapAction;
  final VoidCallback? onRollback;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.ink,
                  ),
            ),
          ),
          if (onRollback != null)
            IconButton(
              icon: const Icon(
                Icons.undo,
                color: Colors.orangeAccent,
                size: 18,
              ),
              tooltip: 'Descartar cambios',
              onPressed: onRollback,
            ),
          IconButton(
            icon: Icon(
              staged ? Icons.remove_circle_outline : Icons.add_circle_outline,
              color: staged ? Colors.redAccent : AppTheme.accent,
              size: 18,
            ),
            onPressed: onTapAction,
          ),
        ],
      ),
    );
  }
}

class _SyncDialog extends ConsumerStatefulWidget {
  const _SyncDialog({required this.repoPath});

  final String repoPath;

  @override
  ConsumerState<_SyncDialog> createState() => _SyncDialogState();
}

class _SyncDialogState extends ConsumerState<_SyncDialog> {
  final _remoteController = TextEditingController(text: 'origin');
  final _branchController = TextEditingController(text: 'main');
  bool _isLoading = false;
  String? _error;
  String? _status;

  @override
  void dispose() {
    _remoteController.dispose();
    _branchController.dispose();
    super.dispose();
  }

  Future<void> _runSync(bool isPush) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _status = isPush ? 'Haciendo Push...' : 'Haciendo Pull...';
    });

    final remote = _remoteController.text.trim();
    final branch = _branchController.text.trim();

    final token = ref.read(githubTokenProvider);
    final finalUsername = (token != null && token.isNotEmpty ? 'oauth2' : null);
    final finalPassword = (token != null && token.isNotEmpty ? token : null);

    final user = ref.read(githubUserProvider);
    final authorName = user?.username;
    final authorEmail = user?.email;

    try {
      if (isPush) {
        await gitPush(
          path: widget.repoPath,
          remoteName: remote,
          branchName: branch,
          username: finalUsername,
          password: finalPassword,
        );
        setState(() => _status = 'Push hecho.');
      } else {
        final result = await gitPull(
          path: widget.repoPath,
          remoteName: remote,
          branchName: branch,
          username: finalUsername,
          password: finalPassword,
          authorName: authorName,
          authorEmail: authorEmail,
        );
        setState(() => _status = 'Pull hecho: $result');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sincronizar'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _remoteController,
              decoration: const InputDecoration(labelText: 'Remoto'),
            ),
            TextField(
              controller: _branchController,
              decoration: const InputDecoration(labelText: 'Rama'),
            ),
            const SizedBox(height: 12),
            if (ref.watch(githubTokenProvider) != null) ...[
              const Text(
                '',
                style: TextStyle(color: Colors.green, fontSize: 11),
              ),
            ] else ...[
              const Text(
                'No se detectó ningún token de GitHub.',
                style: TextStyle(color: Colors.orangeAccent, fontSize: 11),
              ),
            ],
            if (_status != null) ...[
              const SizedBox(height: 12),
              Text(_status!, style: const TextStyle(color: Colors.green)),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text('Error: $_error', style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : () => _runSync(false),
          child: const Text('Pull'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : () => _runSync(true),
          child: const Text('Push'),
        ),
      ],
    );
  }
}


class _ViewDrawer extends StatelessWidget {
  const _ViewDrawer({required this.currentIndex, required this.onSelect});

  final int currentIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Text(
                'Vistas',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _ViewDrawerItem(
                    label: 'Editor',
                    icon: Icons.edit,
                    active: currentIndex == 0,
                    onTap: () => onSelect(0),
                  ),
                  _ViewDrawerItem(
                    label: 'Git',
                    icon: Icons.alt_route,
                    active: currentIndex == 1,
                    onTap: () => onSelect(1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ViewDrawerItem extends StatelessWidget {
  const _ViewDrawerItem({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: Icon(icon, size: 18, color: active ? AppTheme.accent : AppTheme.muted),
      title: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: active ? AppTheme.ink : AppTheme.muted,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            ),
      ),
      onTap: onTap,
    );
  }
}

class _BottomToolbar extends ConsumerWidget {
  const _BottomToolbar({required this.height});

  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: Container(
          height: height,
          width: double.infinity,
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            border: Border(top: BorderSide(color: AppTheme.border)),
          ),
          child: ref.watch(isSearchingProvider)
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, size: 20),
                        onPressed: () async {
                          ref.read(isSearchingProvider.notifier).state = false;
                          try {
                            const channel = MethodChannel('sora_editor');
                            await channel.invokeMethod('search', {'query': ''});
                          } catch (e) {
                            debugPrint('Error clearing search on back: $e');
                          }
                        },
                      ),
                      Expanded(
                        child: TextField(
                          autofocus: true,
                          style: const TextStyle(fontSize: 14, color: AppTheme.ink),
                          decoration: const InputDecoration(
                            hintText: 'Buscar...',
                            hintStyle: TextStyle(color: AppTheme.muted),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                          ),
                          onChanged: (text) async {
                            try {
                              const channel = MethodChannel('sora_editor');
                              await channel.invokeMethod('search', {'query': text});
                            } catch (e) {
                              debugPrint('Error sending search query: $e');
                            }
                          },
                          onSubmitted: (text) async {
                            try {
                              const channel = MethodChannel('sora_editor');
                              await channel.invokeMethod('findNext');
                            } catch (e) {
                              debugPrint('Error running findNext: $e');
                            }
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_up, size: 20),
                        onPressed: () async {
                          try {
                            const channel = MethodChannel('sora_editor');
                            await channel.invokeMethod('findPrevious');
                          } catch (e) {
                            debugPrint('Error running findPrevious: $e');
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                        onPressed: () async {
                          try {
                            const channel = MethodChannel('sora_editor');
                            await channel.invokeMethod('findNext');
                          } catch (e) {
                            debugPrint('Error running findNext: $e');
                          }
                        },
                      ),
                    ],
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ToolbarButton(
                      icon: Icons.save,
                      onTap: () async {
                        final activeFile = ref.read(activeFilePathProvider);
                        if (activeFile == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('No hay ningún archivo abierto.'),
                              duration: Duration(milliseconds: 1000),
                            ),
                          );
                          return;
                        }

                        try {
                          const channel = MethodChannel('sora_editor');
                          final String text = await channel.invokeMethod('getText') ?? '';
                          await File(activeFile).writeAsString(text);

                          // Delete the draft cache file if it exists
                          final reposPath = ref.read(internalReposPathProvider);
                          if (reposPath != null) {
                            final parentPath = Directory(reposPath).parent.path;
                            final encoded = Uri.encodeComponent(activeFile);
                            final draftFile = File('$parentPath/drafts/$encoded.draft');
                            if (draftFile.existsSync()) {
                              await draftFile.delete();
                            }
                          }

                          // Clear the dirty flag
                          ref.read(dirtyFilesProvider.notifier).setDirty(activeFile, false);

                          // Refresh git status
                          ref.read(gitStatusProvider.notifier).refresh();

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Guardado: ${activeFile.split('/').last}'),
                              duration: const Duration(milliseconds: 1000),
                            ),
                          );

                          final repoPath = ref.read(activeRepoPathProvider);
                          if (ref.read(appSettingsProvider).simpleMode && repoPath != null) {
                            String relativePath = activeFile;
                            if (activeFile.startsWith(repoPath)) {
                              relativePath = activeFile.substring(repoPath.length);
                              if (relativePath.startsWith('/')) {
                                relativePath = relativePath.substring(1);
                              }
                            }
                            _runSimpleModeAutoSync(context, ref, repoPath, relativePath);
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error al guardar: $e'),
                              duration: const Duration(milliseconds: 2000),
                            ),
                          );
                        }
                      },
                    ),
                    _ToolbarButton(
                      icon: Icons.search,
                      onTap: () {
                        ref.read(isSearchingProvider.notifier).state = true;
                      },
                    ),
                    _ToolbarButton(
                      icon: Icons.tune,
                      onTap: () {
                        Navigator.pushNamed(context, '/settings');
                      },
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _runSimpleModeAutoSync(
      BuildContext context, WidgetRef ref, String repoPath, String relativePath) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sincronizando cambios en GitHub...'),
        duration: Duration(milliseconds: 1000),
      ),
    );

    try {
      await gitAdd(path: repoPath, filePath: relativePath);

      final branch = await gitCurrentBranch(path: repoPath);
      final user = ref.read(githubUserProvider);
      final authorName = user?.username ?? 'Tradu-Git';
      final authorEmail = user?.email ?? 'user@tradu-git.internal';

      final now = DateTime.now();
      final year = now.year.toString();
      final month = now.month.toString().padLeft(2, '0');
      final day = now.day.toString().padLeft(2, '0');
      final hour = now.hour.toString().padLeft(2, '0');
      final minute = now.minute.toString().padLeft(2, '0');
      final commitMsg = 'Last sync: $year/$month/$day - $hour:$minute (Tradu-Git)';

      await gitCommit(
        path: repoPath,
        message: commitMsg,
        authorName: authorName,
        authorEmail: authorEmail,
      );

      final token = ref.read(githubTokenProvider);
      final passwordOpt = (token != null && token.isNotEmpty) ? token : null;
      final usernameOpt = passwordOpt != null ? 'oauth2' : null;

      await gitPush(
        path: repoPath,
        remoteName: 'origin',
        branchName: branch,
        username: usernameOpt,
        password: passwordOpt,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cambios guardados y subidos a GitHub.'),
            duration: Duration(milliseconds: 1000),
          ),
        );
        ref.read(gitStatusProvider.notifier).refresh();
        ref.invalidate(gitCompareProvider);
        ref.invalidate(gitHistoryProvider);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al subir cambios: $e'),
            duration: const Duration(milliseconds: 2000),
          ),
        );
      }
    }
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 44,
        height: double.infinity,
        child: Icon(icon, size: 18, color: AppTheme.ink),
      ),
    );
  }
}

Future<void> _showCreateEntityDialog(
  BuildContext context,
  WidgetRef ref,
  String parentPath,
  bool isFile,
) async {
  final controller = TextEditingController();
  final itemType = isFile ? 'archivo' : 'carpeta';

  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Nuevo $itemType'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Nombre del $itemType',
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () {
            final name = controller.text.trim();
            if (name.isEmpty) return;

            try {
              final newPath = '$parentPath/$name';
              if (isFile) {
                final file = File(newPath);
                if (file.existsSync()) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('El archivo ya existe.')),
                  );
                  return;
                }
                file.createSync(recursive: true);
              } else {
                final dir = Directory(newPath);
                if (dir.existsSync()) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('La carpeta ya existe.')),
                  );
                  return;
                }
                dir.createSync(recursive: true);
              }

              ref.read(fileExplorerRefreshProvider.notifier).update((state) => state + 1);
              Navigator.of(context).pop();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Creado: $name')),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error al crear: $e')),
              );
            }
          },
          child: const Text('Crear'),
        ),
      ],
    ),
  );
}

Future<void> _openDocumentsProvider(BuildContext context) async {
  try {
    const storageChannel = MethodChannel('com.tdclub.tradu_git/storage');
    await storageChannel.invokeMethod('openDocumentsProvider');
  } catch (e) {
    debugPrint('Error opening documents provider: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('No se pudo abrir el explorador de archivos: $e')),
    );
  }
}

