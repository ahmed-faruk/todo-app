import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/providers.dart';
import '../domain/todo.dart';

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
    final todoList = ref.watch(todoListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('ToDo')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
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
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _submit,
                  child: const Text('Add'),
                ),
              ],
            ),
          ),
          Expanded(
            child: todoList.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (todos) {
                if (todos.isEmpty) {
                  return const Center(child: Text('No todos yet.'));
                }
                return ListView.builder(
                  itemCount: todos.length,
                  itemBuilder: (context, index) {
                    return _TodoTile(todo: todos[index]);
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
  const _TodoTile({required this.todo});
  final Todo todo;

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
    // Keep controller in sync if the title changes from outside (e.g. undo)
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
    // Capture ref before the async gap; guard against disposal after await.
    final notifier = ref.read(todoNotifierProvider);
    await notifier.rename(widget.todo.id, newTitle);
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Checkbox(
        value: widget.todo.isCompleted,
        onChanged: (_) =>
            ref.read(todoNotifierProvider).toggle(widget.todo.id),
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
                    ? const TextStyle(decoration: TextDecoration.lineThrough)
                    : null,
              ),
            ),
      trailing: _editing
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: _save,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _discard,
                ),
              ],
            )
          : IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () =>
                  ref.read(todoNotifierProvider).delete(widget.todo.id),
            ),
    );
  }
}
