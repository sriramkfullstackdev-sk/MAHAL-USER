import 'package:flutter/material.dart';

class DateInputWidget extends StatelessWidget {

  const DateInputWidget({super.key});

  @override
  Widget build(BuildContext context) {

    return Column(

      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

        const Padding(
          padding: EdgeInsets.only(left: 20),

          child: Text(
            "Enter Date",
            style: TextStyle(
              fontSize: 18,
            ),
          ),
        ),

        const SizedBox(height: 10),

        Container(

          width: double.infinity,
          height: 100,

          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
          ),

          color: Colors.grey.shade300,

          child: const Column(

            crossAxisAlignment: CrossAxisAlignment.end,

            children: [

              Center(
                child: Text(
                  "dd/mm/yy",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 22,
                  ),
                ),
              ),

              Spacer(),

              Text(
                "0K",
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 40,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}