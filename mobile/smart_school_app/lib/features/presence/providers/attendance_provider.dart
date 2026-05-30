import 'package:flutter/material.dart';
import '../../../core/models/student_model.dart';
import '../../../core/models/attendance_model.dart';
import '../../../services/supabase_service.dart';

class AttendanceProvider extends ChangeNotifier {
  List<AttendanceModel> _attendanceRecords = [];
  List<StudentModel> _students = [];
  String _selectedRoomId = 'salle1';
  bool _isLoading = false;
  String? _errorMessage;

  List<AttendanceModel> get attendanceRecords => _attendanceRecords;
  List<StudentModel> get students => _students;
  String get selectedRoomId => _selectedRoomId;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void setRoom(String roomId) {
    _selectedRoomId = roomId;
    loadAttendanceData();
  }

  Future<void> loadAttendanceData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final attendanceData = await SupabaseService.getAttendanceForRoom(_selectedRoomId, limit: 100);
      _attendanceRecords = attendanceData.map((data) => AttendanceModel.fromJson(data)).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load attendance data: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadStudents() async {
    _isLoading = true;
    notifyListeners();

    try {
      final studentsData = await SupabaseService.getStudents();
      _students = studentsData.map((data) => StudentModel.fromJson(data)).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load students: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  double getAttendancePercentage() {
    if (_students.isEmpty) return 0;
    return _attendanceRecords.length / _students.length * 100;
  }

  bool isStudentPresent(int? studentId) {
    if (studentId == null) return false;
    return _attendanceRecords.any((record) => record.studentId == studentId);
  }
}