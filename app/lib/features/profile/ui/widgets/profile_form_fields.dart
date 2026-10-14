import 'package:flutter/material.dart';

import '../../domain/models/user_profile.dart';

/// Estado del formulario de perfil: lo comparten la edición y el onboarding.
class ProfileFormController extends ChangeNotifier {
  ProfileFormController([UserProfile? profile])
    : program = TextEditingController(text: profile?.program ?? ''),
      institution = TextEditingController(text: profile?.institution ?? ''),
      bio = TextEditingController(text: profile?.bio ?? ''),
      _skills = List<String>.from(profile?.skills ?? const []);

  final TextEditingController program;
  final TextEditingController institution;
  final TextEditingController bio;
  final TextEditingController newSkill = TextEditingController();
  final List<String> _skills;

  List<String> get skills => List.unmodifiable(_skills);

  String get programText => program.text.trim();
  String get institutionText => institution.text.trim();
  String get bioText => bio.text.trim();

  /// No hay nada escrito (ni habilidades): guardar sería lo mismo que omitir.
  bool get isEmpty =>
      programText.isEmpty &&
      institutionText.isEmpty &&
      bioText.isEmpty &&
      _skills.isEmpty;

  void addSkill() {
    final value = newSkill.text.trim();
    newSkill.clear();
    if (value.isEmpty) return;
    final exists = _skills.any((s) => s.toLowerCase() == value.toLowerCase());
    if (!exists) _skills.add(value);
    notifyListeners();
  }

  void removeSkill(String skill) {
    _skills.remove(skill);
    notifyListeners();
  }

  @override
  void dispose() {
    program.dispose();
    institution.dispose();
    bio.dispose();
    newSkill.dispose();
    super.dispose();
  }
}

/// Campos editables del perfil: carrera, institución, resumen y habilidades.
class ProfileFormFields extends StatelessWidget {
  const ProfileFormFields({super.key, required this.form});

  final ProfileFormController form;

  InputDecoration _decoration(ColorScheme cs, String hint, {bool dense = false}) =>
      InputDecoration(
        filled: true,
        fillColor: cs.surface,
        hintText: hint,
        isDense: dense,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: cs.outline),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final title = tt.titleMedium?.copyWith(fontWeight: FontWeight.bold);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Carrera', style: title),
        const SizedBox(height: 8),
        TextField(
          controller: form.program,
          textCapitalization: TextCapitalization.sentences,
          decoration: _decoration(cs, 'p. ej. Ingeniería de Sistemas'),
        ),
        const SizedBox(height: 12),
        Text('Institución', style: title),
        const SizedBox(height: 8),
        TextField(
          controller: form.institution,
          textCapitalization: TextCapitalization.words,
          decoration: _decoration(cs, 'p. ej. Universidad del Norte'),
        ),
        const SizedBox(height: 20),
        Text('Sobre ti', style: title),
        const SizedBox(height: 8),
        TextField(
          controller: form.bio,
          maxLines: 5,
          minLines: 3,
          textCapitalization: TextCapitalization.sentences,
          decoration: _decoration(cs, 'Cuéntale al resto de estudiantes sobre ti...'),
        ),
        const SizedBox(height: 20),
        Text('Habilidades', style: title),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: form.newSkill,
                decoration: _decoration(cs, 'p. ej. Pandas, DuckDB...', dense: true),
                onSubmitted: (_) => form.addSkill(),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              style: FilledButton.styleFrom(
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
              onPressed: form.addSkill,
              child: const Text('Aceptar'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListenableBuilder(
          listenable: form,
          builder: (context, _) => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: form.skills
                .map(
                  (s) => Chip(
                    label: Text(s),
                    backgroundColor: cs.secondaryContainer,
                    labelStyle: TextStyle(color: cs.onSecondaryContainer),
                    deleteIcon: Icon(Icons.close, size: 16, color: cs.onSecondaryContainer),
                    onDeleted: () => form.removeSkill(s),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                      side: BorderSide(color: cs.outline),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}
