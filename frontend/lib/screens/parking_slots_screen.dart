import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../models/slot_model.dart';
import 'reservation_screen.dart';

class ParkingSlotsScreen extends StatefulWidget {
  const ParkingSlotsScreen({Key? key}) : super(key: key);

  @override
  State<ParkingSlotsScreen> createState() => _ParkingSlotsScreenState();
}

class _ParkingSlotsScreenState extends State<ParkingSlotsScreen> {
  List<ParkingSlotModel> _slots = [];
  bool _isLoading = true;
  String _selectedZone = "All";
  String _selectedVehicleFilter = "All"; // Filter: All, Car, Bike, EV Charging
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchSlots();
    // Auto-refresh slot occupancy every 2.5 seconds to reflect YOLO vehicle exit events in real-time!
    _autoRefreshTimer = Timer.periodic(const Duration(milliseconds: 2500), (_) {
      _silentRefreshSlots();
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _fetchSlots() async {
    try {
      final slots = await ApiService.getParkingSlots();
      if (mounted) {
        setState(() {
          _slots = slots;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _silentRefreshSlots() async {
    try {
      final slots = await ApiService.getParkingSlots();
      if (mounted) {
        setState(() {
          _slots = slots;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final filteredSlots = _slots.where((slot) {
      final matchesZone = _selectedZone == "All" || slot.zone.contains(_selectedZone);

      bool matchesVehicle = true;
      if (_selectedVehicleFilter == "Car") {
        matchesVehicle = slot.slotType.contains("Standard") || slot.slotType.contains("SUV") || slot.slotType.contains("Car");
      } else if (_selectedVehicleFilter == "Bike") {
        matchesVehicle = slot.slotType.contains("Bike") || slot.slotType.contains("Compact");
      } else if (_selectedVehicleFilter == "EV Charging") {
        matchesVehicle = slot.slotType.contains("EV");
      }

      return matchesZone && matchesVehicle;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Row(
          children: [
            const Text("Book Parking Slot"),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.emeraldGreen.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.emeraldGreen, width: 1),
              ),
              child: const Row(
                children: [
                  Icon(Icons.sync_rounded, size: 12, color: AppTheme.emeraldGreen),
                  SizedBox(width: 4),
                  Text("YOLO LIVE SYNC", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.emeraldGreen)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchSlots();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : Column(
              children: [
                // Vehicle Type Filter Bar (Car, Bike, EV Charging)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: AppTheme.cardBg,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Vehicle Type Filter",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip("All Vehicles", "All", Icons.apps_rounded),
                            const SizedBox(width: 8),
                            _buildFilterChip("Car", "Car", Icons.directions_car_rounded),
                            const SizedBox(width: 8),
                            _buildFilterChip("Bike", "Bike", Icons.two_wheeler_rounded),
                            const SizedBox(width: 8),
                            _buildFilterChip("EV Charging", "EV Charging", Icons.ev_station_rounded),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Zone Filter Chips & Legend
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: AppTheme.background,
                  child: Row(
                    children: [
                      _buildZoneChip("All Zones", "All"),
                      const SizedBox(width: 6),
                      _buildZoneChip("Zone A", "Zone A"),
                      const SizedBox(width: 6),
                      _buildZoneChip("Zone B", "Zone B"),
                    ],
                  ),
                ),

                // Map Legend
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildLegendItem("Available", AppTheme.emeraldGreen),
                      _buildLegendItem("Occupied", AppTheme.crimsonRed),
                      _buildLegendItem("Reserved", AppTheme.amberOrange),
                    ],
                  ),
                ),

                // 2D Parking Grid View
                Expanded(
                  child: filteredSlots.isEmpty
                      ? const Center(
                          child: Text(
                            "No parking slots match the selected filter.",
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () async => _fetchSlots(),
                          child: GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 1.25,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                            ),
                            itemCount: filteredSlots.length,
                            itemBuilder: (context, index) {
                              final slot = filteredSlots[index];
                              return _buildSlotCard(slot);
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon) {
    final isSelected = _selectedVehicleFilter == value;
    return ChoiceChip(
      avatar: Icon(icon, size: 18, color: isSelected ? Colors.black : AppTheme.emeraldGreen),
      label: Text(label),
      selected: isSelected,
      selectedColor: AppTheme.emeraldGreen,
      backgroundColor: AppTheme.background,
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : Colors.white,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedVehicleFilter = value;
          });
        }
      },
    );
  }

  Widget _buildZoneChip(String label, String value) {
    final isSelected = _selectedZone == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppTheme.primary,
      backgroundColor: AppTheme.cardBg,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppTheme.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedZone = value;
          });
        }
      },
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
      ],
    );
  }

  Widget _buildSlotCard(ParkingSlotModel slot) {
    Color cardColor;
    Color borderColor;
    IconData statusIcon;

    if (slot.status == "Available") {
      cardColor = AppTheme.emeraldGreen.withOpacity(0.12);
      borderColor = AppTheme.emeraldGreen;
      statusIcon = Icons.event_available;
    } else if (slot.status == "Occupied") {
      cardColor = AppTheme.crimsonRed.withOpacity(0.12);
      borderColor = AppTheme.crimsonRed;
      statusIcon = Icons.directions_car_filled;
    } else {
      cardColor = AppTheme.amberOrange.withOpacity(0.12);
      borderColor = AppTheme.amberOrange;
      statusIcon = Icons.lock_clock;
    }

    return GestureDetector(
      onTap: () {
        if (slot.status == "Available") {
          Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(
              builder: (_) => ReservationScreen(slot: slot),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: slot.status == "Occupied" ? AppTheme.crimsonRed : AppTheme.amberOrange,
              content: Row(
                children: [
                  Icon(
                    slot.status == "Occupied" ? Icons.directions_car_filled : Icons.lock_clock,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      slot.status == "Occupied"
                          ? "Slot ${slot.slotNumber} is Occupied${slot.currentVehicle != null ? ' by ${slot.currentVehicle}' : ''}. Select an Available slot."
                          : "Slot ${slot.slotNumber} is currently Reserved. Select an Available slot.",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: borderColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    slot.slotNumber,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                Icon(statusIcon, color: borderColor, size: 20),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slot.slotType,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  slot.zone,
                  style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "₹${slot.pricePerHour.toStringAsFixed(0)}/hr",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.emeraldGreen,
                  ),
                ),
                Text(
                  slot.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: borderColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
