import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:imker/features/projects/domain/models/project.dart';
import 'package:imker/features/projects/ui/viewmodels/project_management_controller.dart';
import 'package:imker/features/projects/ui/widgets/management/project_info_panel.dart';
import 'package:imker/features/projects/ui/widgets/management/task_cabinet_panel.dart';
import 'package:imker/features/projects/ui/widgets/management/task_progress_panel.dart';

/// Vista de gestión de un proyecto propio. Reemplaza el contenido de la
/// pestaña Proyectos mientras hay un proyecto seleccionado.
///
/// Dentro del contenedor hay tres paneles apilados:
///  - información (base, siempre debajo);
///  - gabinete de tareas, que BAJA desde arriba al pulsar "Ver Tareas";
///  - progreso de tarea, que SUBE desde abajo y reemplaza al gabinete.
class ProjectManagementView extends StatelessWidget {
  const ProjectManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProjectManagementController>();
    final cs = Theme.of(context).colorScheme;

    return Obx(() {
      final project = controller.selectedProject.value;
      if (project == null) return const SizedBox.shrink();
      final panel = controller.panel.value;

      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ProjectNameBar(project: project, onBack: controller.close),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(border: Border.all(color: cs.outline, width: 1.5)),
                // El recorte evita que los paneles se vean fuera del contenedor
                // mientras se deslizan.
                child: ClipRect(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ProjectInfoPanel(key: ValueKey(project.id), project: project),
                      _SlidingPanel(
                        visible: panel != ManagementPanel.info,
                        hiddenOffset: const Offset(0, -1), // fuera por arriba
                        child: TaskCabinetPanel(key: ValueKey('cab-${project.id}'), projectId: project.id),
                      ),
                      _SlidingPanel(
                        visible: panel == ManagementPanel.task,
                        hiddenOffset: const Offset(0, 1), // fuera por abajo
                        child: const TaskProgressPanel(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _ProjectNameBar extends StatelessWidget {
  const _ProjectNameBar({required this.project, required this.onBack});

  final Project project;
  final VoidCallback onBack;

  /// "Kirche: Proyecto de renovación..." -> "KIRCHE".
  String get _shortName {
    final title = project.title;
    final cut = title.indexOf(':');
    return (cut == -1 ? title : title.substring(0, cut)).trim().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Row(
      children: [
        IconButton(
          tooltip: 'Mis proyectos',
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(color: cs.surface, border: Border.all(color: cs.outline)),
            child: Text(
              _shortName,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 48),
      ],
    );
  }
}

/// Desliza su hijo entre su posición normal y [hiddenOffset] (en fracciones
/// de su propio tamaño). Oculto, no recibe toques.
class _SlidingPanel extends StatelessWidget {
  const _SlidingPanel({required this.visible, required this.hiddenOffset, required this.child});

  final bool visible;
  final Offset hiddenOffset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedSlide(
        offset: visible ? Offset.zero : hiddenOffset,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubic,
        child: child,
      ),
    );
  }
}
