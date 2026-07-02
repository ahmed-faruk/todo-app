import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/providers.dart';
import '../domain/todo.dart';
import '../theme/design_tokens.dart';

class TodoScreen extends ConsumerStatefulWidget {
  const TodoScreen({super.key});

  @override
  ConsumerState<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends ConsumerState<TodoScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _controller.text.trim();
    if (title.isEmpty) return;
    _controller.clear();
    await ref.read(todoNotifierProvider).add(title);
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(filterProvider);
    final filteredList = ref.watch(filteredTodoListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('ToDo')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    decoration: const InputDecoration(
                      hintText: 'Add a todo…',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                FilledButton(onPressed: _submit, child: const Text('Add')),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: SegmentedButton<TodoFilter>(
              segments: const [
                ButtonSegment(value: TodoFilter.all, label: Text('All')),
                ButtonSegment(value: TodoFilter.active, label: Text('Active')),
                ButtonSegment(
                  value: TodoFilter.completed,
                  label: Text('Completed'),
                ),
              ],
              selected: {filter},
              onSelectionChanged: (selected) =>
                  ref.read(filterProvider.notifier).state = selected.first,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: filteredList.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text(
                  'Error: $e',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
              data: (todos) {
                if (todos.isEmpty) {
                  final (message, icon) = switch (filter) {
                    TodoFilter.active => (
                      'No active todos.',
                      Icons.task_alt_outlined,
                    ),
                    TodoFilter.completed => (
                      'No completed todos.',
                      Icons.task_alt_outlined,
                    ),
                    TodoFilter.all => (
                      'No todos yet.',
                      Icons.checklist_outlined,
                    ),
                  };
                  final onSurfaceVariant = Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant;
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 48, color: onSurfaceVariant),
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          message,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: onSurfaceVariant),
                        ),
                      ],
                    ),
                  );
                }
                if (filter != TodoFilter.all) {
                  return ListView.builder(
                    itemCount: todos.length,
                    itemBuilder: (context, index) {
                      return _TodoTile(
                        key: ValueKey(todos[index].id),
                        todo: todos[index],
                        reorderable: false,
                      );
                    },
                  );
                }
                return ReorderableListView.builder(
                  buildDefaultDragHandles: false,
                  itemCount: todos.length,
                  itemBuilder: (context, index) {
                    return _TodoTile(
                      key: ValueKey(todos[index].id),
                      todo: todos[index],
                      reorderable: true,
                      dragIndex: index,
                    );
                  },
                  onReorder: (oldIndex, newIndex) {
                    final adjustedNewIndex = newIndex > oldIndex
                        ? newIndex - 1
                        : newIndex;
                    final ids = todos.map((t) => t.id).toList();
                    final movedId = ids.removeAt(oldIndex);
                    ids.insert(adjustedNewIndex, movedId);
                    ref.read(todoNotifierProvider).reorder(ids);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TodoTile extends ConsumerStatefulWidget {
  const _TodoTile({
    super.key,
    required this.todo,
    required this.reorderable,
    this.dragIndex,
  });
  final Todo todo;
  final bool reorderable;
  final int? dragIndex;

  @override
  ConsumerState<_TodoTile> createState() => _TodoTileState();
}

class _TodoTileState extends ConsumerState<_TodoTile> {
  bool _editing = false;
  late final TextEditingController _editController;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: widget.todo.title);
  }

  @override
  void didUpdateWidget(_TodoTile old) {
    super.didUpdateWidget(old);
    if (!_editing && old.todo.title != widget.todo.title) {
      _editController.text = widget.todo.title;
    }
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  void _startEditing() => setState(() {
    _editController.text = widget.todo.title;
    _editing = true;
  });

  void _discard() => setState(() => _editing = false);

  Future<void> _save() async {
    final newTitle = _editController.text.trim();
    setState(() => _editing = false);
    if (newTitle.isEmpty || newTitle == widget.todo.title) return;
    final notifier = ref.read(todoNotifierProvider);
    await notifier.rename(widget.todo.id, newTitle);
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Checkbox(
        value: widget.todo.isCompleted,
        onChanged: (_) => ref.read(todoNotifierProvider).toggle(widget.todo.id),
      ),
      title: _editing
          ? TextField(
              controller: _editController,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
              onTapOutside: (_) => _discard(),
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
              ),
            )
          : GestureDetector(
              onTap: _startEditing,
              child: Text(
                widget.todo.title,
                style: widget.todo.isCompleted
                    ? Theme.of(context).textTheme.titleMedium?.copyWith(
                        decoration: TextDecoration.lineThrough,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      )
                    : Theme.of(context).textTheme.titleMedium,
              ),
            ),
      trailing: _editing
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: const Icon(Icons.check), onPressed: _save),
                IconButton(icon: const Icon(Icons.close), onPressed: _discard),
              ],
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: () =>
                      ref.read(todoNotifierProvider).delete(widget.todo.id),
                ),
                if (widget.reorderable && widget.dragIndex != null)
                  ReorderableDragStartListener(
                    index: widget.dragIndex!,
                    child: const Icon(Icons.drag_handle),
                  ),
              ],
            ),
    );
  }
}
