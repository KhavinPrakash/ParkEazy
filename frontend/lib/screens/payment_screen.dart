import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/slot_model.dart';
import '../services/api_service.dart';
import 'acknowledgement_screen.dart';

class PaymentScreen extends StatefulWidget {
  final ParkingSlotModel slot;
  final int hours;
  final String vehicleNumber;
  final double totalAmount;

  const PaymentScreen({
    Key? key,
    required this.slot,
    required this.hours,
    required this.vehicleNumber,
    required this.totalAmount,
  }) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedPaymentMethod = "UPI (Google Pay / PhonePe)";
  bool _isProcessing = false;

  void _processPayment() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final reservation = await ApiService.createReservation(
        slotId: widget.slot.id,
        vehicleNumber: widget.vehicleNumber,
        hours: widget.hours,
        paymentMethod: _selectedPaymentMethod,
      );

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => AcknowledgementScreen(reservation: reservation),
          ),
          (route) => route.isFirst,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll("Exception: ", "")),
            backgroundColor: AppTheme.crimsonRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("ParkEazy Payment Portal"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Amount Summary Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primary.withOpacity(0.8), AppTheme.primary.withOpacity(0.4)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text("TOTAL PAYMENT DUE", style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1)),
                  const SizedBox(height: 6),
                  Text(
                    "₹${widget.totalAmount.toStringAsFixed(2)}",
                    style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Slot ${widget.slot.slotNumber} (${widget.slot.zone}) • ${widget.hours} hour(s)",
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              "Select Payment Method",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),

            // UPI Option
            _buildPaymentOption(
              title: "UPI (Google Pay / PhonePe / Paytm / BHIM)",
              subtitle: "Instant payment using UPI ID or QR",
              icon: Icons.qr_code_2_rounded,
              value: "UPI (Google Pay / PhonePe)",
            ),
            const SizedBox(height: 10),

            // Credit / Debit Card Option
            _buildPaymentOption(
              title: "Credit / Debit Card",
              subtitle: "Visa, Mastercard, RuPay",
              icon: Icons.credit_card_rounded,
              value: "Credit / Debit Card",
            ),
            const SizedBox(height: 10),

            // NetBanking Option
            _buildPaymentOption(
              title: "Net Banking",
              subtitle: "SBI, HDFC, ICICI, Axis Bank",
              icon: Icons.account_balance_rounded,
              value: "NetBanking",
            ),
            const SizedBox(height: 28),

            // Secure Gateway Badge
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock, color: AppTheme.emeraldGreen, size: 16),
                SizedBox(width: 6),
                Text(
                  "256-Bit SSL Encrypted Secure Gateway",
                  style: TextStyle(fontSize: 12, color: AppTheme.emeraldGreen),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Pay Now Button
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.emeraldGreen,
                  foregroundColor: Colors.black,
                ),
                child: _isProcessing
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)),
                          SizedBox(width: 12),
                          Text("Processing Payment...", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      )
                    : Text(
                        "Pay ₹${widget.totalAmount.toStringAsFixed(2)} Now",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
  }) {
    final isSelected = _selectedPaymentMethod == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? AppTheme.emeraldGreen : AppTheme.cardBorder, width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.emeraldGreen.withOpacity(0.2) : Colors.white10,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isSelected ? AppTheme.emeraldGreen : AppTheme.textSecondary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                  Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: _selectedPaymentMethod,
              activeColor: AppTheme.emeraldGreen,
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedPaymentMethod = val);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
