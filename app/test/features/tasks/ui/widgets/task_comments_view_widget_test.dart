import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imker/features/tasks/domain/models/task_comment.dart';
import 'package:imker/features/tasks/ui/widgets/task_comments_view.dart';

void main() {
  testWidgets('«hace X» se calcula con el reloj inyectado', (tester) async {
    final now = DateTime.utc(2026, 3, 4, 12);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TaskCommentsView(
              comments: [
                TaskComment(
                  id: 'c1',
                  userId: 'ana',
                  body: 'Listo',
                  createdAt: now.subtract(const Duration(minutes: 5)),
                ),
              ],
              isLoading: false,
              loaded: true,
              isSending: false,
              authorOf: (_) => 'Ana',
              onSend: (_) async => null,
              clock: () => now,
            ),
          ),
        ),
      ),
    );

    expect(find.textContaining('hace 5 min'), findsOneWidget);
  });
}
