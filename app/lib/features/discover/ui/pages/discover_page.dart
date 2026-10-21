import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../viewmodels/discover_controller.dart';
import '../widgets/discover_filter_bar.dart';
import '../widgets/filter_sheet.dart';
import '../widgets/project_card.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  /// Cuántas tarjetas antes del final se pide la página siguiente.
  static const _prefetchDistance = 3;

  final controller = Get.find<DiscoverController>();

  // Estable: si se creara en `build`, cada cambio de la lista reiniciaría la posición.
  final _pageController = PageController(viewportFraction: 0.92);
  final _workers = <Worker>[];

  @override
  void initState() {
    super.initState();
    _workers.add(
      ever(controller.resetCount, (_) {
        if (_pageController.hasClients) _pageController.jumpToPage(0);
      }),
    );
    _workers.add(
      ever(controller.notice, (message) {
        if (message == null || !mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
        controller.clearNotice();
      }),
    );
  }

  @override
  void dispose() {
    for (final worker in _workers) {
      worker.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  /// La barra solo aparece cuando hay algo que filtrar: no durante la primera
  /// carga, ni con error o feed vacío sin filtros.
  bool get _showBar {
    final noProjects = controller.projects.isEmpty;
    final hasFilter = !controller.filter.value.isEmpty;
    if (noProjects && !hasFilter) return false;
    if (noProjects && controller.error.value != null) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Obx(
          () => _showBar
              ? DiscoverFilterBar(controller: controller)
              : const SizedBox.shrink(),
        ),
        Expanded(child: _feed(context)),
      ],
    );
  }

  String _noMatchText() {
    final filter = controller.filter.value;
    final parts = [
      if (filter.career != null)
        optionLabel(controller.careerOptions, filter.career!),
      if (filter.skill != null)
        optionLabel(controller.skillOptions, filter.skill!),
      if (filter.onlyOpen) 'Solo abiertos',
    ];
    return 'Ningún proyecto coincide con ${parts.join(' + ')}.';
  }

  Widget _feed(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && controller.projects.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.error.value != null && controller.projects.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                const SizedBox(height: 12),
                Text(
                  controller.error.value!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: controller.loadProjects,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        );
      }

      if (controller.projects.isEmpty && !controller.filter.value.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.filter_alt_off, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(_noMatchText(), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: controller.clearFilters,
                child: const Text('Limpiar filtros'),
              ),
            ],
          ),
        );
      }

      if (controller.projects.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.folder_open, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              const Text('No hay proyectos disponibles por el momento.'),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: controller.loadProjects,
                icon: const Icon(Icons.refresh),
                label: const Text('Recargar'),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: controller.loadProjects,
        child: PageView.builder(
          scrollDirection: Axis.vertical,
          controller: _pageController,
          padEnds: false,
          itemCount: controller.projects.length,
          onPageChanged: (index) {
            if (index >= controller.projects.length - _prefetchDistance) {
              controller.loadMore();
            }
          },
          itemBuilder: (context, index) {
            final project = controller.projects[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: ProjectCard(project: project),
            );
          },
        ),
      );
    });
  }
}
