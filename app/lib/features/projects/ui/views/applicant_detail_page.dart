import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../domain/models/applicant.dart';
import '../../domain/models/project.dart';
import '../pages/person_profile_page.dart';
import '../viewmodels/collaboration_requests_controller.dart';
import 'request_decision_result_page.dart';

/// Detalle de una solicitud de colaboración: el perfil de quien la hizo (la
/// misma ficha que se abre desde cualquier otro sitio) con los datos de la
/// solicitud encima y las acciones de aceptar o rechazar al pie.
class ApplicantDetailPage extends StatefulWidget {
  final Project project;
  final Applicant applicant;

  const ApplicantDetailPage({
    super.key,
    required this.project,
    required this.applicant,
  });

  @override
  State<ApplicantDetailPage> createState() => _ApplicantDetailPageState();
}

class _ApplicantDetailPageState extends State<ApplicantDetailPage> {
  bool _isSubmitting = false;

  Future<void> _decide(bool accepted) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      final error = await Get.find<CollaborationRequestsController>().decide(
        widget.applicant,
        project: widget.project,
        accepted: accepted,
      );
      if (error == null) {
        Get.to(() => RequestDecisionResultPage(accepted: accepted));
      } else {
        Get.snackbar('Error', error, snackPosition: SnackPosition.BOTTOM);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final applicant = widget.applicant;

    return PersonProfilePage(
      userId: applicant.userId,
      name: applicant.name,
      projectId: widget.project.id,
      showTrust: true,
      header: _RequestHeader(
        projectTitle: widget.project.title,
        appliedAgo: applicant.appliedAgo,
      ),
      bottomBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSubmitting ? null : () => _decide(false),
                  style: OutlinedButton.styleFrom(
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isSubmitting
                      ? const _Spinner()
                      : const Text('Rechazar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : () => _decide(true),
                  style: FilledButton.styleFrom(
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isSubmitting
                      ? const _Spinner()
                      : const Text('Aceptar solicitud'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 20,
    height: 20,
    child: CircularProgressIndicator(strokeWidth: 2),
  );
}

/// Qué pide esta persona y cuándo lo pidió.
class _RequestHeader extends StatelessWidget {
  const _RequestHeader({required this.projectTitle, required this.appliedAgo});

  final String projectTitle;
  final String appliedAgo;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.tertiaryContainer,
        border: Border.all(color: cs.onTertiaryContainer),
      ),
      child: Row(
        children: [
          Icon(Icons.how_to_reg_outlined, color: cs.onTertiaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Solicitud de colaboración',
                  style: tt.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.onTertiaryContainer,
                  ),
                ),
                Text(
                  'Quiere colaborar en «$projectTitle» · $appliedAgo',
                  style: tt.bodySmall?.copyWith(color: cs.onTertiaryContainer),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
