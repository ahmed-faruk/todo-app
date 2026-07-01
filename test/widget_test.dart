import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_app/main.dart';

void main() {
  testWidgets('TodoApp renders the ToDo title', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: TodoApp()));
    expect(find.text('ToDo'), findsOneWidget);
  });
}
