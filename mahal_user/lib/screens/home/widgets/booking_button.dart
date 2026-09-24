import 'package:flutter/material.dart';
import '../../../routes/app_routes.dart';
import '../../../utils/app_colors.dart';
import '../../../models/mahal_model.dart';

class BookingButton extends StatelessWidget {
  final MahalModel? mahal;
  const BookingButton({super.key, this.mahal});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, AppRoutes.bookingPage, arguments: mahal);
      },
      child: Container(
        width: 75,
        height: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [AppColors.bookingButtonStart, AppColors.bookingButtonEnd],
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            "View",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

