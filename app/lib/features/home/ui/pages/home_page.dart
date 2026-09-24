import 'package:imker/features/home/ui/viewmodels/home_view_model.dart';
import 'package:imker/core/widgets/imker_bottom_nav_bar.dart';
import 'package:imker/core/widgets/imker_app_bar.dart';
import 'package:imker/features/discover/ui/pages/discover_page.dart';
import 'package:imker/features/profile/ui/pages/profile_page.dart';
import 'package:imker/features/profile/ui/widgets/profile_settings_drawer.dart';
import 'package:imker/features/projects/ui/pages/projects_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final HomeViewModel homeViewModel = Get.find();

    return Obx(() {
      final cs = Theme.of(context).colorScheme;
      final isProfileTab = homeViewModel.currentIndex.value == 2;
      return Scaffold(
        backgroundColor: cs.primaryContainer,
        appBar: ImkerAppBar(),
        // El ícono de hamburguesa solo aparece (automáticamente, por tener
        // `drawer` no nulo) cuando la pestaña activa es Perfil.
        drawer: isProfileTab ? const ProfileSettingsDrawer() : null,
        body: IndexedStack(
          index: homeViewModel.currentIndex.value,
          children: const [DiscoverPage(), ProjectsPage(), ProfilePage()],
        ),
        bottomNavigationBar: ImkerBottomNavBar(
          currentIndex: homeViewModel.currentIndex.value,
          onTap: homeViewModel.changePage,
        ),
      );
    });
  }
}
