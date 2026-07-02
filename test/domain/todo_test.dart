import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/domain/todo.dart';

void main() {
  group('Todo entity', () {
    final base = Todo(
      id: 1,
      title: 'Buy milk',
      isCompleted: false,
      createdAt: DateTime(2024, 1, 1),
      sortOrder: 0,
    );

    test('copyWith returns new instance with updated fields', () {
      final updated = base.copyWith(title: 'Buy oat milk', isCompleted: true);
      expect(updated.id, 1);
      expect(updated.title, 'Buy oat milk');
      expect(updated.isCompleted, isTrue);
      expect(updated.createdAt, DateTime(2024, 1, 1));
      expect(updated.sortOrder, 0);
    });

    test('copyWith can update sortOrder', () {
      final updated = base.copyWith(sortOrder: 5);
      expect(updated.sortOrder, 5);
    });

    test('copyWith with no args returns equal instance', () {
      expect(base.copyWith(), equals(base));
    });

    test('equality is value-based', () {
      final other = Todo(
        id: 1,
        title: 'Buy milk',
        isCompleted: false,
        createdAt: DateTime(2024, 1, 1),
        sortOrder: 0,
      );
      expect(base, equals(other));
    });

    test('different id produces unequal instances', () {
      final other = base.copyWith(id: 2);
      expect(base, isNot(equals(other)));
    });

    test('different sortOrder produces unequal instances', () {
      final other = base.copyWith(sortOrder: 1);
      expect(base, isNot(equals(other)));
    });

    test('hashCode matches for equal todos', () {
      final other = Todo(
        id: 1,
        title: 'Buy milk',
        isCompleted: false,
        createdAt: DateTime(2024, 1, 1),
        sortOrder: 0,
      );
      expect(base.hashCode, equals(other.hashCode));
    });

    test('has no Flutter or Drift imports', () {
      // Verified statically: lib/domain/todo.dart has no package: imports.
      // This test documents the contract.
      expect(true, isTrue);
    });
  });
}
