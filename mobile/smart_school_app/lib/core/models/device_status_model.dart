class DeviceStatusModel {
  final String deviceId;
  final String? roomId;
  final DateTime? lastSeen;
  final String status;
  final String? ipAddress;
  final int? rssi;
  final int? uptimeMs;
  final DateTime updatedAt;

  DeviceStatusModel({
    required this.deviceId,
    this.roomId,
    this.lastSeen,
    required this.status,
    this.ipAddress,
    this.rssi,
    this.uptimeMs,
    required this.updatedAt,
  });

  factory DeviceStatusModel.fromJson(Map<String, dynamic> json) {
    return DeviceStatusModel(
      deviceId: json['device_id'] ?? '',
      roomId: json['room_id'],
      lastSeen: json['last_seen'] != null ? DateTime.parse(json['last_seen']) : null,
      status: json['status'] ?? 'offline',
      ipAddress: json['ip_address'],
      rssi: json['rssi'],
      uptimeMs: json['uptime_ms'],
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'device_id': deviceId,
      'room_id': roomId,
      'last_seen': lastSeen?.toIso8601String(),
      'status': status,
      'ip_address': ipAddress,
      'rssi': rssi,
      'uptime_ms': uptimeMs,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isOnline => status.toLowerCase() == 'online';
}
