import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../models/mahal_model.dart';
import '../../widgets/user_app_bar.dart';
import 'widgets/mahal_card.dart';
import 'widgets/check_button.dart';

class BookingPage extends StatelessWidget {
  const BookingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final mahal = ModalRoute.of(context)?.settings.arguments as MahalModel?;
    if (mahal == null) return const Scaffold(body: Center(child: Text("Mahal Not Found")));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const UserAppBar(title: 'Mahal Details', showBack: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
          child: Column(
            children: [
              const SizedBox(height: 20),
              MahalCard(mahal: mahal),
              const SizedBox(height: 40),
              CheckButton(mahal: mahal),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

