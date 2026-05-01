import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/event_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/loading_overlay.dart';

class EventDetailScreen extends StatefulWidget {
  final int eventId;
  const EventDetailScreen({super.key, required this.eventId});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<EventProvider>().loadEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Event Details')),
      body: Consumer<EventProvider>(
        builder: (context, provider, _) {
          final event = provider.events.where((e) => e.id == widget.eventId).firstOrNull;

          if (event == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return LoadingOverlay(
            isLoading: provider.isLoading,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primary, AppTheme.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(event.title,
                            style: const TextStyle(color: Colors.white, fontSize: 20,
                                                   fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.people, color: Colors.white70, size: 16),
                            const SizedBox(width: 4),
                            Text('${event.participantCount} participants',
                                style: const TextStyle(color: Colors.white70)),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(event.status,
                                  style: const TextStyle(color: Colors.white, fontSize: 12)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  _InfoRow(icon: Icons.person_outline, label: 'Organizer',
                           value: event.organizerDisplayName),
                  _InfoRow(icon: Icons.location_on_outlined, label: 'Location',
                           value: event.locationName),
                  _InfoRow(icon: Icons.calendar_today_outlined, label: 'Date & Time',
                           value: _formatDate(event.eventDatetime)),

                  if (event.description != null && event.description!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text('About this Event',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text(event.description!,
                        style: const TextStyle(color: AppTheme.textSecondary, height: 1.5)),
                  ],

                  const SizedBox(height: 32),

                  if (event.status == 'UPCOMING')
                    event.registeredByCurrentUser
                        ? AppButton(
                            label: 'Cancel Registration',
                            color: AppTheme.error,
                            isLoading: provider.isLoading,
                            onPressed: () async {
                              await provider.cancelRegistration(event.id);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Registration cancelled')));
                              }
                            },
                          )
                        : AppButton(
                            label: 'Register for Event',
                            isLoading: provider.isLoading,
                            onPressed: () async {
                              final success = await provider.register(event.id);
                              if (success && mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Registered! +20 pts on completion'),
                                                 backgroundColor: AppTheme.primary));
                              }
                            },
                          ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day}/${dt.month}/${dt.year} at ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    } catch (_) { return iso; }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primary, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}
