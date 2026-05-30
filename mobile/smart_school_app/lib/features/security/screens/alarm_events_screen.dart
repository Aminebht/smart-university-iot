import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../providers/security_provider.dart';

class AlarmEventsScreen extends StatefulWidget {
  final int alarmId;
  
  const AlarmEventsScreen({
    super.key,
    required this.alarmId,
  });

  @override
  State<AlarmEventsScreen> createState() => _AlarmEventsScreenState();
}

class _AlarmEventsScreenState extends State<AlarmEventsScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This runs after the first build but before user sees the screen
    Provider.of<SecurityProvider>(context, listen: false)
      .loadAlarmEvents(widget.alarmId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alarm Events'),
      ),
      body: Consumer<SecurityProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final events = provider.alarmEvents;
          
          if (events.isEmpty) {
            return _buildEmptyView();
          }
          
          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: Icon(
                    event.acknowledged ? Icons.check_circle : Icons.warning,
                    color: event.acknowledged ? Colors.green : Colors.orange,
                  ),
                  title: Text(
                    'Trigger: ${event.triggerStatus ?? event.triggerValue?.toString() ?? 'Unknown'}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Device ID: ${event.triggeredByDeviceId ?? 'N/A'}'),
                      Text('Time: ${event.formattedTime} - ${event.formattedDate}'),
                    ],
                  ),
                  trailing: event.acknowledged 
                    ? Text('Ack: ${event.acknowledgedAt?.toString().substring(0, 16) ?? 'Yes'}')
                    : TextButton(
                        child: const Text('Acknowledge'),
                        onPressed: () {
                          provider.acknowledgeAlarmEvent(event.eventId);
                        },
                      ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Provider.of<SecurityProvider>(context, listen: false)
            .loadAlarmEvents(widget.alarmId);
        },
        tooltip: 'Refresh',
        child: const Icon(Icons.refresh),
      ),
    );
  }
  
  Widget _buildEmptyView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_note,
            size: 64,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: 16),
          Text(
            'No alarm events found',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}