import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/application/providers.dart';
import 'package:todo_app/data/app_database.dart';
import 'package:todo_app/data/drift_todo_repository.dart';
import 'package:todo_app/domain/todo_repository.dart';
import 'package:todo_app/presentation/todo_screen.dart';

/// Pumps TodoScreen wired to an in-memory Drift database.
Future<AppDatabase> _pumpScreen(WidgetTester tester) async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  addTearDown(db.close);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        todoRepositoryProvider.overrideWithValue(
          DriftTodoRepository(db) as TodoRepository,
        ),
      ],
      child: const MaterialApp(home: TodoScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return db;
}

/// Unmount the tree and advance the clock so Drift's stream-cleanup timer
/// fires inside the test body — otherwise the framework's end-of-test
/// invariant check trips "A Timer is still pending after dispose".
Future<void> _drain(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}

Future<void> _addTodo(WidgetTester tester, String title) async {
  await tester.enterText(find.byType(TextField).first, title);
  await tester.tap(find.widgetWithText(FilledButton, 'Add'));
  await tester.pumpAndSettle();
}

void main() {
  group('TodoScreen', () {
    testWidgets('AC1: adding a todo shows it in the list', (tester) async {
      await _pumpScreen(tester);
      expect(find.text('No todos yet.'), findsOneWidget);

      await _addTodo(tester, 'Buy milk');

      expect(find.text('Buy milk'), findsOneWidget);
      expect(find.text('No todos yet.'), findsNothing);
      await _drain(tester);
    });

    testWidgets('AC2: tapping checkbox toggles completion + strikethrough', (
      tester,
    ) async {
      await _pumpScreen(tester);
      await _addTodo(tester, 'Task');

      Checkbox checkbox = tester.widget(find.byType(Checkbox));
      expect(checkbox.value, isFalse);

      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      checkbox = tester.widget(find.byType(Checkbox));
      expect(checkbox.value, isTrue);

      final titleText = tester.widget<Text>(find.text('Task'));
      expect(titleText.style?.decoration, TextDecoration.lineThrough);
      await _drain(tester);
    });

    testWidgets('AC3: tapping title opens inline edit and saves new title', (
      tester,
    ) async {
      await _pumpScreen(tester);
      await _addTodo(tester, 'Original');

      await tester.tap(find.text('Original'));
      // Fixed pumps: the autofocus edit field's cursor blink never settles.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(TextField), findsNWidgets(2));

      await tester.enterText(find.byType(TextField).last, 'Renamed');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('Renamed'), findsOneWidget);
      expect(find.text('Original'), findsNothing);
      await _drain(tester);
    });

    testWidgets('AC4: discarding inline edit keeps the original title', (
      tester,
    ) async {
      await _pumpScreen(tester);
      await _addTodo(tester, 'KeepMe');

      await tester.tap(find.text('KeepMe'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.enterText(find.byType(TextField).last, 'ShouldNotStick');
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('KeepMe'), findsOneWidget);
      expect(find.text('ShouldNotStick'), findsNothing);
      await _drain(tester);
    });

    testWidgets('AC5: filter tabs show the correct subset', (tester) async {
      await _pumpScreen(tester);
      await _addTodo(tester, 'ActiveOne');
      await _addTodo(tester, 'DoneOne');

      final doneTile = find.ancestor(
        of: find.text('DoneOne'),
        matching: find.byType(ListTile),
      );
      await tester.tap(
        find.descendant(of: doneTile, matching: find.byType(Checkbox)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Active'));
      await tester.pumpAndSettle();
      expect(find.text('ActiveOne'), findsOneWidget);
      expect(find.text('DoneOne'), findsNothing);

      await tester.tap(find.text('Completed'));
      await tester.pumpAndSettle();
      expect(find.text('DoneOne'), findsOneWidget);
      expect(find.text('ActiveOne'), findsNothing);

      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();
      expect(find.text('ActiveOne'), findsOneWidget);
      expect(find.text('DoneOne'), findsOneWidget);
      await _drain(tester);
    });

    testWidgets('AC6: filter-aware empty-state messages', (tester) async {
      await _pumpScreen(tester);
      await _addTodo(tester, 'OnlyActive');

      await tester.tap(find.text('Completed'));
      await tester.pumpAndSettle();
      expect(find.text('No completed todos.'), findsOneWidget);

      await tester.tap(find.text('Active'));
      await tester.pumpAndSettle();
      expect(find.text('OnlyActive'), findsOneWidget);

      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      expect(find.text('No active todos.'), findsOneWidget);
      await _drain(tester);
    });

    testWidgets('deleting a todo removes it from the list', (tester) async {
      await _pumpScreen(tester);
      await _addTodo(tester, 'Temporary');
      expect(find.text('Temporary'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.text('Temporary'), findsNothing);
      expect(find.text('No todos yet.'), findsOneWidget);
      await _drain(tester);
    });
  });
}
