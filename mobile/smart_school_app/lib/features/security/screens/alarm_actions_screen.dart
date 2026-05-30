import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/core/models/actuator_model.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/alarm_action_model.dart';
import '../../../core/models/alarm_rule_model.dart';
import '../providers/security_provider.dart';

class AlarmActionsScreen extends StatefulWidget {
  final int alarmId;
  const AlarmActionsScreen({super.key, required this.alarmId});

  @override
  State<AlarmActionsScreen> createState() => _AlarmActionsScreenState();
}

class _AlarmActionsScreenState extends State<AlarmActionsScreen> {
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final provider = Provider.of<SecurityProvider>(context, listen: false);
      await provider.loadAlarmActions(widget.alarmId);
      await provider.loadAlarmRules(widget.alarmId); // We need rules for action creation
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load data: ${e.toString()}')),
      );
    }
    
    setState(() => _isLoading = false);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alarm Actions'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<SecurityProvider>(
              builder: (context, provider, child) {
                final actions = provider.alarmActions;
                
                if (actions.isEmpty) {
                  return _buildEmptyState();
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: actions.length,
                  itemBuilder: (context, index) {
                    final action = actions[index];
                    return _buildActionCard(action, provider);
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddActionDialog(context),
        tooltip: 'Add Action',
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.flash_on,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          const Text(
            'No Actions Configured',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add actions to execute when alarm rules are triggered',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddActionDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Action'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionCard(AlarmActionModel action, SecurityProvider provider) {
    // Find the rule associated with this action
    AlarmRuleModel? rule;
    try {
      rule = provider.alarmRules.firstWhere(
        (r) => r.ruleId == action.ruleId,
      );
    } catch (e) {
      rule = null;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(action.icon, color: action.color),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getActionTypeTitle(action.actionType),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        rule != null ? 'For rule: ${rule.ruleName}' : 'Unknown rule',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: action.isActive,
                  activeColor: AppColors.success,
                  onChanged: (value) {
                    provider.toggleAlarmActionActive(action.actionId, value);
                  },
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              action.actionDescription,
              style: const TextStyle(fontSize: 14),
            ),
            ButtonBar(
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.delete),
                  label: const Text('Delete'),
                  onPressed: () => _confirmDeleteAction(action),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                  onPressed: () => _showEditActionDialog(context, action),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  String _getActionTypeTitle(String actionType) {
    switch (actionType) {
      case 'notify':
        return 'Send Notification';
      case 'actuate':
        return 'Trigger Actuator';
      default:
        return 'Unknown Action';
    }
  }
  
  void _confirmDeleteAction(AlarmActionModel action) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Action'),
        content: const Text('Are you sure you want to delete this action?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Delete'),
            onPressed: () {
              Navigator.pop(context);
              _deleteAction(action.actionId);
            },
          ),
        ],
      ),
    );
  }
  
  Future<void> _deleteAction(int actionId) async {
    setState(() => _isLoading = true);
    
    try {
      final result = await Provider.of<SecurityProvider>(context, listen: false)
          .deleteAlarmAction(actionId);
          
      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Action deleted successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete action')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
    
    setState(() => _isLoading = false);
  }
  
  void _showAddActionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ActionFormDialog(
        alarmId: widget.alarmId,
      ),
    );
  }
  
  void _showEditActionDialog(BuildContext context, AlarmActionModel action) {
    showDialog(
      context: context,
      builder: (context) => ActionFormDialog(
        alarmId: widget.alarmId,
        action: action,
      ),
    );
  }
}

// Action Form Dialog for adding/editing actions
class ActionFormDialog extends StatefulWidget {
  final int alarmId;
  final AlarmActionModel? action;
  
  const ActionFormDialog({
    super.key,
    required this.alarmId,
    this.action,
  });

  @override
  State<ActionFormDialog> createState() => _ActionFormDialogState();
}

class _ActionFormDialogState extends State<ActionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  
  int? _selectedRuleId;
  String _actionType = 'notify';
  int? _actuatorId;
  String _targetState = 'on';
  String _notificationSeverity = 'warning';
  final _notificationMessageController = TextEditingController();
  final _webhookUrlController = TextEditingController();
  bool _isActive = true;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    
    // If editing, load existing action data
    if (widget.action != null) {
      _selectedRuleId = widget.action!.ruleId;
      _actionType = widget.action!.actionType;
      _actuatorId = widget.action!.actuatorId;
      _targetState = widget.action!.targetState ?? 'on';
      _notificationSeverity = widget.action!.notificationSeverity ?? 'warning';
      _notificationMessageController.text = widget.action!.notificationMessage ?? '';
      _webhookUrlController.text = widget.action!.externalWebhookUrl ?? '';
      _isActive = widget.action!.isActive;
    }
    
    // Load actuators
    _loadActuators();
  }
  
  Future<void> _loadActuators() async {
    setState(() => _isLoading = true);
    
    try {
      final provider = Provider.of<SecurityProvider>(context, listen: false);
      if (provider.actuators.isEmpty) {
        await provider.loadActuators();
      }
    } catch (e) {
      print('Error loading actuators: $e');
    }
    
    setState(() => _isLoading = false);
  }
  
  @override
  void dispose() {
    _notificationMessageController.dispose();
    _webhookUrlController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.action != null ? 'Edit Action' : 'Add Action'),
      content: _isLoading 
        ? const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          )
        : SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildRuleDropdown(),
                  const SizedBox(height: 16),
                  _buildActionTypeSelector(),
                  const SizedBox(height: 16),
                  _buildActionFields(),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Active'),
                    value: _isActive,
                    onChanged: (value) {
                      setState(() {
                        _isActive = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
      actions: [
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton(
          child: const Text('Save'),
          onPressed: _isLoading ? null : _saveAction,
        ),
      ],
    );
  }
  
  Widget _buildRuleDropdown() {
    final provider = Provider.of<SecurityProvider>(context, listen: false);
    final rules = provider.alarmRules.where((rule) => rule.alarmId == widget.alarmId).toList();
    
    return DropdownButtonFormField<int>(
      value: _selectedRuleId,
      decoration: const InputDecoration(
        labelText: 'Trigger Rule',
        hintText: 'Select rule that triggers this action',
        border: OutlineInputBorder(),
        // Add this to handle text overflow
        isCollapsed: false,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      isExpanded: true, // This will make the dropdown expand to fill available width
      menuMaxHeight: 300, // Limit menu height with a scrollable view if needed
      items: rules.map((rule) {
        return DropdownMenuItem<int>(
          value: rule.ruleId,
          child: Text(
            rule.ruleName,
            overflow: TextOverflow.ellipsis, // Handle text overflow with ellipsis
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedRuleId = value;
        });
      },
      validator: (value) {
        if (value == null) {
          return 'Please select a rule';
        }
        return null;
      },
    );
  }
  
  Widget _buildActionTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Action Type:'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Notify'),
              selected: _actionType == 'notify',
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _actionType = 'notify';
                  });
                }
              },
            ),
            ChoiceChip(
              label: const Text('Actuate'),
              selected: _actionType == 'actuate',
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _actionType = 'actuate';
                  });
                }
              },
            ),
          
          ],
        ),
      ],
    );
  }
  
  Widget _buildActionFields() {
    switch (_actionType) {
      case 'notify':
        return Column(
          children: [
            DropdownButtonFormField<String>(
              value: _notificationSeverity,
              decoration: const InputDecoration(
                labelText: 'Severity',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'info', child: Text('Info')),
                DropdownMenuItem(value: 'warning', child: Text('Warning')),
                DropdownMenuItem(value: 'critical', child: Text('Critical')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _notificationSeverity = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notificationMessageController,
              decoration: const InputDecoration(
                labelText: 'Notification Message',
                hintText: 'Enter notification message',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a message';
                }
                return null;
              },
            ),
          ],
        );
      
      case 'actuate':
        return _buildActuatorFields();
        
      
        
      default:
        return Container();
    }
  }
  
  Widget _buildActuatorFields() {
    final provider = Provider.of<SecurityProvider>(context, listen: false);
    
    // Get actuators as raw JSON data
    final List<dynamic> rawActuators = provider.actuators;
    
    return Column(
      children: [
        if (rawActuators.isEmpty) ...[
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                'No actuators available. Please add actuators first.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ] else ...[
          DropdownButtonFormField<int>(
            value: _actuatorId,
            decoration: const InputDecoration(
              labelText: 'Select Actuator',
              border: OutlineInputBorder(),
            ),
            items: rawActuators.map((dynamic actuator) {
              // Debug: Print each actuator to see its structure
              print('Processing actuator: $actuator');
              
              // Extract the necessary data from the actuator object
              int actuatorId = 0;
              String deviceName = 'Unknown Actuator';
              
              // Handle the actuator data structure
              if (actuator is Map<String, dynamic>) {
                // Try different possible field names for ID
                actuatorId = actuator['actuator_id'] ?? 
                            actuator['id'] ?? 
                            actuator['device_id'] ?? 0;
                
                // Try different possible field names for name
                deviceName = actuator['actuator_name'] ?? 
                            actuator['name'] ?? 
                            actuator['device_name'] ?? 
                            actuator['label'] ?? 
                            'Actuator $actuatorId';
                
                // Add location information if available
                final location = actuator['location'] ?? 
                                actuator['device_location'] ?? 
                                actuator['room'] ?? 
                                actuator['classroom'];
                if (location != null && location.toString().isNotEmpty) {
                  deviceName += ' (${location})';
                }

                // Add type information if available
                final type = actuator['actuator_type'] ?? 
                            actuator['device_type'] ?? 
                            actuator['type'];
                if (type != null && type.toString().isNotEmpty) {
                  deviceName += ' - ${type}';
                }
              }
              
              return DropdownMenuItem<int>(
                value: actuatorId,
                child: Text(
                  deviceName,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _actuatorId = value;
              });
            },
            validator: (value) {
              if (_actionType == 'actuate' && value == null) {
                return 'Please select an actuator';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _targetState,
            decoration: const InputDecoration(
              labelText: 'Target State',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'on', child: Text('On')),
              DropdownMenuItem(value: 'off', child: Text('Off')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _targetState = value;
                });
              }
            },
          ),
        ],
      ],
    );
  }
  
  Future<void> _saveAction() async {
    if (_formKey.currentState!.validate()) {
      final now = DateTime.now();
      
      final action = widget.action == null
          ? AlarmActionModel(
              actionId: 0, // Will be assigned by database
              alarmId: widget.alarmId,
              ruleId: _selectedRuleId!,
              actionType: _actionType,
              actuatorId: _actionType == 'actuate' ? _actuatorId : null,
              targetState: _actionType == 'actuate' ? _targetState : null,
              notificationSeverity: _actionType == 'notify' ? _notificationSeverity : null,
              notificationMessage: _actionType == 'notify' ? _notificationMessageController.text : null,
              notifyUserIds: _actionType == 'notify' ? [1, 2] : null, // Mock user IDs
              externalWebhookUrl: _actionType == 'external' ? _webhookUrlController.text : null,
              isActive: _isActive,
              createdAt: now,
              updatedAt: now,
            )
          : AlarmActionModel(
              actionId: widget.action!.actionId,
              alarmId: widget.alarmId,
              ruleId: _selectedRuleId!,
              actionType: _actionType,
              actuatorId: _actionType == 'actuate' ? _actuatorId : null,
              targetState: _actionType == 'actuate' ? _targetState : null,
              notificationSeverity: _actionType == 'notify' ? _notificationSeverity : null,
              notificationMessage: _actionType == 'notify' ? _notificationMessageController.text : null,
              notifyUserIds: widget.action!.notifyUserIds,
              externalWebhookUrl: _actionType == 'external' ? _webhookUrlController.text : null,
              isActive: _isActive,
              createdAt: widget.action!.createdAt,
              updatedAt: now,
            );
      
      try {
        final provider = Provider.of<SecurityProvider>(context, listen: false);
        final success = widget.action == null
            ? await provider.saveAlarmAction(action)
            : await provider.updateAlarmAction(action,);
            
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(widget.action == null ? 'Action added successfully' : 'Action updated successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save action')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }
}