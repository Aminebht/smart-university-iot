import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/alarm_system_model.dart';
import '../../../core/widgets/custom_button.dart';
import '../providers/security_provider.dart';

class AlarmEditScreen extends StatefulWidget {
  final int? alarmId;
  
  const AlarmEditScreen({
    Key? key,
    this.alarmId,
  }) : super(key: key);
  
  @override
  State<AlarmEditScreen> createState() => _AlarmEditScreenState();
}

class _AlarmEditScreenState extends State<AlarmEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  bool _isLoading = false;
  bool _isActive = true;
  int? _departmentId;
  int? _classroomId;
  
  List<DropdownMenuItem<int>> _departmentItems = [];
  List<DropdownMenuItem<int>> _classroomItems = [];
  
  @override
  void initState() {
    super.initState();
    
    // Always load departments for both new and existing alarms
    _loadDepartments();
    
    // If alarmId is provided, load the alarm system data
    if (widget.alarmId != null) {
      _loadAlarmSystem(widget.alarmId!);
    } else {
      // Initialize with default values for a new system
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  
  // Load existing alarm data if editing
  Future<void> _loadFormData() async {
    if (widget.alarmId != null) {
      setState(() => _isLoading = true);
      try {
        // Load alarm details
        final alarm = await Provider.of<SecurityProvider>(context, listen: false)
            .getAlarmById(widget.alarmId!);
            
        if (alarm != null) {
          setState(() {
            _nameController.text = alarm.name;
            _descriptionController.text = alarm.description ?? '';
            _isActive = alarm.isActive;
            _departmentId = alarm.departmentId;
            _classroomId = alarm.classroomId;
          });
          
          // Load classrooms for the selected department
          if (alarm.departmentId != null) {
            await _loadClassrooms(alarm.departmentId);
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load alarm details: ${e.toString()}')),
        );
      }
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _loadDepartments() async {
    setState(() => _isLoading = true);
    try {
      final departments = await Provider.of<SecurityProvider>(context, listen: false)
          .getDepartments();
          
      _departmentItems = departments.map((dept) {
        return DropdownMenuItem<int>(
          value: dept.departmentId,
          child: Text(dept.name),
        );
      }).toList();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load departments: ${e.toString()}')),
      );
    }
    setState(() => _isLoading = false);
  }
  
  Future<void> _loadClassrooms(int? departmentId) async {
    setState(() => _isLoading = true);
    try {
      final classrooms = await Provider.of<SecurityProvider>(context, listen: false)
          .getClassroomsByDepartment(departmentId);
          
      _classroomItems = classrooms.map((classroom) {
        return DropdownMenuItem<int>(
          value: classroom.classroomId,
          child: Text(classroom.name),
        );
      }).toList();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load classrooms: ${e.toString()}')),
      );
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.alarmId == null ? 'Create Alarm System' : 'Edit Alarm System'),
        actions: [
          if (widget.alarmId != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _confirmDelete,
              tooltip: 'Delete',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: _departmentId,
                      decoration: const InputDecoration(
                        labelText: 'Department (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      items: _departmentItems,
                      onChanged: (value) {
                        setState(() => _departmentId = value);
                        _loadClassrooms(value);
                      },
                      hint: const Text('Select Department'),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: _classroomId,
                      decoration: const InputDecoration(
                        labelText: 'Classroom (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      items: _classroomItems,
                      onChanged: (value) {
                        setState(() => _classroomId = value);
                      },
                      hint: const Text('Select Classroom'),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Alarm Status',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SwitchListTile(
                      title: Text(_isActive ? 'Active (Alarm is currently enabled)' : 'Inactive (Alarm is disabled)'),
                      value: _isActive,
                      onChanged: (value) {
                        setState(() => _isActive = value);
                      },
                      subtitle: Text(
                        _isActive 
                            ? 'The alarm system will detect and report security breaches' 
                            : 'Enable the alarm system to monitor security',
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        text: 'Save Alarm System',
                        onPressed: _saveAlarmSystem,
                        icon: Icons.save,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
  
  Future<void> _saveAlarmSystem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    final provider = Provider.of<SecurityProvider>(context, listen: false);
    final alarmSystem = AlarmSystemModel(
      alarmId: widget.alarmId ?? 0,
      name: _nameController.text,
      description: _descriptionController.text.isEmpty ? "" : _descriptionController.text,
      departmentId: _departmentId,
      classroomId: _classroomId,
      isActive: _isActive,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    setState(() => _isLoading = true);
    
    final success = await provider.saveAlarmSystem(alarmSystem);
    
    setState(() => _isLoading = false);
    
    if (success && mounted) {
      // Display success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alarm system saved successfully')),
      );
      
      // Automatically navigate back to the previous screen
      Navigator.of(context).pop();
    } else if (mounted) {
      // Show error message if the save operation failed
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save alarm system'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
  
  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Alarm System'),
        content: const Text('Are you sure you want to delete this alarm system? This action cannot be undone.'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
            onPressed: () async {
              Navigator.of(context).pop();
              
              setState(() => _isLoading = true);
              
              final success = await Provider.of<SecurityProvider>(context, listen: false)
                  .deleteAlarmSystem(widget.alarmId!);
              
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Alarm system deleted')),
                );
                Navigator.pop(context);
              } else if (mounted) {
                setState(() => _isLoading = false);
              }
            },
          ),
        ],
      ),
    );
  }
  
  Future<void> _loadAlarmSystem(int alarmId) async {
    setState(() => _isLoading = true);
    
    try {
      // Load the security provider 
      final provider = Provider.of<SecurityProvider>(context, listen: false);
      
      // Load departments first (needed for dropdown)
      await _loadDepartments();
      
      // Load alarm details
      final alarm = await provider.getAlarmById(alarmId);
          
      if (alarm != null) {
        setState(() {
          _nameController.text = alarm.name;
          _descriptionController.text = alarm.description ?? '';
          _isActive = alarm.isActive;
          _departmentId = alarm.departmentId;
          _classroomId = alarm.classroomId;
        });
        
        // Load classrooms for the selected department
        if (alarm.departmentId != null) {
          await _loadClassrooms(alarm.departmentId);
        }
      } else {
        // Handle the case where the alarm isn't found
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Alarm system not found')),
          );
          // Navigate back since we can't edit a non-existent alarm
          Navigator.pop(context);
        }
      }
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
}