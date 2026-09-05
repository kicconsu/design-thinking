import 'package:flutter/material.dart';

class OffsetAppBar extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [

        //El espacio justico antes de la app bar
        Container(
          height: MediaQuery.sizeOf(context).height*0.025,
          color: Theme.of(context).colorScheme.primaryContainer,
        ),

        AppBar(
          backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
          elevation: 0,
          title: Text("Imker", style: Theme.of(context).textTheme.headlineLarge),
          centerTitle: true,
          toolbarHeight: 40,

          shape: Border(
            bottom: BorderSide(
              color: Theme.of(context).colorScheme.onTertiaryContainer,
              width: 1
            ),
            top: BorderSide(
              color: Theme.of(context).colorScheme.onTertiaryContainer,
              width: 1
            )
          ),
        )

      ],
    );
  }
}