class AttendanceModel {
  final int attendanceId;
  final int studentId;
  final DateTime attendanceDate;
  final DateTime checkInTime;
  final String studentName; // For displaying in the UI
  
  AttendanceModel({
    required this.attendanceId,
    required this.studentId,
    required this.attendanceDate,
    required this.checkInTime,
    required this.studentName,
  });
  
  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      attendanceId: json['attendance_id'],
      studentId: json['student_id'],
      attendanceDate: DateTime.parse(json['attendance_date']),
      checkInTime: DateTime.parse(json['check_in_time']),
      studentName: json['student_name'] ?? 'Unknown Student',
    );
  }
}