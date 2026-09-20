class ParkingSlotModel {
  final int id;
  final String slotNumber;
  final String zone;
  final String slotType;
  final String floor;
  final String status;
  final double pricePerHour;
  final int xPos;
  final int yPos;
  final String? currentVehicle;

  ParkingSlotModel({
    required this.id,
    required this.slotNumber,
    required this.zone,
    required this.slotType,
    required this.floor,
    required this.status,
    required this.pricePerHour,
    required this.xPos,
    required this.yPos,
    this.currentVehicle,
  });

  factory ParkingSlotModel.fromJson(Map<String, dynamic> json) {
    return ParkingSlotModel(
      id: json['id'],
      slotNumber: json['slot_number'],
      zone: json['zone'],
      slotType: json['slot_type'],
      floor: json['floor'],
      status: json['status'],
      pricePerHour: (json['price_per_hour'] as num).toDouble(),
      xPos: json['x_pos'] ?? 0,
      yPos: json['y_pos'] ?? 0,
      currentVehicle: json['current_vehicle'],
    );
  }
}
