import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/event_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/loading_overlay.dart';
import 'create_event_screen.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<EventProvider>().loadEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clean-Up Events'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const CreateEventScreen())),
          ),
        ],
      ),
      body: Consumer<EventProvider>(
        builder: (context, provider, _) {
          return LoadingOverlay(
            isLoading: provider.isLoading,
            child: provider.events.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy, size: 64, color: AppTheme.textSecondary),
                        SizedBox(height: 12),
                        Text('No events yet', style: TextStyle(color: AppTheme.textSecondary)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.events.length,
                    itemBuilder: (context, index) {
                      final event = provider.events[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AppCard(
                          onTap: () => Navigator.pushNamed(context, AppRouter.eventDetail,
                              arguments: event.id),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(event.title,
                                        style: const TextStyle(fontSize: 16,
                                                               fontWeight: FontWeight.w600)),
                                  ),
                                  _StatusChip(status: event.status),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 14,
                                             color: AppTheme.textSecondary),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(event.locationName,
                                        style: const TextStyle(color: AppTheme.textSecondary,
                                                               fontSize: 13)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today_outlined, size: 14,
                                             color: AppTheme.textSecondary),
                                  const SizedBox(width: 4),
                                  Text(_formatDate(event.eventDatetime),
                                      style: const TextStyle(color: AppTheme.textSecondary,
                                                             fontSize: 13)),
                                  const Spacer(),
                                  const Icon(Icons.people_outline, size: 14,
                                             color: AppTheme.textSecondary),
                                  const SizedBox(width: 4),
                                  Text('${event.participantCount}',
                                      style: const TextStyle(color: AppTheme.textSecondary,
                                                             fontSize: 13)),
                                ],
                              ),
                              if (event.registeredByCurrentUser) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text('✓ Registered',
                                      style: TextStyle(color: AppTheme.primary,
                                                       fontSize: 12, fontWeight: FontWeight.w500)),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    } catch (_) {
      return iso;
    }
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'UPCOMING':   color = AppTheme.primary; break;
      case 'COMPLETED':  color = Colors.blue; break;
      case 'CANCELLED':  color = AppTheme.error; break;
      default:           color = AppTheme.textSecondary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500)),
    );
  }
}
