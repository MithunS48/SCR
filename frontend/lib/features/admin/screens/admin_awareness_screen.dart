import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/loading_overlay.dart';

class AdminAwarenessScreen extends StatefulWidget {
  const AdminAwarenessScreen({super.key});

  @override
  State<AdminAwarenessScreen> createState() => _AdminAwarenessScreenState();
}

class _AdminAwarenessScreenState extends State<AdminAwarenessScreen> {
  final ApiClient _api = ApiClient();
  List<dynamic> _items = [];
  bool _loading = false;
  bool _showForm = false;

  final _titleCtrl   = TextEditingController();
  final _bodyCtrl    = TextEditingController();
  final _iconCtrl    = TextEditingController();
  String _contentType = 'TIP';

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _iconCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    setState(() => _loading = true);
    try {
      final res = await _api.dio.get(ApiConstants.awareness,
          queryParameters: {'page': 0, 'size': 50});
      setState(() => _items = res.data['data']['content'] ?? []);
    } catch (_) {
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _createItem() async {
    if (_titleCtrl.text.trim().isEmpty || _bodyCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and body are required')));
      return;
    }
    setState(() => _loading = true);
    try {
      await _api.dio.post(ApiConstants.awareness, data: {
        'title': _titleCtrl.text.trim(),
        'body': _bodyCtrl.text.trim(),
        'contentType': _contentType,
        if (_iconCtrl.text.trim().isNotEmpty) 'iconIdentifier': _iconCtrl.text.trim(),
      });
      _titleCtrl.clear();
      _bodyCtrl.clear();
      _iconCtrl.clear();
      setState(() => _showForm = false);
      _loadItems();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Content created!'),
            backgroundColor: AppTheme.primary));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create content'),
            backgroundColor: AppTheme.error));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _archiveItem(int id) async {
    try {
      await _api.dio.delete('${ApiConstants.awareness}/$id');
      _loadItems();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item archived')));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Awareness Content'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: Icon(_showForm ? Icons.close : Icons.add),
            onPressed: () => setState(() => _showForm = !_showForm),
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _loading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Column(
                children: [
                  // Create form
                  if (_showForm) ...[
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Add New Content',
                              style: TextStyle(fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          AppTextField(
                            label: 'Title',
                            controller: _titleCtrl,
                            maxLength: 100,
                          ),
                          const SizedBox(height: 12),
                          AppTextField(
                            label: 'Body',
                            controller: _bodyCtrl,
                            maxLines: 4,
                            maxLength: 2000,
                          ),
                          const SizedBox(height: 12),
                          // Content type selector
                          Row(
                            children: ['TIP', 'FACT', 'ARTICLE'].map((type) =>
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(type),
                                  selected: _contentType == type,
                                  selectedColor: AppTheme.primary,
                                  labelStyle: TextStyle(
                                    color: _contentType == type
                                        ? Colors.white : AppTheme.textPrimary,
                                  ),
                                  onSelected: (_) =>
                                      setState(() => _contentType = type),
                                ),
                              )
                            ).toList(),
                          ),
                          const SizedBox(height: 12),
                          AppTextField(
                            label: 'Icon (optional)',
                            controller: _iconCtrl,
                            hint: 'e.g. eco, recycling, water',
                          ),
                          const SizedBox(height: 16),
                          AppButton(
                            label: 'Create Content',
                            isLoading: _loading,
                            onPressed: _createItem,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Items list
                  ..._items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AppCard(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _typeColor(item['contentType'])
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(_typeIcon(item['contentType']),
                                color: _typeColor(item['contentType']), size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['title'],
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Text(item['body'],
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 12)),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _typeColor(item['contentType'])
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(item['contentType'],
                                      style: TextStyle(
                                          color: _typeColor(item['contentType']),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.archive_outlined,
                                color: AppTheme.textSecondary),
                            onPressed: () => _archiveItem(item['id']),
                            tooltip: 'Archive',
                          ),
                        ],
                      ),
                    ),
                  )),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _typeColor(String? type) {
    switch (type) {
      case 'TIP':     return AppTheme.primary;
      case 'FACT':    return Colors.blue;
      case 'ARTICLE': return Colors.purple;
      default:        return AppTheme.textSecondary;
    }
  }

  IconData _typeIcon(String? type) {
    switch (type) {
      case 'TIP':     return Icons.lightbulb_outline;
      case 'FACT':    return Icons.info_outline;
      case 'ARTICLE': return Icons.article_outlined;
      default:        return Icons.eco;
    }
  }
}
