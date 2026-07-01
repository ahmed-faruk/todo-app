import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/data/app_database.dart';
import 'package:todo_app/data/drift_todo_repository.dart';

void main() {
  late AppDatabase db;
  late DriftTodoRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftTodoRepository(db);
  });

  tearDown(() => db.close());

  group('DriftTodoRepository', () {
    test('watchAll emits empty list on fresh DB', () async {
      final todos = await repo.watchAll().first;
      expect(todos, isEmpty);
    });

    test('create adds a todo that appears in watchAll', () async {
      await repo.create('Walk the dog');
      final todos = await repo.watchAll().first;
      expect(todos, hasLength(1));
      expect(todos.first.title, 'Walk the dog');
      expect(todos.first.isCompleted, isFalse);
    });

    test('create multiple todos, all appear in watchAll', () async {
      await repo.create('First');
      await repo.create('Second');
      final todos = await repo.watchAll().first;
      expect(todos, hasLength(2));
      expect(todos.map((t) => t.title), containsAll(['First', 'Second']));
    });

    test('delete removes the todo', () async {
      await repo.create('Temporary');
      final before = await repo.watchAll().first;
      expect(before, hasLength(1));

      await repo.delete(before.first.id);
      final after = await repo.watchAll().first;
      expect(after, isEmpty);
    });

    test('delete non-existent id is a no-op', () async {
      await repo.create('Stays');
      await repo.delete(9999);
      final todos = await repo.watchAll().first;
      expect(todos, hasLength(1));
    });

    test('toggle marks an incomplete todo as completed', () async {
      await repo.create('Buy milk');
      final before = await repo.watchAll().first;
      expect(before.first.isCompleted, isFalse);

      await repo.toggle(before.first.id);
      final after = await repo.watchAll().first;
      expect(after.first.isCompleted, isTrue);
    });

    test('toggle marks a completed todo back to incomplete', () async {
      await repo.create('Buy milk');
      final id = (await repo.watchAll().first).first.id;
      await repo.toggle(id);
      await repo.toggle(id);
      final after = await repo.watchAll().first;
      expect(after.first.isCompleted, isFalse);
    });

    test('toggle non-existent id is a no-op', () async {
      await repo.create('Safe');
      await repo.toggle(9999);
      final todos = await repo.watchAll().first;
      expect(todos.first.isCompleted, isFalse);
    });

    test('rename updates the title', () async {
      await repo.create('Old title');
      final id = (await repo.watchAll().first).first.id;
      await repo.rename(id, 'New title');
      final todos = await repo.watchAll().first;
      expect(todos.first.title, 'New title');
    });

    test('rename with empty string is a no-op', () async {
      await repo.create('Stays');
      final id = (await repo.watchAll().first).first.id;
      await repo.rename(id, '   ');
      final todos = await repo.watchAll().first;
      expect(todos.first.title, 'Stays');
    });

    test('rename trims whitespace', () async {
      await repo.create('Original');
      final id = (await repo.watchAll().first).first.id;
      await repo.rename(id, '  Trimmed  ');
      final todos = await repo.watchAll().first;
      expect(todos.first.title, 'Trimmed');
    });

    test('rename non-existent id is a no-op', () async {
      await repo.create('Untouched');
      await repo.rename(9999, 'Ghost');
      final todos = await repo.watchAll().first;
      expect(todos.first.title, 'Untouched');
    });
  });
}
