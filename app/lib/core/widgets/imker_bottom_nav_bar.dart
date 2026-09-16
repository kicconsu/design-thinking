import 'package:flutter/material.dart';

class ImkerBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const ImkerBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _items = [
    _NavItem(
      icon: Icons.bolt_outlined,
      activeIcon: Icons.bolt,
      label: 'DESCUBRIR',
    ),
    _NavItem(
      icon: Icons.language_outlined,
      activeIcon: Icons.language,
      label: 'PROYECTOS',
    ),
    _NavItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'PERFIL',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        border: Border(
          top: BorderSide(color: cs.onTertiaryContainer, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: List.generate(_items.length, (index) {
            final item = _items[index];
            final isSelected = currentIndex == index;
            return Expanded(
              child: _NavCell(
                icon: isSelected ? item.activeIcon : item.icon,
                label: item.label,
                isSelected: isSelected,
                onTap: () => onTap(index),
                showRightBorder: index < _items.length - 1,
                borderColor: cs.onTertiaryContainer,
                selectedBg: cs.tertiaryContainer,
                unselectedBg: cs.primaryContainer,
                contentColor: cs.onPrimaryContainer,
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class _NavCell extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool showRightBorder;
  final Color borderColor;
  final Color selectedBg;
  final Color unselectedBg;
  final Color contentColor;

  const _NavCell({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.showRightBorder,
    required this.borderColor,
    required this.selectedBg,
    required this.unselectedBg,
    required this.contentColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : unselectedBg,
          border: showRightBorder
              ? Border(right: BorderSide(color: borderColor, width: 1))
              : null,
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: contentColor, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: contentColor,
                letterSpacing: 1.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
