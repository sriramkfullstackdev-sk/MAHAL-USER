import 'package:flutter/material.dart';

class NotificationIconWidget extends StatelessWidget {

  const NotificationIconWidget({super.key});

  @override
  Widget build(BuildContext context) {

    return const Align(

      alignment: Alignment.topRight,

      child: Icon(
        Icons.notifications_none,
        size: 28,
      ),
    );
  }
}