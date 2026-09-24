import 'package:flutter/material.dart';

class TopBarWidget extends StatelessWidget {

  const TopBarWidget({super.key});

  @override
  Widget build(BuildContext context) {

    return const Row(

      mainAxisAlignment: MainAxisAlignment.end,

      children: [

        Icon(
          Icons.notifications_none,
          size: 28,
        ),
      ],
    );
  }
}