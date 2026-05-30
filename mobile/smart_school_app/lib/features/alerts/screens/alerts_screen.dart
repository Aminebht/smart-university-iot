import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/alert_model.dart';
import '../providers/alerts_provider.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Load alerts after the first frame renders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAlerts();
    });
    
    // Listen to tab changes to load filtered data
    _tabController.addListener(_handleTabChange);
  }
  
  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }
  
  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      _loadAlerts();
    }
  }
  
  Future<void> _loadAlerts() async {
    final provider = Provider.of<AlertsProvider>(context, listen: false);
    
    switch (_tabController.index) {
      case 0: // All alerts
        await provider.loadAlerts();
        break;
      case 1: // Active (unresolved) alerts
        await provider.loadAlerts(resolved: false);
        break;
      case 2: // Resolved alerts
        await provider.loadAlerts(resolved: true);
        break;
    }
  }
  
  String _getTabTitle(int index) {
    switch (index) {
      case 0:
        return 'All Alerts';
      case 1:
        return 'Active Alerts';
      case 2:
        return 'Resolved Alerts';
      default:
        return 'Alerts';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTabTitle(_tabController.index)),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Active'),
            Tab(text: 'Resolved'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAlertsList(null),      // All alerts
          _buildAlertsList(false),     // Active alerts
          _buildAlertsList(true),      // Resolved alerts
        ],
      ),
    );
  }
  
  Widget _buildAlertsList(bool? resolved) {
    return Consumer<AlertsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (provider.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                Text(
                  provider.errorMessage ?? 'An error occurred',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.error),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _loadAlerts,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        
        List<AlertModel> filteredAlerts = provider.alerts;
        if (resolved != null) {
          filteredAlerts = filteredAlerts.where((alert) => alert.resolved == resolved).toList();
        }
        
        if (filteredAlerts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_off, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  resolved == null
                      ? 'No alerts found'
                      : resolved
                          ? 'No resolved alerts'
                          : 'No active alerts',
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Alerts will appear here when detected',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }
        
        return RefreshIndicator(
          onRefresh: _loadAlerts,
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            itemCount: filteredAlerts.length,
            itemBuilder: (context, index) {
              return _buildAlertCard(context, filteredAlerts[index], provider);
            },
          ),
        );
      },
    );
  }
  
  Widget _buildAlertCard(BuildContext context, AlertModel alert, AlertsProvider provider) {
    final severityColor = alert.severityColor;
    final severityIcon = alert.alertIcon;
    final formatter = DateFormat('MMM d, yyyy • h:mm a');
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: alert.resolved ? Colors.grey.shade300 : severityColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Alert header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: severityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    severityIcon,
                    color: severityColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.alertType,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        formatter.format(alert.timestamp.toLocal()),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: alert.resolved 
                        ? Colors.green.shade50 
                        : severityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        alert.resolved ? Icons.check_circle : Icons.radio_button_unchecked,
                        size: 12,
                        color: alert.resolved ? Colors.green : severityColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        alert.resolved ? 'Resolved' : alert.severity.toUpperCase(),
                        style: TextStyle(
                          color: alert.resolved ? Colors.green : severityColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Alert message
            Text(
              alert.message,
              style: const TextStyle(fontSize: 14),
            ),
            
            const SizedBox(height: 16),
            
            // Device info and action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Device #${alert.deviceId}',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                  ),
                ),
                if (!alert.resolved)
                  ElevatedButton(
                    onPressed: () async {
                      // Show confirmation dialog
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Resolve Alert'),
                          content: const Text('Are you sure you want to mark this alert as resolved?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Resolve'),
                            ),
                          ],
                        ),
                      );
                      
                      if (confirm == true) {
                        await provider.resolveAlert(alert.alertId);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontSize: 14),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    child: const Text('Resolve'),
                  ),
              ],
            ),
            
            if (alert.resolved && alert.resolvedAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Resolved on ${DateFormat('MMM d, yyyy').format(alert.resolvedAt!.toLocal())}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}