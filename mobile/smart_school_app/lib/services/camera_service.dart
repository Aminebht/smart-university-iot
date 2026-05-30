import 'package:smart_school/core/models/camera_model.dart';
import 'package:smart_school/core/utils/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/supabase_service.dart';

class CameraService {
  final SupabaseClient _supabaseClient = SupabaseService.getClient();
  final Logger _logger = Logger('CameraService');

  // Get all cameras
  Future<List<CameraModel>> getAllCameras() async {
    try {
      final response = await _supabaseClient
          .from('cameras')
          .select()
          .order('camera_id');
      
      return response.map<CameraModel>((camera) => CameraModel.fromJson(camera)).toList();
    } catch (e, stackTrace) {
      _logger.error('Failed to get all cameras', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  // Get cameras for a specific classroom
  Future<List<CameraModel>> getCamerasForClassroom(int classroomId) async {
    try {
      // Since we know there's no direct classroom_id in cameras table,
      // let's use devices as the bridge between cameras and classrooms
      final response = await _supabaseClient
          .from('cameras')
          .select('*, devices!inner(*)')  // Join with devices that have classroom_id
          .eq('devices.classroom_id', classroomId);
      
      return response.map<CameraModel>((data) {
        // Merge device data with camera data
        final deviceData = data['devices'] ?? {};
        
        // Set up a proper camera object with valid data
        final mergedData = {
          ...data,
          'classroom_id': classroomId,
          // Ensure we have a valid stream URL
          'stream_url': data['stream_url'] ?? 'https://example.com/stream/${data['camera_id']}',
          // Default to active for testing
          'is_active': true,  // Force active for testing until real status is available
        };
        
        return CameraModel.fromJson(mergedData);
      }).toList();
    } catch (e, stackTrace) {
      _logger.error('Failed to get cameras for classroom: $classroomId', error: e, stackTrace: stackTrace);
      
      // For debugging - create a mock camera if no real cameras found
      return [_createMockCamera(classroomId)];
    }
  }

  // Add a method to create a mock camera for testing
  CameraModel _createMockCamera(int classroomId) {
    return CameraModel(
      cameraId: -1,  // Negative ID to indicate mock
      streamUrl: 'http://192.168.0.22:3000/stream', // Public test video
      motionDetectionEnabled: true,
      name: "Test Camera",
      description: "Mock camera for testing",
      classroomId: classroomId,
      isActive: true,  // Always active
      isRecording: false,
    );
  }

  // Get a single camera by ID
  Future<CameraModel?> getCameraById(int cameraId) async {
    try {
      final response = await _supabaseClient
          .from('cameras')
          .select()
          .eq('camera_id', cameraId)
          .single();
      
      return CameraModel.fromJson(response);
    } catch (e, stackTrace) {
      _logger.error('Failed to get camera by id: $cameraId', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  // Update camera status (active, recording, etc.)
  Future<bool> updateCameraStatus(int cameraId, bool isActive) async {
    try {
      await _supabaseClient
          .from('cameras')
          .update({'is_active': isActive})
          .eq('camera_id', cameraId);
      
      return true;
    } catch (e, stackTrace) {
      _logger.error('Failed to update camera status. Camera ID: $cameraId', error: e, stackTrace: stackTrace);
      return false;
    }
  }
}