import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:imker/features/tasks/ui/widgets/new_task_dialog.dart';

typedef _Result = ({String title, String description, DateTime? deadlineDay});

void main() {
  // «Hoy» fijo: 14 de marzo de 2026, a media tarde.
  DateTime clock() => DateTime(2026, 3, 14, 15, 30);

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Get.dialog<_Result>(NewTaskDialog(clock: clock)),
            child: const Text('abrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  Future<_Result?> createWith(
    WidgetTester tester, {
    Future<void> Function()? pickDate,
  }) async {
    _Result? result;
    await tester.pumpWidget(
      GetMaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async =>
                result = await Get.dialog<_Result>(NewTaskDialog(clock: clock)),
            child: const Text('abrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('task.new.title')), 'Login');
    if (pickDate != null) await pickDate();
    await tester.tap(find.text('Crear'));
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets('sin fecha límite la tarea se crea igual, con deadline nulo', (
    tester,
  ) async {
    final result = await createWith(tester);

    expect(result?.title, 'Login');
    expect(result?.deadlineDay, isNull);
  });

  testWidgets('elegir un día lo devuelve como fecha límite', (tester) async {
    final result = await createWith(
      tester,
      pickDate: () async {
        await tester.tap(find.byKey(const Key('task.new.deadline')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('20'));
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
      },
    );

    expect(result?.deadlineDay, DateTime(2026, 3, 20));
  });

  testWidgets('el botón muestra el día elegido y se puede quitar', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.byKey(const Key('task.new.deadline')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('20'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text('Límite: 20/03/2026'), findsOneWidget);

    await tester.tap(find.byKey(const Key('task.new.deadline.clear')));
    await tester.pumpAndSettle();

    expect(find.text('Fecha límite (opcional)'), findsOneWidget);
    expect(find.byKey(const Key('task.new.deadline.clear')), findsNothing);
  });

  testWidgets('no se pueden elegir días anteriores a hoy', (tester) async {
    await open(tester);
    await tester.tap(find.byKey(const Key('task.new.deadline')));
    await tester.pumpAndSettle();

    final picker = tester.widget<CalendarDatePicker>(
      find.byType(CalendarDatePicker),
    );
    expect(picker.firstDate, DateTime(2026, 3, 14));
    expect(picker.selectableDayPredicate, isNull);
    // El 13 existe en pantalla pero está deshabilitado: tocarlo no lo elige.
    await tester.tap(find.text('13'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('Límite: 13/03/2026'), findsNothing);
  });

  testWidgets('el nombre sigue siendo obligatorio', (tester) async {
    await open(tester);
    await tester.tap(find.text('Crear'));
    await tester.pumpAndSettle();

    expect(find.text('Escribe un nombre'), findsOneWidget);
  });
}
