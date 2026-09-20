class ReservationModel {
  final int id;
  final String bookingId;
  final int slotId;
  final String slotNumber;
  final String zone;
  final String vehicleNumber;
  final int hours;
  final double totalAmount;
  final String status;
  final DateTime createdAt;
  final DateTime startTime;
  final DateTime endTime;
  final String paymentTransactionId;

  ReservationModel({
    required this.id,
    required this.bookingId,
    required this.slotId,
    required this.slotNumber,
    required this.zone,
    required this.vehicleNumber,
    required this.hours,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    required this.startTime,
    required this.endTime,
    required this.paymentTransactionId,
  });

  factory ReservationModel.fromJson(Map<String, dynamic> json) {
    return ReservationModel(
      id: json['id'],
      bookingId: json['booking_id'],
      slotId: json['slot_id'],
      slotNumber: json['slot_number'] ?? 'A1',
      zone: json['zone'] ?? 'Zone A',
      vehicleNumber: json['vehicle_number'],
      hours: json['hours'],
      totalAmount: (json['total_amount'] as num).toDouble(),
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      paymentTransactionId: json['payment_transaction_id'] ?? 'TXN-PARK-001',
    );
  }
}
