import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/core/models/alarm_system_model.dart';
import '../providers/security_provider.dart';
import '../widgets/security_event_list.dart';
import '../widgets/device_status_grid.dart';
import '../widgets/alarm_control_widget.dart';
import 'security_events_screen.dart';
import '../../../core/constants/app_constants.dart';

class SecurityDashboardScreen extends StatefulWidget {
  const SecurityDashboardScreen({super.key});

  @override
  State<SecurityDashboardScreen> createState() => _SecurityDashboardScreenState();
}

class _SecurityDashboardScreenState extends State<SecurityDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Schedule the data loading for after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<SecurityProvider>(context, listen: false);
      provider.loadSecurityDevices(alarmId: 0);
      provider.loadAlarmSystems();
      // Add this line to load recent events immediately
      provider.loadRecentSecurityEvents(limit: 5);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Don't call methods that update state here
    return Consumer<SecurityProvider>(
      builder: (context, provider, _) {
        // Use the data, don't load it here
        return Scaffold(
          appBar: AppBar(
            title: const Text('Security'),
            automaticallyImplyLeading: false,
        
          centerTitle: true,
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              await Future.wait([
                provider.loadSecurityDevices(alarmId: 0),
                provider.loadAlarmSystems(),
                provider.loadRecentSecurityEvents(limit: 5), // Make sure this is called
              ]);
            },
            child: Consumer<SecurityProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.devices.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.errorMessage != null && provider.devices.isEmpty) {
                  return _buildErrorView(context, provider);
                }

                return _buildDashboard(context, provider);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildDashboard(BuildContext context, SecurityProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAlarmSystemsSection(context, provider),
          const SizedBox(height: 24),  
          // Door/Window Status Section
         Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Events',
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.securityEvents);
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SecurityEventList(
            events: provider.recentEvents,
            onAcknowledge: (eventId) {
              provider.acknowledgeSecurityEvent(eventId);
            },
            compact: true,
            maxEvents: 5,
          ),
          // Recent Events Section
          
          const SizedBox(height: 24),
          
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildAlarmSystemsSection(BuildContext context, SecurityProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Alarm Systems',
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.alarmSystems);
              },
              icon: const Icon(Icons.view_list),
              label: const Text('Manage'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (provider.alarmSystems.isEmpty)
          _buildEmptyAlarmSystems(context)
        else
          _buildAlarmSystemsPreview(context, provider),
      ],
    );
  }

  Widget _buildEmptyAlarmSystems(BuildContext context) {
    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.security_outlined,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            const Text(
              'No alarm systems configured',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create alarm systems to protect your school',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.alarmEdit);
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Alarm System'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlarmSystemsPreview(BuildContext context, SecurityProvider provider) {
    // Display up to 3 alarm systems as preview
    final previewSystems = provider.alarmSystems.take(3).toList();
    
    return Column(
      children: [
        ...previewSystems.map((alarm) => _buildAlarmPreviewCard(context, alarm)),
        if (provider.alarmSystems.length > 3)
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.alarmSystems);
            },
            child: Text('View all ${provider.alarmSystems.length} alarm systems'),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () {
            Navigator.pushNamed(context, AppRoutes.alarmEdit);
          },
          icon: const Icon(Icons.add),
          label: const Text('Add New Alarm System'),
        ),
      ],
    );
  }

  Widget _buildAlarmPreviewCard(BuildContext context, AlarmSystemModel alarm) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: alarm.statusColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Icon(alarm.statusIcon, color: alarm.statusColor),
        title: Text(
          alarm.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          alarm.displayStatus,
          style: TextStyle(color: alarm.statusColor),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.pushNamed(
            context, 
            AppRoutes.alarmDetail,
            arguments: alarm.alarmId,
          );
        },
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, SecurityProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            provider.errorMessage ?? 'An error occurred',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.error),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              provider.loadSecurityDevices(alarmId: 0);
              provider.loadAlarmSystems();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}