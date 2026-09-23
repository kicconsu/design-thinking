import 'package:flutter/material.dart';

class FilterDropdownButton extends StatelessWidget {
  const FilterDropdownButton({
    super.key,
    required this.labels,
    required this.currentIndex,
    required this.onSelected,
    this.width = 160,
    this.height = 38,
    this.offset = const Offset(0, 42),
  });

  final List<String> labels;
  final int currentIndex;
  final ValueChanged<int> onSelected;
  final double width;
  final double height;
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      offset: offset,
      onSelected: onSelected,
      itemBuilder: (_) => [
        for (int i = 0; i < labels.length; i++)
          PopupMenuItem<int>(
            value: i,
            child: Text(
              labels[i],
              style: TextStyle(
                fontWeight: i == currentIndex ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
      ],
      child: SizedBox(
        width: width,
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.black, width: 1.2),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  labels[currentIndex],
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.arrow_drop_down, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}