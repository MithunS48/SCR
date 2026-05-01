import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/loading_overlay.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  final ApiClient _api = ApiClient();
  List<dynamic> _reports = [];
  bool _loading = false;
  String _filterStatus = 'ALL';

  final List<String> _statuses = ['ALL', 'PENDING', 'APPROVED', 'REJECTED', 'CLEANED'];

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _loading = true);
    try {
      final params = <String, dynamic>{'page': 0, 'size': 50};
      if (_filterStatus != 'ALL') params['status'] = _filterStatus;
      final res = await _api.dio.get(ApiConstants.reports, queryParameters: params);
      setState(() => _reports = res.data['data']['content'] ?? []);
    } catch (e) {
      _showSnack('Failed to load reports', isError: true);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(int id, String action) async {
    try {
      await _api.dio.patch('${ApiConstants.reports}/$id/$action');
      _showSnack('Report $action successfully');
      _loadReports();
    } catch (e) {
      _showSnack('Failed to update report', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppTheme.error : AppTheme.primary,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Waste Reports'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadReports),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _loading,
        child: Column(
          children: [
            // Filter chips
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _statuses.map((s) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(s),
                    selected: _filterStatus == s,
                    selectedColor: Colors.deepPurple.withOpacity(0.2),
                    onSelected: (_) {
                      setState(() => _filterStatus = s);
                      _loadReports();
                    },
                  ),
                )).toList(),
              ),
            ),

            Expanded(
              child: _reports.isEmpty
                  ? const Center(child: Text('No reports found',
                      style: TextStyle(color: AppTheme.textSecondary)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _reports.length,
                      itemBuilder: (context, i) {
                        final r = _reports[i];
                        final status = r['status'] as String;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        r['description'] ?? 'No description',
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    _StatusBadge(status: status),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'By: ${r['userDisplayName'] ?? 'Unknown'} • '
                                  'Lat: ${r['latitude']}, Lng: ${r['longitude']}',
                                  style: const TextStyle(
                                      color: AppTheme.textSecondary, fontSize: 12),
                                ),
                                if (r['imageUrl'] != null) ...[
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      r['imageUrl'],
                                      height: 120,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        height: 60,
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.broken_image,
                                            color: AppTheme.textSecondary),
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 10),
                                // Action buttons
                                Row(
                                  children: [
                                    if (status == 'PENDING') ...[
                                      _ActionBtn(
                                        label: 'Approve',
                                        color: Colors.green,
                                        icon: Icons.check,
                                        onTap: () => _updateStatus(r['id'], 'approve'),
                                      ),
                                      const SizedBox(width: 8),
                                      _ActionBtn(
                                        label: 'Reject',
                                        color: AppTheme.error,
                                        icon: Icons.close,
                                        onTap: () => _updateStatus(r['id'], 'reject'),
                                      ),
                                    ],
                                    if (status == 'APPROVED')
                                      _ActionBtn(
                                        label: 'Mark Cleaned',
                                        color: AppTheme.accent,
                                        icon: Icons.cleaning_services,
                                        onTap: () => _updateStatus(r['id'], 'clean'),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'APPROVED': color = Colors.green; break;
      case 'REJECTED': color = AppTheme.error; break;
      case 'CLEANED':  color = AppTheme.accent; break;
      default:         color = AppTheme.warning;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(status,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionBtn({required this.label, required this.color,
                    required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        minimumSize: const Size(0, 32),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
    );
  }
}
