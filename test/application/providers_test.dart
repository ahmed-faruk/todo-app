import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/application/providers.dart';
import 'package:todo_app/data/app_database.dart';
import 'package:todo_app/data/drift_todo_repository.dart';
import 'package:todo_app/domain/todo_repository.dart';

ProviderContainer _makeContainer() {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final repo = DriftTodoRepository(db);
  return ProviderContainer(
    overrides: [
      todoRepositoryProvider.overrideWithValue(repo as TodoRepository),
    ],
  );
}

void main() {
  group('todoListProvider', () {
    test('initially emits empty list', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);

      final result = await container.read(todoListProvider.future);
      expect(result, isEmpty);
    });

    test('reflects a todo added via todoNotifierProvider', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);

      await container.read(todoNotifierProvider).add('Test item');
      final result = await container.read(todoListProvider.future);
      expect(result, hasLength(1));
      expect(result.first.title, 'Test item');
    });

    test('reflects toggle via todoNotifierProvider', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);

      await container.read(todoNotifierProvider).add('Toggleable');
      final before = await container.read(todoListProvider.future);
      expect(before.first.isCompleted, isFalse);

      await container.read(todoNotifierProvider).toggle(before.first.id);
      final after = await container
          .read(todoRepositoryProvider)
          .watchAll()
          .firstWhere((list) => list.isNotEmpty && list.first.isCompleted);
      expect(after.first.isCompleted, isTrue);
    });

    test('reflects deletion via todoNotifierProvider', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);

      await container.read(todoNotifierProvider).add('To delete');
      final before = await container.read(todoListProvider.future);
      expect(before, hasLength(1));

      await container.read(todoNotifierProvider).delete(before.first.id);
      // Wait for the stream to emit the updated (empty) list
      final after = await container
          .read(todoRepositoryProvider)
          .watchAll()
          .firstWhere((list) => list.isEmpty);
      expect(after, isEmpty);
    });
  });
}
