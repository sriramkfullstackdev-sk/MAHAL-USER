import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../routes/app_routes.dart';
import '../../models/mahal_model.dart';
import '../../services/booking_service.dart';
import '../../widgets/user_app_bar.dart';
import 'widgets/event_name_field.dart';
import 'widgets/date_field.dart';
import 'widgets/time_field.dart';
import 'widgets/confirm_booking_button.dart';

class BookingFormPage extends StatefulWidget {
  const BookingFormPage({super.key});

  @override
  State<BookingFormPage> createState() => _BookingFormPageState();
}

class _BookingFormPageState extends State<BookingFormPage> {
  final TextEditingController _eventNameController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();

  final BookingService _bookingService = BookingService();
  bool _isLoadingTimings = false;
  bool _isSubmitting = false;

  final Map<String, String> _bookingTypeLabels = {
    'Morning': '🌅 Morning Booking',
    'Afternoon': '🌇 Afternoon / Evening Booking',
    'Full Day': '☀️ Full Day Booking',
    'Wedding': '💍 Wedding Booking',
  };

  String _selectedBookingType = 'Morning';
  Map<String, dynamic> _defaultTimings = {};
  bool _hasLoadedTimings = false;
  String? _originalTargetDate;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoadedTimings) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final mahal = args?['mahal'] as MahalModel?;
      final allowedTypes = (args?['available_booking_types'] as List?)
          ?.map((type) => type.toString())
          .where((type) => type.isNotEmpty)
          .toList();
      if (allowedTypes != null &&
          allowedTypes.isNotEmpty &&
          !allowedTypes.contains(_selectedBookingType)) {
        _selectedBookingType = allowedTypes.first;
      }
      if (mahal?.id != null) {
        _hasLoadedTimings = true;
        _fetchDefaultTimings(mahal!.id!);
      }
    }
  }

  Future<void> _fetchDefaultTimings(String mahalId) async {
    setState(() {
      _isLoadingTimings = true;
    });
    final res = await _bookingService.getDefaultTimings(mahalId);
    if (!mounted) return;
    setState(() {
      _isLoadingTimings = false;
    });

    if (res['success'] == true && res['timings'] != null) {
      setState(() {
        _defaultTimings = Map<String, dynamic>.from(res['timings']);
        _applyTimingsForType(_selectedBookingType);
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              res['message'] ??
                  'Default timings not configured for this Mahal.',
            ),
          ),
        );
      }
    }
  }

  void _applyTimingsForType(String bookingType) {
    if (_defaultTimings.containsKey(bookingType)) {
      final timing = _defaultTimings[bookingType];
      _startTimeController.text = timing['start_time'] ?? '';
      _endTimeController.text = timing['end_time'] ?? '';
    } else {
      if (bookingType == 'Morning') {
        _startTimeController.text = '06:00 AM';
        _endTimeController.text = '12:00 PM';
      } else if (bookingType == 'Afternoon') {
        _startTimeController.text = '01:00 PM';
        _endTimeController.text = '06:00 PM';
      } else if (bookingType == 'Full Day') {
        _startTimeController.text = '06:00 AM';
        _endTimeController.text = '06:00 PM';
      } else if (bookingType == 'Wedding') {
        _startTimeController.text = '06:00 PM';
        _endTimeController.text = '02:00 PM';
      }
    }
    _autoUpdateEndDate(bookingType);
  }

  void _autoUpdateEndDate(String bookingType) {
    if (_startDateController.text.isEmpty) return;
    try {
      final parts = _startDateController.text.split('/');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        final startDt = DateTime(year, month, day);

        if (bookingType == 'Wedding') {
          final nextDay = startDt.add(const Duration(days: 1));
          _endDateController.text =
              '${nextDay.day.toString().padLeft(2, '0')}/${nextDay.month.toString().padLeft(2, '0')}/${nextDay.year}';
        } else {
          _endDateController.text = _startDateController.text;
        }
      }
    } catch (_) {
      if (_endDateController.text.isEmpty) {
        _endDateController.text = _startDateController.text;
      }
    }
  }

  String _toApiDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        return '${parts[2]}-${parts[1]}-${parts[0]}';
      }
    } catch (_) {}
    return dateStr;
  }

  Future<void> _handleBookingTypeChange(
    String newBookingType,
    String mahalId,
  ) async {
    if (newBookingType == 'Wedding') {
      String targetDateStr = _originalTargetDate ?? _endDateController.text;
      if (targetDateStr.isEmpty) {
        targetDateStr = _startDateController.text;
      }
      if (targetDateStr.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select Event Date first')),
        );
        return;
      }

      try {
        final parts = targetDateStr.split('/');
        if (parts.length == 3) {
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final year = int.parse(parts[2]);
          final weddingDateObj = DateTime(year, month, day);
          final prevDateObj = weddingDateObj.subtract(const Duration(days: 1));

          final prevDateApiStr =
              '${prevDateObj.year}-${prevDateObj.month.toString().padLeft(2, '0')}-${prevDateObj.day.toString().padLeft(2, '0')}';
          final prevDateDisplayStr =
              '${prevDateObj.day.toString().padLeft(2, '0')}/${prevDateObj.month.toString().padLeft(2, '0')}/${prevDateObj.year}';
          final targetDateDisplayStr =
              '${weddingDateObj.day.toString().padLeft(2, '0')}/${weddingDateObj.month.toString().padLeft(2, '0')}/${weddingDateObj.year}';

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Checking availability for previous evening ($prevDateDisplayStr)...',
              ),
              duration: const Duration(seconds: 1),
            ),
          );

          final res = await _bookingService.checkDateAvailability(
            mahalId,
            prevDateApiStr,
          );

          if (res['success'] == true &&
              res['data'] != null &&
              (res['data'] as List).isNotEmpty) {
            final availData = res['data'][0];
            final bool isEveningBooked =
                availData['evening_booked'] == 1 ||
                availData['full_day_booked'] == 1;

            bool isWeddingAvailable = true;
            if (availData['owner_default_slots'] != null) {
              final slots = availData['owner_default_slots'] as List;
              final wSlot = slots.firstWhere(
                (s) =>
                    (s['booking_type'] ?? '').toString().toLowerCase() ==
                    'wedding',
                orElse: () => null,
              );
              if (wSlot != null && wSlot['is_available'] == false) {
                isWeddingAvailable = false;
              }
            }

            if (isEveningBooked || !isWeddingAvailable) {
              if (mounted) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.red,
                    content: Text(
                      'Previous evening ($prevDateDisplayStr) is already booked. Wedding slot is unavailable for $targetDateDisplayStr.',
                    ),
                    duration: const Duration(seconds: 4),
                  ),
                );
              }
              return;
            }
          }

          if (mounted) {
            setState(() {
              _startDateController.text = prevDateDisplayStr;
              _endDateController.text = targetDateDisplayStr;
              _selectedBookingType = 'Wedding';
              _applyTimingsForType('Wedding');
            });
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: Colors.green,
                content: Text(
                  'Wedding booking set from previous evening $prevDateDisplayStr 06:00 PM to $targetDateDisplayStr 02:00 PM.',
                ),
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('Error computing previous date: $e');
      }
    } else {
      setState(() {
        if (_originalTargetDate != null && _originalTargetDate!.isNotEmpty) {
          _startDateController.text = _originalTargetDate!;
          _endDateController.text = _originalTargetDate!;
        }
        _selectedBookingType = newBookingType;
        _applyTimingsForType(newBookingType);
      });
    }
  }

  void _showBookingTimeBottomSheet(BuildContext context, String mahalId) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final allowedTypes = (args?['available_booking_types'] as List?)
        ?.map((type) => type.toString())
        .where((type) => type.isNotEmpty)
        .toSet();
    final visibleEntries = allowedTypes == null || allowedTypes.isEmpty
        ? _bookingTypeLabels.entries
        : _bookingTypeLabels.entries.where(
            (entry) => allowedTypes.contains(entry.key),
          );

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: Text(
                  "Select Booking Time",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              const Divider(),
              ...visibleEntries.map((entry) {
                final isSelected = entry.key == _selectedBookingType;
                return ListTile(
                  title: Text(
                    entry.value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected ? Colors.deepOrange : Colors.black87,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: Colors.deepOrange)
                      : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    if (entry.key != _selectedBookingType) {
                      _handleBookingTypeChange(entry.key, mahalId);
                    }
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _confirmBooking(MahalModel mahal) async {
    final eventName = _eventNameController.text.trim();
    final startDate = _startDateController.text.trim();
    final startTime = _startTimeController.text.trim();
    final endDate = _endDateController.text.isEmpty
        ? startDate
        : _endDateController.text.trim();
    final endTime = _endTimeController.text.trim();

    final totalAmt = mahal.price
        .replaceAll(',', '')
        .replaceAll('Rs.', '')
        .trim();
    final initialAmt = 1000;

    if (eventName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Event Name is required')));
      return;
    }

    if (startDate.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Event Date is required')));
      return;
    }

    if (startTime.isEmpty || endTime.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Default timing for selected Booking Type is missing'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final bookingResult = await _bookingService.createBooking(
      mahalId: mahal.id ?? '1',
      bookingDate: _toApiDate(startDate),
      endDate: _toApiDate(endDate),
      eventName: eventName,
      bookingType: _selectedBookingType,
      eventTime: startTime,
      endTime: endTime,
      totalAmt: totalAmt,
      initialAmt: initialAmt.toString(),
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (bookingResult['success'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(bookingResult['message'] ?? 'Booking creation failed'),
        ),
      );
      return;
    }

    final bookingId =
        (bookingResult['data']?['booking_id'] ??
                bookingResult['data']?['_id'] ??
                bookingResult['booking_id'] ??
                bookingResult['_id'])
            ?.toString();

    if (bookingId == null || bookingId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking created but booking ID was not returned.'),
        ),
      );
      return;
    }

    Navigator.pushNamed(
      context,
      AppRoutes.selectVisitingTimePage,
      arguments: {
        'booking_id': bookingId,
        'amount': initialAmt.toString(),
        'total_amount': totalAmt,
        'mahal_id': mahal.id,
        'mahal_name': mahal.mahalName,
        'booking_date': _toApiDate(startDate),
        'end_date': _toApiDate(endDate),
        'event_name': eventName,
        'booking_type': _selectedBookingType,
        'event_time': startTime,
        'end_time': endTime,
        'user_name': 'User',
        'payment_time': DateTime.now().toUtc().toIso8601String(),
      },
    );
  }

  @override
  void dispose() {
    _eventNameController.dispose();
    _startDateController.dispose();
    _startTimeController.dispose();
    _endDateController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final mahal = args?['mahal'] as MahalModel?;
    final selectedDate = args?['selectedDate'] as String?;

    if (mahal == null) {
      return const Scaffold(body: Center(child: Text("Mahal Not Found")));
    }

    if (_startDateController.text.isEmpty && selectedDate != null) {
      try {
        final parts = selectedDate.split('-');
        if (parts.length == 3) {
          _startDateController.text = '${parts[2]}/${parts[1]}/${parts[0]}';
        } else {
          _startDateController.text = selectedDate;
        }
      } catch (_) {}
    }
    if (_originalTargetDate == null && _startDateController.text.isNotEmpty) {
      _originalTargetDate = _startDateController.text;
    }
    if (_endDateController.text.isEmpty &&
        _startDateController.text.isNotEmpty) {
      _autoUpdateEndDate(_selectedBookingType);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const UserAppBar(title: 'Booking', showBack: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 25),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),

                /// 1. SELECT MAHAL HEADER
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Select Mahal",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      mahal.mahalName.isNotEmpty
                          ? mahal.mahalName
                          : "Royal Mahal",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                /// 2. EVENT DATE & END DATE COLUMNS
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Text(
                                "Event Date",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(width: 5),
                              Text(
                                "(Read Only)",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          DateField(
                            controller: _startDateController,
                            readOnly: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "End Date",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 10),
                          DateField(
                            controller: _endDateController,
                            readOnly: false,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                /// 3. ENTER YOUR EVENT NAME
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Enter Your Event Name",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    EventNameField(controller: _eventNameController),
                  ],
                ),

                const SizedBox(height: 25),

                /// 4. BOOKING TIME
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          "Booking Time",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        if (_isLoadingTimings) ...[
                          const SizedBox(width: 10),
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () =>
                          _showBookingTimeBottomSheet(context, mahal.id ?? '1'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 15,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.textFieldColor,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _bookingTypeLabels[_selectedBookingType] ??
                                  '🌅 Morning Booking',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const Icon(
                              Icons.arrow_drop_down,
                              size: 30,
                              color: Colors.black87,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                /// 5 & 6. START TIME AND END TIME (READ ONLY)
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Text(
                                "Start Time",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(width: 5),
                              Text(
                                "(Read Only)",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TimeField(
                            controller: _startTimeController,
                            readOnly: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Text(
                                "End Time",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(width: 5),
                              Text(
                                "(Read Only)",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TimeField(
                            controller: _endTimeController,
                            readOnly: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                /// 7. PROCEED TO PAYMENT BUTTON
                Center(
                  child: _isSubmitting
                      ? const CircularProgressIndicator()
                      : ConfirmBookingButton(
                          onTap: () => _confirmBooking(mahal),
                        ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
