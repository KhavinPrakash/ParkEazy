class SMSLogModel {
  final int id;
  final String phoneNumber;
  final String message;
  final DateTime sentAt;
  final String status;

  SMSLogModel({
    required this.id,
    required this.phoneNumber,
    required this.message,
    required this.sentAt,
    required this.status,
  });

  factory SMSLogModel.fromJson(Map<String, dynamic> json) {
    return SMSLogModel(
      id: json['id'],
      phoneNumber: json['phone_number'],
      message: json['message'],
      sentAt: DateTime.parse(json['sent_at']),
      status: json['status'],
    );
  }
}
