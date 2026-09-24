import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../routes/app_routes.dart';
import '../../services/payment_service.dart';
import '../../services/booking_service.dart';
import '../../widgets/user_app_bar.dart';
import 'widgets/booking_info_card.dart';
import 'widgets/card_payment_section.dart';
import 'widgets/payment_header.dart';
import 'widgets/payment_method_tile.dart';
import 'widgets/pay_now_button.dart';
import 'widgets/security_note.dart';
import 'widgets/upi_section.dart';

enum PaymentMethod { upi, card }

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  PaymentMethod selectedMethod = PaymentMethod.upi;
  bool showUpiSection = false;
  bool showCardSection = false;
  bool _isLoading = false;

  final TextEditingController upiController = TextEditingController();
  final TextEditingController cardHolderController = TextEditingController();
  final TextEditingController cardNumberController = TextEditingController();
  final TextEditingController expiryController = TextEditingController();
  final TextEditingController cvvController = TextEditingController();

  final PaymentService _paymentService = PaymentService();
  final BookingService _bookingService = BookingService();

  @override
  void dispose() {
    upiController.dispose();
    cardHolderController.dispose();
    cardNumberController.dispose();
    expiryController.dispose();
    cvvController.dispose();
    super.dispose();
  }

  void updateMethod(PaymentMethod method) {
    setState(() {
      selectedMethod = method;
      showUpiSection = false;
      showCardSection = false;
    });
  }

  void handlePayNow() {
    setState(() {
      showUpiSection = false;
      showCardSection = false;

      if (selectedMethod == PaymentMethod.upi) {
        showUpiSection = true;
      } else if (selectedMethod == PaymentMethod.card) {
        showCardSection = true;
      }
    });
  }

  void _processPayment(String method, String transactionId) async {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String? bookingId = args['booking_id']?.toString();

      // If booking was not created yet (user came from booking form), create it now before payment
      if (bookingId == null || bookingId.isEmpty) {
        final bookingResult = await _bookingService.createBooking(
          mahalId: args['mahal_id']?.toString() ?? '1',
          bookingDate: args['booking_date']?.toString() ?? '',
          endDate: args['end_date']?.toString() ?? '',
          eventName: args['event_name']?.toString() ?? '',
          bookingType: args['booking_type']?.toString() ?? '',
          eventTime: args['event_time']?.toString() ?? '',
          endTime: args['end_time']?.toString() ?? '',
          totalAmt: args['total_amount']?.toString() ?? '',
          initialAmt: args['amount']?.toString() ?? '',
        );

        if (bookingResult['success'] != true) {
          if (!mounted) return;
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                bookingResult['message'] ?? 'Booking Creation Failed',
              ),
            ),
          );
          return;
        }

        bookingId =
            (bookingResult['data']?['booking_id'] ??
                    bookingResult['data']?['_id'] ??
                    bookingResult['booking_id'] ??
                    bookingResult['_id'])
                ?.toString();
      }

      if (bookingId == null || bookingId.isEmpty) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Invalid Booking ID')));
        return;
      }

      final result = await _paymentService.processPayment(
        bookingId: bookingId,
        amount: args['amount']?.toString() ?? '1000',
        paymentMethod: method,
        transactionId: transactionId,
        mahalId: args['mahal_id']?.toString(),
      );

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      if (result['success'] == true) {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Expanded(child: Text('Booking Completed')),
              ],
            ),
            content: const Text(
              'Payment successful. Your booking date is confirmed and added to the Mahal calendar.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.homePage,
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Payment Failed')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Payment Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final amount = args?['amount']?.toString() ?? '1000';
    final totalAmount = args?['total_amount']?.toString() ?? '0';
    final mahalName = args?['mahal_name']?.toString() ?? 'Mahal';
    final userName = args?['user_name']?.toString() ?? 'User';
    final rawBookingDate = args?['booking_date']?.toString() ?? 'Selected Date';

    String formattedBookingDate = rawBookingDate;
    if (rawBookingDate != 'Selected Date') {
      try {
        final parsed = DateTime.parse(rawBookingDate);
        formattedBookingDate =
            '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
      } catch (e) {
        // Fallback to original if parse fails
      }
    }

    final int total = int.tryParse(totalAmount) ?? 0;
    final int initial = int.tryParse(amount) ?? 1000;
    final int remaining = total - initial;

    final double width = MediaQuery.of(context).size.width;
    final double contentWidth = width > 500 ? 500 : width;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const UserAppBar(title: 'Payment', showBack: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const PaymentHeader(title: 'Payment Details'),
                  const SizedBox(height: 24),
                  BookingInfoCard(
                    userName: userName,
                    mahalName: mahalName,
                    bookingDate: formattedBookingDate,
                    initialAmount: '₹$initial',
                    remainingAmount: '₹${remaining > 0 ? remaining : 0}',
                    totalAmount: '₹$total',
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Payment Method',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: PaymentMethodTile(
                          title: 'UPI',
                          icon: Icons.qr_code,
                          isSelected: selectedMethod == PaymentMethod.upi,
                          onTap: () => updateMethod(PaymentMethod.upi),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: PaymentMethodTile(
                          title: 'Card',
                          icon: Icons.credit_card,
                          isSelected: selectedMethod == PaymentMethod.card,
                          onTap: () => updateMethod(PaymentMethod.card),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    PayNowButton(onTap: handlePayNow),
                  if (showUpiSection) ...[
                    const SizedBox(height: 28),
                    UpiSection(
                      controller: upiController,
                      onProceed: () => _processPayment(
                        'UPI',
                        'upi_txn_${DateTime.now().millisecondsSinceEpoch}',
                      ),
                    ),
                  ],
                  if (showCardSection) ...[
                    const SizedBox(height: 28),
                    CardPaymentSection(
                      cardHolderController: cardHolderController,
                      cardNumberController: cardNumberController,
                      expiryController: expiryController,
                      cvvController: cvvController,
                      onProceed: () => _processPayment(
                        'CARD',
                        'card_txn_${DateTime.now().millisecondsSinceEpoch}',
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  const SecurityNote(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
