import 'package:flutter/widgets.dart';

/// Claves de los controles que las pruebas (y la accesibilidad) necesitan
/// encontrar sin depender del texto que se ve. Convención: `zona.control`.
///
/// Las de elementos que se repiten (una por proyecto o por tarea) son
/// funciones del id.
abstract final class AppKeys {
  // Inicio de sesión
  static const loginEmail = Key('auth.login.email');
  static const loginPassword = Key('auth.login.password');
  static const loginSubmit = Key('auth.login.submit');

  /// Pestañas de la barra inferior: `nav.discover`, `nav.projects`, `nav.profile`.
  static Key navTab(String name) => ValueKey('nav.$name');

  // Descubrir y postulación
  static Key readMore(String projectId) =>
      ValueKey('discover.readMore.$projectId');
  static const applyToProject = Key('project.apply');
  static const confirmApplication = Key('application.confirm');
  static const operationDoneButton = Key('operation.done.button');

  // Solicitudes
  static const requestAccept = Key('request.accept');
  static const requestReject = Key('request.reject');
  static const requestMore = Key('request.more');

  // Proyecto y tareas
  static const viewTasks = Key('project.viewTasks');
  static const createTask = Key('task.board.create');
  static const taskBoardTabs = 'task.board.tab';
  static Key taskBoardTab(int index) => ValueKey('$taskBoardTabs.$index');
  static const newTaskSubmit = Key('task.new.submit');
  static const checklistAdd = Key('checklist.add');
  static Key reserveTask(String taskId) => ValueKey('task.reserve.$taskId');
  static const saveProgress = Key('task.progress.save');
}
