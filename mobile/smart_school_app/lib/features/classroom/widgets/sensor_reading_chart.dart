import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/sensor_reading_model.dart';

class SensorReadingChart extends StatelessWidget {
  final List<SensorReadingModel> readings;
  final String sensorType;

  const SensorReadingChart({
    super.key,
    required this.readings,
    required this.sensorType,
  });

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) {
      return const Center(
        child: Text('No data available'),
      );
    }

    // Sort readings by timestamp (oldest first)
    final sortedReadings = List<SensorReadingModel>.from(readings)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chart title
        Text(
          _getChartTitle(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
        
        Text(
          _getYAxisLabel(),
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Chart
        Expanded(
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                horizontalInterval: _getYAxisInterval(),
                verticalInterval: 1,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey.withOpacity(0.2),
                    strokeWidth: 1,
                  );
                },
                getDrawingVerticalLine: (value) {
                  return FlLine(
                    color: Colors.grey.withOpacity(0.2),
                    strokeWidth: 1,
                  );
                },
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: _getXAxisInterval(),
                    getTitlesWidget: _bottomTitleWidgets,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: _getYAxisInterval(),
                    getTitlesWidget: _leftTitleWidgets,
                    reservedSize: 42,
                  ),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: const Color(0xff37434d), width: 1),
              ),
              minX: 0,
              maxX: sortedReadings.length - 1.0,
              minY: _getMinY(),
              maxY: _getMaxY(),
              lineBarsData: [
                LineChartBarData(
                  spots: _getChartSpots(sortedReadings),
                  isCurved: true,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.5),
                      AppColors.primary,
                    ],
                  ),
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.2),
                        AppColors.primary.withOpacity(0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                // Add warning and critical thresholds if relevant
                if (_hasThresholds())
                  LineChartBarData(
                    spots: _getWarningThresholdSpots(sortedReadings),
                    isCurved: false,
                    color: AppColors.warning.withOpacity(0.7),
                    barWidth: 1,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                    dashArray: [5, 5],
                  ),
                if (_hasThresholds())
                  LineChartBarData(
                    spots: _getCriticalThresholdSpots(sortedReadings),
                    isCurved: false,
                    color: AppColors.error.withOpacity(0.7),
                    barWidth: 1,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                    dashArray: [5, 5],
                  ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem(
              AppColors.primary,
              _getLegendValueName(),
            ),
            if (_hasThresholds()) ...[
              const SizedBox(width: 16),
              _buildLegendItem(
                AppColors.warning,
                'Warning',
                isDashed: true,
              ),
              const SizedBox(width: 16),
              _buildLegendItem(
                AppColors.error,
                'Critical',
                isDashed: true,
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String text, {bool isDashed = false}) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(1.5),
          ),
          child: isDashed
              ? LayoutBuilder(
                  builder: (context, constraints) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(
                        (constraints.maxWidth / 4).floor(),
                        (index) => Container(
                          width: 2,
                          color: color,
                        ),
                      ),
                    );
                  },
                )
              : null,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 10,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _bottomTitleWidgets(double value, TitleMeta meta) {
    if (value % _getXAxisInterval() != 0 && value != readings.length - 1) {
      return Container();
    }

    final index = value.toInt();
    if (index < 0 || index >= readings.length) {
      return Container();
    }

    final reading = readings[index];
    final timeFormat = _getTimeFormat(reading.timestamp);

    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(
        timeFormat,
        style: const TextStyle(
          fontSize: 10,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _leftTitleWidgets(double value, TitleMeta meta) {
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(
        '${value.toStringAsFixed(0)}${_getUnitSymbol()}',
        style: const TextStyle(
          fontSize: 10,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  List<FlSpot> _getChartSpots(List<SensorReadingModel> sortedReadings) {
    return List.generate(sortedReadings.length, (index) {
      return FlSpot(index.toDouble(), sortedReadings[index].value);
    });
  }

  List<FlSpot> _getWarningThresholdSpots(List<SensorReadingModel> sortedReadings) {
    // In a real implementation, these thresholds would come from the sensor configuration
    double warningThreshold;
    switch (sensorType) {
      case 'temperature':
        warningThreshold = 28.0;
        break;
      case 'humidity':
        warningThreshold = 70.0;
        break;
      case 'gas':
        warningThreshold = 800.0;
        break;
      default:
        return [];
    }
    
    return [
      FlSpot(0, warningThreshold),
      FlSpot(sortedReadings.length - 1, warningThreshold),
    ];
  }

  List<FlSpot> _getCriticalThresholdSpots(List<SensorReadingModel> sortedReadings) {
    // In a real implementation, these thresholds would come from the sensor configuration
    double criticalThreshold;
    switch (sensorType) {
      case 'temperature':
        criticalThreshold = 30.0;
        break;
      case 'humidity':
        criticalThreshold = 80.0;
        break;
      case 'gas':
        criticalThreshold = 1000.0;
        break;
      default:
        return [];
    }
    
    return [
      FlSpot(0, criticalThreshold),
      FlSpot(sortedReadings.length - 1, criticalThreshold),
    ];
  }

  bool _hasThresholds() {
    return ['temperature', 'humidity', 'gas'].contains(sensorType);
  }

  String _getChartTitle() {
    switch (sensorType) {
      case 'temperature':
        return 'Temperature Readings';
      case 'humidity':
        return 'Humidity Readings';
      case 'gas':
        return 'Air Quality Readings';
      case 'motion':
        return 'Motion Detection';
      case 'light':
        return 'Light Level Readings';
      default:
        return '${sensorType.substring(0, 1).toUpperCase()}${sensorType.substring(1)} Readings';
    }
  }

  String _getLegendValueName() {
    switch (sensorType) {
      case 'temperature':
        return 'Temperature';
      case 'humidity':
        return 'Humidity';
      case 'gas':
        return 'Gas Level';
      case 'motion':
        return 'Motion';
      case 'light':
        return 'Light Level';
      default:
        return sensorType.substring(0, 1).toUpperCase() + sensorType.substring(1);
    }
  }

  String _getYAxisLabel() {
    switch (sensorType) {
      case 'temperature':
        return 'Temperature (°C)';
      case 'humidity':
        return 'Humidity (%)';
      case 'gas':
        return 'Gas Level (ppm)';
      case 'motion':
        return 'Motion Detection';
      case 'light':
        return 'Light Level (lux)';
      default:
        return sensorType.substring(0, 1).toUpperCase() + sensorType.substring(1);
    }
  }

  String _getUnitSymbol() {
    switch (sensorType) {
      case 'temperature':
        return '°';
      case 'humidity':
        return '%';
      case 'gas':
        return '';
      case 'motion':
        return '';
      case 'light':
        return '';
      default:
        return '';
    }
  }

  double _getXAxisInterval() {
    final count = readings.length;
    if (count <= 10) return 1;
    if (count <= 30) return 5;
    if (count <= 60) return 10;
    return count / 10;
  }

  double _getYAxisInterval() {
    switch (sensorType) {
      case 'temperature':
        return 5;
      case 'humidity':
        return 10;
      case 'gas':
        return 200;
      case 'motion':
        return 1;
      case 'light':
        return 100;
      default:
        return 10;
    }
  }

  double _getMinY() {
    switch (sensorType) {
      case 'temperature':
        return 15;
      case 'humidity':
        return 0;
      case 'gas':
        return 0;
      case 'motion':
        return 0;
      case 'light':
        return 0;
      default:
        return 0;
    }
  }

  double _getMaxY() {
    switch (sensorType) {
      case 'temperature':
        return 50;
      case 'humidity':
        return 100;
      case 'gas':
        return 1500;
      case 'motion':
        return 1;
      case 'light':
        return 1500;
      default:
        return 100;
    }
  }

  String _getTimeFormat(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
} 