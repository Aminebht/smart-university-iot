import 'package:flutter/material.dart';
import '../../../core/models/department_model.dart';
import '../../../core/models/classroom_model.dart';
import '../../../services/supabase_service.dart';

class DepartmentProvider extends ChangeNotifier {
  DepartmentModel? _department;
  List<ClassroomModel> _classrooms = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  DepartmentModel? get department => _department;
  List<ClassroomModel> get classrooms => _classrooms;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Load department details
  Future<void> loadDepartment(String departmentId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Get department details from departments
      final departmentsJson = await SupabaseService.getDepartments();
      final departmentsList = departmentsJson.map((json) => DepartmentModel.fromJson(json)).toList();
      _department = departmentsList.firstWhere((d) => d.departmentId.toString() == departmentId);
      
      // Load classrooms for this department
      await loadClassrooms(departmentId);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to load department: ${e.toString()}';
      notifyListeners();
    }
  }

  // Load classrooms for a department
  Future<void> loadClassrooms(String departmentId) async {
    try {
      final classroomsJson = await SupabaseService.getClassroomsByDepartment(departmentId);
      _classrooms = classroomsJson.map((json) => ClassroomModel.fromJson(json)).toList();
    } catch (e) {
      _errorMessage = 'Failed to load classrooms: ${e.toString()}';
      throw e;
    }
  }

  // Get classrooms grouped by row
  Map<int, List<ClassroomModel>> getClassroomsByRow() {
    Map<int, List<ClassroomModel>> result = {};
    
    // This is a simplified approach, in a real app you might have a
    // 'row' property in the ClassroomModel to determine its position
    int rowSize = 3; // 3 classrooms per row
    int totalRows = (classrooms.length / rowSize).ceil();
    
    for (int i = 0; i < totalRows; i++) {
      int startIndex = i * rowSize;
      int endIndex = startIndex + rowSize;
      if (endIndex > classrooms.length) endIndex = classrooms.length;
      
      result[i] = classrooms.sublist(startIndex, endIndex);
    }
    
    return result;
  }

  // Clear the data
  void clearData() {
    _department = null;
    _classrooms = [];
    _errorMessage = null;
    notifyListeners();
  }

  // Clear any error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
} 