import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/alarm_system_model.dart';
import '../../../core/models/security_device_model.dart';
import '../../../core/models/alarm_event_model.dart';
import '../providers/security_provider.dart';
import 'alarm_rules_screen.dart';
import 'alarm_actions_screen.dart';
import 'alarm_events_screen.dart';

class AlarmDetailScreen extends StatefulWidget {
  final int alarmId;
  
  const AlarmDetailScreen({
    super.key,
    required this.alarmId,
  });

  @override
  State<AlarmDetailScreen> createState() => _AlarmDetailScreenState();
}

class _AlarmDetailScreenState extends State<AlarmDetailScreen> {
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final provider = Provider.of<SecurityProvider>(context, listen: false);
      await provider.loadAlarmSystem(widget.alarmId);
      await provider.loadAlarmRules(widget.alarmId);
      await provider.loadAlarmActions(widget.alarmId);
      await provider.loadAlarmEvents(widget.alarmId, limit: 5);
      await provider.loadSecurityDevices(alarmId: widget.alarmId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load alarm details: ${e.toString()}')),
        );
      }
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  // Toggle alarm active status
  Future<void> _toggleAlarmActive(bool newValue) async {
    try {
      final provider = Provider.of<SecurityProvider>(context, listen: false);
      final success = await provider.toggleAlarmActive(widget.alarmId, newValue);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newValue ? 'Alarm system activated' : 'Alarm system deactivated'),
            backgroundColor: newValue ? AppColors.success : AppColors.warning,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to change alarm status: ${e.toString()}')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<SecurityProvider>(
      builder: (context, provider, _) {
        final alarm = provider.currentAlarmSystem;
        final isLoading = provider.isLoading;
        
        if (isLoading || alarm == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Alarm Details')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        
        return Scaffold(
          appBar: AppBar(
            title: Text(alarm.name),
            actions: [
              Switch(
                value: alarm.isActive,
                activeColor: AppColors.success,
                onChanged: _toggleAlarmActive,
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _showDeleteConfirmation(context, alarm),
                tooltip: 'Delete Alarm System',
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _loadData,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status indicator at the top
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: alarm.isActive ? AppColors.success.withOpacity(0.1) : AppColors.textSecondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: alarm.isActive ? AppColors.success : AppColors.textSecondary),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          alarm.isActive ? Icons.security : Icons.security_outlined,
                          color: alarm.isActive ? AppColors.success : AppColors.textSecondary,
                          size: 36,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                alarm.isActive ? 'Alarm System Active' : 'Alarm System Inactive',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: alarm.isActive ? AppColors.success : AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                _getStatusDescription(alarm.isActive),
                                style: TextStyle(
                                  color: alarm.isActive ? AppColors.success : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildAlarmInfoCard(context, alarm),
                  
                  const SizedBox(height: 16),
                  
                  _buildRecentEventsCard(context, provider.alarmEvents),
                  
                  const SizedBox(height: 16),
                  
                  _buildRulesCard(context, provider.alarmRules),
                  
                  const SizedBox(height: 16),
                  
                  _buildActionsCard(context, provider.alarmActions),
                  
                  
                  
                  const SizedBox(height: 80), // Space for FAB
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.pushNamed(
                context,
                AppRoutes.alarmEdit,
                arguments: alarm.alarmId,
              ).then((_) => _loadData());
            },
            tooltip: 'Edit Alarm',
            child: const Icon(Icons.edit),
          ),
        );
      },
    );
  }
  
  String _getStatusDescription(bool isActive) {
    return isActive
        ? 'The alarm system is actively monitoring for breaches and will trigger configured actions.'
        : 'The alarm system is not monitoring for breaches. Sensors are still active for status monitoring.';
  }
  
  Widget _buildAlarmInfoCard(BuildContext context, AlarmSystemModel alarm) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Alarm Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Description', alarm.description ?? 'No description'),
            const Divider(),
            _buildInfoRow('Department', alarm.departmentName ?? 'Not assigned'),
            const Divider(),
            _buildInfoRow('Classroom', alarm.classroomName ?? 'Not assigned'),
            const Divider(),
            _buildInfoRow('Created', _formatDate(alarm.createdAt)),
            const Divider(),
            _buildInfoRow('Last Updated', _formatDate(alarm.updatedAt)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
  
  Widget _buildRecentEventsCard(BuildContext context, List<AlarmEventModel> events) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    Navigator.pushNamed(
                      context,
                      AppRoutes.alarmEvents,
                      arguments: widget.alarmId,
                    );
                  },
                  child: const Text('VIEW ALL'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (events.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(
                        Icons.event_note,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No events recorded',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: events.length > 5 ? 5 : events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return ListTile(
                    leading: Icon(
                      event.icon,
                      color: event.color,
                    ),
                    title: Text(event.description),
                    subtitle: Text(event.timeAgo),
                    trailing: event.acknowledged
                        ? const Icon(Icons.check_circle, color: AppColors.success, size: 16)
                        : null,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRulesCard(BuildContext context, List<dynamic> rules) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Rules',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AlarmRulesScreen(
                          alarmId: widget.alarmId,
                        ),
                      ),
                    ).then((_) => _loadData());
                  },
                  child: const Text('MANAGE'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (rules.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(
                        Icons.rule,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No rules configured',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AlarmRulesScreen(
                                alarmId: widget.alarmId,
                              ),
                            ),
                          ).then((_) => _loadData());
                        },
                        child: const Text('Add Rules'),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: rules.length > 3 ? 3 : rules.length,
                itemBuilder: (context, index) {
                  final rule = rules[index];
                  return ListTile(
                    leading: Icon(rule.icon),
                    title: Text(rule.ruleName),
                    subtitle: Text(rule.conditionText),
                    trailing: Switch(
                      value: rule.isActive,
                      activeColor: AppColors.success,
                      onChanged: (value) {
                        Provider.of<SecurityProvider>(context, listen: false)
                            .toggleAlarmRuleActive(rule.ruleId, value);
                      },
                    ),
                  );
                },
              ),
            if (rules.length > 3)
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AlarmRulesScreen(
                          alarmId: widget.alarmId,
                        ),
                      ),
                    ).then((_) => _loadData());
                  },
                  child: Text('${rules.length - 3} more rules...'),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionsCard(BuildContext context, List<dynamic> actions) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AlarmActionsScreen(
                          alarmId: widget.alarmId,
                        ),
                      ),
                    ).then((_) => _loadData());
                  },
                  child: const Text('MANAGE'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (actions.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(
                        Icons.flash_on,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No actions configured',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AlarmActionsScreen(
                                alarmId: widget.alarmId,
                              ),
                            ),
                          ).then((_) => _loadData());
                        },
                        child: const Text('Add Actions'),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: actions.length > 3 ? 3 : actions.length,
                itemBuilder: (context, index) {
                  final action = actions[index];
                  return ListTile(
                    leading: Icon(action.icon, color: action.color),
                    title: Text(action.actionDescription ?? 'Action ${index + 1}'),
                    subtitle: Text(action.actionType.toUpperCase()),
                    trailing: Switch(
                      value: action.isActive,
                      activeColor: AppColors.success,
                      onChanged: (value) {
                        Provider.of<SecurityProvider>(context, listen: false)
                            .toggleAlarmActionActive(action.actionId, value);
                      },
                    ),
                  );
                },
              ),
            if (actions.length > 3)
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AlarmActionsScreen(
                          alarmId: widget.alarmId,
                        ),
                      ),
                    ).then((_) => _loadData());
                  },
                  child: Text('${actions.length - 3} more actions...'),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  
  Widget _buildEmptyCard(String title, String message) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.devices,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _getDeviceTypeIcon(String deviceType) {
    IconData iconData;
    
    switch (deviceType.toLowerCase()) {
      case 'camera':
        iconData = Icons.videocam;
        break;
      case 'motion':
        iconData = Icons.motion_photos_on;
        break;
      case 'door':
      case 'window':
        iconData = Icons.sensor_door;
        break;
      case 'temperature':
        iconData = Icons.thermostat;
        break;
      case 'smoke':
        iconData = Icons.whatshot;
        break;
      case 'water':
        iconData = Icons.water_damage;
        break;
      default:
        iconData = Icons.developer_board;
    }
    
    return Icon(iconData);
  }
  
  Widget _getDeviceStatusIndicator(String status) {
    Color color;
    String statusText;
    
    switch (status.toLowerCase()) {
      case 'online':
      case 'active':
      case 'secured':
        color = AppColors.success;
        statusText = 'OK';
        break;
      case 'breached':
      case 'triggered':
      case 'alarm':
        color = AppColors.error;
        statusText = '!';
        break;
      case 'offline':
      case 'inactive':
        color = Colors.grey;
        statusText = 'OFF';
        break;
      case 'warning':
        color = AppColors.warning;
        statusText = '!';
        break;
      default:
        color = AppColors.primary;
        statusText = '?';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  Future<void> _showDeleteConfirmation(BuildContext context, AlarmSystemModel alarm) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Alarm System'),
        content: Text(
          'Are you sure you want to delete "${alarm.name}"? This action cannot be undone and will remove all associated rules, actions, and event history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        final success = await Provider.of<SecurityProvider>(context, listen: false)
          .deleteAlarmSystem(alarm.alarmId);
          
        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Alarm system deleted successfully')),
            );
            
            // Navigate back to alarm systems list
            Navigator.pop(context);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to delete alarm system')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting alarm system: ${e.toString()}')),
          );
        }
      }
    }
  }
}