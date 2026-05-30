import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/attendance_model.dart';
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
        title: const Text('Presence'),
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
              _buildRoomSelector(context, provider),
              _buildAttendanceStats(provider),
              Expanded(
                child: _buildRecentEntries(provider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRoomSelector(BuildContext context, AttendanceProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          const Icon(Icons.meeting_room, color: AppColors.primary),
          const SizedBox(width: 12),
          Text(
            'Room: ${provider.selectedRoomId}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceStats(AttendanceProvider provider) {
    final presentCount = provider.attendanceRecords.length;
    final totalCount = provider.students.length;
    final percentage = provider.getAttendancePercentage();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCard('Present', '$presentCount', Colors.green, Icons.check_circle),
          _buildStatCard('Total', '$totalCount', Colors.blue, Icons.people),
          _buildStatCard('Rate', '${percentage.toStringAsFixed(0)}%', Colors.orange, Icons.percent),
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
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentEntries(AttendanceProvider provider) {
    final records = provider.attendanceRecords;
    if (records.isEmpty) {
      return const Center(child: Text('No RFID presence events yet'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        final formatter = DateFormat('MMM d, h:mm a');
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.green,
              child: Icon(Icons.check, color: Colors.white),
            ),
            title: Text(record.studentName ?? 'Unknown'),
            subtitle: Text('RFID: ${record.tagId}'),
            trailing: Text(
              formatter.format(record.timestamp.toLocal()),
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorView(BuildContext context, AttendanceProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.red),
          const SizedBox(height: 16),
          Text(provider.errorMessage ?? 'An error occurred', textAlign: TextAlign.center),
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