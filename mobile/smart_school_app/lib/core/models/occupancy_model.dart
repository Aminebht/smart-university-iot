class OccupancyModel {
  final int id;
  final String roomId;
  final int personCount;
  final double? confidence;
  final DateTime timestamp;
  final DateTime createdAt;

  OccupancyModel({
    required this.id,
    required this.roomId,
    required this.personCount,
    this.confidence,
    required this.timestamp,
    required this.createdAt,
  });

  factory OccupancyModel.fromJson(Map<String, dynamic> json) {
    return OccupancyModel(
      id: json['id'] ?? 0,
      roomId: json['room_id'] ?? '',
      personCount: json['person_count'] ?? 0,
      confidence: json['confidence'] != null ? (json['confidence'] as num).toDouble() : null,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_id': roomId,
      'person_count': personCount,
      'confidence': confidence,
      'timestamp': timestamp.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  double get occupancyPercent {
    // Simple heuristic: assume room capacity 30 if not known
    return (personCount / 30.0).clamp(0.0, 1.0);
  }
}
