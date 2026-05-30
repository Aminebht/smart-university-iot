import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/models/camera_model.dart';

class CameraProvider extends ChangeNotifier {
  bool _isFullscreen = false;
  bool _isRecording = false;
  bool _isPanning = false;
  bool _isLoading = false;
  double _zoomLevel = 1.0;
  String _recordingDuration = "00:00";
  Timer? _recordingTimer;
  int _recordingSeconds = 0;
  String? _errorMessage;
  CameraModel? _camera;

  // Getters
  bool get isFullscreen => _isFullscreen;
  bool get isRecording => _isRecording;
  bool get isPanning => _isPanning;
  bool get isLoading => _isLoading;
  double get zoomLevel => _zoomLevel;
  String get recordingDuration => _recordingDuration;
  String? get errorMessage => _errorMessage;
  CameraModel? get camera => _camera;

  Future<void> loadCamera(int cameraId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      // Here you would typically call an API or service to fetch camera details
      await Future.delayed(const Duration(seconds: 1));
      
      // Create a CameraModel object with the fixed stream URL
      _camera = CameraModel(
        cameraId: cameraId,
        name: 'Camera $cameraId',
        streamUrl: 'http://192.168.0.22:3000/stream',
        isActive: true,
        description: 'Classroom camera',
        motionDetectionEnabled: true,
        isRecording: false
      );
      
      _isLoading = false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to load camera: ${e.toString()}';
    }
    
    notifyListeners();
  }
  
  void toggleFullscreen() {
    _isFullscreen = !_isFullscreen;
    notifyListeners();
  }
  
  void togglePan() {
    _isPanning = !_isPanning;
    notifyListeners();
  }
  
  void zoomIn() {
    if (_zoomLevel < 5.0) { // Maximum zoom level
      _zoomLevel += 0.5;
      notifyListeners();
    }
  }
  
  void zoomOut() {
    if (_zoomLevel > 1.0) { // Minimum zoom level
      _zoomLevel -= 0.5;
      notifyListeners();
    }
  }
  
  void toggleRecording() {
    _isRecording = !_isRecording;
    
    if (_isRecording) {
      // Start recording timer
      _recordingSeconds = 0;
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _recordingSeconds++;
        final minutes = (_recordingSeconds ~/ 60).toString().padLeft(2, '0');
        final seconds = (_recordingSeconds % 60).toString().padLeft(2, '0');
        _recordingDuration = "$minutes:$seconds";
        notifyListeners();
      });
    } else {
      // Stop recording timer
      _recordingTimer?.cancel();
      _recordingTimer = null;
      _recordingDuration = "00:00";
    }
    
    notifyListeners();
  }
  
  void takeSnapshot() {
    // Implement snapshot capture logic
    print('Taking snapshot');
  }
  
  @override
  void dispose() {
    _recordingTimer?.cancel();
    super.dispose();
  }
}