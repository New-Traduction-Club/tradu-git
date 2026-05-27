import 'package:flutter/material.dart';
import 'package:tradu_git/ui/app_theme.dart';
import 'package:tradu_git/ui/widgets/sora_editor_view.dart';

class WorkspaceScreen extends StatefulWidget {
  const WorkspaceScreen({super.key});

  @override
  State<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends State<WorkspaceScreen> {
  int _navIndex = 0;

  static const double _toolbarHeight = 44;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('renpy'),
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
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Text(
                  'Explorador',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: const [
                    _FolderTile(
                      title: 'scripts',
                      children: [
                        _FileTile(title: 'script.rpy'),
                        _FileTile(title: 'options.rpy', dirty: true),
                      ],
                    ),
                    _FolderTile(
                      title: 'l10n',
                      children: [
                        _FileTile(title: 'screens.rpy'),
                        _FileTile(title: 'definitions.rpy'),
                      ],
                    ),
                  ],
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
              bottom: _toolbarHeight + MediaQuery.of(context).padding.bottom,
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
                      const _TerminalPanel(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _BottomToolbar(height: _toolbarHeight),
          ),
        ],
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          bottom: BorderSide(color: AppTheme.border),
        ),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: const [
          _TabChip(title: 'script.rpy', dirty: true, active: true),
          _TabChip(title: 'screens.rpy', dirty: true),
          _TabChip(title: 'definitions.rpy'),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.title,
    this.dirty = false,
    this.active = false,
  });

  final String title;
  final bool dirty;
  final bool active;

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
            const Icon(Icons.close, size: 14),
          ],
        ),
      ),
    );
  }
}

class _EditorView extends StatelessWidget {
  const _EditorView();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.all(6),
      child: const SoraEditorView(),
    );
  }
}

class _GitPanel extends StatelessWidget {
  const _GitPanel();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Cambios',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        _GitFileTile(name: 'script.rpy', status: 'Modificado'),
        _GitFileTile(name: 'options.rpy', status: 'Modificado'),
        const SizedBox(height: 24),
        Text(
          'Staging',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        _GitFileTile(name: 'screens.rpy', status: 'Listo'),
        const SizedBox(height: 24),
        TextField(
          maxLines: 2,
          decoration: InputDecoration(
            labelText: 'Mensaje',
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () {},
            child: const Text('Hacer commit'),
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.sync),
          label: const Text('Sincronizar cambios'),
        ),
      ],
    );
  }
}

class _GitFileTile extends StatelessWidget {
  const _GitFileTile({required this.name, required this.status});

  final String name;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(
                  status,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppTheme.muted,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class _TerminalPanel extends StatelessWidget {
  const _TerminalPanel();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Terminal',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0B0F0E),
                borderRadius: BorderRadius.zero,
              ),
              child: Text(
                r'''
$ git status
On branch traduccion-es
Changes not staged for commit:
  modified: script.rpy
  modified: options.rpy

$ git add script.rpy
''',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  color: Color(0xFF91CABB),
                  height: 1.35,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              hintText: 'Escribe un comando',
              prefixIcon: const Icon(Icons.chevron_right),
            ),
          ),
        ],
      ),
    );
  }
}

class _FolderTile extends StatelessWidget {
  const _FolderTile({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          child: Row(
            children: [
              const Icon(Icons.keyboard_arrow_down, size: 16, color: AppTheme.muted),
              const SizedBox(width: 4),
              const Icon(Icons.folder, size: 16, color: AppTheme.muted),
              const SizedBox(width: 6),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.ink,
                    ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 18),
          child: Column(children: children),
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
                  _ViewDrawerItem(
                    label: 'Terminal',
                    icon: Icons.terminal,
                    active: currentIndex == 2,
                    onTap: () => onSelect(2),
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

class _BottomToolbar extends StatelessWidget {
  const _BottomToolbar({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ToolbarButton(icon: Icons.save, onTap: () {}),
              _ToolbarButton(icon: Icons.search, onTap: () {}),
              _ToolbarButton(icon: Icons.find_replace, onTap: () {}),
              _ToolbarButton(icon: Icons.tune, onTap: () {}),
            ],
          ),
        ),
      ),
    );
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

class _FileTile extends StatelessWidget {
  const _FileTile({required this.title, this.dirty = false});

  final String title;
  final bool dirty;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: const Icon(Icons.insert_drive_file, size: 16, color: AppTheme.muted),
      title: Text(
        dirty ? '$title *' : title,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.ink),
      ),
      onTap: () {},
    );
  }
}

const sampleText = '''# TODO: example
# game/script-ch1.rpy:9
translate spanish ch1_main_0f077782:

    # m "Hi again, [player]!"
    m "¡Hola de nuevo, [player]!"

# game/script-ch1.rpy:10
translate spanish ch1_main_95ea4bac:

    # m "Glad to see you didn't run away on us. Hahaha!"
    m "Qué bien, no has huido con el rabo entre las piernas. ¡Ja, ja, ja!"

# game/script-ch1.rpy:11
translate spanish ch1_main_ecaf5654:

    # mc "Nah, don't worry."
    mc "Qué va, yo no hago esas cosas."

# game/script-ch1.rpy:12
translate spanish ch1_main_a0e98f5a:

    # mc "This might be a little strange for me, but I at least keep my word."
    mc "Se me hace un poco raro, pero pienso cumplir mi palabra."

# game/script-ch1.rpy:15
translate spanish ch1_main_5bff8fb6:

    # "Well, I'm back at the Literature Club."
    "Bien, he vuelto al club de literatura."

# game/script-ch1.rpy:16
translate spanish ch1_main_0565e928:

    # "I was the last to come in, so everyone else is already hanging out."
    "He sido el último en llegar, así que las chicas ya están pasando el rato."

# game/script-ch1.rpy:18
translate spanish ch1_main_209577b0:

    # y "Thanks for keeping your promise, [player]."
    y "Gracias por mantener tu promesa, [player]."

# game/script-ch1.rpy:19
translate spanish ch1_main_fc35d1a5:

    # y "I hope this isn't too overwhelming of a commitment for you."
    y "Espero que este compromiso no se te haga muy cuesta arriba."

# game/script-ch1.rpy:20
translate spanish ch1_main_0b033aa0:

    # y 1u "Making you dive headfirst into literature when you're not accustomed to it..."
    y 1u "Es duro que te obliguen a zambullirte en la literatura cuando no estás acostumbrado..."

# game/script-ch1.rpy:22
translate spanish ch1_main_4bc8df14:

    # n "Oh, come on! Like he deserves any slack."
    n "¡Venga ya! No hace falta que te compadezcas de él."

# game/script-ch1.rpy:23
translate spanish ch1_main_54887548:

    # n "Sayori told me you didn't even want to join any clubs this year."
    n "Sayori me dijo que ni siquiera pensabas unirte a ningún club este año."

# game/script-ch1.rpy:24
translate spanish ch1_main_0e4e14ce:

    # n "And last year, too!"
    n "¡Ni el año pasado!"

# game/script-ch1.rpy:25
translate spanish ch1_main_131e8e4b:

    # n 4c "I don't know if you plan to just come here and hang out, or what..."
    n 4c "No sé si piensas venir a hacer el zángano..."
''';
