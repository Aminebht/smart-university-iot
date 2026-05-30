import 'package:smart_school/core/models/alarm_rule_model.dart';
import 'package:smart_school/core/models/classroom_model.dart';
import 'package:smart_school/core/models/department_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/app_constants.dart';

class SupabaseService {
  // Add this static client property
  static late SupabaseClient client;
  
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
    
    // Initialize the client
    client = Supabase.instance.client;
  }

    static SupabaseClient getClient() {
    return client;
  }
  
  // Authentication methods
  static Future<void> signIn(String email, String password) async {
    await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }
  
  static Future<void> signOut() async {
    await client.auth.signOut();
  }
  
  static Future<void> resetPassword(String email) async {
    await client.auth.resetPasswordForEmail(email);
  }
  
  static User? getCurrentUser() {
    return client.auth.currentUser;
  }
  
  static Stream<AuthState> authStateChanges() {
    return client.auth.onAuthStateChange;
  }
  
  // Sensor data methods
  static Future<List<Map<String, dynamic>>> getSensorReadings(
      String classroomId, String sensorType, {int limit = 20}) async {
    try {
      // First, get the classroom details which includes devices and sensors
      final classroom = await getClassroomDetails(classroomId);
      
      if (classroom['sensors'] == null || !(classroom['sensors'] is List) || 
          (classroom['sensors'] as List).isEmpty) {
        return [];
      }
      
      final sensors = classroom['sensors'] as List<dynamic>;
      
      // Filter sensors by type
      final filteredSensors = sensors.where((s) => s['sensor_type'] == sensorType).toList();
      
      if (filteredSensors.isEmpty) {
        return [];
      }
      
      // Get sensor IDs
      final sensorIds = filteredSensors.map((s) => s['sensor_id']).toList();
      
      if (sensorIds.isEmpty) {
        return [];
      }
      
      // Get readings for these sensors
      final readings = await client
          .from('sensor_readings')
          .select('*')
          .filter('sensor_id', 'in', sensorIds)
          .order('timestamp', ascending: false)
          .limit(limit);
      
      // Add sensor_type to each reading if it doesn't already have one
      for (var reading in readings) {
        // If sensor_type is null, find which sensor this reading belongs to
        if (reading['sensor_type'] == null) {
          for (var sensor in filteredSensors) {
            if (sensor['sensor_id'] == reading['sensor_id']) {
              reading['sensor_type'] = sensor['sensor_type'] ?? sensorType;
              break;
            }
          }
          
          // If we still couldn't find the sensor type, use the requested sensorType
          if (reading['sensor_type'] == null) {
            reading['sensor_type'] = sensorType;
          }
        }
      }
      
      return readings;
    } catch (e) {
      print('Error in getSensorReadings: $e');
      return [];
    }
  }
  
  static Stream<List<Map<String, dynamic>>> streamSensorReadings(String classroomId) {
    return client
        .from('sensor_readings')
        .stream(primaryKey: ['id'])
        .eq('classroom_id', classroomId);
  }
  
  // Get recent sensor readings across all classrooms
  static Future<List<Map<String, dynamic>>> getRecentSensorReadings({int limit = 100}) async {
    final client = await getClient();
    
    try {
      // Get the most recent readings, joining with sensors to get sensor types
      final response = await client
        .from('sensor_readings')
        .select('''
          *,
          sensors:sensor_id (
            sensor_id,
            sensor_type,
            measurement_unit
          )
        ''')
        .order('timestamp', ascending: false)
        .limit(limit);
        
      // Process the response to flatten the structure
      return (response as List).map((item) {
        final sensor = item['sensors'] as Map<String, dynamic>;
        return {
          'reading_id': item['reading_id'],
          'sensor_id': item['sensor_id'],
          'value': item['value'],
          'timestamp': item['timestamp'],
          'sensor_type': sensor['sensor_type'],
          'unit': sensor['measurement_unit'],
        };
      }).toList();
    } catch (e) {
      print('Error getting recent sensor readings: $e');
      return [];
    }
  }
  
  // Device control methods
  static Future<void> updateDeviceState(String deviceId, bool state) async {
    // Convert boolean to the expected string status value
    final String statusValue = state ? 'online' : 'offline';
    
    await client
        .from('devices')
        .update({'status': statusValue})  // Use string value instead of boolean
        .eq('device_id', deviceId);
  }
  
  static Future<void> updateDeviceValue(String deviceId, double value) async {
    await client
        .from('devices')
        .update({'value': value})
        .eq('device_id', deviceId);
  }
  
  static Future<void> toggleActuator(String actuatorId, bool isOn) async {
    final client = await getClient();
    
    try {
      // Get existing actuator to preserve settings
      final response = await client
        .from('actuators')
        .select('settings')
        .eq('actuator_id', actuatorId)
        .single();
        
      Map<String, dynamic> settings = {};
      if (response != null && response['settings'] != null) {
        settings = Map<String, dynamic>.from(response['settings']);
      }
      
      // Update with preserved settings
      await client
        .from('actuators')
        .update({
          'current_state': isOn ? 'on' : 'off',
          'settings': settings, // Preserve existing settings
          'updated_at': DateTime.now().toIso8601String()
        })
        .eq('actuator_id', actuatorId);
    } catch (e) {
      print('Error toggling actuator: $e');
      throw e;
    }
  }
  
  static Future<void> toggleDeviceAndActuator(String deviceId, String actuatorId, bool isOn) async {
    // Start a transaction to update both records
    try {
      // Update device status
      await updateDeviceState(deviceId, isOn);
      
      // Update actuator state
      if (actuatorId.isNotEmpty) {
        await toggleActuator(actuatorId, isOn);
      }
    } catch (e) {
      print('Error toggling device and actuator: $e');
      throw e;
    }
  }
  
  static Future<void> updateActuatorSettings(String actuatorId, Map<String, dynamic> settings) async {
    final client = await getClient();
    
    try {
      await client
        .from('actuators')
        .update({
          'settings': settings,
          'updated_at': DateTime.now().toIso8601String()
        })
        .eq('actuator_id', actuatorId);
        
    } catch (e) {
      print('Error updating actuator settings: $e');
      throw Exception('Failed to update actuator settings: $e');
    }
  }
  

  
  static Future<List<Map<String, dynamic>>> getClassroomsByDepartment(String departmentId) async {
    final response = await client
        .from('classrooms')
        .select('*')
        .eq('department_id', departmentId);
    
    return response;
  }
  
  static Future<Map<String, dynamic>> getClassroomDetails(String classroomId) async {
    try {
      print('🔍 Fetching classroom details for ID: $classroomId');
      
      // Get the classroom base details
      final classroom = await client
          .from('classrooms')
          .select('*')
          .eq('classroom_id', classroomId)
          .single();
      
      print('📊 Base classroom data: $classroom');
      
      // Get the devices for the classroom
      final devices = await client
          .from('devices')
          .select('*')
          .eq('classroom_id', classroomId);
      
      print('🔌 Devices: ${devices.length} found');
      
      // Get device IDs for this classroom
      final deviceIds = devices.map((device) => device['device_id']).toList();
      print('🆔 Device IDs: $deviceIds');
      
      // Get sensors and actuators using device_id
      List<Map<String, dynamic>> sensors = [];
      if (deviceIds.isNotEmpty) {
        try {
          sensors = await client
              .from('sensors')
              .select('*')
              .filter('device_id', 'in', deviceIds);
          print('📡 Sensors: ${sensors.length} found');
          
          // Debug each sensor's fields
          for (var i = 0; i < sensors.length; i++) {
            print('📡 Sensor $i: ${sensors[i]}');
          }
        } catch (e) {
          print('❌ Error fetching sensors: $e');
        }
      }
      
      List<Map<String, dynamic>> actuators = [];
      if (deviceIds.isNotEmpty) {
        try {
          actuators = await client
              .from('actuators')
              .select('*')
              .filter('device_id', 'in', deviceIds);
          print('🎮 Actuators: ${actuators.length} found');
        } catch (e) {
          print('❌ Error fetching actuators: $e');
        }
      }
      
      List<Map<String, dynamic>> cameras = [];
      if (deviceIds.isNotEmpty) {
        try {
          cameras = await client
              .from('cameras')
              .select('*')
              .filter('device_id', 'in', deviceIds);
          
          print('📷 Cameras: ${cameras.length} found');
          
          // Print raw camera data for debugging
          print('📷 Raw cameras data: $cameras');
          
          // Add a verification step to check and handle null values
          for (var camera in cameras) {
            // Check for null stream_url and set a default if needed
            if (camera['stream_url'] == null) {
              print('⚠️ Found null stream_url in camera ${camera['camera_id']}');
              camera['stream_url'] = ''; // Set to empty string instead of null
            }
          }
          
          // Debug each camera to find the problematic one
          for (var i = 0; i < cameras.length; i++) {
            print('📷 Camera $i: ${cameras[i]}');
            
            // Ensure stream_url is not null
            if (cameras[i]['stream_url'] == null) {
              print('⚠️ Warning: Camera $i has null stream_url. Setting default value.');
              cameras[i]['stream_url'] = '';
            }
          }
        } catch (e) {
          print('❌ Error fetching cameras: $e');
        }
      }
      
      // Get sensor readings
      final sensorIds = sensors.map((sensor) => sensor['sensor_id']).toList();
      print('🆔 Sensor IDs: $sensorIds');
      
      List<Map<String, dynamic>> readings = [];
      if (sensorIds.isNotEmpty) {
        try {
          readings = await client
              .from('sensor_readings')
              .select('*')
              .filter('sensor_id', 'in', sensorIds)
              .order('timestamp', ascending: false)
              .limit(50);
          
          print('📈 Readings: ${readings.length} found');
          
          // Enhance sensor readings with sensor type
          for (var i = 0; i < readings.length; i++) {
            var reading = readings[i];
            print('📊 Before enhancement - Reading $i: $reading');
            
            // Find the sensor for this reading
            final sensorId = reading['sensor_id'];
            final sensor = sensors.firstWhere(
              (s) => s['sensor_id'] == sensorId,
              orElse: () => {'sensor_type': 'unknown'}
            );
            
            print('🔍 Matching sensor for reading $i: $sensor');
            
            // Add the sensor type to the reading
            reading['sensor_type'] = sensor['sensor_type'] ?? 'unknown';
            print('📊 After enhancement - Reading $i: $reading');
          }
        } catch (e) {
          print('❌ Error fetching readings: $e');
        }
      }
      
      // Combine all the data
      classroom['devices'] = devices;
      classroom['sensors'] = sensors;
      classroom['actuators'] = actuators;
      classroom['cameras'] = cameras;
      classroom['sensor_readings'] = readings;
      
      print('🏫 Final classroom data structure keys: ${classroom.keys.toList()}');
      return classroom;
    } catch (e) {
      print('❌ Error in getClassroomDetails: $e');
      print('❌ Error stack trace: ${StackTrace.current}');
      throw e;
    }
  }
  
  // Get occupancy data for classrooms
  static Future<List<Map<String, dynamic>>> getOccupancyData() async {
    final client = await getClient();
    
    try {
      // Query classrooms with their latest motion sensor readings
      final classroomsResponse = await client
        .from('classrooms')
        .select('classroom_id, name, capacity');
        
      List<Map<String, dynamic>> classrooms = List<Map<String, dynamic>>.from(classroomsResponse);
      List<Map<String, dynamic>> result = [];
      
      // For each classroom, determine if it's occupied based on motion sensor readings
      for (var classroom in classrooms) {
        // Get the devices associated with this classroom
        final devicesResponse = await client
          .from('devices')
          .select('device_id')
          .eq('classroom_id', classroom['classroom_id'])
          .eq('device_type', 'sensor');
          
        List<Map<String, dynamic>> devices = List<Map<String, dynamic>>.from(devicesResponse);
        bool isOccupied = false;
        
        for (var device in devices) {
          // Get any motion sensors for this device
          final sensorResponse = await client
            .from('sensors')
            .select('sensor_id')
            .eq('device_id', device['device_id'])
            .eq('sensor_type', 'motion');
            
          List<Map<String, dynamic>> motionSensors = List<Map<String, dynamic>>.from(sensorResponse);
          
          // Check if any motion sensors detected movement in the last 15 minutes
          for (var sensor in motionSensors) {
            final DateTime fifteenMinutesAgo = DateTime.now().subtract(const Duration(minutes: 15));
            
            final readingResponse = await client
              .from('sensor_readings')
              .select('value')
              .eq('sensor_id', sensor['sensor_id'])
              .gt('timestamp', fifteenMinutesAgo.toIso8601String())
              .eq('value', 1) // Motion detected
              .limit(1);
              
            if ((readingResponse as List).isNotEmpty) {
              isOccupied = true;
              break;
            }
          }
          
          if (isOccupied) break;
        }
        
        result.add({
          'classroom_id': classroom['classroom_id'],
          'name': classroom['name'],
          'capacity': classroom['capacity'],
          'is_occupied': isOccupied,
        });
      }
      
      return result;
    } catch (e) {
      print('Error getting occupancy data: $e');
      return [];
    }
  }
  
  // Alert methods
  static Future<List<Map<String, dynamic>>> getAlerts({
  int limit = 20, 
  String? severity,
  bool? resolved,
}) async {
  final client = await getClient();
  try {
    // Start with the base query - using proper join syntax
    var query = client
        .from('alerts')
        .select('''
          *,
          devices:device_id (
            model, 
            location
          )
        ''')
        ;
    
    // Apply filters
    if (severity != null) {
      query = query.eq('severity', severity);
    }
    
    if (resolved != null) {
      query = query.eq('resolved', resolved);
    }
    
    // Apply order and limit at the end
    final data = await query
        .order('timestamp', ascending: false)
        .limit(limit);
    
    // Debug the data before returning
    if (data is List && data.isNotEmpty) {
      print('First alert data structure:');
      data[0].forEach((key, value) {
        print('  $key: ${value.runtimeType} = $value');
      });
    }
    
    return List<Map<String, dynamic>>.from(data);
  } catch (e) {
    print('Error fetching alerts: $e');
    throw Exception('Failed to fetch alerts: $e');
  }
}

static Future<List<Map<String, dynamic>>> getRecentAlerts({int limit = 5}) async {
  final client = await getClient();
  try {
    String query = '*';
    
    // Check if devices table exists before adding the join
    try {
      await client.from('devices').select('model').limit(1);
      query = '*,devices:device_id(model,location)';
    } catch (e) {
      print('Warning: devices table might be missing, proceeding without join');
    }
    
    // Use the modified query
    final data = await client
        .from('alerts')
        .select(query)
        .order('timestamp', ascending: false)
        .limit(limit);
    
    return List<Map<String, dynamic>>.from(data);
  } catch (e) {
    print('Error fetching recent alerts: $e');
    throw Exception('Failed to fetch recent alerts: $e');
  }
}

// Mark an alert as resolved
static Future<bool> resolveAlert(int alertId) async {
  final client = await getClient();
  try {
    // Get current timestamp for the resolved_at field
    final now = DateTime.now().toIso8601String();
    
    // Get current user ID
    final userId = client.auth.currentUser?.id;
    
    // Update the alert in the database
    final response = await client
        .from('alerts')
        .update({
          'resolved': true,
          'resolved_at': now,
          'resolved_by_user_id': userId,
        })
        .eq('alert_id', alertId);
    
    print('Alert $alertId marked as resolved by user $userId');
    return true;
  } catch (e) {
    print('Error resolving alert: $e');
    return false;
  }
}

  // Camera feed URL
  static String getCameraFeedUrl(String cameraId) {
    return '$supabaseUrl/edge/v1/camera-stream?camera_id=$cameraId';
  }

  static getCameraDetails(int cameraId) {}

  // Get all security devices with their status
  static Future<List<Map<String, dynamic>>> getSecurityDevices() async {
    final client = await getClient();
    
    try {
      // First get security-related devices
      final response = await client
        .from('devices')
        .select('''
          *,
          classrooms:classroom_id (
            classroom_id,
            name
          )
        ''')
        .inFilter('device_type', ['door_lock', 'window_sensor', 'motion_sensor', 'camera'])
        .order('device_id');

      return (response as List).map((device) {
        final classroom = device['classrooms'];
        return {
          'device_id': device['device_id'],
          'device_type': device['device_type'],
          'name': device['name'] ?? 'Security Device',
          'location': device['location'],
          'classroom_id': classroom != null ? classroom['classroom_id'] : null,
          'classroom_name': classroom != null ? classroom['name'] : null,
          'status': _mapDeviceStatusToSecurity(device['status']),
          'is_active': device['status'] == 'online',
          'updated_at': device['updated_at'],
        };
      }).toList();
    } catch (e) {
      print('Error getting security devices: $e');
      return [];
    }
  }

  // Add this method to your SupabaseService class
  static Future<List<Map<String, dynamic>>> getSecurityDevicesByAlarm(int alarmId) async {
    final client = await getClient();
    try {
      // First get the devices associated with this alarm through rules
      final rulesResponse = await client
        .from('alarm_rules')
        .select('device_id')
        .eq('alarm_id', alarmId)
        .order('device_id');
      
      // Extract device IDs from rules
      final deviceIds = (rulesResponse as List).map((rule) => rule['device_id'] as int).toSet().toList();
      
      if (deviceIds.isEmpty) {
        return [];
      }
      
      // Then fetch the actual devices
      final devicesResponse = await client
        .from('devices')
        .select('''
          *,
          classrooms:classroom_id (classroom_id, name)
        ''')
        .filter('device_id', 'in', deviceIds);
      
      return List<Map<String, dynamic>>.from(devicesResponse);
    } catch (e) {
      print('Error getting security devices by alarm: $e');
      return [];
    }
  }

  // Helper method to map device status to security status
  static String _mapDeviceStatusToSecurity(String? status) {
    if (status == null) return 'offline';
    
    switch (status.toLowerCase()) {
      case 'online':
        return 'secured';
      case 'offline':
        return 'offline';
      case 'maintenance':
        return 'offline';
      default:
        return status.toLowerCase();
    }
  }

  // Get security events
  static Future<List<Map<String, dynamic>>> getSecurityEvents({int limit = 20, required bool acknowledged}) async {
    final client = await getClient();
    
    try {
      // Correctly reference the foreign keys using the proper syntax
      final response = await client
        .from('alarm_events')
        .select('''
          *,
          devices!triggered_by_device_id(*),
          alarm_systems!alarm_id(*),
          alarm_rules!rule_id(*)
        ''')
        .order('triggered_at', ascending: false)
        .limit(limit);

      // Transform the events into a more useful format
      return (response as List).map((event) {
        final device = event['devices'];
        final alarm = event['alarm_systems'];
        final rule = event['alarm_rules'];
        
        return {
          'event_id': event['event_id'],
          'alarm_id': event['alarm_id'],
          'alarm_name': alarm != null ? alarm['name'] : 'Unknown Alarm',
          'rule_id': event['rule_id'],
          'rule_name': rule != null ? rule['rule_name'] : 'Unknown Rule',
          'device_id': event['triggered_by_device_id'],
          'device_name': device != null ? device['name'] : 'Unknown Device',
          'device_type': device != null ? device['device_type'] : 'unknown',
          'event_type': _getEventTypeFromTrigger(event),
          'description': _getEventDescription(event, device, rule),
          'trigger_value': event['trigger_value'],
          'trigger_status': event['trigger_status'],
          'timestamp': event['triggered_at'],
          'acknowledged': event['acknowledged'] ?? false,
          'acknowledged_at': event['acknowledged_at'],
        };
      }).toList();
    } catch (e) {
      print('Error getting security events: $e');
      // Return empty list instead of throwing to avoid crashing the app
      return [];
    }
  }

  // Helper methods to format event data
  static String _getEventTypeFromTrigger(Map<String, dynamic> event) {
    if (event['trigger_status'] != null) {
      return 'status_change';
    } else if (event['trigger_value'] != null) {
      return 'threshold';
    } else {
      return 'alarm_triggered';
    }
  }

  static String _getEventDescription(
    Map<String, dynamic> event, 
    Map<String, dynamic>? device, 
    Map<String, dynamic>? rule
  ) {
    final deviceName = device != null ? device['name'] : 'Unknown device';
    final ruleName = rule != null ? rule['rule_name'] : '';
    
    if (event['trigger_status'] != null) {
      return 'Status changed to ${event['trigger_status']} on $deviceName';
    } else if (event['trigger_value'] != null) {
      return 'Threshold value ${event['trigger_value']} detected on $deviceName';
    } else if (ruleName.isNotEmpty) {
      return 'Rule "$ruleName" triggered on $deviceName';
    } else {
      return 'Alarm triggered by $deviceName';
    }
  }

  // Toggle security device (lock/unlock doors, etc.)
  static Future<void> toggleSecurityDevice(String deviceId, bool secure) async {
    final client = await getClient();
    
    try {
      // Update device status
      await client
        .from('devices')
        .update({
          'status': secure ? 'online' : 'offline', // Using online/offline as proxy for secured/breached
          'updated_at': DateTime.now().toIso8601String()
        })
        .eq('device_id', deviceId);
        
    } catch (e) {
      print('Error toggling security device: $e');
      throw e;
    }
  }

  // Acknowledge security event
  static Future<bool> acknowledgeSecurityEvent({
  required int eventId,
  String? userId,
}) async {
  final client = await getClient();
  try {
    print('Sending acknowledge request to Supabase for event $eventId');
    
    // Get current timestamp
    final now = DateTime.now().toIso8601String();
    
    // Update the event in the database
    await client
        .from('security_events')
        .update({
          'acknowledged': true,
          'acknowledged_at': now,
          'acknowledged_by_user_id': userId,
        })
        .eq('event_id', eventId);
    
    print('Database updated successfully for event $eventId');
    return true;
  } catch (e) {
    print('Error in SupabaseService.acknowledgeSecurityEvent: $e');
    return false;
  }
}

  // Get alarm system status
  static Future<String> getAlarmSystemStatus() async {
    // In a real app, you'd fetch this from your database
    // For this example, we'll return a fixed value
    return 'inactive';
  }

  // Set alarm system status
  static Future<void> setAlarmSystemStatus(String status) async {
    // In a real app, you'd update this in your database
    print('Setting alarm system status to: $status');
  }

  // Alarm Systems
  static Future<List<Map<String, dynamic>>> getAlarmSystems() async {
    final client = await getClient();
    try {
      final response = await client
        .from('alarm_systems')
        .select('*, departments:department_id(*), classrooms:classroom_id(*)')
        .order('created_at');
      
      return response;
    } catch (e) {
      print('Error getting alarm systems: $e');
      throw e;
    }
  }

  static Future<Map<String, dynamic>> getAlarmSystemById(int alarmId) async {
    final client = await getClient();
    try {
      final response = await client
        .from('alarm_systems')
        .select('*, departments:department_id(*), classrooms:classroom_id(*)')
        .eq('alarm_id', alarmId)
        .single();
      
      // Add default empty arrays for related data that might be missing
      final result = Map<String, dynamic>.from(response);
      
      // Add default empty collections if they're not present
      if (!result.containsKey('devices')) {
        result['devices'] = [];
        print('! No devices found in JSON');
      }
      
      if (!result.containsKey('sensors')) {
        result['sensors'] = [];
        print('! No sensors found in JSON');
      }
      
      if (!result.containsKey('actuators')) {
        result['actuators'] = [];
        print('! No actuators found in JSON');
      }
      
      if (!result.containsKey('cameras')) {
        result['cameras'] = [];
        print('! No cameras found in JSON');
      }
      
      if (!result.containsKey('sensor_readings')) {
        result['sensor_readings'] = [];
        print('! No sensor readings found in JSON');
      }
      
      return result;
    } catch (e) {
      print('Error getting alarm system details: $e');
      throw e;
    }
  }

  static Future<Map<String, dynamic>?> getAlarmById(int alarmId) async {
    final client = await getClient();
    try {
      final response = await client
        .from('alarm_systems')
        .select('*')
        .eq('alarm_id', alarmId)
        .single();
      
      return response;
    } catch (e) {
      print('Error getting alarm by ID: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> createAlarmSystem(Map<String, dynamic> data) async {
    final client = await getClient();
    try {
      // Make sure alarm_id is not included in the data
      data.remove('alarm_id');
      
      // Also remove timestamps to let the database handle them
      data.remove('created_at');
      data.remove('updated_at');
      
      final response = await client
        .from('alarm_systems')
        .insert(data)
        .select()
        .single();
      
      return response;
    } catch (e) {
      print('Error creating alarm system: $e');
      throw e;
    }
  }

  static Future<bool> updateAlarmSystem(int alarmId, Map<String, dynamic> data) async {
    final client = await getClient();
    try {
      final response =await client
        .from('alarm_systems')
        .update(data)
        .eq('alarm_id', alarmId);
        return response;
    } catch (e) {
      print('Error updating alarm system: $e');
      throw e;
    }
  }

  static Future<bool> deleteAlarmSystem(int alarmId) async {
  final client = await getClient();
  try {
    // First, delete all related records (alarm actions, rules, and events)

    // Finally, delete the alarm system itself
    await client.from('alarm_systems')
      .delete()
      .eq('alarm_id', alarmId);
    
    return true;
  } catch (e) {
    print('Error deleting alarm system: $e');
    return false;
  }
}

  // Alarm Rules
  static Future<List<Map<String, dynamic>>> getAlarmRules(int alarmId) async {
    final client = await getClient();
    try {
      final response = await client
        .from('alarm_rules')
        .select('*, devices:device_id(*)')
        .eq('alarm_id', alarmId)
        .order('created_at');
      
      return response;
    } catch (e) {
      print('Error getting alarm rules: $e');
      throw e;
    }
  }

  static Future<int> createAlarmRule(Map<String, dynamic> data) async {
    final client = await getClient();
    try {
      final response = await client
        .from('alarm_rules')
        .insert(data)
        .select('rule_id')
        .single();
      
      return response['rule_id'];
    } catch (e) {
      print('Error creating alarm rule: $e');
      throw e;
    }
  }

  static Future<bool> updateAlarmRule(int ruleId, Map<String, dynamic> data) async {
  final client = await getClient();
  try {
    await client
      .from('alarm_rules')
      .update(data)
      .eq('rule_id', ruleId);
    
    // If we made it here without an exception, the update was successful
    return true;
  } catch (e) {
    print('Error updating alarm rule: $e');
    // Return false instead of throwing, so we have a consistent return type
    return false;
  }
}

  static Future<void> deleteAlarmRule(int ruleId) async {
    final client = await getClient();
    try {
      await client
        .from('alarm_rules')
        .delete()
        .eq('rule_id', ruleId);
    } catch (e) {
      print('Error deleting alarm rule: $e');
      throw e; // Re-throw to handle in the provider
    }
  }

  static Future<Map<String, dynamic>> saveAlarmRule(AlarmRuleModel rule) async {
    final client = await getClient();
    try {
      // Important: For insert operations, omit the rule_id field entirely
      // Let Postgres handle auto-assigning the value
      final data = {
        'alarm_id': rule.alarmId,
        'rule_name': rule.ruleName,
        'device_id': rule.deviceId,
        'condition_type': rule.conditionType,
        'threshold_value': rule.thresholdValue,
        'comparison_operator': rule.comparisonOperator,
        'status_value': rule.statusValue,
        'time_restriction_start': rule.timeRestrictionStart?.toIso8601String(),
        'time_restriction_end': rule.timeRestrictionEnd?.toIso8601String(),
        'days_active': rule.daysActive,
        'is_active': rule.isActive,
        'created_at': rule.createdAt.toIso8601String(),
        'updated_at': rule.updatedAt.toIso8601String(),
      };

      final response = await client
        .from('alarm_rules')
        .insert(data)
        .select()
        .single();
      
      return response;
    } catch (e) {
      print('Error saving alarm rule: $e');
      throw e;
    }
  }

  // Alarm Events
  static Future<List<Map<String, dynamic>>> getAlarmEvents(int alarmId, {int limit = 20}) async {
    final client = await getClient();
    try {
      final response = await client
        .from('alarm_events')
        .select('*, alarm_systems:alarm_id(*), alarm_rules:rule_id(*), devices:triggered_by_device_id(*)')
        .eq('alarm_id', alarmId)
        .order('triggered_at', ascending: false)
        .limit(limit);
      
      return response;
    } catch (e) {
      print('Error getting alarm events: $e');
      throw e;
    }
  }

  static Future<void> acknowledgeAlarmEvent(int eventId) async {
    final client = await getClient();
    try {
      await client
        .from('alarm_events')
        .update({
          'acknowledged': true,
          'acknowledged_at': DateTime.now().toIso8601String(),
          'acknowledged_by_user_id': getCurrentUserId(),
        })
        .eq('event_id', eventId);
    } catch (e) {
      print('Error acknowledging alarm event: $e');
      throw e;
    }
  }

  // Alarm Actions
  static Future<List<Map<String, dynamic>>> getAlarmActions(int alarmId) async {
    final client = await getClient();
    try {
      final response = await client
        .from('alarm_actions')
        .select('*, actuators:actuator_id(*)')
        .eq('alarm_id', alarmId)
        .order('created_at');
      
      return response;
    } catch (e) {
      print('Error getting alarm actions: $e');
      throw e;
    }
  }

  static Future<int?> createAlarmAction(Map<String, dynamic> data) async {
    try {
      // Ensure action_id is not included for new records
      data.remove('action_id');
      
      final response = await client
        .from('alarm_actions')
        .insert(data)
        .select()
        .single();
      
      return response['action_id'];
    } catch (e) {
      print('Error creating alarm action: $e');
      return null;
    }
  }

  static Future<bool> updateAlarmAction(int actionId, Map<String, dynamic> data) async {
  final client = await getClient();
  try {
    await client
      .from('alarm_actions')
      .update(data)
      .eq('action_id', actionId);
    
    // If we got here without exceptions, the update was successful
    return true;
  } catch (e) {
    print('Error updating alarm action: $e');
    // Return false instead of null when there's an error
    return false;
  }
}

  static Future<bool> deleteAlarmAction(int actionId) async {
    final client = await getClient();
    try {
      await client
        .from('alarm_actions')
        .delete()
        .eq('action_id', actionId);
        
      // Return true if we got here without any exceptions
      return true;
    } catch (e) {
      print('Error deleting alarm action: $e');
      // Return false instead of null when there's an error
      return false;
    }
  }

  // Helper method to get current user ID
  static int? getCurrentUserId() {
    final user = getCurrentUser();
    return user != null ? int.tryParse(user.id) : null;
  }



  // Get departments
  static Future<List<Map<String, dynamic>>> getDepartments() async {
    final client = await getClient();
    try {
      final response = await client
        .from('departments')
        .select('*')
        .order('name');
        
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting departments: $e');
      throw e;
    }
  }

  // Get classrooms
  static Future<List<Map<String, dynamic>>> getClassrooms({int? departmentId}) async {
    final client = await getClient();
    try {
      var query = client
        .from('classrooms')
        .select('*');
        
      if (departmentId != null) {
        query = query.eq('department_id', departmentId);
      }
      
      final response = await query.order('name');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting classrooms: $e');
      throw e;
    }
  }

  // Add this method to your SupabaseService class
  static Future<bool> updateAlarmArmStatus(int alarmId, String status) async {
    final client = await getClient();
    try {
      // Ensure status is a valid value according to your database constraints
      if (!['disarmed', 'armed_stay', 'armed_away'].contains(status)) {
        throw Exception('Invalid arm status value: $status');
      }
      
      await client
        .from('alarm_systems')
        .update({
          'arm_status': status,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('alarm_id', alarmId);
      
      return true;
    } catch (e) {
      print('Error updating alarm arm status: $e');
      throw e;
    }
  }

  // Corrected getSensors method
  static Future<List<Map<String, dynamic>>> getSensors() async {
    final client = await getClient();
    try {
      final response = await client
        .from('sensors')
        .select('''
          *,
          devices!device_id(
            device_id,
            device_type,
            model,
            location,
            status,
            department_id,
            classroom_id,
            classrooms:classroom_id(classroom_id, name)
          )
        ''')
        .order('sensor_id');
      
      // Process the response to include additional useful info
      return List<Map<String, dynamic>>.from(response).map((sensor) {
        final device = sensor['devices'];
        return {
          ...sensor,
          'device_model': device['model'],
          'device_location': device['location'],
          'device_status': device['status'],
          'classroom_id': device['classroom_id'],
          'classroom_name': device['classrooms'] != null ? device['classrooms']['name'] : null,
          'department_id': device['department_id']
        };
      }).toList();
    } catch (e) {
      print('Error getting sensors: $e');
      return [];
    }
  }

  // Corrected getCameras method
  static Future<List<Map<String, dynamic>>> getCameras() async {
    final client = await getClient();
    try {
      final response = await client
        .from('cameras')
        .select('''
          *,
          devices!device_id(
            device_id,
            device_type,
            model,
            location, 
            status,
            department_id,
            classroom_id,
            classrooms:classroom_id(classroom_id, name),
            departments:department_id(department_id, name)
          )
        ''')
        .order('camera_id');
      
      // Process the response to include additional useful info
      return List<Map<String, dynamic>>.from(response).map((camera) {
        final device = camera['devices'];
        return {
          ...camera,
          'device_model': device['model'],
          'device_location': device['location'],
          'device_status': device['status'],
          'classroom_id': device['classroom_id'],
          'classroom_name': device['classrooms'] != null ? device['classrooms']['name'] : null,
          'department_id': device['department_id'],
          'department_name': device['departments'] != null ? device['departments']['name'] : null
        };
      }).toList();
    } catch (e) {
      print('Error getting cameras: $e');
      return [];
    }
  }

  // Corrected getActuators method
  static Future<List<Map<String, dynamic>>> getActuators() async {
    final client = await getClient();
    try {
      final response = await client
        .from('actuators')
        .select('''
          *,
          devices!device_id(
            device_id,
            device_type,
            model,
            location,
            status,
            department_id,
            classroom_id,
            classrooms:classroom_id(classroom_id, name)
          )
        ''')
        .order('actuator_id');
      
      // Process the response to include additional useful info
      return List<Map<String, dynamic>>.from(response).map((actuator) {
        final device = actuator['devices'];
        return {
          ...actuator,
          'device_model': device['model'],
          'device_location': device['location'],
          'device_status': device['status'],
          'classroom_id': device['classroom_id'],
          'classroom_name': device['classrooms'] != null ? device['classrooms']['name'] : null,
          'department_id': device['department_id']
        };
      }).toList();
    } catch (e) {
      print('Error getting actuators: $e');
      return [];
    }
  }

  // Update/create this method in the SupabaseService class
static Future<bool> saveAlarmSystem(Map<String, dynamic> alarmData) async {
  final client = await getClient();
  try {
    final alarmId = alarmData['alarm_id'];
    
    // If alarmId is 0 or null, this is a new record - INSERT
    if (alarmId == null || alarmId == 0) {
      // Remove alarm_id field for new records
      alarmData.remove('alarm_id');
      
      await client
        .from('alarm_systems')
        .insert(alarmData);
    } 
    // Otherwise, this is an existing record - UPDATE
    else {
      await client
        .from('alarm_systems')
        .update(alarmData)
        .eq('alarm_id', alarmId);
    }
    
    // If we made it here without exceptions, the operation was successful
    return true;
  } catch (e) {
    print('Error saving alarm system: $e');
    // Return false instead of null for error cases
    return false;
  }
}
static Future<int> getUnresolvedAlertCount() async {
  final client = await getClient();
  try {
    // Simple approach: just fetch the records and count them
    final data = await client
        .from('alerts')
        .select('alert_id') // Select only ID for efficiency
        .eq('resolved', false);
    
    // The response is a List in most SDK versions
      return data.length;
  } catch (e) {
    print('Error getting unresolved alert count: $e');
    return 0;
  }
}

// Get student attendance data by date
  static Future<List<Map<String, dynamic>>> getAttendanceByDate(DateTime date) async {
    final client = await getClient();
    try {
      final response = await client
          .from('daily_attendance')
          .select('''
            attendance_id,
            student_id,
            attendance_date,
            check_in_time,
            students!inner(name, email)
          ''')
          .eq('attendance_date', date.toIso8601String().split('T')[0])
          .order('check_in_time', ascending: true);
          
      // Transform the response to include student name directly
      return List<Map<String, dynamic>>.from(response.map((record) {
        return {
          'attendance_id': record['attendance_id'],
          'student_id': record['student_id'],
          'attendance_date': record['attendance_date'],
          'check_in_time': record['check_in_time'],
          'student_name': record['students']['name'],
        };
      }));
    } catch (e) {
      print('Error getting attendance data: $e');
      return [];
    }
  }
  
  // Get all students
  static Future<List<Map<String, dynamic>>> getStudents() async {
    final client = await getClient();
    try {
      final response = await client
          .from('students')
          .select('''
            student_id,
            name,
            email,
            rfid_cards!left(rfid_uid)
          ''')
          .order('name');
          
      // Transform the response to flatten structure
      return List<Map<String, dynamic>>.from(response.map((record) {
        return {
          'student_id': record['student_id'],
          'name': record['name'],
          'email': record['email'],
          'rfid_uid': record['rfid_cards'] != null ? 
                     record['rfid_cards']['rfid_uid'] : null,
        };
      }));
    } catch (e) {
      print('Error getting students: $e');
      return [];
    }
  }
  
  // Record student attendance
  static Future<bool> recordAttendance(int studentId, DateTime date) async {
    final client = await getClient();
    try {
      final dateString = date.toIso8601String().split('T')[0];
      await client.from('daily_attendance').upsert({
        'student_id': studentId,
        'attendance_date': dateString,
        'check_in_time': DateTime.now().toIso8601String(),
      }, onConflict: 'student_id, attendance_date');
      return true;
    } catch (e) {
      print('Error recording attendance: $e');
      return false;
    }
  }
}