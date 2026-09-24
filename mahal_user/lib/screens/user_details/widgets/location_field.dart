import 'package:flutter/material.dart';

class LocationField extends StatelessWidget {

  const LocationField({super.key});

  @override
  Widget build(BuildContext context) {

    return TextField(

      decoration: InputDecoration(

        hintText: "Location add",

        hintStyle: const TextStyle(
          color: Colors.grey,
          fontSize: 18,
        ),

        filled: true,

        fillColor: Colors.grey.shade300,

        border: OutlineInputBorder(

          borderRadius: BorderRadius.circular(0),

          borderSide: BorderSide.none,
        ),

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 18,
        ),

        suffixIcon: const Icon(
          Icons.location_on_outlined,
          color: Colors.black54,
        ),
      ),
    );
  }
}