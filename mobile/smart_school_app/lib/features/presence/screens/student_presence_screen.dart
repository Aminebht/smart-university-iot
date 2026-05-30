import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/student_model.dart';
import '../providers/attendance_provider.dart';

class StudentPresenceScreen extends StatefulWidget {
  const StudentPresenceScreen({super.key});

  @override
  State<StudentPresenceScreen> createState() => _StudentPresenceScreenState();
}

class _StudentPresenceScreenState extends State<StudentPresenceScreen> {
  @override
  void initState() {
    super.initState();
    // Load initial data
    Future.microtask(() {
      final provider = Provider.of<AttendanceProvider>(context, listen: false);
      provider.loadAttendanceData();
      provider.loadStudents();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Presence'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final provider = Provider.of<AttendanceProvider>(context, listen: false);
              provider.loadAttendanceData();
              provider.loadStudents();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Consumer<AttendanceProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (provider.errorMessage != null) {
            return _buildErrorView(context, provider);
          }

          return Column(
            children: [
              _buildDateSelector(context, provider),
              _buildAttendanceStats(provider),
              Expanded(
                child: _buildStudentList(provider),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddAttendanceDialog(context),
        tooltip: 'Record Attendance',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDateSelector(BuildContext context, AttendanceProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () {
              final newDate = provider.selectedDate.subtract(const Duration(days: 1));
              provider.setSelectedDate(newDate);
            },
          ),
          GestureDetector(
            onTap: () => _selectDate(context, provider),
            child: Text(
              DateFormat('EEEE, MMMM d, yyyy').format(provider.selectedDate),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios),
            onPressed: () {
              final newDate = provider.selectedDate.add(const Duration(days: 1));
              provider.setSelectedDate(newDate);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, AttendanceProvider provider) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: provider.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != provider.selectedDate) {
      provider.setSelectedDate(picked);
    }
  }

  Widget _buildAttendanceStats(AttendanceProvider provider) {
    final attendancePercentage = provider.getAttendancePercentage();
    final presentCount = provider.attendanceRecords.length;
    final totalCount = provider.students.length;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCard(
            'Present',
            '$presentCount',
            Colors.green,
            Icons.check_circle,
          ),
          _buildStatCard(
            'Absent',
            '${totalCount - presentCount}',
            Colors.red,
            Icons.cancel,
          ),
          _buildStatCard(
            'Percentage',
            '${attendancePercentage.toStringAsFixed(0)}%',
            Colors.blue,
            Icons.percent,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentList(AttendanceProvider provider) {
    final students = provider.students;
    
    if (students.isEmpty) {
      return const Center(
        child: Text('No students found'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: students.length,
      itemBuilder: (context, index) {
        final student = students[index];
        final isPresent = provider.isStudentPresent(student.studentId);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isPresent ? Colors.green : Colors.grey[300],
              child: Icon(
                isPresent ? Icons.check : Icons.person,
                color: Colors.white,
              ),
            ),
            title: Text(student.name),
            subtitle: Text(student.email),
            trailing: isPresent 
              ? const Icon(Icons.check_circle, color: Colors.green)
              : IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => _recordAttendance(context, provider, student),
                ),
          ),
        );
      },
    );
  }

  void _recordAttendance(BuildContext context, AttendanceProvider provider, StudentModel student) async {
    // Store context in a local variable to capture it before any potential deactivation
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Don't call setState here as it might not be necessary and could cause issues
    
    final success = await provider.recordAttendance(student.studentId);
    
    // Use the stored scaffoldMessenger reference instead of trying to get it after the async gap
    if (success) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('${student.name} marked as present')),
      );
    } else {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Failed to record attendance for ${student.name}')),
      );
    }
  }

  void _showAddAttendanceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const StudentAttendanceDialog(),
    );
  }

  Widget _buildErrorView(BuildContext context, AttendanceProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 60,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            provider.errorMessage ?? 'An error occurred',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              provider.loadAttendanceData();
              provider.loadStudents();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

// Dialog for manually adding attendance
class StudentAttendanceDialog extends StatefulWidget {
  const StudentAttendanceDialog({super.key});

  @override
  State<StudentAttendanceDialog> createState() => _StudentAttendanceDialogState();
}

class _StudentAttendanceDialogState extends State<StudentAttendanceDialog> {
  int? _selectedStudentId;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AttendanceProvider>(context);
    final students = provider.students.where(
      (student) => !provider.isStudentPresent(student.studentId)
    ).toList();

    return AlertDialog(
      title: const Text('Record Attendance'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (students.isEmpty)
            const Text('All students are already marked present')
          else
            DropdownButtonFormField<int>(
              value: _selectedStudentId,
              decoration: const InputDecoration(
                labelText: 'Select Student',
                border: OutlineInputBorder(),
                isCollapsed: false,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              ),
              isExpanded: true,
              items: students.map((student) {
                return DropdownMenuItem<int>(
                  value: student.studentId,
                  child: Text(
                    student.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedStudentId = value;
                });
              },
            ),
          const SizedBox(height: 16),
          Text(
            'Date: ${DateFormat('EEEE, MMMM d, yyyy').format(provider.selectedDate)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: students.isEmpty || _selectedStudentId == null
            ? null
            : () async {
                if (_selectedStudentId != null) {
                  final success = await provider.recordAttendance(_selectedStudentId!);
                  if (success) {
                    Navigator.pop(context);
                  }
                }
              },
          child: const Text('Save'),
        ),
      ],
    );
  }
}