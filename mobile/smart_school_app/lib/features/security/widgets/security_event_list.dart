import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/security_event_model.dart';

class SecurityEventList extends StatelessWidget {
  final List<SecurityEventModel> events;
  final Function(int) onAcknowledge;
  final bool compact;
  final int? maxEvents;

  const SecurityEventList({
    super.key,
    required this.events,
    required this.onAcknowledge,
    this.compact = false,
    this.maxEvents,
  });

  @override
  Widget build(BuildContext context) {
    // Handle empty list
    if (events.isEmpty) {
      return SizedBox(
        height: 100,
        child: Center(
          child: Text(
            'No events to display',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    // Limit the number of events if maxEvents is specified
    final displayEvents = maxEvents != null && events.length > maxEvents!
        ? events.take(maxEvents!).toList()
        : events;

    return ListView.builder(
      // Adjust these properties based on the compact mode
      shrinkWrap: true,
      physics: compact 
          ? const NeverScrollableScrollPhysics() 
          : const AlwaysScrollableScrollPhysics(),
      itemCount: displayEvents.length,
      itemBuilder: (context, index) {
        final event = displayEvents[index];
        
        return _buildEventCard(context, event);
      },
    );
  }

  Widget _buildEventCard(BuildContext context, SecurityEventModel event) {
    // Make sure to handle null values safely
    final eventTime = event.timestamp ?? DateTime.now();
    final formatter = DateFormat('MMM d, yyyy • h:mm a');
    
    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: compact ? 0 : 16, 
        vertical: compact ? 4 : 8,
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 8 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _getEventIcon(event.eventType),
                  color: _getEventColor(event.eventType),
                  size: compact ? 20 : 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.eventType ?? 'Unknown Event',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: compact ? 14 : 16,
                        ),
                      ),
                    
                    ],
                  ),
                ),
                if (!compact && !event.acknowledged)
                  TextButton(
                    onPressed: () => onAcknowledge(event.eventId),
                    child: const Text('Acknowledge'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              event.description ?? 'No description available',
              style: TextStyle(fontSize: compact ? 13 : 14),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formatter.format(eventTime),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: compact ? 11 : 12,
                  ),
                ),
                if (compact && !event.acknowledged)
                  TextButton(
                    onPressed: () => onAcknowledge(event.eventId),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      minimumSize: const Size(0, 0),
                    ),
                    child: const Text('Acknowledge'),
                  ),
                if (event.acknowledged)
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green[400],
                        size: compact ? 14 : 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Acknowledged',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: compact ? 11 : 12,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getEventIcon(String? eventType) {
    if (eventType == null) return Icons.warning;
    
    switch (eventType.toLowerCase()) {
      case 'door open':
        return Icons.door_front_door;
      case 'window open':
        return Icons.window;
      case 'motion detected':
        return Icons.directions_run;
      case 'alarm triggered':
        return Icons.notifications_active;
      case 'power outage':
        return Icons.power_off;
      case 'system failure':
        return Icons.error_outline;
      default:
        return Icons.security;
    }
  }

  Color _getEventColor(String? eventType) {
    if (eventType == null) return Colors.orange;
    
    switch (eventType.toLowerCase()) {
      case 'alarm triggered':
        return Colors.red;
      case 'door open':
      case 'window open':
      case 'motion detected':
        return Colors.orange;
      case 'power outage':
      case 'system failure':
        return Colors.deepOrange;
      default:
        return Colors.blue;
    }
  }
}