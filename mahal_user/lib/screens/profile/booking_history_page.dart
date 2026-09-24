import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../services/booking_service.dart';
import '../../widgets/user_app_bar.dart';

String formatDateForDisplay(String rawDate, [String fallback = 'Not available']) {
  final value = rawDate.trim();
  if (value.isEmpty || value == '-' || value.toLowerCase() == 'null') {
    return fallback;
  }

  String normalized = value;
  if (normalized.contains('T')) {
    normalized = normalized.split('T').first;
  }
  if (normalized.contains(' ')) {
    normalized = normalized.split(' ').first;
  }

  final parsed = DateTime.tryParse(normalized);
  if (parsed == null) {
    return value;
  }

  final day = parsed.day.toString().padLeft(2, '0');
  final month = parsed.month.toString().padLeft(2, '0');
  final year = parsed.year.toString().substring(2);
  return '$day/$month/$year';
}

class BookingHistoryPage extends StatefulWidget {
  const BookingHistoryPage({super.key});

  @override
  State<BookingHistoryPage> createState() => _BookingHistoryPageState();
}

class _BookingHistoryPageState extends State<BookingHistoryPage> {
  final BookingService _bookingService = BookingService();
  List<dynamic> _bookings = [];
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    final result = await _bookingService.getBookingHistory();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result['success'] == true) {
        _bookings = result['data'] as List? ?? [];
      } else {
        _errorMessage = result['message']?.toString() ?? 'Unable to load bookings';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const UserAppBar(title: 'My Bookings', showBack: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadBookings,
              child: _bookings.isEmpty
                  ? ListView(children: [SizedBox(height: 180), Center(child: Text(_errorMessage ?? 'No bookings yet'))])
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                      itemCount: _bookings.length,
                      itemBuilder: (context, index) => _BookingDetailsCard(booking: _bookings[index]),
                    ),
            ),
    );
  }
}

class _BookingDetailsCard extends StatelessWidget {
  final dynamic booking;

  const _BookingDetailsCard({required this.booking});

  String _value(String key, [String fallback = 'Not available']) {
    final value = booking[key]?.toString().trim() ?? '';
    return value.isEmpty ? fallback : value;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [BoxShadow(color: AppColors.subtleShadow, blurRadius: 8, offset: Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_city, color: AppColors.accent),
              const SizedBox(width: 10),
              Expanded(child: Text(_value('mahal_name', 'Mahal'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
              Text(_value('booking_status', 'Pending'), style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700)),
            ],
          ),
          const Divider(height: 24),
          _Detail(label: 'Mahal name', value: _value('mahal_name')),
          _Detail(label: 'User name', value: _value('user_name')),
          _Detail(label: 'Booking date', value: formatDateForDisplay(_value('booking_date'))),
          _Detail(label: 'Event name', value: _value('event_name')),
          _Detail(label: 'Event date', value: formatDateForDisplay(_value('end_date'))),
          _Detail(label: 'Total amount', value: '₹${_value('total_amt', '0')}'),
          _Detail(label: 'Paid amount', value: '₹${_value('initial_amt', '0')}'),
        ],
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  final String label;
  final String value;

  const _Detail({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 115, child: Text(label, style: const TextStyle(color: AppColors.textSecondary))),
          const Text(': ', style: TextStyle(color: AppColors.textSecondary)),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
        ],
      ),
    );
  }
}
