import 'package:flutter/material.dart';
import '../../../core/models/classroom_model.dart';
import '../../../core/models/sensor_model.dart'; // Add this for SensorModel
import '../../../core/models/actuator_model.dart'; // Add this for ActuatorModel
import '../../../core/models/sensor_reading_model.dart';
import '../../../core/constants/app_constants.dart'; // Add this for DeviceStatus enum
import '../../../services/supabase_service.dart';

class ClassroomProvider extends ChangeNotifier {
  ClassroomModel? _classroom;
  List<SensorReadingModel> _sensorData = [];
  bool _isLoading = false;
  bool _isLoadingData = false;
  String? _errorMessage;
  String? _selectedSensorType;
  String _selectedTimeRange = '24 hours';
  
  // Getters
  ClassroomModel? get classroom => _classroom;
  List<SensorReadingModel> get sensorData => _sensorData;
  bool get isLoading => _isLoading;
  bool get isLoadingData => _isLoadingData;
  String? get errorMessage => _errorMessage;
  String? get selectedSensorType => _selectedSensorType;
  String get selectedTimeRange => _selectedTimeRange;
  
  // Available time ranges for filtering data
  final List<String> availableTimeRanges = [
    '1 hour',
    '6 hours',
    '24 hours',
    '7 days',
    '30 days',
  ];

  // Load classroom details
  Future<void> loadClassroom(String classroomId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('🔄 Loading classroom with ID: $classroomId');
      final classroomJson = await SupabaseService.getClassroomDetails(classroomId);
      print('✅ Classroom JSON data received');
      
      // Debug the actuators data directly from the JSON
      if (classroomJson['actuators'] != null) {
        print('🔌 Actuators in JSON: ${classroomJson['actuators'].length}');
      } else {
        print('⚠️ No actuators in JSON response');
      }
      
      try {
        _classroom = ClassroomModel.fromJson(classroomJson);
        print('✅ Classroom model created successfully');
        print('📋 Classroom: $_classroom');
        
        // Debug actuators in the created model
        print('🔌 Actuators count in model: ${_classroom?.actuators.length ?? 0}');
      } catch (e) {
        print('❌ Error creating ClassroomModel: $e');
        print('❌ Stack trace: ${StackTrace.current}');
        _errorMessage = 'Failed to parse classroom data: ${e.toString()}';
        _isLoading = false;
        notifyListeners();
        return;
      }
      
      // If we have sensor readings, set the initial selected sensor type
      final sensorTypes = getAvailableSensorTypes();
      print('📊 Available sensor types: $sensorTypes');
      
      if (sensorTypes.isNotEmpty) {
        _selectedSensorType = sensorTypes.first;
        print('📊 Selected sensor type: $_selectedSensorType');
        
        try {
          await loadSensorData(classroomId, _selectedSensorType!);
          print('✅ Sensor data loaded successfully');
        } catch (e) {
          print('❌ Error loading sensor data: $e');
          _errorMessage = 'Failed to load sensor data: ${e.toString()}';
          // Continue with classroom data even if sensor data fails
        }
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('❌ Error in loadClassroom: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      _isLoading = false;
      _errorMessage = 'Failed to load classroom: ${e.toString()}';
      notifyListeners();
    }
  }

  // Get all available sensor types from readings
  List<String> getAvailableSensorTypes() {
    if (_classroom == null || _classroom!.sensorReadings.isEmpty) {
      print('⚠️ No classroom or sensor readings available');
      return [];
    }
    
    final types = <String>{};
    print('🔍 Getting sensor types from ${_classroom!.sensorReadings.length} readings');
    
    for (var reading in _classroom!.sensorReadings) {
      print('📊 Reading sensor type: ${reading.sensorType} (${reading.sensorType.runtimeType})');
      types.add(reading.sensorType);
    }
    
    print('✅ Found ${types.length} unique sensor types: $types');
    return types.toList();
  }

  // Set selected sensor type
  void setSelectedSensorType(String type) {
    _selectedSensorType = type;
    notifyListeners();
  }

  // Set selected time range
  void setSelectedTimeRange(String range) {
    _selectedTimeRange = range;
    notifyListeners();
  }

  // Load sensor data for a specific sensor type
  Future<void> loadSensorData(String classroomId, String sensorType) async {
    _isLoadingData = true;
    notifyListeners();

    try {
      final limit = _getDataLimitFromTimeRange();
      final readings = await SupabaseService.getSensorReadings(
        classroomId,
        sensorType,
        limit: limit,
      );
      
      _sensorData = readings.map((json) => SensorReadingModel.fromJson(json)).toList();
      _isLoadingData = false;
      notifyListeners();
    } catch (e) {
      _isLoadingData = false;
      _errorMessage = 'Failed to load sensor data: ${e.toString()}';
      notifyListeners();
    }
  }

  // Toggle device state (on/off)
  Future<void> toggleDevice(String actuatorId, bool isOn) async {
    try {
      if (_classroom == null) {
        _errorMessage = 'Classroom data not available';
        notifyListeners();
        return;
      }

      // Find the actuator directly by actuatorId
      final actuatorIndex = _classroom!.actuators.indexWhere(
        (a) => a.actuatorId.toString() == actuatorId
      );
      
      if (actuatorIndex == -1) {
        _errorMessage = 'Actuator not found';
        notifyListeners();
        return;
      }
      
      // Get actuator and its device ID
      final actuator = _classroom!.actuators[actuatorIndex];
      final deviceId = actuator.deviceId.toString();
      
      // Call service to toggle the device state
      await SupabaseService.toggleDeviceAndActuator(deviceId, actuatorId, isOn);
      
      // Update local state immediately to reflect UI change
      final updatedActuator = ActuatorModel(
        actuatorId: actuator.actuatorId,
        deviceId: actuator.deviceId,
        actuatorType: actuator.actuatorType,
        currentState: isOn ? "on" : "off", // Set state based on toggle value
        createdAt: actuator.createdAt,
        updatedAt: DateTime.now(),
        status: actuator.status, // Keep existing status
        name: actuator.name,
        settings: actuator.settings, // Preserve existing settings
      );
      
      // Update actuator in the list
      _classroom!.actuators[actuatorIndex] = updatedActuator;
      notifyListeners();
      
    } catch (e) {
      _errorMessage = 'Failed to toggle device: ${e.toString()}';
      notifyListeners();
    }
  }

  // Update device value (for dimmable lights, fans, etc.)
  Future<void> updateDeviceValue(String actuatorId, double value) async {
    try {
      if (_classroom == null) {
        _errorMessage = 'Classroom data not available';
        notifyListeners();
        return;
      }

      // Find the actuator directly by actuatorId
      final actuatorIndex = _classroom!.actuators.indexWhere(
        (a) => a.actuatorId.toString() == actuatorId
      );
      
      if (actuatorIndex == -1) {
        _errorMessage = 'Actuator not found';
        notifyListeners();
        return;
      }
      
      // Get actuator
      final actuator = _classroom!.actuators[actuatorIndex];
      
      // Determine what setting to update based on actuator type
      String settingKey;
      if (actuator.actuatorType.toLowerCase() == 'light') {
        settingKey = 'brightness';
      } else if (actuator.actuatorType.toLowerCase() == 'fan') {
        settingKey = 'speed';
      } else {
        _errorMessage = 'Unsupported actuator type';
        notifyListeners();
        return;
      }
      
      // Create updated settings - ensure we preserve existing settings
      final updatedSettings = Map<String, dynamic>.from(actuator.settings);
      updatedSettings[settingKey] = value.round();
      
      // Update local state immediately to reflect UI change
      final updatedActuator = ActuatorModel(
        actuatorId: actuator.actuatorId,
        deviceId: actuator.deviceId,
        actuatorType: actuator.actuatorType,
        currentState: actuator.currentState,
        createdAt: actuator.createdAt,
        updatedAt: DateTime.now(),
        status: actuator.status,
        name: actuator.name,
        settings: updatedSettings,
      );
      
      // Update actuator in the list immediately for UI responsiveness
      _classroom!.actuators[actuatorIndex] = updatedActuator;
      notifyListeners();
      
      // Call service to update the actuator settings
      await SupabaseService.updateActuatorSettings(
        actuator.actuatorId.toString(), 
        updatedSettings
      );
      
    } catch (e) {
      _errorMessage = 'Failed to update device value: ${e.toString()}';
      notifyListeners();
    }
  }

  // Calculate data limit based on selected time range
  int _getDataLimitFromTimeRange() {
    switch (_selectedTimeRange) {
      case '1 hour':
        return 60; // One reading per minute
      case '6 hours':
        return 72; // One reading per 5 minutes
      case '24 hours':
        return 96; // One reading per 15 minutes
      case '7 days':
        return 168; // One reading per hour
      case '30 days':
        return 240; // One reading per 3 hours
      default:
        return 100;
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}