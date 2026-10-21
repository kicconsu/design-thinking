import 'package:flutter_test/flutter_test.dart';
import 'package:imker/features/tasks/data/datasources/in_memory_task_data_source.dart';
import 'package:imker/features/tasks/data/repositories/task_repository.dart';
import 'package:imker/features/tasks/domain/models/task_status.dart';
import 'package:imker/features/trust/data/datasources/in_memory_trust_data_source.dart';
import 'package:imker/features/trust/data/repositories/trust_repository.dart';

/// T-01 de punta a punta, con datos mock: los contadores que escribe
/// [TaskRepository] a lo largo de una historia completa son los que luego
/// leen los indicadores de confianza.
void main() {
  const projectId = 'p1';
  const ana = 'ana';

  late InMemoryTaskDataSource tasksSource;
  late TaskRepository tasks;

  setUp(() {
    tasksSource = InMemoryTaskDataSource();
    tasks = TaskRepository(tasksSource);
  });

  /// Lo que devuelve la consulta guardada de participaciones: los contadores
  /// de todas las estancias de la persona sumados por proyecto, junto a los
  /// totales del proyecto.
  Future<TrustRepository> trustFromWrittenCounters() async {
    final stays = tasksSource.members.where((m) => m['user_id'] == ana);
    int sum(String key) =>
        stays.fold(0, (total, m) => total + ((m[key] as num?)?.toInt() ?? 0));
    final source = InMemoryTrustDataSource()
      ..participations.add({
        'user_id': ana,
        'project_id': projectId,
        'tasks_taken': '${sum('tasks_taken')}',
        'tasks_finished': '${sum('tasks_finished')}',
        'total_tasks': '${tasksSource.totalTasksByProject[projectId]}',
        'progress': '${tasksSource.progressByProject[projectId]}',
      });
    return TrustRepository(source);
  }

  void join(String rowId, String joinedAt) => tasksSource.members.add({
    '_id': rowId,
    'project_id': projectId,
    'user_id': ana,
    'status': 'active',
    'joinedAt': joinedAt,
  });

  Map<String, dynamic> stay(String rowId) =>
      tasksSource.members.firstWhere((m) => m['_id'] == rowId);

  test('reservar, terminar, reabrir, salir y volver', () async {
    join('m1', '2026-01-01T00:00:00Z');
    final a = await tasks.createTask(projectId: projectId, title: 'a');
    final b = await tasks.createTask(projectId: projectId, title: 'b');
    final c = await tasks.createTask(projectId: projectId, title: 'c');

    // Reserva dos, termina una, la reabre y la vuelve a terminar.
    final ta = await tasks.reserveTask(task: a, userId: ana);
    final tb = await tasks.reserveTask(task: b, userId: ana);
    final doneA = await tasks.updateTaskStatus(
      task: ta,
      status: TaskStatus.done,
    );
    expect(stay('m1')['tasks_finished'], 1);
    final reopenedA = await tasks.updateTaskStatus(
      task: doneA,
      status: TaskStatus.doing,
    );
    expect(stay('m1')['tasks_finished'], 0);
    await tasks.updateTaskStatus(task: reopenedA, status: TaskStatus.done);
    await tasks.updateTaskStatus(task: tb, status: TaskStatus.done);
    expect(stay('m1')['tasks_taken'], 2);
    expect(stay('m1')['tasks_finished'], 2);

    // Toma una tercera y sale con ella sin terminar: queda libre, pero sigue
    // contando como tomada en su primera estancia.
    await tasks.reserveTask(task: c, userId: ana);
    stay('m1')['status'] = 'left';
    await tasks.releaseUnfinishedTasks(projectId: projectId, userId: ana);
    expect(stay('m1')['tasks_taken'], 3);
    expect(stay('m1')['tasks_finished'], 2);

    final partial = await (await trustFromWrittenCounters()).getTrustMetricsOf(
      ana,
    );
    // 2 de 3 tomadas terminadas; el proyecto va al 67 %: no está completado.
    expect(partial.hasHistory, isTrue);
    expect(partial.fulfillment, 67);
    expect(partial.completedProjects, 0);
    expect(partial.onTime, isNull);

    // Vuelve (estancia nueva), retoma la tarea y la termina.
    join('m2', '2026-02-01T00:00:00Z');
    final freeC = (await tasks.getTasks(projectId))
        .firstWhere((t) => t.id == c.id);
    final tc = await tasks.reserveTask(task: freeC, userId: ana);
    await tasks.updateTaskStatus(task: tc, status: TaskStatus.done);

    // Cada estancia anota lo suyo; el total no se duplica.
    expect(stay('m1')['tasks_taken'], 3);
    expect(stay('m1')['tasks_finished'], 2);
    expect(stay('m2')['tasks_taken'], 1);
    expect(stay('m2')['tasks_finished'], 1);

    final metrics = await (await trustFromWrittenCounters()).getTrustMetricsOf(
      ana,
    );
    // Tomó 4 (3 + 1) y terminó 3 (2 + 1); el proyecto llegó al 100 %.
    expect(metrics.fulfillment, 75);
    expect(metrics.completedProjects, 100);
    expect(metrics.onTime, isNull);
    expect(metrics.commitment, 88);
  });
}
