import 'package:flutter/material.dart';
import '../../../core/models/student_model.dart';
import '../../../core/models/attendance_model.dart';
import '../../../services/supabase_service.dart';

class AttendanceProvider extends ChangeNotifier {
  List<AttendanceModel> _attendanceRecords = [];
  List<StudentModel> _students = [];
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  String? _errorMessage;
  
  // Getters
  List<AttendanceModel> get attendanceRecords => _attendanceRecords;
  List<StudentModel> get students => _students;
  DateTime get selectedDate => _selectedDate;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  // Set selected date and fetch attendance records
  Future<void> setSelectedDate(DateTime date) async {
    _selectedDate = date;
    await loadAttendanceData();
  }
  
  // Load attendance data for the selected date
  Future<void> loadAttendanceData() async {
    _isLoading = true;
    _errorMessage = null;
    
    // Schedule notification for after the frame completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
    
    try {
      final attendanceData = await SupabaseService.getAttendanceByDate(_selectedDate);
      
      _attendanceRecords = attendanceData
          .map((data) => AttendanceModel.fromJson(data))
          .toList();
      
      _isLoading = false;
      
      // Schedule notification for after any ongoing build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } catch (e) {
      _errorMessage = 'Failed to load attendance data: ${e.toString()}';
      _isLoading = false;
      
      // Schedule notification for after any ongoing build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }
  
  // Load all students
  Future<void> loadStudents() async {
    _isLoading = true;
    
    // Schedule notification for after the frame completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
    
    try {
      final studentsData = await SupabaseService.getStudents();
      
      _students = studentsData
          .map((data) => StudentModel.fromJson(data))
          .toList();
      
      _isLoading = false;
      
      // Schedule notification for after any ongoing build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } catch (e) {
      _errorMessage = 'Failed to load students: ${e.toString()}';
      _isLoading = false;
      
      // Schedule notification for after any ongoing build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }
  
  // Record student attendance
  Future<bool> recordAttendance(int studentId) async {
    try {
      final success = await SupabaseService.recordAttendance(studentId, _selectedDate);
      
      if (success) {
        // Reload attendance data to reflect the changes
        await loadAttendanceData();
      }
      
      return success;
    } catch (e) {
      _errorMessage = 'Failed to record attendance: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
  
  // Get attendance percentage for the selected date
  double getAttendancePercentage() {
    if (_students.isEmpty) return 0;
    return _attendanceRecords.length / _students.length * 100;
  }
  
  // Check if a student is present on the selected date
  bool isStudentPresent(int studentId) {
    return _attendanceRecords.any((record) => record.studentId == studentId);
  }
}