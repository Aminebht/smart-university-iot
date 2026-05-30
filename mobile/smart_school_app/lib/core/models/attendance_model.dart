class AttendanceModel {
  final int id;
  final String roomId;
  final String tagId;
  final int? studentId;
  final DateTime timestamp;
  final String status;
  final DateTime createdAt;
  // Enriched from join
  final String? studentName;

  AttendanceModel({
    required this.id,
    required this.roomId,
    required this.tagId,
    this.studentId,
    required this.timestamp,
    required this.status,
    required this.createdAt,
    this.studentName,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    String? name;
    if (json['students'] != null) {
      name = json['students']['name']?.toString();
    } else if (json['student_name'] != null) {
      name = json['student_name'].toString();
    }

    return AttendanceModel(
      id: json['id'] ?? 0,
      roomId: json['room_id'] ?? '',
      tagId: json['tag_id'] ?? '',
      studentId: json['student_id'],
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      status: json['status'] ?? 'unknown',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      studentName: name,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_id': roomId,
      'tag_id': tagId,
      'student_id': studentId,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}