import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../models/reservation_model.dart';
import '../models/sms_model.dart';
import 'login_screen.dart';
import 'acknowledgement_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ReservationModel> _bookings = [];
  List<SMSLogModel> _smsLogs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  void _loadData() async {
    try {
      final bookings = await ApiService.getMyBookings();
      final sms = await ApiService.getMySMSLogs();
      if (mounted) {
        setState(() {
          _bookings = bookings;
          _smsLogs = sms;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _openPassFromSMS(SMSLogModel sms) {
    ReservationModel? matched;
    for (final b in _bookings) {
      if (b.bookingId.isNotEmpty && sms.message.contains(b.bookingId)) {
        matched = b;
        break;
      }
    }

    if (matched == null) {
      final RegExp regExp = RegExp(r'Booking ID:\s*([A-Z0-9-]+)');
      final match = regExp.firstMatch(sms.message);
      final bookingId = match?.group(1) ?? 'PRK-${sms.id}';

      final RegExp slotExp = RegExp(r'Slot:\s*([A-Z0-9]+)\s*\(([^)]+)\)');
      final slotMatch = slotExp.firstMatch(sms.message);
      final slotNumber = slotMatch?.group(1) ?? 'A1';
      final zone = slotMatch?.group(2) ?? 'Zone A';

      final RegExp vehicleExp = RegExp(r'Vehicle:\s*([A-Z0-9-]+)');
      final vehicleMatch = vehicleExp.firstMatch(sms.message);
      final vehicleNumber = vehicleMatch?.group(1) ?? 'TN-01-AB-1234';

      final RegExp durationExp = RegExp(r'Duration:\s*(\d+)hr');
      final durationMatch = durationExp.firstMatch(sms.message);
      final hours = int.tryParse(durationMatch?.group(1) ?? '2') ?? 2;

      final RegExp paidExp = RegExp(r'Paid:\s*Rs\.?([0-9.]+)');
      final paidMatch = paidExp.firstMatch(sms.message);
      final totalAmount = double.tryParse(paidMatch?.group(1) ?? '80.0') ?? 80.0;

      matched = ReservationModel(
        id: sms.id,
        bookingId: bookingId,
        slotId: 1,
        slotNumber: slotNumber,
        zone: zone,
        vehicleNumber: vehicleNumber,
        hours: hours,
        totalAmount: totalAmount,
        status: "Active",
        createdAt: sms.sentAt,
        startTime: sms.sentAt,
        endTime: sms.sentAt.add(Duration(hours: hours)),
        paymentTransactionId: "TXN-PARK-SMS${sms.id}",
      );
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AcknowledgementScreen(reservation: matched!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ApiService.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("My Profile & Bookings"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppTheme.crimsonRed),
            onPressed: () async {
              await ApiService.logout();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : Column(
              children: [
                // User Card
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: AppTheme.primary.withOpacity(0.2),
                        child: Text(
                          (user?.fullName.isNotEmpty == true) ? user!.fullName[0].toUpperCase() : "U",
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primary),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.fullName ?? "User",
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            Text(
                              user?.email ?? "",
                              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.phone_android, size: 14, color: AppTheme.emeraldGreen),
                                const SizedBox(width: 4),
                                Text(
                                  user?.phoneNumber ?? "",
                                  style: const TextStyle(fontSize: 12, color: AppTheme.emeraldGreen, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Tabs: Bookings vs SMS Logs
                TabBar(
                  controller: _tabController,
                  indicatorColor: AppTheme.primary,
                  labelColor: AppTheme.primary,
                  unselectedLabelColor: AppTheme.textSecondary,
                  tabs: const [
                    Tab(icon: Icon(Icons.confirmation_number), text: "My Bookings"),
                    Tab(icon: Icon(Icons.sms), text: "SMS Acknowledgements"),
                  ],
                ),

                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Bookings Tab
                      _bookings.isEmpty
                          ? const Center(
                              child: Text("No booking history found.", style: TextStyle(color: AppTheme.textSecondary)),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _bookings.length,
                              itemBuilder: (context, index) {
                                final b = _bookings[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => AcknowledgementScreen(reservation: b),
                                        ),
                                      );
                                    },
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.all(14),
                                      leading: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppTheme.emeraldGreen.withOpacity(0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          b.slotNumber,
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.emeraldGreen),
                                        ),
                                      ),
                                      title: Text("Booking ${b.bookingId}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                      subtitle: Text("${b.zone} • ${b.hours}hr(s) • ${b.vehicleNumber}\nPaid: ₹${b.totalAmount.toStringAsFixed(2)}", style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                                      trailing: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: b.status == "Active" ? AppTheme.emeraldGreen.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              b.status,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: b.status == "Active" ? AppTheme.emeraldGreen : Colors.grey,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.qr_code_rounded, color: AppTheme.primary, size: 12),
                                              SizedBox(width: 2),
                                              Text("Pass", style: TextStyle(fontSize: 10, color: AppTheme.primary, fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),

                      // SMS Logs Tab
                      _smsLogs.isEmpty
                          ? const Center(
                              child: Text("No SMS logs dispatched yet.", style: TextStyle(color: AppTheme.textSecondary)),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _smsLogs.length,
                              itemBuilder: (context, index) {
                                final sms = _smsLogs[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () => _openPassFromSMS(sms),
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  const Icon(Icons.sms_outlined, color: AppTheme.primary, size: 18),
                                                  const SizedBox(width: 6),
                                                  Text(sms.phoneNumber, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                                ],
                                              ),
                                              Row(
                                                children: [
                                                  Text(sms.status, style: const TextStyle(color: AppTheme.emeraldGreen, fontSize: 11, fontWeight: FontWeight.bold)),
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: AppTheme.primary.withOpacity(0.2),
                                                      borderRadius: BorderRadius.circular(8),
                                                      border: Border.all(color: AppTheme.primary.withOpacity(0.4)),
                                                    ),
                                                    child: const Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Icon(Icons.qr_code_rounded, color: AppTheme.primary, size: 12),
                                                        SizedBox(width: 4),
                                                        Text("View Pass", style: TextStyle(fontSize: 10, color: AppTheme.primary, fontWeight: FontWeight.bold)),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(sms.message, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                                          const SizedBox(height: 10),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: AppTheme.cardBorder.withOpacity(0.3),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Row(
                                              children: [
                                                Icon(Icons.touch_app_rounded, color: AppTheme.primary, size: 14),
                                                SizedBox(width: 6),
                                                Text(
                                                  "Tap message to view digital QR Pass",
                                                  style: TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.w600),
                                                ),
                                              ],
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
                ),
              ],
            ),
    );
  }
}
