import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../routes/app_routes.dart';
import '../../services/visiting_service.dart';
import '../../widgets/user_app_bar.dart';

class SelectVisitingTimePage extends StatefulWidget {
  const SelectVisitingTimePage({super.key});

  @override
  State<SelectVisitingTimePage> createState() => _SelectVisitingTimePageState();
}

class _SelectVisitingTimePageState extends State<SelectVisitingTimePage> {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _selectedTime;
  bool _isLoading = false;
  bool _initializedDate = false;

  final VisitingService _visitingService = VisitingService();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedDate) {
      _initializedDate = true;
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
      final paymentTimeStr = args['payment_time']?.toString();
      if (paymentTimeStr != null) {
        final parsed = DateTime.tryParse(paymentTimeStr);
        if (parsed != null) {
          _selectedDate = parsed;
        }
      }
      _dateController.text =
          '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _pickTime(BuildContext context) async {
    final nowTime = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? nowTime,
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        final hour = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
        final minute = picked.minute.toString().padLeft(2, '0');
        final period = picked.period == DayPeriod.am ? 'AM' : 'PM';
        _timeController.text = '${hour.toString().padLeft(2, '0')}:$minute $period';
      });
    }
  }

  void _handleConfirmVisiting(Map<String, dynamic> args) async {
    if (_selectedTime == null || _timeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a Visiting Time')),
      );
      return;
    }

    final bookingId = args['booking_id']?.toString() ?? '';
    final paymentTimeStr = args['payment_time']?.toString() ?? DateTime.now().toUtc().toIso8601String();
    final paymentTime = DateTime.tryParse(paymentTimeStr) ?? DateTime.now();

    final chosenDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    // Validate 3 Hours limit from payment completion time
    final maxAllowedTime = paymentTime.add(const Duration(hours: 3));

    if (chosenDateTime.isAfter(maxAllowedTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Selected visiting time exceeds the allowed limit (Max 3 hours from payment time).'),
        ),
      );
      return;
    }

    if (chosenDateTime.isBefore(paymentTime.subtract(const Duration(minutes: 5)))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Visiting time cannot be in the past.'),
        ),
      );
      return;
    }

    setState(() { _isLoading = true; });

    final result = await _visitingService.saveVisitingTime(
      bookingId: bookingId,
      visitingDate: _dateController.text,
      visitingTime: _timeController.text,
      paymentTime: paymentTimeStr,
    );

    setState(() { _isLoading = false; });
    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text('Visiting Time confirmed! QR Pass generated.'),
        ),
      );

      final qrArgs = {
        ...args,
        'booking_id': bookingId,
        'visiting_date': _dateController.text,
        'visiting_time': _timeController.text,
        'expiry_time': chosenDateTime.toIso8601String(),
        'payment_time': paymentTimeStr,
        if (result['data'] != null) 'qr_token': result['data']['qr_token'],
      };

      Navigator.pushNamed(
        context,
        AppRoutes.qrPassPage,
        arguments: qrArgs,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(result['message'] ?? 'Failed to save visiting time'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const UserAppBar(title: 'Visiting Time', showBack: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.deepOrange.shade400, Colors.orange.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Row(
                      children: [
                        Icon(Icons.storefront, color: Colors.white, size: 28),
                        SizedBox(width: 10),
                        Text(
                          "Visit the Mahal",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      "Please select when you will visit the Mahal Owner. "
                      "The visiting time is different from the event time. "
                      "You must visit the Mahal within 3 hours of completing payment.",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Max time reminder banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade400),
                ),
                child: Row(
                  children: [
                    Icon(Icons.timer, color: Colors.amber.shade900),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Visiting time must be within 3 Hours from your payment time.",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Locked Visiting Date Display (Read-Only)
              const Text(
                "Visiting Date",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _dateController,
                readOnly: true,
                decoration: InputDecoration(
                  suffixIcon: const Icon(Icons.lock_clock, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Time Picker Field
              const Text(
                "Visiting Time",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _timeController,
                readOnly: true,
                onTap: () => _pickTime(context),
                decoration: InputDecoration(
                  hintText: "Select Visiting Time (e.g. 11:00 PM)",
                  suffixIcon: const Icon(Icons.access_time, color: Colors.deepOrange),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),

              const SizedBox(height: 36),

              // ELEGANT & WELL-ORDERED CONFIRM BUTTON
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: const LinearGradient(
                    colors: [Colors.orange, Colors.deepOrange],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(30),
                    onTap: _isLoading ? null : () => _handleConfirmVisiting(args),
                    child: Center(
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.qr_code_2, color: Colors.white, size: 24),
                                SizedBox(width: 10),
                                Text(
                                  "Confirm & Generate QR Pass",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
