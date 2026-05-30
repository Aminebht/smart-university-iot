import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/app_utils.dart';
import '../../../core/models/department_model.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import 'department_detail_screen.dart';

class DepartmentListScreen extends StatelessWidget {
  const DepartmentListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Departments'),
        automaticallyImplyLeading: false,
          centerTitle: true,
      ),
      body: Consumer<DashboardProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final departments = provider.departments;
          
          return RefreshIndicator(
            onRefresh: () => provider.loadDashboardData(),
            child: departments.isEmpty
                ? const Center(child: Text('No departments found'))
                : _buildDepartmentsList(context, departments),
          );
        },
      ),
    );
  }

  Widget _buildDepartmentsList(
      BuildContext context, List<DepartmentModel> departments) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: departments.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final department = departments[index];
        return _buildDepartmentItem(context, department);
      },
    );
  }

  Widget _buildDepartmentItem(BuildContext context, DepartmentModel department) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: getStatusColor(department.status).withOpacity(0.5),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DepartmentDetailScreen(
                departmentId: department.departmentId.toString(),
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Status circle
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: getStatusColor(department.status),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 16),
              
              // Department info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                        Text(
                          department.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                          ),
                        ),
                      ],
                   
                  
                ),
              ),
              
              // Status text
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: getStatusColor(department.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getStatusText(department.status),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: getStatusColor(department.status),
                  ),
                ),
              ),
              
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
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