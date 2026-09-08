import 'package:f_clean_template/core/navigation/ui/viewmodels/navigation_controller.dart';
import 'package:f_clean_template/core/navigation/ui/views/imker_bottom_nav_bar.dart';
import 'package:f_clean_template/core/shared_widgets/offset_app_bar.dart';
import 'package:f_clean_template/features/discover/discover_page.dart';
import 'package:f_clean_template/features/profile/profile_page.dart';
import 'package:f_clean_template/features/projects/project_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    final NavigationController navController = Get.find();

    return Obx(
      () {
        final cs = Theme.of(context).colorScheme;
        return Scaffold(
          backgroundColor: cs.primaryContainer,
          appBar: OffsetAppBar(),
          body: IndexedStack(
            index: navController.currentIndex.value,
            children: const [DiscoverPage(), ProjectPage(), ProfilePage()],
          ),
          bottomNavigationBar: ImkerBottomNavBar(
            currentIndex: navController.currentIndex.value,
            onTap: navController.changePage,
          ),
        );
      },
    );
  }
}
