import 'package:flutter/material.dart';

class ImkerAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ImkerAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
      elevation: 0,
      title: Text("Imker", style: Theme.of(context).textTheme.headlineLarge),
      centerTitle: true,
      toolbarHeight: 40,
      shape: Border(
        bottom: BorderSide(
          color: Theme.of(context).colorScheme.onTertiaryContainer,
          width: 1,
        ),
      ),
    );
  }
}
