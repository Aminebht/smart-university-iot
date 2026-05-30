import 'package:flutter/material.dart';
import '../../../core/models/room_model.dart';
import '../../../core/models/sensor_reading_model.dart';
import '../../../core/models/alert_model.dart';
import '../../../services/supabase_service.dart';

class DashboardProvider extends ChangeNotifier {
  List<RoomModel> _rooms = [];
  List<AlertModel> _recentAlerts = [];
  Map<String, double> _quickStats = {};
  bool _isLoading = false;
  String? _errorMessage;

  List<RoomModel> get rooms => _rooms;
  List<AlertModel> get recentAlerts => _recentAlerts;
  Map<String, double> get quickStats => _quickStats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  DashboardProvider() {
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await loadRooms();
      await calculateQuickStats();
      await loadRecentAlerts();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load dashboard data: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadRooms() async {
    try {
      final roomsJson = await SupabaseService.getRooms();
      _rooms = roomsJson.map((json) => RoomModel.fromJson(json)).toList();
    } catch (e) {
      _errorMessage = 'Failed to load rooms: ${e.toString()}';
    }
  }

  Future<void> calculateQuickStats() async {
    try {
      final sensorReadingsJson = await SupabaseService.getRecentSensorData(limit: 100);
      final readings = sensorReadingsJson
          .map((json) => SensorReadingModel.fromJson(json))
          .where((r) => r.value != null)
          .toList();

      double avgTemperature = _avgForType(readings, 'temperature');
      double avgHumidity = _avgForType(readings, 'humidity');
      double avgGas = _avgForType(readings, 'gas');

      int alertCount = _recentAlerts.where((a) => !a.acknowledged).length;

      _quickStats = {
        'average_temperature': double.parse(avgTemperature.toStringAsFixed(1)),
        'average_humidity': double.parse(avgHumidity.toStringAsFixed(1)),
        'air_quality': double.parse(avgGas.toStringAsFixed(1)),
        'alert_count': alertCount.toDouble(),
      };
    } catch (e) {
      _quickStats = {
        'average_temperature': 0,
        'average_humidity': 0,
        'air_quality': 0,
        'alert_count': 0,
      };
    }
  }

  double _avgForType(List<SensorReadingModel> readings, String type) {
    final filtered = readings.where((r) => r.sensorType.toLowerCase() == type).toList();
    if (filtered.isEmpty) return 0;
    return filtered.map((r) => r.value!).reduce((a, b) => a + b) / filtered.length;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> loadRecentAlerts() async {
    try {
      final alertsJson = await SupabaseService.getRecentAlerts(limit: 5);
      _recentAlerts = alertsJson.map((json) => AlertModel.fromJson(json)).toList();
    } catch (e) {
      // Silently ignore to keep dashboard loading
    }
  }
}