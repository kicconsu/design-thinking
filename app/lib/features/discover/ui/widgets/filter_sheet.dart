import 'package:flutter/material.dart';

import 'package:imker/features/discover/domain/models/filter_option.dart';
import 'package:imker/features/discover/domain/models/project_filter.dart';
import 'package:imker/features/discover/domain/models/project_page.dart';
import 'package:imker/features/discover/ui/viewmodels/discover_controller.dart';
import 'package:imker/features/discover/ui/widgets/option_picker.dart';

/// Etiqueta con la que se muestra [key], o la clave si ya no se ofrece.
String optionLabel(List<FilterOption> options, String key) {
  for (final option in options) {
    if (option.key == key) return option.label;
  }
  return key;
}

/// Hoja inferior con los filtros. Los cambios se aplican al pulsar el botón
/// principal; cerrar la hoja de otra forma los descarta.
Future<void> showDiscoverFilterSheet(
  BuildContext context,
  DiscoverController controller,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _FilterSheet(controller: controller),
  );
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.controller});

  final DiscoverController controller;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late ProjectFilter _draft = widget.controller.filter.value;
  late FilterOptions _options = FilterOptions(
    careers: widget.controller.careerOptions.toList(),
    skills: widget.controller.skillOptions.toList(),
  );
  late int? _count = widget.controller.total.value;
  bool _failed = false;
  int _request = 0;

  /// Cambia el borrador y recalcula opciones y cantidad de resultados. Una
  /// respuesta que llega después de otro cambio se ignora.
  Future<void> _change(ProjectFilter next) async {
    final request = ++_request;
    setState(() {
      _draft = next;
      _count = null;
      _failed = false;
    });
    try {
      var draft = next;
      var options = await widget.controller.previewOptions(draft);
      if (!mounted || request != _request) return;

      // Quitar «Solo abiertos» o cambiar la carrera puede dejar sin sentido lo
      // elegido; se descarta igual que al recargar el feed.
      if (draft.career != null &&
          !options.careers.any((o) => o.key == draft.career)) {
        draft = draft.withCareer(null);
        options = await widget.controller.previewOptions(draft);
        if (!mounted || request != _request) return;
      }
      if (draft.skill != null &&
          !options.skills.any((o) => o.key == draft.skill)) {
        draft = draft.withSkill(null);
      }
      final count = await widget.controller.previewCount(draft);
      if (!mounted || request != _request) return;
      setState(() {
        _draft = draft;
        _options = options;
        _count = count;
      });
    } catch (_) {
      if (!mounted || request != _request) return;
      setState(() => _failed = true);
    }
  }

  Future<void> _pickCareer() async {
    final choice = await showOptionPicker(
      context,
      title: 'Carrera',
      options: _options.careers,
      selectedKey: _draft.career,
    );
    if (choice != null && choice.key != _draft.career) {
      await _change(_draft.withCareer(choice.key));
    }
  }

  Future<void> _pickSkill() async {
    final choice = await showOptionPicker(
      context,
      title: 'Habilidad',
      options: _options.skills,
      selectedKey: _draft.skill,
    );
    if (choice != null && choice.key != _draft.skill) {
      await _change(_draft.withSkill(choice.key));
    }
  }

  void _apply() {
    Navigator.pop(context);
    widget.controller.applyFilter(_draft);
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final count = _count;
    final noResults = count == 0;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text('Filtros', style: tt.titleLarge)),
                TextButton(
                  onPressed: _draft.isEmpty
                      ? null
                      : () => _change(ProjectFilter.none),
                  child: const Text('Limpiar'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _SelectorField(
              key: const ValueKey('career-field'),
              label: 'Carrera',
              value: _draft.career == null
                  ? 'Todas'
                  : optionLabel(_options.careers, _draft.career!),
              onTap: _pickCareer,
            ),
            const SizedBox(height: 12),
            _SelectorField(
              key: const ValueKey('skill-field'),
              label: 'Habilidad',
              value: _draft.skill == null
                  ? 'Todas'
                  : optionLabel(_options.skills, _draft.skill!),
              onTap: _pickSkill,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Solo abiertos'),
              value: _draft.onlyOpen,
              onChanged: (value) => _change(_draft.withOnlyOpen(value)),
            ),
            if (_failed)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'No se pudo calcular los resultados. Revisa tu conexión.',
                  style: tt.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            FilledButton(
              onPressed: noResults || _failed ? null : _apply,
              style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
              child: Text(
                count == null
                    ? (_failed ? 'Sin conexión' : 'Calculando…')
                    : noResults
                    ? 'Sin resultados'
                    : 'Ver ${_projects(count)}',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// «1 proyecto» / «12 proyectos».
String _projects(int n) => n == 1 ? '1 proyecto' : '$n proyectos';

String projectsLabel(int n) => _projects(n);

class _SelectorField extends StatelessWidget {
  const _SelectorField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$label: $value',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              suffixIcon: const Icon(Icons.arrow_drop_down),
            ),
            child: Text(value, maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
        ),
      ),
    );
  }
}
