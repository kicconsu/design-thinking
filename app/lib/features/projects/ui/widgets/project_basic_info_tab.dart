import 'package:flutter/material.dart';

import 'package:imker/core/widgets/checklist_editor.dart';

/// Pestaña "Info. básica" de la información del proyecto: nombre,
/// descripción, carreras relacionadas y conocimientos requeridos.
///
/// Es de solo lectura si [canEdit] es `false`. Los borradores los guarda quien
/// la usa (ver `ProjectBasicInfoController`), no este widget.
class ProjectBasicInfoTab extends StatelessWidget {
  const ProjectBasicInfoTab({
    super.key,
    required this.title,
    required this.description,
    required this.jobs,
    required this.skills,
    required this.onJobsChanged,
    required this.onSkillsChanged,
    required this.canEdit,
    required this.isSaving,
    required this.onSave,
  });

  final TextEditingController title;
  final TextEditingController description;
  final List<ChecklistEntry> jobs;
  final List<ChecklistEntry> skills;
  final ValueChanged<List<ChecklistEntry>> onJobsChanged;
  final ValueChanged<List<ChecklistEntry>> onSkillsChanged;
  final bool canEdit;
  final bool isSaving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    InputDecoration box() => InputDecoration(
      filled: true,
      fillColor: cs.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: cs.outline),
      ),
    );

    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: Text(
        text,
        style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!canEdit) ...[
          Text(
            'Solo el creador del proyecto puede editar esta información.',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
        ],
        Text(
          'Nombre del proyecto',
          style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: title,
          readOnly: !canEdit,
          textAlign: TextAlign.center,
          style: tt.headlineSmall,
          decoration: box(),
        ),
        label('Descripción'),
        TextField(
          controller: description,
          readOnly: !canEdit,
          minLines: 3,
          maxLines: 6,
          decoration: box(),
        ),
        label('Carreras relacionadas'),
        ChecklistEditor(
          initial: jobs,
          hint: 'Escribe una carrera relacionada',
          enabled: canEdit,
          onChanged: onJobsChanged,
        ),
        label('Conocimientos requeridos'),
        ChecklistEditor(
          initial: skills,
          hint: 'Añade una habilidad',
          enabled: canEdit,
          onChanged: onSkillsChanged,
        ),
        if (canEdit) ...[
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
            ),
            onPressed: isSaving ? null : onSave,
            child: isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Guardar Cambios'),
          ),
        ],
      ],
    );
  }
}
