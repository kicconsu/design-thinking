import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:imker/features/discover/ui/viewmodels/discover_controller.dart';
import 'package:imker/features/discover/ui/widgets/filter_sheet.dart';
import 'package:imker/features/discover/ui/widgets/filter_style.dart';

/// Barra de una sola línea sobre el feed: el botón «Filtros» y, a su lado, una
/// etiqueta por filtro activo que se quita con la ✕. Sin filtros activos solo
/// queda el botón, para quitarle al feed la menor altura posible.
class DiscoverFilterBar extends StatelessWidget {
  const DiscoverFilterBar({super.key, required this.controller});

  final DiscoverController controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Obx(() {
      final filter = controller.filter.value;
      final tags = <Widget>[
        if (filter.career != null)
          _FilterTag(
            label: optionLabel(controller.careerOptions, filter.career!),
            onRemoved: () => controller.setCareer(null),
          ),
        if (filter.skill != null)
          _FilterTag(
            label: optionLabel(controller.skillOptions, filter.skill!),
            onRemoved: () => controller.setSkill(null),
          ),
        if (filter.onlyOpen)
          _FilterTag(
            label: 'Solo abiertos',
            onRemoved: () => controller.setOnlyOpen(false),
          ),
      ];

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: Row(
              children: [
                FilledButton.icon(
                  onPressed: () => showDiscoverFilterSheet(context, controller),
                  style: squareButtonStyle(cs).copyWith(
                    minimumSize: const WidgetStatePropertyAll(Size(48, 44)),
                  ),
                  icon: const Icon(Icons.tune),
                  label: Text(
                    filter.isEmpty
                        ? 'Filtros'
                        : 'Filtros (${filter.activeCount})',
                    style: Theme.of(context).textTheme.labelLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                if (tags.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(children: tags),
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(
            height: 3,
            child: controller.isLoading.value
                ? const LinearProgressIndicator()
                : null,
          ),
        ],
      );
    });
  }
}

/// Etiqueta rectangular con borde, como el resto de la interfaz.
class _FilterTag extends StatelessWidget {
  const _FilterTag({required this.label, required this.onRemoved});

  final String label;
  final VoidCallback onRemoved;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Semantics(
        button: true,
        label: 'Quitar filtro $label',
        excludeSemantics: true,
        child: Tooltip(
          message: 'Quitar filtro $label',
          child: InkWell(
            onTap: onRemoved,
            child: Container(
              constraints: const BoxConstraints(minHeight: 44, maxWidth: 180),
              padding: const EdgeInsets.only(left: 10, right: 6),
              decoration: BoxDecoration(
                color: cs.tertiaryContainer,
                border: Border.all(color: cs.onTertiaryContainer),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge
                          ?.copyWith(color: cs.onTertiaryContainer),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.close, size: 18, color: cs.onTertiaryContainer),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
