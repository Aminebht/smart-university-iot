import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/utils/app_utils.dart';
import '../../../core/models/sensor_model.dart';
import '../../../core/models/actuator_model.dart';
import '../providers/classroom_provider.dart';
import '../widgets/device_control_widget.dart';
import '../widgets/sensor_reading_chart.dart';
import '../widgets/sensor_status_card.dart';
import '../widgets/camera_thumbnail_widget.dart';

class ClassroomDetailScreen extends StatefulWidget {
  final String classroomId;

  const ClassroomDetailScreen({
    super.key,
    required this.classroomId,
  });

  @override
  State<ClassroomDetailScreen> createState() => _ClassroomDetailScreenState();
}

class _ClassroomDetailScreenState extends State<ClassroomDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ClassroomProvider()..loadClassroom(widget.classroomId),
      child: Consumer<ClassroomProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return Scaffold(
              appBar: AppBar(title: const Text('Classroom')),
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          if (provider.errorMessage != null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Classroom')),
              body: _buildErrorView(context, provider),
            );
          }

          final classroom = provider.classroom;
          if (classroom == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Classroom')),
              body: const Center(
                child: Text('Classroom not found'),
              ),
            );
          }

          return Scaffold(
            appBar: AppBar(
              title: Text(classroom.name),
              bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.secondary,
              labelColor: Colors.white,
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Devices'),
                Tab(text: 'Data'),
              ],
              ),
            ),
            body: TabBarView(
              controller: _tabController,
              children: [
                // Overview Tab
                SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildClassroomHeader(classroom),
                      _buildSensorStatusGrid(provider),
                      if (classroom.name == 'Salle C')
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                            'Classroom Camera',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            ),
                            TextButton.icon(
                            icon: const Icon(Icons.history),
                            label: const Text('View Events'),
                            onPressed: () {
                              // Navigate to camera events history
                            },
                            ),
                          ],
                          ),
                          const SizedBox(height: 8),
                          CameraThumbnailWidget(
                          classroomId: int.parse(widget.classroomId),
                          height: 180,
                          ),
                        ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Devices Tab
                _buildDevicesTab(provider),

                // Data Tab
                _buildDataTab(provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildClassroomHeader(classroom) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: classroom.statusColor.withOpacity(0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: classroom.statusColor,
            shape: BoxShape.circle,
          ),
              ),
              const SizedBox(width: 8),
              Text(
          classroom.name,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
              ),
              const Spacer(),
              Text(
          _getStatusText(classroom.status),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: classroom.statusColor,
          ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (classroom.capacity != 0)
            Text(
              'Capacity: ${classroom.capacity} students',
              style: const TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSensorStatusGrid(ClassroomProvider provider) {
    final classroom = provider.classroom!;
    final sensorReadings = classroom.sensorReadings;
    
    if (sensorReadings.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Text('No sensor data available'),
        ),
      );
    }

    // Group the latest readings by sensor type
    final latestReadings = <String, dynamic>{};
    for (var reading in sensorReadings) {
      final sensorType = reading.sensorType;
      if (!latestReadings.containsKey(sensorType) || 
          (latestReadings[sensorType].timestamp.isBefore(reading.timestamp))) {
        latestReadings[sensorType] = reading;
      }
    }

    if (latestReadings.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Text('No sensor data available'),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Readings',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: latestReadings.length,
            itemBuilder: (context, index) {
              final sensorType = latestReadings.keys.elementAt(index);
              final reading = latestReadings[sensorType];
              return SensorStatusCard(
                reading: reading,
                onTap: () {
                  _tabController.animateTo(2); // Switch to Data tab
                  provider.setSelectedSensorType(sensorType);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDevicesTab(ClassroomProvider provider) {
    final classroom = provider.classroom!;
    final List<SensorModel> sensors = classroom.sensors; 
    final List<ActuatorModel> actuators = classroom.actuators;
    
    // Debug prints
    print('📱 Devices Tab - Sensors count: ${sensors.length}');
    print('📱 Devices Tab - Actuators count: ${actuators.length}');
    if (actuators.isEmpty) {
      print('⚠️ No actuators found in the classroom model');
    } else {
      for (var actuator in actuators) {
        print('🔌 Actuator: ${actuator.name}, Type: ${actuator.actuatorType}, State: ${actuator.currentState}');
      }
    }
    
    if (sensors.isEmpty && actuators.isEmpty) {
      return const Center(
        child: Text('No devices available'),
      );
    }

    // Force both sections to be visible for testing
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
         
          
          // Regular actuators section
          if (actuators.isNotEmpty) ...[
            const Text(
              'Actuators',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: actuators.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final actuator = actuators[index];
                return DeviceControlWidget(
                  key: ValueKey('actuator_${actuator.actuatorId}'),
                  device: actuator,
                  sensorReadings: classroom.sensorReadings,
                  onToggle: (isOn) {
                    provider.toggleDevice(actuator.actuatorId.toString(), isOn);
                  },
                  onValueChanged: (value) {
                    if (actuator.actuatorType == 'light' || actuator.actuatorType == 'fan') {
                      provider.updateDeviceValue(actuator.actuatorId.toString(), value);
                    }
                  },
                );
              },
            ),
          ],
          
          // Add space between sections
          if (actuators.isNotEmpty && sensors.isNotEmpty)
            const SizedBox(height: 24),
          
          // Sensors section
          if (sensors.isNotEmpty) ...[
            const Text(
              'Sensors',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sensors.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final sensor = sensors[index];
                return DeviceControlWidget(
                  key: ValueKey('sensor_${sensor.sensorId}'),
                  device: sensor,
                  sensorReadings: classroom.sensorReadings,
                  onToggle: (_) {}, // Empty function for sensors that can't be toggled
                  onValueChanged: null, // Sensors don't have adjustable values
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDataTab(ClassroomProvider provider) {
    final classroom = provider.classroom!;
    final sensorTypes = provider.getAvailableSensorTypes();
    
    if (sensorTypes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sensors_off, size: 48, color: AppColors.textSecondary),
            SizedBox(height: 16),
            Text(
              'No sensor data available', 
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sensor type selection
          DropdownButton<String>(
            value: provider.selectedSensorType,
            isExpanded: true,
            hint: const Text('Select Sensor Type'),
            onChanged: (value) {
              if (value != null) {
                provider.setSelectedSensorType(value);
              }
            },
            items: sensorTypes.map((type) {
              return DropdownMenuItem<String>(
                value: type,
                child: Text(_getSensorTypeDisplayName(type)),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          
          // Date range selection
          Row(
            children: [
              Expanded(
                child: DropdownButton<String>(
                  value: provider.selectedTimeRange,
                  isExpanded: true,
                  onChanged: (value) {
                    if (value != null) {
                      provider.setSelectedTimeRange(value);
                    }
                  },
                  items: provider.availableTimeRanges.map((range) {
                    return DropdownMenuItem<String>(
                      value: range,
                      child: Text(range),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () {
                  provider.loadSensorData(
                    widget.classroomId,
                    provider.selectedSensorType ?? sensorTypes.first,
                  );
                },
                child: const Text('Update'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Chart
          Expanded(
            child: provider.isLoadingData
                ? const Center(child: CircularProgressIndicator())
                : SensorReadingChart(
                    readings: provider.sensorData,
                    sensorType: provider.selectedSensorType ?? sensorTypes.first,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, ClassroomProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 60,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            provider.errorMessage ?? 'An error occurred',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.error),
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Retry',
            onPressed: () => provider.loadClassroom(widget.classroomId),
            icon: Icons.refresh,
          ),
        ],
      ),
    );
  }

  String _getStatusText(DeviceStatus status) {
    switch (status) {
      case DeviceStatus.normal:
        return 'Normal';
      case DeviceStatus.warning:
        return 'Warning';
      case DeviceStatus.critical:
        return 'Critical';
      default:
        return 'Normal';
    }
  }

  String _getSensorTypeDisplayName(String type) {
    switch (type) {
      case 'temperature':
        return 'Temperature';
      case 'humidity':
        return 'Humidity';
      case 'gas':
        return 'Air Quality';
      case 'motion':
        return 'Motion';
      case 'light':
        return 'Light Level';
      default:
        return type.substring(0, 1).toUpperCase() + type.substring(1);
    }
  }
}