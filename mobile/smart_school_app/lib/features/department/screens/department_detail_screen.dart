import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/utils/app_utils.dart';
import '../providers/department_provider.dart';
import '../widgets/classroom_card.dart';

class DepartmentDetailScreen extends StatefulWidget {
  final String departmentId;

  const DepartmentDetailScreen({
    super.key,
    required this.departmentId,
  });

  @override
  State<DepartmentDetailScreen> createState() => _DepartmentDetailScreenState();
}

class _DepartmentDetailScreenState extends State<DepartmentDetailScreen> {
  late DepartmentProvider _departmentProvider;
  
  @override
  void initState() {
    super.initState();
    _departmentProvider = DepartmentProvider();
    _departmentProvider.loadDepartment(widget.departmentId);
  }

  @override
  void dispose() {
    // Clean up the provider when leaving the screen
    _departmentProvider.clearData();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _departmentProvider,
      child: Consumer<DepartmentProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return Scaffold(
              appBar: AppBar(title: const Text('Department')),
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          if (provider.errorMessage != null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Department')),
              body: _buildErrorView(context, provider),
            );
          }

          final department = provider.department;
          if (department == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Department')),
              body: const Center(
                child: Text('Department not found'),
              ),
            );
          }

          return Scaffold(
            appBar: AppBar(
              title: Text(department.name),
            ),
            body: RefreshIndicator(
              onRefresh: () => provider.loadDepartment(widget.departmentId),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    // Classrooms section
                    _buildClassroomsSection(provider),
                    
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDepartmentHeader(department) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Department name and status
        
          
          // Department info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoCard(
                'Status',
                _getStatusText(department.status),
                Icons.info_outline,
                color: getStatusColor(department.status),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon, {Color? color}) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: (color ?? AppColors.primary).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color ?? AppColors.primary,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color ?? AppColors.text,
          ),
        ),
      ],
    );
  }

  Widget _buildClassroomsSection(DepartmentProvider provider) {
    final classrooms = provider.classrooms;
    final classroomsByRow = provider.getClassroomsByRow();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Classrooms',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              Text(
                '${classrooms.length} Total',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        if (classrooms.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: Text(
                'No classrooms found',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          )
        else
          // Show classrooms grouped by rows to create a layout/map
          ...classroomsByRow.keys.map((rowIndex) {
            final rowClassrooms = classroomsByRow[rowIndex]!;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: rowClassrooms.map((classroom) {
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      child: ClassroomCard(
                        classroom: classroom,
                        onTap: () {
                          // Navigate to classroom detail
                          Navigator.pushNamed(
                            context,
                            AppRoutes.classroom,
                            arguments: classroom.classroomId.toString(),
                          );
                        },
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          }).toList(),
      ],
    );
  }

  Widget _buildErrorView(BuildContext context, DepartmentProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 60,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            provider.errorMessage ?? 'An error occurred',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.error),
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Retry',
            onPressed: () => provider.loadDepartment(widget.departmentId),
            icon: Icons.refresh,
          ),
        ],
      ),
    );
  }

  String _getStatusText(DeviceStatus status) {
    switch (status) {
      case DeviceStatus.normal:
        return 'Normal';
      case DeviceStatus.warning:
        return 'Warning';
      case DeviceStatus.critical:
        return 'Critical';
      default:
        return 'Normal';
    }
  }
}