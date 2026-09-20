import 'slot_model.dart';

class FacilityModel {
  final int id;
  final String name;
  final String category;
  final String address;
  final double distanceKm;
  final double pricePerHour;
  final String openingHours;
  final bool isOpen;
  final String imageCategory;
  final String cameraId;
  final int totalSlots;
  final int availableSlots;
  final int occupiedSlots;
  final int reservedSlots;

  FacilityModel({
    required this.id,
    required this.name,
    required this.category,
    required this.address,
    required this.distanceKm,
    required this.pricePerHour,
    required this.openingHours,
    required this.isOpen,
    required this.imageCategory,
    required this.cameraId,
    required this.totalSlots,
    required this.availableSlots,
    required this.occupiedSlots,
    required this.reservedSlots,
  });

  factory FacilityModel.fromJson(Map<String, dynamic> json) {
    return FacilityModel(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      address: json['address'],
      distanceKm: (json['distance_km'] as num).toDouble(),
      pricePerHour: (json['price_per_hour'] as num).toDouble(),
      openingHours: json['opening_hours'] ?? "24/7 Open",
      isOpen: json['is_open'] ?? true,
      imageCategory: json['image_category'] ?? "mall",
      cameraId: json['camera_id'] ?? "CAM-01-NORTH",
      totalSlots: json['total_slots'] ?? 10,
      availableSlots: json['available_slots'] ?? 0,
      occupiedSlots: json['occupied_slots'] ?? 0,
      reservedSlots: json['reserved_slots'] ?? 0,
    );
  }
}

class FacilityDetailModel extends FacilityModel {
  final List<ParkingSlotModel> slots;

  FacilityDetailModel({
    required int id,
    required String name,
    required String category,
    required String address,
    required double distanceKm,
    required double pricePerHour,
    required String openingHours,
    required bool isOpen,
    required String imageCategory,
    required String cameraId,
    required int totalSlots,
    required int availableSlots,
    required int occupiedSlots,
    required int reservedSlots,
    required this.slots,
  }) : super(
          id: id,
          name: name,
          category: category,
          address: address,
          distanceKm: distanceKm,
          pricePerHour: pricePerHour,
          openingHours: openingHours,
          isOpen: isOpen,
          imageCategory: imageCategory,
          cameraId: cameraId,
          totalSlots: totalSlots,
          availableSlots: availableSlots,
          occupiedSlots: occupiedSlots,
          reservedSlots: reservedSlots,
        );

  factory FacilityDetailModel.fromJson(Map<String, dynamic> json) {
    final List slotsJson = json['slots'] ?? [];
    return FacilityDetailModel(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      address: json['address'],
      distanceKm: (json['distance_km'] as num).toDouble(),
      pricePerHour: (json['price_per_hour'] as num).toDouble(),
      openingHours: json['opening_hours'] ?? "24/7 Open",
      isOpen: json['is_open'] ?? true,
      imageCategory: json['image_category'] ?? "mall",
      cameraId: json['camera_id'] ?? "CAM-01-NORTH",
      totalSlots: json['total_slots'] ?? 10,
      availableSlots: json['available_slots'] ?? 0,
      occupiedSlots: json['occupied_slots'] ?? 0,
      reservedSlots: json['reserved_slots'] ?? 0,
      slots: slotsJson.map((item) => ParkingSlotModel.fromJson(item)).toList(),
    );
  }
}
