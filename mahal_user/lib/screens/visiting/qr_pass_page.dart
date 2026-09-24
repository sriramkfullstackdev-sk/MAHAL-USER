import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../constants/app_colors.dart';
import '../../routes/app_routes.dart';
import '../../services/visiting_service.dart';
import '../../widgets/user_app_bar.dart';

class QrPassPage extends StatefulWidget {
  const QrPassPage({super.key});

  @override
  State<QrPassPage> createState() => _QrPassPageState();
}

class _QrPassPageState extends State<QrPassPage> {
  final VisitingService _visitingService = VisitingService();
  final GlobalKey _ticketKey = GlobalKey();
  Timer? _countdownTimer;
  Timer? _statusCheckTimer;

  Map<String, dynamic>? _ticketData;
  bool _isLoading = true;
  Duration _remainingTime = Duration.zero;
  bool _isExpired = false;
  bool _isQrVerified = false;
  bool _isOwnerAccepted = false;
  bool _showReminder30m = false;
  bool _hasShownPopup = false;
  bool _hasShownApprovalDialog = false;
  bool _hasShownRejectionDialog = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ticketData == null) {
      _loadTicketDetails();
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadTicketDetails() async {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    final bookingId = args['booking_id']?.toString() ?? '1';

    final res = await _visitingService.generateQrPass(bookingId);

    if (!mounted) return;
    setState(() { _isLoading = false; });

    if (res['success'] == true && res['data'] != null) {
      setState(() {
        _ticketData = Map<String, dynamic>.from(res['data']);
      });

      _startTimer();
      _startStatusPolling(bookingId);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Failed to load QR pass details')),
      );
    }
  }

  void _startTimer() {
    if (_ticketData == null) return;
    final expiryStr = _ticketData!['expiry_time']?.toString() ?? _ticketData!['qr_valid_until']?.toString();
    if (expiryStr == null) return;

    final DateTime expiryTime = (DateTime.tryParse(expiryStr) ?? DateTime.now()).toUtc();

    final serverTimeStr = _ticketData!['server_time']?.toString();
    final DateTime serverTime = (serverTimeStr != null 
        ? (DateTime.tryParse(serverTimeStr) ?? DateTime.now()) 
        : DateTime.now()).toUtc();

    final Duration serverOffset = serverTime.difference(DateTime.now().toUtc());

    _countdownTimer?.cancel();

    void updateTick() {
      final nowServer = DateTime.now().toUtc().add(serverOffset);
      final diff = expiryTime.difference(nowServer);

      if (diff.isNegative || diff.inSeconds <= 0) {
        _countdownTimer?.cancel();
        if (mounted) {
          setState(() {
            _remainingTime = Duration.zero;
            _isExpired = true;
          });
          _showExpiredPopup();
        }
      } else {
        if (mounted) {
          setState(() {
            _remainingTime = diff;
            _showReminder30m = diff.inMinutes <= 30;
          });
        }
      }
    }

    updateTick();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      updateTick();
    });
  }

  void _startStatusPolling(String bookingId) {
    _statusCheckTimer?.cancel();
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 4), (timer) async {
      final res = await _visitingService.getVisitStatus(bookingId);
      if (!mounted) return;
      if (res['success'] == true && res['data'] != null) {
        final statusData = res['data'];
        final bookingStatus = statusData['booking_status']?.toString() ?? '';
        final visitStatus = statusData['visit_status']?.toString() ?? '';
        final rejectionReason = statusData['rejection_reason']?.toString();
        final ownerAccepted = statusData['owner_decision']?.toString() == 'Accepted' ||
            bookingStatus == 'Waiting For User Confirmation';

        setState(() {
          _ticketData = {...?_ticketData, ...Map<String, dynamic>.from(statusData)};
          if (ownerAccepted) _isOwnerAccepted = true;
        });

        if (bookingStatus == 'Confirmed' || bookingStatus == 'Payment Completed') {
          timer.cancel();
          _countdownTimer?.cancel();
        } else if (visitStatus == 'Verified' || visitStatus == 'Completed' || bookingStatus == 'QR Verified') {
          if (!_isQrVerified) {
            setState(() {
              _isQrVerified = true;
              _remainingTime = Duration.zero;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: Colors.blue,
                content: Text('QR Verified Successfully by Owner.'),
                duration: Duration(seconds: 3),
              ),
            );
          }
        } else if (ownerAccepted) {
          _countdownTimer?.cancel();
          if (!_isQrVerified) {
            setState(() {
              _isQrVerified = true;
              _remainingTime = Duration.zero;
            });
          }
          if (!_hasShownApprovalDialog) {
            _hasShownApprovalDialog = true;
            _showOwnerDecisionMessage('Booking Accepted', 'The Mahal Owner has accepted your booking request.');
          }
        } else if (bookingStatus == 'Rejected' || statusData['owner_decision'] == 'Rejected') {
          timer.cancel();
          _countdownTimer?.cancel();
          if (!_hasShownRejectionDialog) {
            _hasShownRejectionDialog = true;
            _showOwnerRejectedPopup(rejectionReason);
          }
        } else if (visitStatus == 'Expired' || bookingStatus == 'Cancelled') {
          timer.cancel();
          _countdownTimer?.cancel();
          setState(() {
            _isExpired = true;
            _remainingTime = Duration.zero;
          });
          _showExpiredPopup();
        }
      }
    });
  }

  void _showOwnerDecisionMessage(String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.green, size: 28),
                const SizedBox(width: 10),
                Expanded(
              child: Text(
                title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                Text(
              message,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            SizedBox(height: 10),
          ],
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showOwnerRejectedPopup(String? reason) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.cancel_outlined, color: Colors.red, size: 28),
            SizedBox(width: 10),
            Text("Booking Rejected", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          "Unfortunately,\n\nyour booking request has been rejected by the Mahal Owner.${reason != null && reason.isNotEmpty ? '\nReason: $reason' : ''}\n\nPlease choose another date or another Mahal.",
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamedAndRemoveUntil(context, AppRoutes.homePage, (route) => false);
            },
            child: const Text("CHOOSE ANOTHER MAHAL", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showExpiredPopup() {
    if (_hasShownPopup) return;
    _hasShownPopup = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.error_outline, color: Colors.red, size: 28),
            SizedBox(width: 10),
            Text("QR Expired", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          "Your visiting time has expired.\n\n"
          "Since you did not visit the Mahal before the selected visiting time, "
          "your booking has been cancelled automatically.\n\n"
          "Please make a new booking if required.",
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamedAndRemoveUntil(context, AppRoutes.homePage, (route) => false);
            },
            child: const Text("OK", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatDateOnly(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty || dateStr == '-') return '-';
    String s = dateStr.trim();
    if (s.contains('T')) {
      s = s.split('T')[0];
    }
    if (s.contains(' ')) {
      s = s.split(' ')[0];
    }
    return s;
  }

  String _formatDuration(Duration d) {
    if (d.isNegative || d.inSeconds <= 0) return "00:00:00";
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return "$hours:$minutes:$seconds";
  }

  Future<void> _saveQrPassToGallery() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saving QR Pass to Gallery...')),
      );

      RenderRepaintBoundary? boundary =
          _ticketKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not locate ticket element')),
        );
        return;
      }

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to generate image')),
        );
        return;
      }

      final Uint8List bytes = byteData.buffer.asUint8List();

      await Gal.putImageBytes(
        bytes,
        name: 'Mahal_QR_Pass_${_ticketData?['booking_id'] ?? DateTime.now().millisecondsSinceEpoch}',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text('QR Pass saved to Gallery successfully! 📸'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Error saving to gallery: $e'),
        ),
      );
    }
  }

  void _simulatedAction(String actionName) {
    if (actionName.contains("Download") || actionName.contains("Image") || actionName.contains("Save")) {
      _saveQrPassToGallery();
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.deepOrange,
        content: Text('$actionName triggered successfully!'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        appBar: UserAppBar(title: 'QR Pass', showBack: true),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_ticketData == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        appBar: UserAppBar(title: 'QR Pass', showBack: true),
        body: Center(child: Text("Unable to load QR pass details.")),
      );
    }

    final mahalName = _ticketData!['mahal_name']?.toString() ?? 'Mahal';
    final eventName = _ticketData!['event_name']?.toString() ?? 'Event';
    final bookingId = _ticketData!['booking_id']?.toString() ?? '-';
    final userName = _ticketData!['user_name']?.toString() ?? '-';
    final mblNo = _ticketData!['mbl_no']?.toString() ?? '-';
    final eventDate = _formatDateOnly(_ticketData!['booking_date']?.toString());
    final visitingDate = _formatDateOnly(_ticketData!['visiting_date']?.toString());
    final visitingTime = _ticketData!['visiting_time']?.toString() ?? '-';
    final qrToken = _ticketData!['qr_token']?.toString() ?? 'TOKEN';
    final visitStatus = _ticketData!['visit_status']?.toString() ?? 'Scheduled';
    final bookingStatus = _ticketData!['booking_status']?.toString() ?? _ticketData!['current_b_status']?.toString() ?? 'Pending';
    final ownerDecision = _ticketData!['owner_decision']?.toString() ?? '';

    final routeArgs = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    final amount = _ticketData!['initial_amt']?.toString() ?? routeArgs['amount']?.toString() ?? '0';
    final totalAmount = _ticketData!['total_amt']?.toString() ?? routeArgs['total_amount']?.toString() ?? '0';
    final mahalId = _ticketData!['mahal_id']?.toString() ?? routeArgs['mahal_id']?.toString() ?? '';
    final paymentTime = _ticketData!['payment_time']?.toString() ?? routeArgs['payment_time']?.toString() ?? DateTime.now().toUtc().toIso8601String();
    final bool canPayNow = _isQrVerified
      || _isOwnerAccepted
        || bookingStatus == 'QR Verified'
        || bookingStatus == 'Payment Completed'
        || bookingStatus == 'Confirmed'
        || ownerDecision == 'Accepted';

    return PopScope(
      canPop: false,
      child: Scaffold(
      backgroundColor: AppColors.background,
      appBar: const UserAppBar(title: 'QR Pass', showBack: false),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              // 30 MIN REMINDER BANNER
              if (_showReminder30m && !_isExpired) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade700),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.notifications_active, color: Colors.amber.shade900),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Reminder: Your QR Pass will expire soon. Please visit the Mahal before expiry.",
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
                const SizedBox(height: 16),
              ],

              // LIVE COUNTDOWN TIMER CARD (3 Hours Reverse Countdown)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                    color: _isQrVerified ? Colors.green.shade50 : (_isExpired ? Colors.red.shade50 : Colors.deepOrange.shade50),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isQrVerified ? Colors.green : (_isExpired ? Colors.red : Colors.deepOrange),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      _isQrVerified ? "QR VERIFIED BY OWNER" : (_isExpired ? "QR PASS EXPIRED" : "QR Validity Remaining"),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _isQrVerified ? Colors.green : (_isExpired ? Colors.red : Colors.deepOrange),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Visiting Time: $visitingTime",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.deepOrange.shade900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isQrVerified ? "VERIFIED" : _formatDuration(_remainingTime),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _isQrVerified ? Colors.green.shade900 : (_isExpired ? Colors.red.shade900 : Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // PROFESSIONAL TICKET PASS DESIGN
              RepaintBoundary(
                key: _ticketKey,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // TICKET TOP: MAHAL NAME & EVENT NAME
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.orange, Colors.deepOrange],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              mahalName.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.1,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                "Event: $eventName",
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // TICKET CENTER: QR CODE
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            _isExpired
                                ? Container(
                                    height: 200,
                                    width: 200,
                                    color: Colors.grey.shade200,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: const [
                                        Icon(Icons.block, size: 60, color: Colors.red),
                                        SizedBox(height: 10),
                                        Text(
                                          "EXPIRED",
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : QrImageView(
                                    data: qrToken,
                                    version: QrVersions.auto,
                                    size: 200.0,
                                    backgroundColor: Colors.white,
                                  ),
                            const SizedBox(height: 12),
                            Text(
                              "Status: ${visitStatus.toUpperCase()}",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: visitStatus == 'Completed'
                                    ? Colors.green
                                    : (_isExpired ? Colors.red : Colors.deepOrange),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Divider(indent: 25, endIndent: 25),

                      // TICKET BOTTOM: BOOKING DETAILS
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            _buildDetailRow("Booking ID", "#$bookingId"),
                            _buildDetailRow("User Name", userName),
                            _buildDetailRow("Mobile Number", mblNo),
                            _buildDetailRow("Event Date", eventDate),
                            _buildDetailRow("Visiting Date", visitingDate),
                            _buildDetailRow("Visiting Time", visitingTime),
                            _buildDetailRow("QR Valid Until", visitingTime),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // WARNING / NOTICE NOTIFICATION BOX BELOW TICKET (TAMIL & ENGLISH)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber.shade400, width: 1.5),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "அவசர அறிவிப்பு / Emergency Notice",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "தமிழ்: $visitingDate அன்று $visitingTime மணிக்குள் மஹால் உரிமையாளரிடம் நேரில் சென்று இந்த QR குறியீட்டை ஸ்கேன் செய்ய வேண்டும். குறித்த நேரத்திற்குள் QR குறியீட்டை ஸ்கேன் செய்யவில்லை என்றால், உங்கள் புக்கிங் ரத்து செய்யப்பட்டு நீங்கள் செலுத்திய தொகை 48 மணி நேரத்திற்குள் திருப்பி அளிக்கப்படும் (Refund).",
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              fontWeight: FontWeight.w600,
                              color: Colors.amber.shade900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "English: Please visit the Mahal and scan this QR Code with the Mahal Owner before $visitingTime on $visitingDate. If you do not scan the QR Code before expiry, your booking will be cancelled and your payment will be refunded within 48 hours.",
                            style: TextStyle(
                              fontSize: 12.5,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: canPayNow ? () {
                      Navigator.pushNamed(context, AppRoutes.paymentPage, arguments: {
                        'booking_id': bookingId,
                        'mahal_id': mahalId,
                        'amount': amount,
                        'total_amount': totalAmount,
                        'mahal_name': mahalName,
                        'booking_date': _ticketData!['booking_date'] ?? '',
                        'end_date': _ticketData!['end_date'] ?? '',
                        'event_name': eventName,
                        'booking_type': _ticketData!['booking_type'] ?? '',
                        'event_time': _ticketData!['event_time'] ?? '',
                        'end_time': _ticketData!['end_time'] ?? '',
                        'user_name': userName,
                        'payment_time': paymentTime,
                      });
                    } : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canPayNow ? Colors.deepOrange : Colors.grey.shade400,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.payment),
                    label: Text(canPayNow ? 'Pay Now' : 'Waiting for Owner Approval'),
                  ),
                ),

              const SizedBox(height: 16),

              // ACTION BUTTONS (Download, Share, Save as Image, Save as PDF)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    icon: Icons.download,
                    label: "Download",
                    onTap: () => _simulatedAction("Download QR Pass"),
                  ),
                  _buildActionButton(
                    icon: Icons.share,
                    label: "Share",
                    onTap: () => _simulatedAction("Share QR Pass"),
                  ),
                  _buildActionButton(
                    icon: Icons.image,
                    label: "Save Image",
                    onTap: () => _simulatedAction("Save as Image"),
                  ),
                  _buildActionButton(
                    icon: Icons.picture_as_pdf,
                    label: "Save PDF",
                    onTap: () => _simulatedAction("Save as PDF"),
                  ),
                ],
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.deepOrange, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}
