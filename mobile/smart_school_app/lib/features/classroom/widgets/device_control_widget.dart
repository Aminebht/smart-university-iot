import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/actuator_model.dart';
import '../../../core/models/sensor_model.dart';
import '../../../core/models/sensor_reading_model.dart';
import '../../../core/models/classroom_model.dart';

class DeviceControlWidget extends StatelessWidget {
  final dynamic device; // Can be SensorModel or ActuatorModel
  final Function(bool)? onToggle;
  final Function(double)? onValueChanged;
  final List<SensorReadingModel>? sensorReadings;

  const DeviceControlWidget({
    Key? key,
    required this.device,
    this.onToggle,
    this.onValueChanged,
    this.sensorReadings,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('🔄 Building DeviceControlWidget for: ${device.runtimeType}');
    
    if (device is ActuatorModel) {
      print('🔌 Building for Actuator: ${(device as ActuatorModel).name}');
      return _buildActuatorControl(context, device as ActuatorModel);
    } else if (device is SensorModel) {
      print('📡 Building for Sensor: ${(device as SensorModel).name}');
      return _buildSensorDisplay(context, device as SensorModel);
    } else {
      print('⚠️ Unknown device type: ${device.runtimeType}');
      return const ListTile(
        title: Text('Unknown Device'),
        subtitle: Text('Type: unknown'),
      );
    }
  }

  Widget _buildActuatorControl(BuildContext context, ActuatorModel actuator) {
    // Add null safety check for currentState
    final bool isOn = actuator.currentState?.toLowerCase() == "on";
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          key: ValueKey('actuator_control_${actuator.actuatorId}'),
          leading: Icon(
            _getIconForType(actuator.actuatorType),
            color: isOn ? Colors.green : Colors.grey,
          ),
          title: Text(
            actuator.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Type: ${actuator.actuatorType}'),
              Text(
                'Status: ${isOn ? "On" : "Off"}',
                style: TextStyle(
                  color: isOn ? Colors.green : Colors.grey,
                ),
              ),
            ],
          ),
          trailing: Switch(
            value: isOn,
            activeColor: Colors.green,
            onChanged: onToggle,
          ),
        ),
        
        // Only show sliders when the device is turned on
        if (isOn) _buildControlSlider(context, actuator),
      ],
    );
  }
  
  Widget _buildControlSlider(BuildContext context, ActuatorModel actuator) {
    // Only show controls for specific actuator types
    if (actuator.actuatorType.toLowerCase() == 'light') {
      // Read brightness value from actuator settings, ensuring we have a valid value
      final brightness = actuator.brightness;
      
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.brightness_6, size: 20),
                const SizedBox(width: 8),
                const Text('Brightness:'),
                Expanded(
                  child: Slider(
                    value: brightness.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 20,
                    label: '$brightness%',
                    onChanged: onValueChanged,
                  ),
                ),
                Text('$brightness%'),
              ],
            ),
          ],
        ),
      );
    } 
    else if (actuator.actuatorType.toLowerCase() == 'fan') {
      // Read speed value from actuator settings, ensuring we have a valid value
      final speed = actuator.speed;
      
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.speed, size: 20),
                const SizedBox(width: 8),
                const Text('Speed:'),
                Expanded(
                  child: Slider(
                    value: speed.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 20,
                    label: '$speed%',
                    onChanged: onValueChanged,
                  ),
                ),
                Text('$speed%'),
              ],
            ),
          ],
        ),
      );
    }
    
    // Return an empty container for other types
    return const SizedBox.shrink();
  }

  Widget _buildSensorDisplay(BuildContext context, SensorModel sensor) {
    final bool isOnline = sensor.status == DeviceStatus.online;
    String? latestReading;
    
    // Find the latest reading for this sensor
    if (sensorReadings != null) {
      final matchingReadings = sensorReadings!
          .where((reading) => reading.sensorId == sensor.sensorId)
          .toList();
      
      if (matchingReadings.isNotEmpty) {
        // Sort by timestamp descending and get the latest
        matchingReadings.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        final latest = matchingReadings.first;
        latestReading = '${latest.value} ${sensor.unit}';
      }
    }

    return ListTile(
      leading: Icon(
        _getIconForType(sensor.type),
        color: isOnline ? Colors.blue : Colors.grey,
      ),
      title: Text(
        sensor.name,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Type: ${sensor.type}'),
          if (latestReading != null)
            Text(
              'Reading: $latestReading',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _getColorForReading(sensor, latestReading),
              ),
            ),
          Text(
            'Status: ${isOnline ? "Online" : "Offline"}',
            style: TextStyle(
              color: isOnline ? Colors.green : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'temperature':
        return Icons.thermostat;
      case 'humidity':
        return Icons.water_drop;
      case 'gas':
        return Icons.air;
      case 'motion':
        return Icons.motion_photos_on;
      case 'light':
        return Icons.lightbulb;
      case 'door':
        return Icons.door_front_door;
      case 'fan':
        return Icons.air;
      case 'ac':
        return Icons.ac_unit;
      default:
        return Icons.device_unknown;
    }
  }

  Color _getColorForReading(SensorModel sensor, String? reading) {
    if (reading == null) return Colors.grey;
    
    try {
      final value = double.parse(reading.split(' ').first);
      
      if (value > sensor.maxValue) {
        return Colors.red;
      } else if (value < sensor.minValue) {
        return Colors.orange;
      } else {
        return Colors.green;
      }
    } catch (e) {
      return Colors.grey;
    }
  }
}