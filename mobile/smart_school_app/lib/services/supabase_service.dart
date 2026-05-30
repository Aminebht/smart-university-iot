import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/app_constants.dart';
import '../core/models/room_model.dart';
import '../core/models/sensor_reading_model.dart';
import '../core/models/attendance_model.dart';
import '../core/models/actuator_model.dart';
import '../core/models/alert_model.dart';
import '../core/models/occupancy_model.dart';
import '../core/models/device_status_model.dart';
import '../core/models/student_model.dart';
import '../core/models/alarm_rule_model.dart';

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
  
  // ==================== ROOMS ====================
  static Future<List<Map<String, dynamic>>> getRooms() async {
    try {
      return await client.from('rooms').select('*').order('name');
    } catch (e) {
      print('Error getting rooms: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> getRoomDetails(String roomId) async {
    try {
      final room = await client.from('rooms').select('*').eq('room_id', roomId).single();
      // Fetch related data
      final sensorReadings = await client
          .from('sensor_data')
          .select('*')
          .eq('room_id', roomId)
          .order('timestamp', ascending: false)
          .limit(50);
      final actuators = await client
          .from('actuators')
          .select('*')
          .eq('room_id', roomId);
      final deviceStatus = await client
          .from('device_status')
          .select('*')
          .eq('room_id', roomId);
      final occupancy = await client
          .from('room_occupancy')
          .select('*')
          .eq('room_id', roomId)
          .order('timestamp', ascending: false)
          .limit(1)
          .maybeSingle();

      room['sensor_readings'] = sensorReadings;
      room['actuators'] = actuators;
      room['device_status'] = deviceStatus;
      room['occupancy'] = occupancy;
      return room;
    } catch (e) {
      print('Error getting room details: $e');
      throw e;
    }
  }

  // ==================== SENSOR DATA ====================
  static Future<List<Map<String, dynamic>>> getSensorData(
      String roomId, String sensorType, {int limit = 50}) async {
    try {
      return await client
          .from('sensor_data')
          .select('*')
          .eq('room_id', roomId)
          .eq('sensor_type', sensorType)
          .order('timestamp', ascending: false)
          .limit(limit);
    } catch (e) {
      print('Error in getSensorData: $e');
      return [];
    }
  }

  static Stream<List<Map<String, dynamic>>> streamSensorData(String roomId) {
    return client
        .from('sensor_data')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId);
  }

  static Future<List<Map<String, dynamic>>> getRecentSensorData({int limit = 100}) async {
    try {
      return await client
          .from('sensor_data')
          .select('*')
          .order('timestamp', ascending: false)
        .limit(limit);
    } catch (e) {
      print('Error getting recent sensor data: $e');
      return [];
    }
  }

  // ==================== ACTUATORS ====================
  static Future<List<Map<String, dynamic>>> getActuatorsForRoom(String roomId) async {
    try {
      return await client.from('actuators').select('*').eq('room_id', roomId);
    } catch (e) {
      print('Error getting actuators: $e');
      return [];
    }
  }

  static Future<void> toggleActuator(String roomId, String actuatorType, bool isOn) async {
    try {
      await client.from('actuators').update({
        'current_state': isOn ? 'on' : 'off',
        'command': isOn ? 'on' : 'off',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('room_id', roomId).eq('actuator_type', actuatorType);
    } catch (e) {
      print('Error toggling actuator: $e');
      throw e;
    }
  }

  // ==================== ATTENDANCE ====================
  static Future<List<Map<String, dynamic>>> getAttendanceForRoom(String roomId, {int limit = 50}) async {
    try {
      return await client
          .from('attendance')
          .select('*, students:student_id(name)')
          .eq('room_id', roomId)
          .order('timestamp', ascending: false)
          .limit(limit);
    } catch (e) {
      print('Error getting attendance: $e');
      return [];
    }
  }

  // ==================== OCCUPANCY ====================
  static Future<Map<String, dynamic>?> getOccupancyForRoom(String roomId) async {
    try {
      return await client
          .from('room_occupancy')
          .select('*')
          .eq('room_id', roomId)
          .order('timestamp', ascending: false)
          .limit(1)
          .maybeSingle();
    } catch (e) {
      print('Error getting occupancy: $e');
      return null;
    }
  }

  static Stream<List<Map<String, dynamic>>> streamOccupancyForRoom(String roomId) {
    return client
        .from('room_occupancy')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId);
  }

  // ==================== ALERTS ====================
  static Future<List<Map<String, dynamic>>> getAlerts({String? roomId, int limit = 50}) async {
    try {
      var query = client.from('alerts').select('*');
      if (roomId != null) query = query.eq('room_id', roomId);
      return await query.order('timestamp', ascending: false).limit(limit);
    } catch (e) {
      print('Error fetching alerts: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getRecentAlerts({int limit = 5}) async {
    return getAlerts(limit: limit);
  }

  static Future<bool> acknowledgeAlert(int alertId) async {
    try {
      await client.from('alerts').update({
        'acknowledged': true,
      }).eq('id', alertId);
      return true;
    } catch (e) {
      print('Error acknowledging alert: $e');
      return false;
    }
  }

  static Stream<List<Map<String, dynamic>>> streamAlerts() {
    return client.from('alerts').stream(primaryKey: ['id']);
  }

  // ==================== DEVICE STATUS ====================
  static Future<List<Map<String, dynamic>>> getDeviceStatusForRoom(String roomId) async {
    try {
      return await client.from('device_status').select('*').eq('room_id', roomId);
    } catch (e) {
      print('Error getting device status: $e');
      return [];
    }
  }

  // ==================== CAMERA / STREAM ====================
  static Future<String?> getStreamUrlForRoom(String roomId) async {
    try {
      final room = await client.from('rooms').select('stream_ws_url').eq('room_id', roomId).single();
      return room['stream_ws_url']?.toString();
    } catch (e) {
      print('Error getting stream URL: $e');
      return null;
    }
  }

  static String buildStreamWsUrl(String streamWsUrl, String token) {
    final base = streamWsUrl.replaceAll(RegExp(r'\?.*$'), '');
    return '$base?token=$token';
  }

  // ==================== STUDENTS ====================
  static Future<List<Map<String, dynamic>>> getStudents() async {
    try {
      return await client.from('students').select('*').order('name');
    } catch (e) {
      print('Error getting students: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getStudentByRfid(String rfidUid) async {
    try {
      final card = await client
          .from('rfid_cards')
          .select('student_id, students:student_id(*)')
          .eq('rfid_uid', rfidUid)
          .single();
      return card['students'];
    } catch (e) {
      return null;
    }
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

  static Future<List<Map<String, dynamic>>> getSensorReadings(
    String roomId,
    String sensorType, {
    int limit = 50,
  }) async {
    return getSensorData(roomId, sensorType, limit: limit);
  }

  static Future<List<Map<String, dynamic>>> getClassroomsByDepartment(int departmentId) async {
    return getClassrooms(departmentId: departmentId);
  }

  // ==================== LEGACY COMPATIBILITY STUBS ====================
  static Future<Map<String, dynamic>> getClassroomDetails(String classroomId) async {
    return getRoomDetails(classroomId);
  }

  static Future<List<Map<String, dynamic>>> getAttendanceByDate(DateTime date) async {
    return [];
  }

  static Future<bool> recordAttendance(int studentId, DateTime date) async {
    return false;
  }

  static Future<bool> resolveAlert(int alertId) async {
    return acknowledgeAlert(alertId);
  }

  static Future<List<Map<String, dynamic>>> getRecentSensorReadings({int limit = 100}) async {
    return getRecentSensorData(limit: limit);
  }

  static Future<void> toggleDeviceAndActuator(String deviceId, String actuatorId, bool isOn) async {
    // Legacy no-op
  }

  static Future<void> updateActuatorSettings(String actuatorId, Map<String, dynamic> settings) async {
    // Legacy no-op
  }

  static Future<void> updateDeviceState(String deviceId, bool state) async {
    // Legacy no-op
  }

  static Future<void> updateDeviceValue(String deviceId, double value) async {
    // Legacy no-op
  }

}