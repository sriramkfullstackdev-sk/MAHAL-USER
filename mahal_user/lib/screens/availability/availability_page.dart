import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../models/mahal_model.dart';
import '../../widgets/user_app_bar.dart';
import 'widgets/book_now_button.dart';
import 'widgets/calendar_widget.dart';

class AvailabilityPage extends StatefulWidget {
  const AvailabilityPage({super.key});

  @override
  State<AvailabilityPage> createState() => _AvailabilityPageState();
}

class _AvailabilityPageState extends State<AvailabilityPage> {
  String? selectedDate;
  List<String> availableBookingTypes = [];

  @override
  Widget build(BuildContext context) {
    final mahal = ModalRoute.of(context)?.settings.arguments as MahalModel?;
    if (mahal == null) {
      return const Scaffold(body: Center(child: Text("Mahal Not Found")));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const UserAppBar(title: 'Select Date', showBack: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              CalendarWidget(
                mahalId: mahal.id ?? '',
                onDateSelected: (date, availableTypes) {
                  setState(() {
                    selectedDate = date;
                    availableBookingTypes = availableTypes;
                  });
                },
              ),
              const SizedBox(height: 30),
              Center(
                child: BookNowButton(
                  mahal: mahal,
                  selectedDate: selectedDate,
                  availableBookingTypes: availableBookingTypes,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
