import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app/main.dart';
import 'package:todo_app/theme/app_theme.dart';

void main() {
  testWidgets('TodoApp renders the ToDo title', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: TodoApp()));
    expect(find.text('ToDo'), findsOneWidget);
  });

  test('AppTheme.dark() is a dark-brightness theme', () {
    expect(AppTheme.dark().brightness, Brightness.dark);
  });

  test('AppTheme.light() is a light-brightness theme', () {
    expect(AppTheme.light().brightness, Brightness.light);
  });

  testWidgets('TodoApp wires ThemeMode.system', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: TodoApp()));
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.system);
  });
}
