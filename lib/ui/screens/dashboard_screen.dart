import 'package:flutter/material.dart';
import 'package:tradu_git/ui/app_theme.dart';
import 'package:tradu_git/ui/screens/workspace_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Repositorios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
        children: [
          Text(
            'Inicio',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Inicio.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.muted,
                  height: 1.35,
                ),
          ),
          const SizedBox(height: 20),
          _RepoCard(
            name: 'renpy',
            branch: 'test',
            updated: 'Editado hace 2 horas',
            onOpen: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WorkspaceScreen()),
              );
            },
          ),
          _RepoCard(
            name: 'ui',
            branch: 'main',
            updated: 'Editado ayer',
            onOpen: () {},
          ),
          _RepoCard(
            name: 'proyecto',
            branch: 'fix',
            updated: 'Sincronizado hace 3 dias',
            onOpen: () {},
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const _CloneSheet(),
          );
        },
        backgroundColor: AppTheme.accent,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('Clonar'),
      ),
    );
  }
}

class _RepoCard extends StatelessWidget {
  const _RepoCard({
    required this.name,
    required this.branch,
    required this.updated,
    required this.onOpen,
  });

  final String name;
  final String branch;
  final String updated;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: InkWell(
        borderRadius: BorderRadius.zero,
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                children: [
                  _Tag(icon: Icons.alt_route, label: branch),
                  _Tag(icon: Icons.history, label: updated),
                ],
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
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppTheme.ink,
                ),
          ),
        ],
      ),
    );
  }
}

class _CloneSheet extends StatelessWidget {
  const _CloneSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
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
            'Elige un repositorio disponible o pega la URL manualmente.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.ink.withOpacity(0.6),
                ),
          ),
          const SizedBox(height: 16),
          _RepoListTile(
            name: 'renpy',
            owner: 'random',
            onTap: () {},
          ),
          _RepoListTile(
            name: 'ui',
            owner: 'random',
            onTap: () {},
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              labelText: 'URL',
              hintText: 'https://github.com/org/repo.git',
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {},
              child: const Text('Clonar'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RepoListTile extends StatelessWidget {
  const _RepoListTile({
    required this.name,
    required this.owner,
    required this.onTap,
  });

  final String name;
  final String owner;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: AppTheme.accentSoft,
        child: const Icon(Icons.folder_copy, color: AppTheme.accent),
      ),
      title: Text(name),
      subtitle: Text(owner),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
