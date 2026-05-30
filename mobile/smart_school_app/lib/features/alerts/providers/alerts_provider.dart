import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/models/alert_model.dart';
import '../../../services/supabase_service.dart';

class AlertsProvider extends ChangeNotifier {
  List<AlertModel> _alerts = [];
  List<AlertModel> _recentAlerts = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription? _alertSub;

  List<AlertModel> get alerts => _alerts;
  List<AlertModel> get recentAlerts => _recentAlerts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AlertsProvider() {
    loadRecentAlerts();
    _subscribeToAlerts();
  }

  void _subscribeToAlerts() {
    _alertSub = SupabaseService.streamAlerts().listen((data) {
      // On new alert data, reload recent alerts
      loadRecentAlerts();
      loadAlerts(showLoading: false);
    }, onError: (e) {
      // Silently handle realtime errors
    });
  }

  @override
  void dispose() {
    _alertSub?.cancel();
    super.dispose();
  }

  Future<void> loadAlerts({
    int limit = 50,
    String? roomId,
    bool showLoading = true,
  }) async {
    if (showLoading) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final alertsJson = await SupabaseService.getAlerts(
        roomId: roomId,
        limit: limit,
      );

      _alerts = alertsJson.map((json) => AlertModel.fromJson(json)).toList();

      if (showLoading) {
        _isLoading = false;
      }
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load alerts: ${e.toString()}';
      if (showLoading) _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadRecentAlerts({int limit = 5, bool showLoading = false}) async {
    if (showLoading) {
      _isLoading = true;
      notifyListeners();
    }
    try {
      final alertsJson = await SupabaseService.getRecentAlerts(limit: limit);
      _recentAlerts = alertsJson.map((json) => AlertModel.fromJson(json)).toList();
      if (showLoading) _isLoading = false;
      notifyListeners();
    } catch (e) {
      if (showLoading) _isLoading = false;
    }
  }

  Future<bool> acknowledgeAlert(int alertId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final success = await SupabaseService.acknowledgeAlert(alertId);
      if (success) {
        _updateAlertAckStatus(alertId);
      }
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = 'Error acknowledging alert: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void _updateAlertAckStatus(int alertId) {
    for (int i = 0; i < _alerts.length; i++) {
      if (_alerts[i].id == alertId) {
        _alerts[i] = AlertModel(
          id: _alerts[i].id,
          roomId: _alerts[i].roomId,
          alertType: _alerts[i].alertType,
          severity: _alerts[i].severity,
          message: _alerts[i].message,
          personCount: _alerts[i].personCount,
          timestamp: _alerts[i].timestamp,
          acknowledged: true,
          createdAt: _alerts[i].createdAt,
        );
        break;
      }
    }
    for (int i = 0; i < _recentAlerts.length; i++) {
      if (_recentAlerts[i].id == alertId) {
        _recentAlerts[i] = AlertModel(
          id: _recentAlerts[i].id,
          roomId: _recentAlerts[i].roomId,
          alertType: _recentAlerts[i].alertType,
          severity: _recentAlerts[i].severity,
          message: _recentAlerts[i].message,
          personCount: _recentAlerts[i].personCount,
          timestamp: _recentAlerts[i].timestamp,
          acknowledged: true,
          createdAt: _recentAlerts[i].createdAt,
        );
        break;
      }
    }
  }
}