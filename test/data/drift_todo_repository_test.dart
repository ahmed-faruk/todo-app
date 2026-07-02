import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sqlite3;
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

    test('create places new todo at the front (lowest sortOrder)', () async {
      await repo.create('First');
      await repo.create('Second');
      final todos = await repo.watchAll().first;
      expect(todos.map((t) => t.title).toList(), ['Second', 'First']);
    });

    test('reorder persists the new order in watchAll', () async {
      await repo.create('A');
      await repo.create('B');
      await repo.create('C');
      // watchAll order is newest-first by default: C, B, A.
      final initial = await repo.watchAll().first;
      final ids = initial.map((t) => t.id).toList();

      // Reorder to A, B, C.
      await repo.reorder(ids.reversed.toList());

      final reordered = await repo.watchAll().first;
      expect(reordered.map((t) => t.title).toList(), ['A', 'B', 'C']);
    });
  });

  group('v1 -> v2 migration (sortOrder backfill)', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('todo_app_migration_test');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test(
      'backfills sortOrder from createdAt desc, preserving display order',
      () async {
        final dbFile = File(p.join(tempDir.path, 'v1.db'));

        // Simulate an existing v1 install: create the v1-shaped table
        // (no sortOrder column) and insert rows with distinct createdAt
        // values, out of insertion order, then stamp the sqlite
        // user_version to 1 so drift's migrator treats it as an upgrade.
        final rawDb = sqlite3.sqlite3.open(dbFile.path);
        rawDb.execute('''
          CREATE TABLE todo_items (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            is_completed INTEGER NOT NULL DEFAULT 0,
            created_at INTEGER NOT NULL
          );
        ''');
        rawDb.execute('''
          INSERT INTO todo_items (id, title, is_completed, created_at)
          VALUES
            (1, 'Oldest', 0, 1000),
            (2, 'Middle', 0, 2000),
            (3, 'Newest', 0, 3000);
        ''');
        rawDb.execute('PRAGMA user_version = 1;');
        rawDb.dispose();

        // Reopen with the real (v2) AppDatabase — triggers onUpgrade.
        final upgradedDb = AppDatabase.forTesting(NativeDatabase(dbFile));
        final upgradedRepo = DriftTodoRepository(upgradedDb);

        final todos = await upgradedRepo.watchAll().first;

        // Pre-migration display order was createdAt desc: Newest, Middle,
        // Oldest. The backfill must preserve exactly that order.
        expect(todos.map((t) => t.title).toList(), [
          'Newest',
          'Middle',
          'Oldest',
        ]);

        await upgradedDb.close();
      },
    );
  });
}
