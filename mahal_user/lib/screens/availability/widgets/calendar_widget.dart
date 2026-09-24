import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../constants/api_constants.dart';

class CalendarWidget extends StatefulWidget {
  final String mahalId;
  final Function(String, List<String>) onDateSelected;

  const CalendarWidget({
    super.key,
    required this.mahalId,
    required this.onDateSelected,
  });

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  static const monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  int selectedMonthIndex =
      0; // Or whatever current month is. Let's use current month.
  int selectedYear = DateTime.now().year;
  String? selectedDay;

  Map<String, Map<String, dynamic>> availabilityData = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    selectedMonthIndex = DateTime.now().month - 1;
    _fetchBookedDates();
  }

  Future<void> _fetchBookedDates() async {
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConstants.baseUrl}/bookings/availability?mahal_id=${widget.mahalId}',
        ),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List bookings = data['data'];
          final Map<String, Map<String, dynamic>> tempData = {};
          for (var b in bookings) {
            if (b['booking_date'] != null) {
              String dateStr = b['booking_date'].toString();
              if (dateStr.length > 10) {
                dateStr = dateStr.substring(0, 10);
              }
              tempData[dateStr] = Map<String, dynamic>.from(b);
            }
          }
          setState(() {
            availabilityData = tempData;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching booked dates: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showBookingDetailsPopup(
    BuildContext context,
    String dateStr,
    Map<String, dynamic> avail,
  ) {
    String readableDate = dateStr;
    try {
      final parsedDate = DateTime.parse(dateStr);
      final months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];
      readableDate =
          '${parsedDate.day} ${months[parsedDate.month - 1]} ${parsedDate.year}';
    } catch (_) {}

    // Filter active bookings for THIS clicked date in chronological order
    final List dateBookingsList = (avail['bookings'] as List? ?? []).toList();
    dateBookingsList.sort((a, b) {
      final String dateA = a['booking_date'] ?? '';
      final String dateB = b['booking_date'] ?? '';
      if (dateA != dateB) {
        return dateA.compareTo(dateB);
      }
      final String timeA = a['event_time'] ?? '';
      final String timeB = b['event_time'] ?? '';
      return timeA.compareTo(timeB);
    });

    final bool isFullDayBooked = avail['full_day_booked'] == 1;
    final List availableSlots = (avail['available_slots'] as List? ?? [])
        .toList();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        final screenHeight = MediaQuery.of(context).size.height;
        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    color: Colors.deepPurple,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Date: $readableDate",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.deepPurple,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Divider(),
            ],
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: screenHeight * 0.65,
              minWidth: double.maxFinite,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. DATE OCCUPANCY & AVAILABILITY SUMMARY
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.purple.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.cancel_outlined,
                              color: Colors.red,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              "Occupied Slots: ",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                                fontSize: 13,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                "${avail['occupied_slots_text'] ?? (isFullDayBooked ? 'Full Day Occupied' : 'Partially Occupied')}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              color: Colors.green,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              "Available Slots: ",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                                fontSize: 13,
                              ),
                            ),
                            Expanded(
                              child: availableSlots.isEmpty
                                  ? const Text(
                                      'None',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                        fontSize: 13,
                                      ),
                                    )
                                  : Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: availableSlots.map((slot) {
                                        return Chip(
                                          label: Text(
                                            slot['booking_type']?.toString() ??
                                                'Available',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          backgroundColor: Colors.green.shade50,
                                          side: BorderSide(
                                            color: Colors.green.shade200,
                                          ),
                                        );
                                      }).toList(),
                                    ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2. BOOKINGS FOR THIS DATE IN CHRONOLOGICAL ORDER
                  const Text(
                    "Bookings for this Date",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (dateBookingsList.isEmpty)
                    const Text(
                      "No active bookings on this date.",
                      style: TextStyle(color: Colors.grey),
                    )
                  else
                    ...dateBookingsList.asMap().entries.map((entry) {
                      final int idx = entry.key + 1;
                      final Map<String, dynamic> b = entry.value;

                      final String eventName = b['event_name'] ?? 'Booking';
                      final String bookingType = b['booking_type'] ?? '';
                      final String durationText =
                          b['booked_duration_text'] ??
                          "${b['booking_date'] ?? ''} ${b['event_time'] ?? ''} ↓ ${b['end_date'] ?? ''} ${b['end_time'] ?? ''}";
                      final String occupiedSlots =
                          b['occupied_slots_text'] ?? '';
                      final String availableSlots =
                          b['available_slots_text'] ?? '';

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          border: Border.all(color: Colors.red.shade200),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    "$idx. $eventName${bookingType.isNotEmpty ? ' ($bookingType)' : ''}",
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.redAccent,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    "${b['booking_status'] ?? 'Confirmed'}",
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Booked Duration",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              durationText,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            if (occupiedSlots.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                "Occupied: $occupiedSlots",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                            if (availableSlots.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                "Available: $availableSlots",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
          actions: [
            Wrap(
              alignment: WrapAlignment.spaceEvenly,
              spacing: 10,
              runSpacing: 10,
              children: [
                if (availableSlots.isNotEmpty)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(
                      Icons.add_task,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: const Text(
                      "Book Available Slot",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        try {
                          final parsedDate = DateTime.parse(dateStr);
                          selectedDay = parsedDate.day.toString();
                        } catch (_) {
                          selectedDay = null;
                        }
                      });
                      widget.onDateSelected(
                        dateStr,
                        availableSlots
                            .map(
                              (slot) => slot['booking_type']?.toString() ?? '',
                            )
                            .where((type) => type.isNotEmpty)
                            .toList(),
                      );
                    },
                  ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "OK",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  List<String> _buildDaysForMonth(int month, int year) {
    final monthNumber = month + 1;
    final daysInMonth = DateTime(year, monthNumber + 1, 0).day;
    final firstWeekday = DateTime(year, monthNumber, 1).weekday;
    final blanks = firstWeekday % 7;
    final list = List<String>.filled(blanks, '', growable: true);
    list.addAll(List<String>.generate(daysInMonth, (index) => '${index + 1}'));
    return list;
  }

  void _changeMonth(int offset) {
    setState(() {
      selectedMonthIndex = (selectedMonthIndex + offset) % 12;
      if (selectedMonthIndex < 0) selectedMonthIndex += 12;
      selectedDay = null;
    });
  }

  void _showMonthPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, sheetSetState) {
            return SizedBox(
              height: 360,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 20,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => sheetSetState(() {
                            selectedYear -= 1;
                            selectedDay = null;
                          }),
                          icon: const Icon(
                            Icons.arrow_back_ios,
                            color: Colors.deepPurple,
                          ),
                        ),
                        Text(
                          '$selectedYear',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () => sheetSetState(() {
                            selectedYear += 1;
                            selectedDay = null;
                          }),
                          icon: const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GridView.builder(
                        itemCount: monthNames.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 2.5,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                        itemBuilder: (context, index) {
                          final isSelectedMonth = index == selectedMonthIndex;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedMonthIndex = index;
                                selectedDay = null;
                              });
                              Navigator.pop(context);
                            },
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelectedMonth
                                    ? Colors.deepPurple
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                monthNames[index],
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isSelectedMonth
                                      ? Colors.white
                                      : Colors.black,
                                  fontWeight: isSelectedMonth
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final days = _buildDaysForMonth(selectedMonthIndex, selectedYear);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.pink.shade100),
      ),
      child: Column(
        children: [
          /// HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.menu, color: Colors.deepPurple),
              Row(
                children: [
                  IconButton(
                    onPressed: () => _changeMonth(-1),
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      size: 18,
                      color: Colors.deepPurple,
                    ),
                  ),
                  Text(
                    '${monthNames[selectedMonthIndex]} $selectedYear',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _changeMonth(1),
                    icon: const Icon(
                      Icons.arrow_forward_ios,
                      size: 18,
                      color: Colors.deepPurple,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => _showMonthPicker(context),
                icon: const Icon(
                  Icons.calendar_month_outlined,
                  color: Colors.deepPurple,
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          /// WEEK DAYS
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Colors.pink, Colors.blue]),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text('SUN', style: TextStyle(color: Colors.white)),
                Text('MON', style: TextStyle(color: Colors.white)),
                Text('TUE', style: TextStyle(color: Colors.white)),
                Text('WED', style: TextStyle(color: Colors.white)),
                Text('THU', style: TextStyle(color: Colors.white)),
                Text('FRI', style: TextStyle(color: Colors.white)),
                Text('SAT', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),

          /// CALENDAR GRID
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: days.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              final day = days[index];
              final isSelected = day.isNotEmpty && day == selectedDay;

              final dateStr = day.isNotEmpty
                  ? '$selectedYear-${(selectedMonthIndex + 1).toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}'
                  : '';

              final avail = day.isNotEmpty ? availabilityData[dateStr] : null;
              final isBooked = avail != null;
              final hasPending =
                  avail != null && ((avail['pending_count'] as int?) ?? 0) > 0;
              final isFullBooked =
                  avail != null && avail['full_day_booked'] == 1;
              final isMorningBooked =
                  avail != null && avail['morning_booked'] == 1;
              final isEveningBooked =
                  avail != null && avail['evening_booked'] == 1;

              return GestureDetector(
                onTap: day.isEmpty
                    ? null
                    : (isBooked
                          ? () => _showBookingDetailsPopup(
                              context,
                              dateStr,
                              avail,
                            )
                          : () {
                              setState(() {
                                selectedDay = day;
                              });
                              widget.onDateSelected(dateStr, const []);
                            }),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? Colors.deepPurple
                          : (isBooked
                                ? Colors.grey.shade400
                                : Colors.green.shade300),
                      width: isSelected ? 2.5 : 1,
                    ),
                  ),
                  child: day.isEmpty
                      ? const SizedBox()
                      : CustomPaint(
                          painter: BookingBackgroundPainter(
                            isMorningBooked: isMorningBooked,
                            isEveningBooked: isEveningBooked,
                            isFullBooked: isFullBooked,
                          ),
                          child: Stack(
                            children: [
                              Align(
                                alignment: Alignment.center,
                                child: isFullBooked
                                    ? Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Text(
                                            'X',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                              height: 1.1,
                                            ),
                                          ),
                                          Text(
                                            day,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              height: 1.1,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Text(
                                        day,
                                        style: TextStyle(
                                          fontSize: 17,
                                          color: isSelected
                                              ? Colors.deepPurple
                                              : (isEveningBooked &&
                                                        !isMorningBooked
                                                    ? Colors.white
                                                    : Colors.black87),
                                          fontWeight: isSelected || isBooked
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                              ),
                              if (hasPending && !isFullBooked)
                                const Positioned(
                                  top: 2,
                                  right: 2,
                                  child: Icon(
                                    Icons.access_time,
                                    size: 12,
                                    color: Colors.orange,
                                  ),
                                ),
                            ],
                          ),
                        ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class BookingBackgroundPainter extends CustomPainter {
  final bool isMorningBooked;
  final bool isEveningBooked;
  final bool isFullBooked;

  BookingBackgroundPainter({
    required this.isMorningBooked,
    required this.isEveningBooked,
    required this.isFullBooked,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    if (isFullBooked) {
      // Full Day Booked -> RED color shade
      paint.color = Colors.red;
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    } else {
      if (isMorningBooked) {
        // Morning Booked (e.g. Marriage End Date) -> Top-Left corner YELLOW color shade
        paint.color = Colors.yellow;
        final path = Path()
          ..moveTo(0, 0)
          ..lineTo(size.width, 0)
          ..lineTo(0, size.height)
          ..close();
        canvas.drawPath(path, paint);
      }
      if (isEveningBooked) {
        // Evening Booked (e.g. Marriage Start Date) -> Right-Bottom corner BLACK color shade
        paint.color = Colors.black;
        final path = Path()
          ..moveTo(size.width, 0)
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height)
          ..close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant BookingBackgroundPainter oldDelegate) {
    return oldDelegate.isMorningBooked != isMorningBooked ||
        oldDelegate.isEveningBooked != isEveningBooked ||
        oldDelegate.isFullBooked != isFullBooked;
  }
}
