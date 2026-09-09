import 'package:f_clean_template/features/home/ui/viewmodels/home_view_model.dart';
import 'package:f_clean_template/core/widgets/imker_bottom_nav_bar.dart';
import 'package:f_clean_template/core/widgets/imker_app_bar.dart';
import 'package:f_clean_template/features/discover/ui/pages/discover_page.dart';
import 'package:f_clean_template/features/profile/pages/profile_page.dart';
import 'package:f_clean_template/features/projects/project_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final HomeViewModel homeViewModel = Get.find();

    return Obx(() {
      final cs = Theme.of(context).colorScheme;
      return Scaffold(
        backgroundColor: cs.primaryContainer,
        appBar: ImkerAppBar(),
        body: IndexedStack(
          index: homeViewModel.currentIndex.value,
          children: const [DiscoverPage(), ProjectPage(), ProfilePage()],
        ),
        bottomNavigationBar: ImkerBottomNavBar(
          currentIndex: homeViewModel.currentIndex.value,
          onTap: homeViewModel.changePage,
        ),
      );
    });
  }
}
