import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:imker/core/widgets/score_gauge.dart';
import 'package:imker/core/widgets/segmented_tab_switch.dart';
import 'package:imker/features/projects/domain/models/project.dart';
import 'package:imker/features/projects/ui/viewmodels/project_management_controller.dart';
import 'checklist_editor.dart';
import 'management_panel_frame.dart';

/// Panel "Información de Proyecto": progreso, información básica y miembros.
class ProjectInfoPanel extends StatefulWidget {
  const ProjectInfoPanel({super.key, required this.project});

  final Project project;

  @override
  State<ProjectInfoPanel> createState() => _ProjectInfoPanelState();
}

class _ProjectInfoPanelState extends State<ProjectInfoPanel> {
  int _tab = 0; // 0: Progreso, 1: Info. básica, 2: Miembros

  final _title = TextEditingController();
  final _description = TextEditingController();
  late List<ChecklistEntry> _jobs;
  late List<ChecklistEntry> _skills;

  @override
  void initState() {
    super.initState();
    _title.text = widget.project.title;
    _description.text = widget.project.description;
    _jobs = [for (final j in widget.project.jobs) ChecklistEntry(j)];
    _skills = [for (final s in widget.project.skills) ChecklistEntry(s)];
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      Get.snackbar('Falta el nombre', 'El proyecto necesita un nombre.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    // Las casillas desmarcadas se descartan al guardar.
    final error = await Get.find<ProjectManagementController>().saveProjectInfo(
      title: title,
      description: _description.text.trim(),
      jobs: [for (final e in _jobs) if (e.checked) e.label],
      skills: [for (final e in _skills) if (e.checked) e.label],
    );
    Get.snackbar(
      error == null ? 'Listo' : 'Error',
      error ?? 'Los cambios del proyecto se guardaron.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProjectManagementController>();

    return ManagementPanelFrame(
      title: 'Información de Proyecto',
      tabs: SegmentedTabSwitch(
        tabs: const ['Progreso', 'Info. básica', 'Miembros'],
        selectedIndex: _tab,
        onTabSelected: (i) => setState(() => _tab = i),
      ),
      body: switch (_tab) {
        0 => _ProgressTab(projectId: widget.project.id),
        1 => _BasicInfoTab(
          title: _title,
          description: _description,
          jobs: _jobs,
          skills: _skills,
          onJobsChanged: (v) => _jobs = v,
          onSkillsChanged: (v) => _skills = v,
        ),
        _ => _MembersTab(members: widget.project.members),
      },
      bottom: switch (_tab) {
        0 => PanelButton(label: 'Ver Tareas', onPressed: controller.showCabinet),
        1 => Obx(
          () => PanelButton(
            label: 'Guardar Cambios',
            busy: controller.isSavingProject.value,
            onPressed: _save,
          ),
        ),
        _ => null,
      },
    );
  }
}

class _ProgressTab extends StatelessWidget {
  const _ProgressTab({required this.projectId});

  final String projectId;

  // Todavía no hay fechas límite en las tareas, así que "Entregas a tiempo"
  // es un valor fijo, igual que los indicadores de confianza del perfil.
  static const _onTimePlaceholder = 83;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProjectManagementController>();
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Obx(() {
      final completion = controller.completionPercent(projectId);
      final inProgress = controller.inProgressPercent(projectId);

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: cs.surface, border: Border.all(color: cs.outline)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Progreso general', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: Text('Porcentaje de Finalización', style: tt.bodyMedium)),
                Text('$completion%', style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: completion / 100,
              minHeight: 8,
              backgroundColor: cs.surfaceContainerHighest,
              color: cs.primary,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ScoreGauge(label: 'Tareas en Progreso', value: inProgress),
                const ScoreGauge(label: 'Entregas a Tiempo', value: _onTimePlaceholder),
              ],
            ),
          ],
        ),
      );
    });
  }
}

class _BasicInfoTab extends StatelessWidget {
  const _BasicInfoTab({
    required this.title,
    required this.description,
    required this.jobs,
    required this.skills,
    required this.onJobsChanged,
    required this.onSkillsChanged,
  });

  final TextEditingController title;
  final TextEditingController description;
  final List<ChecklistEntry> jobs;
  final List<ChecklistEntry> skills;
  final ValueChanged<List<ChecklistEntry>> onJobsChanged;
  final ValueChanged<List<ChecklistEntry>> onSkillsChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    InputDecoration box([String? hint]) => InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: cs.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: cs.outline),
      ),
    );

    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: Text(text, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Nombre del proyecto', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextField(controller: title, decoration: box()),
        label('Descripción'),
        TextField(controller: description, minLines: 3, maxLines: 6, decoration: box()),
        label('Carreras relacionadas'),
        ChecklistEditor(
          initial: jobs,
          hint: 'Escribe una carrera relacionada',
          onChanged: onJobsChanged,
        ),
        label('Conocimientos requeridos'),
        ChecklistEditor(
          initial: skills,
          hint: 'Añade una habilidad',
          onChanged: onSkillsChanged,
        ),
      ],
    );
  }
}

class _MembersTab extends StatelessWidget {
  const _MembersTab({required this.members});

  final List<String> members;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (members.isEmpty) {
      return Text('Este proyecto todavía no tiene miembros.', style: tt.bodyMedium);
    }

    return Column(
      children: [
        for (final name in members)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: cs.surface, border: Border.all(color: cs.outline)),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: cs.tertiaryContainer,
                  child: Icon(Icons.person, size: 20, color: cs.onTertiaryContainer),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(name, style: tt.bodyLarge)),
              ],
            ),
          ),
      ],
    );
  }
}
