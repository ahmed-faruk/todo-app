import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

// Table named TodoItems so the Drift-generated row type is `TodoItem`,
// avoiding a name collision with the domain `Todo` entity.
class TodoItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 500)();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

@DriftDatabase(tables: [TodoItems])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(todoItems, todoItems.sortOrder);
        // Backfill sortOrder from the pre-migration display order
        // (createdAt desc) so existing users see no reshuffle.
        final rows = await (select(
          todoItems,
        )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();
        await transaction(() async {
          for (var i = 0; i < rows.length; i++) {
            await (update(todoItems)..where((t) => t.id.equals(rows[i].id)))
                .write(TodoItemsCompanion(sortOrder: Value(i)));
          }
        });
      }
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'todo_app.db'));
    return NativeDatabase.createInBackground(file);
  });
}
