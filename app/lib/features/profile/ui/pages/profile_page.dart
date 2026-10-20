import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:imker/features/auth/ui/viewmodels/authentication_controller.dart';
import 'package:imker/features/profile/domain/models/user_profile.dart';
import 'package:imker/features/projects/ui/pages/project_detail_page.dart';
import 'package:imker/features/projects/ui/viewmodels/user_projects_controller.dart';
import 'package:imker/routes/app_routes.dart';

import '../viewmodels/profile_controller.dart';
import '../widgets/profile_view.dart';
import 'collaboration_history_page.dart';
import 'edit_profile_page.dart';
import 'settings_page.dart';
import 'trust_indicators_page.dart';

/// Pestaña Perfil: la presentación del propio perfil (lo que verá otra
/// persona) con acceso a editarlo, a ajustes y al detalle de cada sección.
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

class _ProfileContent extends StatelessWidget {
  const _ProfileContent();

  Future<void> _refresh() async {
    final projects = Get.find<UserProjectsController>();
    await Future.wait([
      Get.find<ProfileController>().loadProfile(),
      Get.find<ProfileController>().loadTrust(),
      projects.fetchCoCreatedProjects(),
      projects.fetchUserApplications(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthenticationController>();
    final profileController = Get.find<ProfileController>();
    final projectsController = Get.find<UserProjectsController>();

    return Obx(() {
      if (profileController.isLoading.value &&
          profileController.profile == null) {
        return const Center(child: CircularProgressIndicator());
      }

      if (profileController.error.value != null &&
          profileController.profile == null) {
        return _MessageState(
          icon: Icons.cloud_off,
          message: profileController.error.value!,
          buttonLabel: 'Reintentar',
          onPressed: profileController.loadProfile,
        );
      }

      final profile = profileController.profileWithTrust ?? const UserProfile();
      final created = projectsController.coCreatedProjects.toList();
      final collaborating = projectsController.activeProjects.toList();
      final myProjects = [...created, ...collaborating];

      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            ProfileView(
              name: auth.loggedName,
              profile: profile,
              isOwn: true,
              projects: myProjects,
              onOpenSettings: () => Get.to(() => const SettingsPage()),
              onComplete: () => Get.to(() => const EditProfilePage()),
              onOpenProject: (p) => Get.to(() => ProjectDetailPage(project: p)),
              onOpenIndicators: () =>
                  Get.to(() => const OwnTrustIndicatorsPage()),
              trustLoading:
                  profileController.isLoadingTrust.value &&
                  profileController.trust.value == null,
              trustError: profileController.trustError.value,
              onRetryTrust: profileController.loadTrust,
              onOpenHistory: () => Get.to(
                () => CollaborationHistoryPage(
                  created: created,
                  collaborating: collaborating,
                ),
              ),
            ),
          ],
        ),
      );
    });
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
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
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
