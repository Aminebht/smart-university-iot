import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/alarm_system_model.dart';
import '../../../core/widgets/custom_button.dart';
import '../providers/security_provider.dart';

class AlarmSystemsScreen extends StatefulWidget {
  const AlarmSystemsScreen({super.key});

  @override
  State<AlarmSystemsScreen> createState() => _AlarmSystemsScreenState();
}

class _AlarmSystemsScreenState extends State<AlarmSystemsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => 
      Provider.of<SecurityProvider>(context, listen: false).loadAlarmSystems()
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alarm Systems'),
      ),
      body: Consumer<SecurityProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (provider.errorMessage != null) {
            return _buildErrorView(context, provider);
          }
          
          if (provider.alarmSystems.isEmpty) {
            return _buildEmptyView();
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.alarmSystems.length,
            itemBuilder: (context, index) {
              final alarm = provider.alarmSystems[index];
              return _buildAlarmCard(context, alarm, provider);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAlarmEdit(context, null),
        tooltip: 'Add Alarm System',
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildAlarmCard(BuildContext context, AlarmSystemModel alarm, SecurityProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: alarm.statusColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(alarm.statusIcon, color: alarm.statusColor),
            title: Text(
              alarm.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(alarm.description ?? 'No description'),
            trailing: Switch(
              value: alarm.isActive,
              activeColor: AppColors.success,
              onChanged: (value) {
                provider.toggleAlarmActive(alarm.alarmId, value);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Chip(
                  label: Text(alarm.displayStatus),
                  backgroundColor: alarm.statusColor.withOpacity(0.1),
                  labelStyle: TextStyle(color: alarm.statusColor),
                ),
                const Spacer(),
               
                TextButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                  onPressed: () => _navigateToAlarmEdit(context, alarm),
                ),
                // Add a delete button
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.error),
                  onPressed: () => _showDeleteConfirmation(context, alarm),
                  tooltip: 'Delete',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  void _navigateToAlarmEdit(BuildContext context, AlarmSystemModel? alarm) {
    Navigator.pushNamed(
      context,
      AppRoutes.alarmEdit,
      arguments: alarm,
    );
  }
  
  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.security_outlined,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          const Text(
            'No Alarm Systems Found',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap the + button to create a new alarm system',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Add Alarm System',
            onPressed: () => _navigateToAlarmEdit(context, null),
            icon: Icons.add,
          ),
        ],
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
            provider.errorMessage ?? 'An unknown error occurred',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.error),
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Retry',
            onPressed: () => provider.loadAlarmSystems(),
            icon: Icons.refresh,
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmation(BuildContext context, AlarmSystemModel alarm) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Alarm System'),
        content: const Text('Are you sure you want to delete this alarm system?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      // Call the delete method from the provider
      Provider.of<SecurityProvider>(context, listen: false).deleteAlarmSystem(alarm.alarmId);
    }
  }
}