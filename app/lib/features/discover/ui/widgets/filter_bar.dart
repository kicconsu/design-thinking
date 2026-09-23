import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:imker/core/widgets/filter_drowpdown_button.dart';
import 'package:imker/features/discover/ui/viewmodels/discover_controller.dart';

class FilterBar extends StatelessWidget {
  const FilterBar({super.key, required this.controller});

  final DiscoverController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Obx(() => FilterDropdownButton(
            labels: ["carrera 1", "carrera 2", "carrera 3"],
            currentIndex: controller.careerIndex.value,
            onSelected: (int index) => {},
          )),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Obx(() => FilterDropdownButton(
            labels: ["skill 1", "skill 2", "skill 3"],
            currentIndex: controller.skillIndex.value,
            onSelected: (int index) => {},
          )),
        ),
      ],
    );
  }
}