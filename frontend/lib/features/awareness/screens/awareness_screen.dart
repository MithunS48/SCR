import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/awareness_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/loading_overlay.dart';

class AwarenessScreen extends StatefulWidget {
  const AwarenessScreen({super.key});

  @override
  State<AwarenessScreen> createState() => _AwarenessScreenState();
}

class _AwarenessScreenState extends State<AwarenessScreen> {
  String _filter = 'ALL';
  String _search = '';

  @override
  void initState() {
    super.initState();
    context.read<AwarenessProvider>().loadItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Awareness')),
      body: Consumer<AwarenessProvider>(
        builder: (context, provider, _) {
          final filtered = provider.items.where((item) {
            final matchType =
                _filter == 'ALL' || item.contentType == _filter;
            final matchSearch = _search.isEmpty ||
                item.title.toLowerCase().contains(_search.toLowerCase()) ||
                item.body.toLowerCase().contains(_search.toLowerCase());
            return matchType && matchSearch;
          }).toList();

          return LoadingOverlay(
            isLoading: provider.isLoading,
            child: Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search tips, facts...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _search.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () =>
                                  setState(() => _search = ''),
                            )
                          : null,
                    ),
                    onChanged: (v) => setState(() => _search = v),
                  ),
                ),

                // Filter chips
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['ALL', 'TIP', 'FACT', 'ARTICLE']
                          .map((type) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(type),
                                  selected: _filter == type,
                                  selectedColor:
                                      _typeColor(type).withOpacity(0.2),
                                  checkmarkColor: _typeColor(type),
                                  labelStyle: TextStyle(
                                    color: _filter == type
                                        ? _typeColor(type)
                                        : AppTheme.textSecondary,
                                    fontWeight: _filter == type
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                  onSelected: (_) =>
                                      setState(() => _filter = type),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ),

                // Count
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${filtered.length} item${filtered.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 4),

                // List
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off,
                                  size: 48,
                                  color: AppTheme.textSecondary),
                              SizedBox(height: 8),
                              Text('No content found',
                                  style: TextStyle(
                                      color: AppTheme.textSecondary)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _AwarenessCard(item: item),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'TIP':     return AppTheme.primary;
      case 'FACT':    return Colors.blue;
      case 'ARTICLE': return Colors.purple;
      default:        return AppTheme.textSecondary;
    }
  }
}

class _AwarenessCard extends StatelessWidget {
  final AwarenessItem item;
  const _AwarenessCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _typeColor(item.contentType).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_typeIcon(item.contentType),
                    color: _typeColor(item.contentType), size: 24),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(item.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: _typeColor(item.contentType)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(item.contentType,
                              style: TextStyle(
                                  color: _typeColor(item.contentType),
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                          height: 1.4),
                    ),
                    const SizedBox(height: 6),
                    Text('Tap to read more →',
                        style: TextStyle(
                            color: _typeColor(item.contentType),
                            fontSize: 11,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (_, controller) => SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _typeColor(item.contentType).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(_typeIcon(item.contentType),
                        color: _typeColor(item.contentType)),
                  ),
                  const SizedBox(width: 10),
                  Text(item.contentType,
                      style: TextStyle(
                          color: _typeColor(item.contentType),
                          fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 14),
              Text(item.title,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text(item.body,
                  style: const TextStyle(
                      fontSize: 15,
                      height: 1.7,
                      color: AppTheme.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'TIP':     return AppTheme.primary;
      case 'FACT':    return Colors.blue;
      case 'ARTICLE': return Colors.purple;
      default:        return AppTheme.textSecondary;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'TIP':     return Icons.lightbulb_outline;
      case 'FACT':    return Icons.info_outline;
      case 'ARTICLE': return Icons.article_outlined;
      default:        return Icons.eco;
    }
  }
}
