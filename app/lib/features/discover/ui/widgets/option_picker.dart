import 'package:flutter/material.dart';

import 'package:imker/core/utils/normalize_label.dart';
import 'package:imker/features/discover/domain/models/filter_option.dart';
import 'package:imker/features/discover/ui/widgets/filter_style.dart';

/// Opción elegida en el selector. Envuelve la clave para distinguir «Todas»
/// (`key == null`) de cerrar el selector sin elegir (resultado nulo).
class OptionChoice {
  const OptionChoice(this.key);

  final String? key;
}

/// Las listas con más opciones que esto ganan un buscador.
const optionPickerSearchThreshold = 12;

/// Lista de [options] con «Todas» al principio. Devuelve la elección, o nulo si
/// se cierra sin elegir.
Future<OptionChoice?> showOptionPicker(
  BuildContext context, {
  required String title,
  required List<FilterOption> options,
  required String? selectedKey,
}) {
  return showModalBottomSheet<OptionChoice>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) =>
        _OptionPicker(title: title, options: options, selectedKey: selectedKey),
  );
}

class _OptionPicker extends StatefulWidget {
  const _OptionPicker({
    required this.title,
    required this.options,
    required this.selectedKey,
  });

  final String title;
  final List<FilterOption> options;
  final String? selectedKey;

  @override
  State<_OptionPicker> createState() => _OptionPickerState();
}

class _OptionPickerState extends State<_OptionPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final needle = normalizeLabel(_query);
    final shown = widget.options
        .where((o) => needle.isEmpty || o.key.contains(needle))
        .toList();
    final searchable = widget.options.length > optionPickerSearchThreshold;

    final media = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: media.viewInsets.bottom > 0
            ? media.viewInsets.bottom
            : media.viewPadding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(widget.title, style: tt.titleMedium),
          ),
          if (searchable)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  border: squareInputBorder,
                  prefixIcon: Icon(Icons.search),
                  labelText: 'Buscar',
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                if (needle.isEmpty)
                  _tile(
                    label: 'Todas',
                    selected: widget.selectedKey == null,
                    onTap: () =>
                        Navigator.pop(context, const OptionChoice(null)),
                  ),
                for (final option in shown)
                  _tile(
                    label: option.label,
                    count: option.count,
                    selected: option.key == widget.selectedKey,
                    onTap: () =>
                        Navigator.pop(context, OptionChoice(option.key)),
                  ),
                if (shown.isEmpty && needle.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Sin resultados para esa búsqueda.'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    int? count,
  }) {
    return ListTile(
      title: Text(label, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: selected
          ? const Icon(Icons.check)
          : (count == null ? null : Text('$count')),
      selected: selected,
      onTap: onTap,
    );
  }
}
