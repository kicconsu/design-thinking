import 'package:f_clean_template/core/shared_widgets/offset_app_bar.dart';
import 'package:flutter/material.dart';

class ScrollPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [

            OffsetAppBar(),
            Expanded(
              child: Container(

                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                ),
                
                child: Center(child: Text("ola")),
              
              ),
            ),
          ],
        ),
      ),
    );
  }
}


