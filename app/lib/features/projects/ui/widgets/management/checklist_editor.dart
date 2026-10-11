import 'package:flutter/material.dart';

/// Un ítem de [ChecklistEditor]: texto más si está marcado.
class ChecklistEntry {
  const ChecklistEntry(this.label, {this.checked = true});

  final String label;
  final bool checked;

  ChecklistEntry copyWith({bool? checked}) =>
      ChecklistEntry(label, checked: checked ?? this.checked);
}

/// Campo para añadir ítems más la lista de ítems con casilla de verificación.
///
/// Mantiene su propia lista y avisa de cada cambio con [onChanged]; el padre
/// decide qué hacer con ella al guardar.
class ChecklistEditor extends StatefulWidget {
  const ChecklistEditor({
    super.key,
    required this.initial,
    required this.hint,
    required this.onChanged,
    this.addedChecked = true,
  });

  final List<ChecklistEntry> initial;
  final String hint;
  final ValueChanged<List<ChecklistEntry>> onChanged;

  /// Si los ítems recién añadidos nacen marcados.
  final bool addedChecked;

  @override
  State<ChecklistEditor> createState() => _ChecklistEditorState();
}

class _ChecklistEditorState extends State<ChecklistEditor> {
  final _input = TextEditingController();
  late List<ChecklistEntry> _items = List.of(widget.initial);

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _emit() => widget.onChanged(List.unmodifiable(_items));

  void _add() {
    final value = _input.text.trim();
    if (value.isEmpty) return;
    final exists = _items.any((e) => e.label.toLowerCase() == value.toLowerCase());
    if (!exists) {
      setState(() => _items = [..._items, ChecklistEntry(value, checked: widget.addedChecked)]);
      _emit();
    }
    _input.clear();
  }

  void _toggle(int index, bool checked) {
    setState(() => _items[index] = _items[index].copyWith(checked: checked));
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _input,
                onSubmitted: (_) => _add(),
                decoration: InputDecoration(
                  hintText: widget.hint,
                  isDense: true,
                  filled: true,
                  fillColor: cs.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(color: cs.outline),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              style: FilledButton.styleFrom(
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
              onPressed: _add,
              child: const Text('Añadir'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < _items.length; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              color: cs.secondaryContainer,
              border: Border.all(color: cs.outline),
            ),
            child: CheckboxListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              controlAffinity: ListTileControlAffinity.trailing,
              value: _items[i].checked,
              onChanged: (v) => _toggle(i, v ?? false),
              title: Text(
                _items[i].label,
                style: TextStyle(color: cs.onSecondaryContainer),
              ),
            ),
          ),
      ],
    );
  }
}
