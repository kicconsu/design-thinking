import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:imker/core/widgets/segmented_tab_switch.dart';
import 'package:imker/core/widgets/trust_indicators.dart';
import 'package:imker/features/auth/ui/viewmodels/authentication_controller.dart';
import 'package:imker/features/projects/domain/models/project.dart';
import 'package:imker/features/projects/ui/viewmodels/user_projects_controller.dart';
import 'package:imker/features/projects/ui/widgets/project_tile.dart';
import 'package:imker/features/profile/domain/models/user_profile.dart';
import 'package:imker/routes/app_routes.dart';
import '../viewmodels/profile_controller.dart';
import 'edit_profile_page.dart';

/// Pantalla "Profiles" del flujo de Figma: perfil del propio usuario, con
/// pestañas de perfil general y proyectos, y acceso a editar el perfil.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthenticationController auth = Get.find<AuthenticationController>();
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return SafeArea(
      child: Obx(() {
        final isLogged = auth.isLogged;
        final isGuest = auth.isAnonymous;

        if (!isLogged) {
          return _MessageState(
            icon: Icons.account_circle_outlined,
            message: 'Inicia sesión para ver tu perfil',
            buttonLabel: 'Iniciar sesión',
            onPressed: () => Get.offAllNamed(AppRoutes.login),
          );
        }

        if (isGuest) {
          return _GuestBanner(cs: cs, tt: tt);
        }

        return const _ProfileContent();
      }),
    );
  }
}

class _ProfileContent extends StatefulWidget {
  const _ProfileContent();

  @override
  State<_ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends State<_ProfileContent> {
  int _tab = 0; // 0: Perfil General, 1: Proyectos

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthenticationController>();
    final profileController = Get.find<ProfileController>();
    final projectsController = Get.find<UserProjectsController>();
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Obx(() {
      if (profileController.isLoading.value && profileController.profile == null) {
        return const Center(child: CircularProgressIndicator());
      }

      if (profileController.error.value != null && profileController.profile == null) {
        return _MessageState(
          icon: Icons.cloud_off,
          message: profileController.error.value!,
          buttonLabel: 'Reintentar',
          onPressed: profileController.loadProfile,
        );
      }

      final profile = profileController.profile;
      final myProjects = <Project>[
        ...projectsController.coCreatedProjects,
        ...projectsController.activeProjects,
      ];

      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Text('Mi Perfil', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 8),
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: cs.tertiaryContainer,
                child: Icon(Icons.person, color: cs.onTertiaryContainer, size: 30),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      auth.loggedName,
                      style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (profile != null && profile.academicInfo.isNotEmpty)
                      Text(profile.academicInfo, style: tt.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SegmentedTabSwitch(
            tabs: ['Perfil General', 'Proyectos (${myProjects.length})'],
            selectedIndex: _tab,
            onTabSelected: (i) => setState(() => _tab = i),
          ),
          const SizedBox(height: 16),
          if (_tab == 0)
            _GeneralTab(profile: profile, cs: cs, tt: tt)
          else
            _ProjectsTab(projects: myProjects, tt: tt),
          const SizedBox(height: 24),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            onPressed: () => Get.to(() => const EditProfilePage()),
            child: const Text('Editar Perfil'),
          ),
        ],
      );
    });
  }
}

class _GeneralTab extends StatelessWidget {
  final UserProfile? profile;
  final ColorScheme cs;
  final TextTheme tt;

  const _GeneralTab({required this.profile, required this.cs, required this.tt});

  @override
  Widget build(BuildContext context) {
    final profile = this.profile;
    if (profile == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TrustIndicators(
          commitmentScore: profile.commitmentScore,
          onTimeScore: profile.onTimeScore,
          responseRateScore: profile.responseRateScore,
          completedProjectsScore: profile.completedProjectsScore,
        ),
        const SizedBox(height: 24),
        Text('Sobre ti', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: cs.surface, border: Border.all(color: cs.outline)),
          child: Text(
            profile.bio.isNotEmpty ? profile.bio : 'Aún no has escrito nada sobre ti.',
            style: tt.bodyMedium,
          ),
        ),
        const SizedBox(height: 20),
        Text('Habilidades', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (profile.skills.isEmpty)
          Text('Aún no agregas habilidades.', style: tt.bodyMedium)
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: profile.skills
                .map(
                  (s) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: cs.secondaryContainer,
                      border: Border.all(color: cs.outline),
                    ),
                    child: Text(s, style: TextStyle(color: cs.onSecondaryContainer)),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}

class _ProjectsTab extends StatelessWidget {
  final List<Project> projects;
  final TextTheme tt;

  const _ProjectsTab({required this.projects, required this.tt});

  @override
  Widget build(BuildContext context) {
    if (projects.isEmpty) {
      return Text('Todavía no participas en ningún proyecto.', style: tt.bodyMedium);
    }
    return Column(
      children: projects
          .map(
            (p) => ProjectTile(
              project: p,
              onTap: () => Get.toNamed(AppRoutes.projectDetail, arguments: p),
            ),
          )
          .toList(),
    );
  }
}

class _MessageState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String buttonLabel;
  final VoidCallback onPressed;

  const _MessageState({
    required this.icon,
    required this.message,
    required this.buttonLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: cs.primary),
            const SizedBox(height: 16),
            Text(message, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton(onPressed: onPressed, child: Text(buttonLabel)),
          ],
        ),
      ),
    );
  }
}

class _GuestBanner extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;

  const _GuestBanner({required this.cs, required this.tt});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_outline, size: 72, color: cs.primary),
            const SizedBox(height: 16),
            Text(
              'Crea tu perfil completo',
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Personaliza tu carrera, añade tus habilidades y postúlate a proyectos para colaborar con otros estudiantes.',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => Get.toNamed(AppRoutes.upgradeAccount),
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: const Text('Completar mi perfil'),
            ),
          ],
        ),
      ),
    );
  }
}
