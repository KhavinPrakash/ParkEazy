import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/slot_model.dart';
import '../services/api_service.dart';
import 'payment_screen.dart';

class ReservationScreen extends StatefulWidget {
  final ParkingSlotModel slot;

  const ReservationScreen({Key? key, required this.slot}) : super(key: key);

  @override
  State<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  int _selectedHours = 2;
  late TextEditingController _vehicleController;

  @override
  void initState() {
    super.initState();
    final user = ApiService.currentUser;
    _vehicleController = TextEditingController(text: user?.vehicleNumber ?? "");
  }

  double get _totalPrice => widget.slot.pricePerHour * _selectedHours;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text("Reserve Slot ${widget.slot.slotNumber}"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Slot Detail Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.emeraldGreen.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      widget.slot.slotNumber,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.emeraldGreen,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${widget.slot.zone} • ${widget.slot.floor}",
                          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.slot.slotType,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Rate: ₹${widget.slot.pricePerHour.toStringAsFixed(0)} / hour",
                          style: const TextStyle(fontSize: 14, color: AppTheme.emeraldGreen, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Vehicle Details
            const Text(
              "Vehicle Details",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _vehicleController,
              decoration: const InputDecoration(
                hintText: "Enter Vehicle Plate No. (e.g. KA-01-MJ-4821)",
                prefixIcon: Icon(Icons.directions_car, color: AppTheme.textSecondary),
              ),
            ),
            const SizedBox(height: 24),

            // Duration Selector (Hours)
            const Text(
              "Select Parking Duration",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [1, 2, 3, 4, 6, 8].map((hours) {
                final isSelected = _selectedHours == hours;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedHours = hours;
                    });
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primary : AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.cardBorder),
                    ),
                    child: Center(
                      child: Text(
                        "${hours}h",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),

            // Pricing Summary Card (Rupee ₹)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primary.withOpacity(0.5)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Base Rate", style: TextStyle(color: AppTheme.textSecondary)),
                      Text("₹${widget.slot.pricePerHour.toStringAsFixed(2)} / hr", style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Duration", style: TextStyle(color: AppTheme.textSecondary)),
                      Text("$_selectedHours hour(s)", style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                  const Divider(height: 24, color: AppTheme.cardBorder),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Total Payable Amount", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text(
                        "₹${_totalPrice.toStringAsFixed(2)}",
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.emeraldGreen),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Proceed to Payment Portal Button
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  final vehicle = _vehicleController.text.trim();
                  if (vehicle.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please enter your vehicle number")),
                    );
                    return;
                  }

                  Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(
                      builder: (_) => PaymentScreen(
                        slot: widget.slot,
                        hours: _selectedHours,
                        vehicleNumber: vehicle,
                        totalAmount: _totalPrice,
                      ),
                    ),
                  );
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Proceed to Payment Portal", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
