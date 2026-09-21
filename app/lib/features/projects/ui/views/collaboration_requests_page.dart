import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../domain/models/project.dart';
import '../../domain/models/applicant.dart';
import '../viewmodels/user_projects_controller.dart';
import 'applicant_detail_page.dart';

/// Pantalla "Requests" del flujo de Figma: lista las solicitudes de
/// colaboración recibidas para un proyecto co-creado.
class CollaborationRequestsPage extends StatelessWidget {
  final Project project;

  const CollaborationRequestsPage({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UserProjectsController>();
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.primaryContainer,
      appBar: AppBar(
        backgroundColor: cs.tertiaryContainer,
        title: const Text('Imker'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Obx(() {
          final applicants = controller.applicantsFor(project.id);
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Solicitudes de colaboración',
                style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                project.title,
                style: tt.titleMedium,
              ),
              Text(
                'Revisa cada perfil antes de decidir',
                style: tt.bodySmall,
              ),
              const SizedBox(height: 8),
              Divider(color: cs.outline),
              const SizedBox(height: 8),
              if (applicants.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No hay solicitudes pendientes por revisar.',
                    style: tt.bodyMedium,
                  ),
                )
              else
                ...applicants.map(
                  (applicant) => _ApplicantTile(
                    applicant: applicant,
                    onTap: () {
                      Get.to(
                        () => ApplicantDetailPage(
                          project: project,
                          applicant: applicant,
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _ApplicantTile extends StatelessWidget {
  final Applicant applicant;
  final VoidCallback onTap;

  const _ApplicantTile({required this.applicant, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border.all(color: cs.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    applicant.name,
                    style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(applicant.appliedAgo, style: tt.bodySmall),
              ],
            ),
            Text(applicant.academicInfo, style: tt.bodySmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(color: cs.secondaryContainer),
                  child: Text(
                    applicant.requestedRole,
                    style: TextStyle(
                      color: cs.onSecondaryContainer,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${applicant.commonProjects} en común',
                  style: tt.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              child: LinearProgressIndicator(
                value: applicant.commitmentScore / 100,
                minHeight: 8,
                backgroundColor: cs.surfaceContainerHighest,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Compromiso ${applicant.commitmentScore}%',
                style: tt.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
