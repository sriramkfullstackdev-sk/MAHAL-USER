import 'package:flutter/material.dart';

import '../../../routes/app_routes.dart';
import '../../../models/mahal_model.dart';

class BookNowButton extends StatelessWidget {
  final MahalModel? mahal;
  final String? selectedDate;
  final List<String> availableBookingTypes;
  const BookNowButton({
    super.key,
    this.mahal,
    this.selectedDate,
    this.availableBookingTypes = const [],
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (selectedDate == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select a date from the calendar first'),
            ),
          );
          return;
        }
        Navigator.pushNamed(
          context,
          AppRoutes.bookingFormPage,
          arguments: {
            'mahal': mahal,
            'selectedDate': selectedDate,
            'available_booking_types': availableBookingTypes,
          },
        );
      },
      child: Container(
        width: 170,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: const LinearGradient(
            colors: [Colors.orange, Colors.deepOrange],
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 5,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            "Book Now",
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
