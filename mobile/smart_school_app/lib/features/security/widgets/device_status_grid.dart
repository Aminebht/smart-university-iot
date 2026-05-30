import 'package:flutter/material.dart';
import '../../../core/models/security_device_model.dart';
import '../../../core/constants/app_constants.dart';

class DeviceStatusGrid extends StatelessWidget {
  final List<SecurityDeviceModel> doorDevices;
  final List<SecurityDeviceModel> windowDevices;
  final List<SecurityDeviceModel> motionDevices;
  final Function(int, bool) onToggleDevice;
  
  const DeviceStatusGrid({
    super.key,
    required this.doorDevices,
    required this.windowDevices,
    required this.motionDevices,
    required this.onToggleDevice,
  });

  @override
  Widget build(BuildContext context) {
    if (doorDevices.isEmpty && windowDevices.isEmpty && motionDevices.isEmpty) {
      return const Center(
        child: Text('No security devices found'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (doorDevices.isNotEmpty) ...[
          const Text(
            'Door Security',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildDeviceGrid(doorDevices),
          const SizedBox(height: 16),
        ],
        
        if (windowDevices.isNotEmpty) ...[
          const Text(
            'Window Security',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildDeviceGrid(windowDevices),
          const SizedBox(height: 16),
        ],
        
        if (motionDevices.isNotEmpty) ...[
          const Text(
            'Motion Sensors',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildDeviceGrid(motionDevices),
        ],
      ],
    );
  }
  
  Widget _buildDeviceGrid(List<SecurityDeviceModel> devices) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: devices.length,
      itemBuilder: (context, index) {
        return _buildDeviceCard(devices[index]);
      },
    );
  }
  
  Widget _buildDeviceCard(SecurityDeviceModel device) {
    final bool isSecured = device.status == 'secured';
    final bool canToggle = device.deviceType == 'door_lock';
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: device.statusColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  device.deviceIcon,
                  color: device.statusColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    device.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (canToggle)
                  Switch(
                    value: isSecured,
                    activeColor: AppColors.success,
                    onChanged: (secured) {
                      onToggleDevice(device.deviceId, secured);
                    },
                  ),
              ],
            ),
            if (device.classroomName != null)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  device.classroomName!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: device.statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                device.statusDisplay,
                style: TextStyle(
                  fontSize: 12,
                  color: device.statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}