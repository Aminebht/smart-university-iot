import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';

class StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const StatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10), // Further reduced padding
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon and Value in a row to save vertical space
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5), // Further reduced padding
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 16, // Smaller icon
                  ),
                ),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15, // Slightly smaller font
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            const SizedBox(height: 6), // Reduced spacing
            
            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 10, // Further reduced font size
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class StatsCardGrid extends StatelessWidget {
  final Map<String, double> stats;

  const StatsCardGrid({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 2.0, // Increased to allow more width than height
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10, // Reduced spacing
      mainAxisSpacing: 10, // Reduced spacing
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        if (stats.containsKey('average_temperature'))
          StatsCard(
            title: 'Average Temperature',
            value: '${stats['average_temperature']!.toStringAsFixed(1)}°C',
            icon: Icons.thermostat,
            color: AppColors.primary,
          ),
        if (stats.containsKey('average_humidity'))
          StatsCard(
            title: 'Average Humidity',
            value: '${stats['average_humidity']!.toStringAsFixed(1)}%',
            icon: Icons.water_drop,
            color: Colors.blue,
          ),
        if (stats.containsKey('air_quality'))
          StatsCard(
            title: 'Air Quality',
            value: '${stats['air_quality']!.toStringAsFixed(1)} ppm',
            icon: Icons.cloud, // Changed from people to cloud icon
            color: _getAirQualityColor(stats['air_quality'] ?? 0),
          ),
        if (stats.containsKey('alert_count'))
          StatsCard(
            title: 'Active Alerts',
            value: '${stats['alert_count']!.toInt()}',
            icon: Icons.warning_amber,
            color: stats['alert_count']! > 0 ? AppColors.warning : AppColors.success,
          ),
        
      ],
    );
  }


  Color _getAirQualityColor(double value) {
    // Air quality thresholds (adjust based on your specific measurements)
    if (value < 500) {
      return Colors.green; // Good
    } else if (value < 1000) {
      return Colors.orange; // Moderate
    } else {
      return Colors.red; // Poor
    }
  }
}