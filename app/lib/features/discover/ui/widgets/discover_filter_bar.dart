import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:imker/features/discover/ui/viewmodels/discover_controller.dart';
import 'package:imker/features/discover/ui/widgets/filter_sheet.dart';

/// Barra fina sobre el feed: botón «Filtros», un chip por filtro activo que se
/// quita con la ✕ (en una segunda línea que solo existe con filtros activos) y,
/// con filtros activos, cuántos proyectos hay.
class DiscoverFilterBar extends StatelessWidget {
  const DiscoverFilterBar({super.key, required this.controller});

  final DiscoverController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final filter = controller.filter.value;
      final active = filter.activeCount;
      final chips = <Widget>[
        if (filter.career != null)
          _FilterChip(
            label: optionLabel(controller.careerOptions, filter.career!),
            onRemoved: () => controller.setCareer(null),
          ),
        if (filter.skill != null)
          _FilterChip(
            label: optionLabel(controller.skillOptions, filter.skill!),
            onRemoved: () => controller.setSkill(null),
          ),
        if (filter.onlyOpen)
          _FilterChip(
            label: 'Solo abiertos',
            onRemoved: () => controller.setOnlyOpen(false),
          ),
      ];

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => showDiscoverFilterSheet(context, controller),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(48, 48),
                  ),
                  icon: const Icon(Icons.tune),
                  label: Text(active == 0 ? 'Filtros' : 'Filtros ($active)'),
                ),
                if (active > 0) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      projectsLabel(controller.total.value),
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (chips.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: chips),
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.onRemoved});

  final String label;
  final VoidCallback onRemoved;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Center(
        child: InputChip(
          label: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(label, overflow: TextOverflow.ellipsis),
          ),
          tooltip: label,
          onDeleted: onRemoved,
          deleteButtonTooltipMessage: 'Quitar filtro $label',
        ),
      ),
    );
  }
}
