import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';

class AlarmControlWidget extends StatelessWidget {
  final bool isActive;
  final Function(bool) onToggle;
  
  const AlarmControlWidget({
    super.key,
    required this.isActive,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isActive ? AppColors.success.withOpacity(0.5) : AppColors.textSecondary.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  isActive ? Icons.security : Icons.security_outlined,
                  color: isActive ? AppColors.success : AppColors.textSecondary,
                  size: 30,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isActive ? 'Alarm System Active' : 'Alarm System Inactive',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isActive ? AppColors.success : AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        isActive 
                            ? 'The alarm system will detect and report security breaches' 
                            : 'Enable the alarm system to monitor security',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isActive,
                  activeColor: AppColors.success,
                  onChanged: onToggle,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildAlarmOptions(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAlarmOptions() {
    if (!isActive) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 8),
        _buildOptionTile(
          'Door Breach Detection',
          'Alerts when doors are opened without authorization',
          true,
          (value) {},
        ),
        _buildOptionTile(
          'Window Breach Detection',
          'Alerts when windows are opened without authorization',
          true,
          (value) {},
        ),
        _buildOptionTile(
          'Motion Detection',
          'Alerts when motion is detected in secured areas',
          true,
          (value) {},
        ),
        _buildOptionTile(
          'Automatic Door Lock',
          'Automatically locks doors when a breach is detected',
          false,
          (value) {},
        ),
      ],
    );
  }
  
  Widget _buildOptionTile(String title, String description, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: AppColors.success,
            onChanged: (_) {},
          ),
        ],
      ),
    );
  }
}