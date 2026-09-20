import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../models/facility_model.dart';
import '../models/slot_model.dart';
import 'reservation_screen.dart';

class FacilityDetailScreen extends StatefulWidget {
  final int facilityId;

  const FacilityDetailScreen({Key? key, required this.facilityId}) : super(key: key);

  @override
  State<FacilityDetailScreen> createState() => _FacilityDetailScreenState();
}

class _FacilityDetailScreenState extends State<FacilityDetailScreen> {
  FacilityDetailModel? _facility;
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedVehicleFilter = "All";
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
    _autoRefreshTimer = Timer.periodic(const Duration(milliseconds: 2500), (_) {
      _silentRefresh();
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _fetchDetail() async {
    try {
      final detail = await ApiService.getFacilityDetail(widget.facilityId);
      if (mounted) {
        setState(() {
          _facility = detail;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll("Exception: ", "");
        });
      }
    }
  }

  void _silentRefresh() async {
    try {
      final detail = await ApiService.getFacilityDetail(widget.facilityId);
      if (mounted) {
        setState(() {
          _facility = detail;
          _errorMessage = null;
        });
      }
    } catch (_) {}
  }

  void _showServerIpDialog() {
    final controller = TextEditingController(text: ApiService.baseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: const Text("Configure Backend Server IP", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Enter the IP address of your host machine running the FastAPI server:",
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "e.g. http://192.168.0.211:8000",
                prefixIcon: Icon(Icons.dns, color: AppTheme.primary),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final newUrl = controller.text.trim();
              if (newUrl.isNotEmpty) {
                await ApiService.setCustomServerUrl(newUrl);
                if (mounted) {
                  Navigator.pop(ctx);
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _fetchDetail();
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text("Save & Reconnect"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(title: const Text("Loading Facility...")),
        body: const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    if (_facility == null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text("Facility Details"),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: _showServerIpDialog,
            ),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.wifi_off_rounded, color: AppTheme.crimsonRed, size: 54),
                const SizedBox(height: 16),
                const Text(
                  "Unable to Load Facility Details",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage ?? "Connection timed out connecting to ParkEazy server (${ApiService.baseUrl}).",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _isLoading = true;
                          _errorMessage = null;
                        });
                        _fetchDetail();
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text("Retry Connection"),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _showServerIpDialog,
                      icon: const Icon(Icons.settings_rounded, color: Colors.white),
                      label: const Text("Server IP", style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    final filteredSlots = _facility!.slots.where((slot) {
      if (_selectedVehicleFilter == "Car") {
        return slot.slotType.contains("Standard") || slot.slotType.contains("SUV") || slot.slotType.contains("Car");
      } else if (_selectedVehicleFilter == "Bike") {
        return slot.slotType.contains("Bike") || slot.slotType.contains("Compact");
      } else if (_selectedVehicleFilter == "EV Charging") {
        return slot.slotType.contains("EV");
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(_facility!.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchDetail();
            },
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: AppTheme.cardBg,
          border: Border(top: BorderSide(color: AppTheme.cardBorder, width: 1)),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.emeraldGreen.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.emeraldGreen.withOpacity(0.5)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.touch_app_rounded, color: AppTheme.emeraldGreen, size: 22),
              SizedBox(width: 8),
              Text(
                "Tap any Available (Green) Slot on the Map to Reserve",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.emeraldGreen),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Facility Hero Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primary.withOpacity(0.85), AppTheme.primary.withOpacity(0.45)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _facility!.category.toUpperCase(),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.emeraldGreen),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.near_me_rounded, color: Colors.white70, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            "${_facility!.distanceKm} km away",
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _facility!.name,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _facility!.address,
                    style: const TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded, color: Colors.white70, size: 16),
                          const SizedBox(width: 6),
                          Text(_facility!.openingHours, style: const TextStyle(color: Colors.white, fontSize: 12)),
                        ],
                      ),
                      Text(
                        "₹${_facility!.pricePerHour.toStringAsFixed(0)} / hour",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.emeraldGreen),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Availability Quick Stats
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildQuickCount("Total", "${_facility!.totalSlots}", Colors.white),
                      _buildQuickCount("Available", "${_facility!.availableSlots}", AppTheme.emeraldGreen),
                      _buildQuickCount("Occupied", "${_facility!.occupiedSlots}", AppTheme.crimsonRed),
                      _buildQuickCount("Reserved", "${_facility!.reservedSlots}", AppTheme.amberOrange),
                    ],
                  ),
                ),
              ),
            ),

            // Vehicle Type Filter Chips
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
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
            ),

            // Visual Parking Grid Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Visual Parking Layout", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.emeraldGreen.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.emeraldGreen),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.sync, size: 12, color: AppTheme.emeraldGreen),
                        SizedBox(width: 4),
                        Text("YOLO LIVE SYNC", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.emeraldGreen)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 2D Parking Slots Grid
            filteredSlots.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text("No parking slots match the selected vehicle filter.", style: TextStyle(color: AppTheme.textSecondary)),
                    ),
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
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
          ],
        ),
      ),
    );
  }

  Widget _buildQuickCount(String label, String val, Color color) {
    return Column(
      children: [
        Text(val, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon) {
    final isSelected = _selectedVehicleFilter == value;
    return ChoiceChip(
      avatar: Icon(icon, size: 16, color: isSelected ? Colors.black : AppTheme.emeraldGreen),
      label: Text(label),
      selected: isSelected,
      selectedColor: AppTheme.emeraldGreen,
      backgroundColor: AppTheme.cardBg,
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
          _autoRefreshTimer?.cancel();
          Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(
              builder: (_) => ReservationScreen(slot: slot),
            ),
          ).then((_) {
            if (mounted) {
              _autoRefreshTimer?.cancel();
              _autoRefreshTimer = Timer.periodic(const Duration(milliseconds: 2500), (_) {
                _silentRefresh();
              });
              _fetchDetail();
            }
          });
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
