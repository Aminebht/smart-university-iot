import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/core/models/security_event_model.dart';
import '../providers/security_provider.dart';
import '../widgets/security_event_list.dart';
import '../../../core/constants/app_constants.dart';

class SecurityEventsScreen extends StatefulWidget {
  const SecurityEventsScreen({super.key});

  @override
  State<SecurityEventsScreen> createState() => _SecurityEventsScreenState();
}

class _SecurityEventsScreenState extends State<SecurityEventsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Add listener to reload data when tab changes
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _loadEvents();
      }
    });
    
    // Load events after the first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEvents();
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadEvents() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final provider = Provider.of<SecurityProvider>(context, listen: false);
      
      // Load different data based on the selected tab
      switch (_tabController.index) {
        case 0: // All events
          await provider.loadSecurityEvents();
          break;
        case 1: // Unacknowledged events
          await provider.loadSecurityEvents(acknowledged: false);
          break;
        case 2: // Acknowledged events
          await provider.loadSecurityEvents(acknowledged: true);
          break;
      }
    } catch (e) {
      print('Error loading security events: $e');
      // Don't show error UI here, let the Consumer handle it
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Events'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Unacknowledged'),
            Tab(text: 'Acknowledged'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEventsList(null),     // All events
          _buildEventsList(false),    // Unacknowledged events
          _buildEventsList(true),     // Acknowledged events
        ],
      ),
    );
  }
  
  Widget _buildEventsList(bool? acknowledged) {
    return Consumer<SecurityProvider>(
      builder: (context, provider, child) {
        // Show loading state if we're loading for the first time
        if (_isLoading && provider.securityEvents.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        
        // Show error if there is one
        if (provider.errorMessage != null && provider.securityEvents.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  provider.errorMessage!,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _loadEvents,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        
        // Filter events based on the acknowledged parameter
        final events = acknowledged == null 
            ? provider.securityEvents
            : provider.securityEvents.where((e) => e.acknowledged == acknowledged).toList();
        
        // Show empty state if there are no events
        if (events.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.event_note, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  acknowledged == null
                    ? 'No security events found'
                    : acknowledged 
                        ? 'No acknowledged events'
                        : 'No unacknowledged events',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          );
        }
        
        // Show the events list
        return RefreshIndicator(
          onRefresh: _loadEvents,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: SecurityEventList(
              events: events,
              onAcknowledge: (eventId) async {
                final success = await provider.acknowledgeSecurityEvent(eventId);
                
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Event acknowledged')),
                  );
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to acknowledge event'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ),
        );
      },
    );
  }
}