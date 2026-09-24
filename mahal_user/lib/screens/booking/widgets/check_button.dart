import 'package:flutter/material.dart';
import '../../../routes/app_routes.dart';
import '../../../models/mahal_model.dart';

class CheckButton extends StatelessWidget {
  final MahalModel? mahal;
  const CheckButton({super.key, this.mahal});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, AppRoutes.availabilityPage, arguments: mahal);
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
            "check availability",
            style: TextStyle(
              fontSize: 16,
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
