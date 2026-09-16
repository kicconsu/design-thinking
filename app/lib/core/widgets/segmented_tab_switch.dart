import 'package:flutter/material.dart';

/// Widget reutilizable de pestañas segmentadas tipo píldora.
/// Soporta un número dinámico/variable de tabs y se adapta al diseño Imker.
class SegmentedTabSwitch extends StatelessWidget {
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final Color? selectedBackgroundColor;
  final Color? selectedTextColor;
  final Color? unselectedTextColor;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry itemPadding;
  final bool isScrollable;

  const SegmentedTabSwitch({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
    this.selectedBackgroundColor,
    this.selectedTextColor,
    this.unselectedTextColor,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1.5,
    this.borderRadius = 8.0,
    this.padding = const EdgeInsets.all(4),
    this.itemPadding = const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
    this.isScrollable = false,
  }) : assert(tabs.length >= 2, 'SegmentedTabSwitch requiere al menos 2 tabs');

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final effectiveSelectedBg = selectedBackgroundColor ?? cs.tertiaryContainer;
    final effectiveSelectedText = selectedTextColor ?? cs.onTertiaryContainer;
    final effectiveUnselectedText = unselectedTextColor ?? cs.onSurface;
    final effectiveBg = backgroundColor ?? cs.surface;
    final effectiveBorder = borderColor ?? Colors.black;

    final List<Widget> tabWidgets = [];
    for (int i = 0; i < tabs.length; i++) {
      final isSelected = i == selectedIndex;
      final tabPill = _TabPill(
        label: tabs[i],
        isSelected: isSelected,
        onTap: () => onTabSelected(i),
        selectedBgColor: effectiveSelectedBg,
        selectedTextColor: effectiveSelectedText,
        unselectedTextColor: effectiveUnselectedText,
        borderRadius: borderRadius > 2 ? borderRadius - 2 : borderRadius,
        itemPadding: itemPadding,
        tt: tt,
      );

      if (i > 0) {
        tabWidgets.add(const SizedBox(width: 4));
      }

      tabWidgets.add(isScrollable ? tabPill : Expanded(child: tabPill));
    }

    Widget content = Row(children: tabWidgets);
    if (isScrollable) {
      content = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: content,
      );
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: effectiveBorder, width: borderWidth),
      ),
      child: content,
    );
  }
}

class _TabPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color selectedBgColor;
  final Color selectedTextColor;
  final Color unselectedTextColor;
  final double borderRadius;
  final EdgeInsetsGeometry itemPadding;
  final TextTheme tt;

  const _TabPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.selectedBgColor,
    required this.selectedTextColor,
    required this.unselectedTextColor,
    required this.borderRadius,
    required this.itemPadding,
    required this.tt,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: itemPadding,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? selectedBgColor : Colors.transparent,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: tt.bodyMedium?.copyWith(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? selectedTextColor : unselectedTextColor,
          ),
        ),
      ),
    );
  }
}
