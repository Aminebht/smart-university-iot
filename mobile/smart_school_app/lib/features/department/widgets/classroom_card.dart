import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/classroom_model.dart';
import '../../../core/utils/app_utils.dart';

class ClassroomCard extends StatelessWidget {
  final ClassroomModel classroom;
  final VoidCallback onTap;

  const ClassroomCard({
    super.key,
    required this.classroom,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: classroom.statusColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Status indicator and name
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: classroom.statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      classroom.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Quick info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Temperature indicator
                  _buildSensorIndicator(
                    classroom,
                    'temperature',
                    Icons.thermostat,
                  ),
                  
                  // Camera indicator if available
                  if (classroom.hasCamera)
                    const Icon(
                      Icons.videocam,
                      size: 14,
                      color: AppColors.primary,
                    )
                  else
                    const SizedBox.shrink(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSensorIndicator(
    ClassroomModel classroom,
    String sensorType,
    IconData icon,
  ) {
    final reading = classroom.getLatestReading(sensorType);
    
    if (reading == null) {
      return Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 4),
          const Text(
            'N/A',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      );
    }
    
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: reading.statusColor,
        ),
        const SizedBox(width: 4),
        Text(
          reading.displayValue,
          style: TextStyle(
            fontSize: 12,
            color: reading.statusColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
} 