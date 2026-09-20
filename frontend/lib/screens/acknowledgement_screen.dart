import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../theme/app_theme.dart';
import '../models/reservation_model.dart';
import '../services/api_service.dart';

class AcknowledgementScreen extends StatelessWidget {
  final ReservationModel reservation;

  const AcknowledgementScreen({Key? key, required this.reservation}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = ApiService.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("Booking Confirmation & Pass"),
        automaticallyImplyLeading: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Success Icon Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.emeraldGreen.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: AppTheme.emeraldGreen, size: 64),
            ),
            const SizedBox(height: 14),
            const Text(
              "Parking Slot Reserved!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 6),
            const Text(
              "Your payment was successful and your slot is locked.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),

            // SMS Notification Receipt Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.primary.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.sms_rounded, color: AppTheme.primary, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "SMS Acknowledgement Sent!",
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Sent to registered mobile: ${user?.phoneNumber ?? 'Mobile Number'}",
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.check, color: AppTheme.emeraldGreen, size: 18),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Digital Parking Ticket Card with QR Code
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Column(
                children: [
                  const Text("DIGITAL PARKING TICKET", style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, letterSpacing: 1.5)),
                  const SizedBox(height: 12),

                  // QR Code
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: QrImageView(
                      data: reservation.bookingId,
                      version: QrVersions.auto,
                      size: 160.0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "ID: ${reservation.bookingId}",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primary),
                  ),
                  const Divider(height: 32, color: AppTheme.cardBorder),

                  // Ticket Details
                  _buildTicketRow("Assigned Slot", "${reservation.slotNumber} (${reservation.zone})"),
                  _buildTicketRow("Vehicle Number", reservation.vehicleNumber),
                  _buildTicketRow("Duration", "${reservation.hours} hour(s)"),
                  _buildTicketRow("Total Paid", "₹${reservation.totalAmount.toStringAsFixed(2)}"),
                  _buildTicketRow("Transaction ID", reservation.paymentTransactionId),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Navigation Button & Home Button
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Launching Google Maps Navigation to Slot ${reservation.slotNumber}..."),
                          backgroundColor: AppTheme.primary,
                        ),
                      );
                    },
                    icon: const Icon(Icons.navigation_rounded, color: Colors.white),
                    label: const Text("Navigate"),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      }
                    },
                    icon: const Icon(Icons.home_rounded, color: Colors.white),
                    label: const Text("Done", style: TextStyle(color: Colors.white)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.cardBorder),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
