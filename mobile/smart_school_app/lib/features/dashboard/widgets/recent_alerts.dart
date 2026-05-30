import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/alert_model.dart';
import '../../../core/utils/app_utils.dart';

class RecentAlerts extends StatelessWidget {
  final List<AlertModel> alerts;
  final VoidCallback onViewAllTap;

  const RecentAlerts({
    super.key,
    required this.alerts,
    required this.onViewAllTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Alerts',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: onViewAllTap,
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Check if alerts list is empty
            if (alerts.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'No recent alerts',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              Column(
                children: alerts
                    .map((alert) => AlertListItem(
                          alert: alert,
                          onTap: () {
                            onViewAllTap();
                          },
                        ))
                    .toList(),
              ),
          ],
        ),
    );
  }
}

class AlertListItem extends StatelessWidget {
  final AlertModel alert;
  final VoidCallback? onTap; // Add this parameter

  const AlertListItem({
    super.key,
    required this.alert,
    this.onTap, // Make it optional
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        // Use the passed onTap callback
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
        children: [
          // Alert icon with severity color background
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
          color: alert.severityColor.withOpacity(0.1),
          shape: BoxShape.circle,
            ),
            child: Icon(
          alert.alertIcon,
          color: alert.severityColor,
          size: 20,
            ),
          ),
          const SizedBox(width: 12),
          
          // Alert info
          Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              alert.title,
              style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              alert.message,
              style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
            ),
          ),
          
          // Timestamp
          Text(
            formatDateTime(alert.timestamp),
            style: const TextStyle(
          fontSize: 10,
          color: AppColors.textSecondary,
            ),
          ),
        ],
          ),
        ),
      ),
    );
  }
}