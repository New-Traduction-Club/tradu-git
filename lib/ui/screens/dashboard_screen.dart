import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tradu_git/l10n/app_localizations.dart';
import 'package:tradu_git/ui/app_theme.dart';
import 'package:tradu_git/ui/screens/workspace_screen.dart';
import 'package:tradu_git/src/workspace_provider.dart';
import 'package:tradu_git/src/rust/api/simple.dart' as rust;

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  List<Directory> _repos = [];
  bool _loading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Load repos on start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRepos();
    });
  }

  void _loadRepos() {
    final workspacePath = ref.read(internalReposPathProvider);
    if (workspacePath == null) {
      setState(() {
        _repos = [];
        _errorMessage = "Iniciando...";
      });
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final dir = Directory(workspacePath);
      if (!dir.existsSync()) {
        setState(() {
          _repos = [];
          _errorMessage = "La carpeta seleccionada no existe.";
          _loading = false;
        });
        return;
      }

      final subdirs = dir.listSync().whereType<Directory>().toList();
      final List<Directory> gitRepos = [];
      for (var subdir in subdirs) {
        if (rust.hasGitRepo(path: subdir.path)) {
          gitRepos.add(subdir);
        }
      }

      // Sort alphabetically by folder name
      gitRepos.sort((a, b) {
        final nameA = a.path.split('/').last.toLowerCase();
        final nameB = b.path.split('/').last.toLowerCase();
        return nameA.compareTo(nameB);
      });

      setState(() {
        _repos = gitRepos;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _repos = [];
        _errorMessage = "Error al leer: $e";
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final workspacePath = ref.watch(internalReposPathProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.repositories),
        leading: IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            Navigator.pushNamed(context, '/settings');
          },
        ),
      ),
      body: workspacePath == null
          ? _buildSetupPrompt()
          : RefreshIndicator(
              onRefresh: () async {
                _loadRepos();
              },
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? _buildErrorView()
                      : _repos.isEmpty
                          ? _buildEmptyView()
                          : _buildRepoList(),
            ),
      floatingActionButton: workspacePath != null
          ? FloatingActionButton.extended(
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (context) => _CloneSourceDialog(
                    workspacePath: workspacePath,
                    onCloneSuccess: _loadRepos,
                  ),
                );
              },
              backgroundColor: AppTheme.accent,
              foregroundColor: Colors.black,
              icon: const Icon(Icons.add),
              label: Text(l10n.clone),
            )
          : null,
    );
  }

  Widget _buildSetupPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder_shared, size: 64, color: AppTheme.muted),
            const SizedBox(height: 20),
            Text(
              'Carpeta no configurado',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Debes seleccionar una carpeta donde se almacenarán tus repositorios.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.pushNamed(context, '/saf'),
              child: const Text('Configurar ahora'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
        const SizedBox(height: 16),
        Text(
          'Ocurrió un error',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          _errorMessage ?? '',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
        ),
        const SizedBox(height: 24),
        Center(
          child: OutlinedButton(
            onPressed: _loadRepos,
            child: const Text('Reintentar'),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyView() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 100),
        const Icon(Icons.folder_open, size: 64, color: AppTheme.muted),
        const SizedBox(height: 20),
        Text(
          'Sin repositorios',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Haz clic en "Clonar"',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
        ),
      ],
    );
  }

  Widget _buildRepoList() {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
      itemCount: _repos.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 20, top: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Repositorios locales.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.muted,
                      ),
                ),
              ],
            ),
          );
        }

        final repoDir = _repos[index - 1];
        final name = repoDir.path.split('/').last;

        return _RepoCard(
          name: name,
          path: repoDir.path,
          onOpen: () {
            ref.read(activeRepoPathProvider.notifier).setPath(repoDir.path);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WorkspaceScreen()),
            );
          },
        );
      },
    );
  }
}

class _RepoCard extends ConsumerWidget {
  const _RepoCard({
    required this.name,
    required this.path,
    required this.onOpen,
  });

  final String name;
  final String path;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: InkWell(
        borderRadius: BorderRadius.zero,
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.ink,
                    ),
              ),
              const SizedBox(height: 8),
              FutureBuilder<String>(
                future: rust.gitCurrentBranch(path: path),
                builder: (context, snapshot) {
                  final branch = snapshot.data ?? '...';
                  return Wrap(
                    spacing: 12,
                    children: [
                      _Tag(icon: Icons.call_split, label: branch),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.panel,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.ink.withOpacity(0.6)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppTheme.ink,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CloneSheet extends StatefulWidget {
  const _CloneSheet({
    required this.workspacePath,
    required this.onCloneSuccess,
  });

  final String workspacePath;
  final VoidCallback onCloneSuccess;

  @override
  State<_CloneSheet> createState() => _CloneSheetState();
}

class _CloneSheetState extends State<_CloneSheet> {
  final _urlController = TextEditingController();
  final _nameController = TextEditingController();
  bool _cloning = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _urlController.addListener(_onUrlChanged);
  }

  @override
  void dispose() {
    _urlController.removeListener(_onUrlChanged);
    _urlController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _onUrlChanged() {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;
    
    // Auto-generate repository folder name from URL
    try {
      final uri = Uri.parse(url);
      var lastSegment = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
      if (lastSegment.endsWith('.git')) {
        lastSegment = lastSegment.substring(0, lastSegment.length - 4);
      }
      if (lastSegment.isNotEmpty) {
        setState(() {
          _nameController.text = lastSegment;
        });
      }
    } catch (_) {
      // Ignore invalid URL formatting errors during typing
    }
  }

  Future<void> _startClone() async {
    final url = _urlController.text.trim();
    final name = _nameController.text.trim();

    if (url.isEmpty || name.isEmpty) {
      setState(() {
        _error = "Todos los campos son obligatorios.";
      });
      return;
    }

    setState(() {
      _cloning = true;
      _error = null;
    });

    final targetPath = '${widget.workspacePath}/$name';

    try {
      // Check if folder already exists
      if (Directory(targetPath).existsSync()) {
        throw Exception("La carpeta '$name' ya existe.");
      }

      await rust.gitClone(url: url, path: targetPath);

      if (mounted) {
        widget.onCloneSuccess();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Clonado: $name')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll("Exception: ", "");
          _cloning = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 28 + bottomInset),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.zero,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Spacer(),
              if (!_cloning)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Clonar repositorio',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'Ingresa la URL del repositorio Git HTTPS.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.ink.withOpacity(0.6),
                ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _urlController,
            enabled: !_cloning,
            decoration: const InputDecoration(
              labelText: 'URL Git (HTTPS)',
              hintText: 'https://github.com/user/repo.git',
            ),
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            enabled: !_cloning,
            decoration: const InputDecoration(
              labelText: 'Nombre de la carpeta local',
              hintText: 'repo-name',
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _startClone(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: _cloning
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(strokeWidth: 2),
                          SizedBox(width: 16),
                          Text('Clonando repositorio...'),
                        ],
                      ),
                    ),
                  )
                : FilledButton(
                    onPressed: _startClone,
                    child: const Text('Clonar'),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CloneSourceDialog extends ConsumerWidget {
  const _CloneSourceDialog({
    required this.workspacePath,
    required this.onCloneSuccess,
  });

  final String workspacePath;
  final VoidCallback onCloneSuccess;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final token = ref.watch(githubTokenProvider);
    final hasToken = token != null && token.isNotEmpty;

    return AlertDialog(
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      title: const Text('Clonar Repositorio', style: TextStyle(color: AppTheme.ink)),
      actions: [
        TextButton.icon(
          onPressed: () {
            Navigator.pop(context);
            showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => _CloneSheet(
                workspacePath: workspacePath,
                onCloneSuccess: onCloneSuccess,
              ),
            );
          },
          label: const Text('URL HTTPS', style: TextStyle(color: AppTheme.accent)),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.accent,
            foregroundColor: Colors.black,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
          onPressed: hasToken
              ? () {
                  Navigator.pop(context);
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => _GithubReposCloneSheet(
                      workspacePath: workspacePath,
                      onCloneSuccess: onCloneSuccess,
                    ),
                  );
                }
              : null,
          label: const Text('Lista de GitHub'),
        ),
      ],
    );
  }
}

class _GithubReposCloneSheet extends ConsumerStatefulWidget {
  const _GithubReposCloneSheet({
    required this.workspacePath,
    required this.onCloneSuccess,
  });

  final String workspacePath;
  final VoidCallback onCloneSuccess;

  @override
  ConsumerState<_GithubReposCloneSheet> createState() => _GithubReposCloneSheetState();
}

class _GithubReposCloneSheetState extends ConsumerState<_GithubReposCloneSheet> {
  List<GithubRepositoryInfo>? _repos;
  List<GithubRepositoryInfo>? _filteredRepos;
  bool _loading = false;
  String? _error;
  
  // Confirmation state
  GithubRepositoryInfo? _selectedRepo;
  final _nameController = TextEditingController();
  bool _cloning = false;
  String? _cloneError;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadGithubRepos();
    _searchController.addListener(_filterRepos);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterRepos);
    _searchController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _filterRepos() {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) {
      setState(() {
        _filteredRepos = _repos;
      });
      return;
    }
    setState(() {
      _filteredRepos = _repos
          ?.where((r) => r.fullName.toLowerCase().contains(query))
          .toList();
    });
  }

  Future<void> _loadGithubRepos() async {
    final token = ref.read(githubTokenProvider);
    if (token == null || token.isEmpty) {
      setState(() {
        _error = "Inicia sesión en GitHub.";
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final repos = await fetchGithubRepositories(token);
      setState(() {
        _repos = repos;
        _filteredRepos = repos;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Error al obtener repositorios: $e";
        _loading = false;
      });
    }
  }

  void _selectRepo(GithubRepositoryInfo repo) {
    setState(() {
      _selectedRepo = repo;
      _nameController.text = repo.name;
      _cloneError = null;
    });
  }

  Future<void> _startClone() async {
    final repo = _selectedRepo;
    if (repo == null) return;

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _cloneError = "El nombre de la carpeta es obligatorio.";
      });
      return;
    }

    setState(() {
      _cloning = true;
      _cloneError = null;
    });

    final targetPath = '${widget.workspacePath}/$name';

    try {
      if (Directory(targetPath).existsSync()) {
        throw Exception("La carpeta '$name' ya existe.");
      }

      final token = ref.read(githubTokenProvider);
      final cloneUrlWithToken = repo.cloneUrl.replaceFirst(
        'https://github.com/',
        'https://oauth2:$token@github.com/',
      );

      await rust.gitClone(url: cloneUrlWithToken, path: targetPath);

      if (mounted) {
        widget.onCloneSuccess();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Clonado: $name')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cloneError = e.toString().replaceAll("Exception: ", "");
          _cloning = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    
    if (_selectedRepo != null) {
      return _buildConfirmationPanel(bottomInset);
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.zero,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Repositorios de GitHub',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Buscar repositorios...',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: _loadGithubRepos,
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      )
                    : _filteredRepos == null || _filteredRepos!.isEmpty
                        ? const Center(child: Text('No se encontraron repositorios.'))
                        : ListView.separated(
                            itemCount: _filteredRepos!.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, idx) {
                              final repo = _filteredRepos![idx];
                              return ListTile(
                                leading: Icon(
                                  repo.isPrivate ? Icons.lock : Icons.public,
                                  color: repo.isPrivate ? AppTheme.accent : AppTheme.ink.withOpacity(0.5),
                                ),
                                title: Text(
                                  repo.fullName,
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                subtitle: Text(
                                  repo.cloneUrl,
                                  style: TextStyle(fontSize: 12, color: AppTheme.ink.withOpacity(0.6)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: const Icon(Icons.chevron_right, size: 20),
                                onTap: () => _selectRepo(repo),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationPanel(double bottomInset) {
    final repo = _selectedRepo!;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 28 + bottomInset),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.zero,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _cloning
                    ? null
                    : () {
                        setState(() {
                          _selectedRepo = null;
                        });
                      },
              ),
              const Spacer(),
              if (!_cloning)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Confirmar',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'Se clonará el repositorio "${repo.fullName}".',
            style: const TextStyle(color: AppTheme.muted),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            enabled: !_cloning,
            decoration: const InputDecoration(
              labelText: 'Nombre de la carpeta local',
              hintText: 'repo-name',
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _startClone(),
          ),
          if (_cloneError != null) ...[
            const SizedBox(height: 16),
            Text(
              _cloneError!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: _cloning
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(strokeWidth: 2),
                          SizedBox(width: 16),
                          Text('Clonando...'),
                        ],
                      ),
                    ),
                  )
                : FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      foregroundColor: Colors.black,
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                    onPressed: _startClone,
                    child: const Text('Clonar'),
                  ),
          ),
        ],
      ),
    );
  }
}

