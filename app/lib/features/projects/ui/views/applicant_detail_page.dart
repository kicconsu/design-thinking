import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../domain/models/project.dart';
import '../../domain/models/applicant.dart';
import '../viewmodels/user_projects_controller.dart';
import 'request_decision_result_page.dart';

/// Pantallas "Requests-Profile" / "Requests-Profile-Projects" del flujo de
/// Figma: detalle de una solicitud, con pestañas de perfil general y
/// proyectos, y las acciones de aceptar/rechazar.
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
  int _tab = 0; // 0: Perfil General, 1: Proyectos

  void _decide(bool accepted) {
    Get.find<UserProjectsController>().decideOnApplicant(
      widget.applicant,
      accepted: accepted,
    );
    Get.to(() => RequestDecisionResultPage(accepted: accepted));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final applicant = widget.applicant;

    return Scaffold(
      backgroundColor: cs.primaryContainer,
      appBar: AppBar(
        backgroundColor: cs.tertiaryContainer,
        title: const Text('Imker'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Solicitud de colaboración',
                          style: tt.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(applicant.appliedAgo, style: tt.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: cs.tertiaryContainer,
                        child: Icon(
                          Icons.person,
                          color: cs.onTertiaryContainer,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              applicant.name,
                              style: tt.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(applicant.academicInfo, style: tt.bodySmall),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: cs.secondaryContainer,
                              ),
                              child: Text(
                                'Rol solicitado: ${applicant.requestedRole}',
                                style: TextStyle(
                                  color: cs.onSecondaryContainer,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 16,
                        color: cs.onPrimaryContainer,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${applicant.commonProjects} colaborador${applicant.commonProjects == 1 ? '' : 'es'} en común contigo',
                        style: tt.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SegmentedTabs(
                    labels: const [
                      'Perfil General',
                      'Proyectos',
                    ],
                    counts: [null, applicant.experience.length],
                    selectedIndex: _tab,
                    onSelected: (i) => setState(() => _tab = i),
                  ),
                  const SizedBox(height: 16),
                  if (_tab == 0)
                    _GeneralProfileTab(applicant: applicant, cs: cs, tt: tt)
                  else
                    _ProjectsTab(applicant: applicant, cs: cs, tt: tt),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _decide(false),
                      style: OutlinedButton.styleFrom(
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Rechazar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: () => _decide(true),
                      style: FilledButton.styleFrom(
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Aceptar solicitud'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentedTabs extends StatelessWidget {
  final List<String> labels;
  final List<int?> counts;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _SegmentedTabs({
    required this.labels,
    required this.counts,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: List.generate(labels.length, (i) {
        final selected = i == selectedIndex;
        final label = counts[i] == null
            ? labels[i]
            : '${labels[i]} (${counts[i]})';
        return Expanded(
          child: GestureDetector(
            onTap: () => onSelected(i),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 10),
              margin: EdgeInsets.only(right: i == labels.length - 1 ? 0 : 8),
              decoration: BoxDecoration(
                color: selected ? cs.primary : cs.surface,
                border: Border.all(color: cs.outline),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? cs.onPrimary : cs.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _GeneralProfileTab extends StatelessWidget {
  final Applicant applicant;
  final ColorScheme cs;
  final TextTheme tt;

  const _GeneralProfileTab({
    required this.applicant,
    required this.cs,
    required this.tt,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Indicadores de confianza',
          style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                'Índice general de compromiso',
                style: tt.bodyMedium,
              ),
            ),
            Text(
              '${applicant.commitmentScore}%',
              style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          child: LinearProgressIndicator(
            value: applicant.commitmentScore / 100,
            minHeight: 8,
            backgroundColor: cs.surfaceContainerHighest,
            color: cs.primary,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ScoreGauge(
              label: 'Entrega a tiempo',
              value: applicant.onTimeScore,
              cs: cs,
              tt: tt,
            ),
            _ScoreGauge(
              label: 'Tasa de respuesta',
              value: applicant.responseRateScore,
              cs: cs,
              tt: tt,
            ),
            _ScoreGauge(
              label: 'Proyectos completados',
              value: applicant.completedProjectsScore,
              cs: cs,
              tt: tt,
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Sobre esta persona',
          style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.surface,
            border: Border.all(color: cs.outline),
          ),
          child: Text(applicant.bio, style: tt.bodyMedium),
        ),
        const SizedBox(height: 20),
        Text(
          'Habilidades',
          style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: applicant.skills
              .map(
                (s) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: cs.secondaryContainer,
                    border: Border.all(color: cs.outline),
                  ),
                  child: Text(
                    s,
                    style: TextStyle(color: cs.onSecondaryContainer),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _ScoreGauge extends StatelessWidget {
  final String label;
  final int value;
  final ColorScheme cs;
  final TextTheme tt;

  const _ScoreGauge({
    required this.label,
    required this.value,
    required this.cs,
    required this.tt,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      child: Column(
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: value / 100,
                  strokeWidth: 6,
                  backgroundColor: cs.surfaceContainerHighest,
                  color: cs.primary,
                ),
                Text(
                  '$value%',
                  style: tt.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: tt.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _ProjectsTab extends StatelessWidget {
  final Applicant applicant;
  final ColorScheme cs;
  final TextTheme tt;

  const _ProjectsTab({
    required this.applicant,
    required this.cs,
    required this.tt,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Historial de participación en proyectos académicos y de investigación.',
          style: tt.bodySmall,
        ),
        const SizedBox(height: 16),
        ...applicant.experience.map(
          (exp) => Container(
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
                        exp.title,
                        style: tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      exp.status,
                      style: tt.labelMedium?.copyWith(
                        color: exp.status == 'Completado'
                            ? Colors.green.shade700
                            : cs.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(exp.description, style: tt.bodyMedium),
                const SizedBox(height: 6),
                Text(
                  'Evaluación de pares: ${exp.peerEvaluation.toStringAsFixed(1)}/5.0',
                  style: tt.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
