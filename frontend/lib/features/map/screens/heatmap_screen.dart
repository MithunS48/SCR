import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/report_provider.dart';
import '../../../core/theme/app_theme.dart';

/// Heatmap screen — shows pollution hotspots on Google Maps.
class HeatmapScreen extends StatefulWidget {
  const HeatmapScreen({super.key});

  @override
  State<HeatmapScreen> createState() => _HeatmapScreenState();
}

class _HeatmapScreenState extends State<HeatmapScreen> {
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    context.read<ReportProvider>().loadHeatmap();
  }

  Set<Circle> _buildCircles(List<HeatmapPoint> points) {
    if (points.isEmpty) return {};

    final weights = points.map((p) => p.weight).toList()..sort();
    final low  = weights.isNotEmpty ? weights[(weights.length * 0.33).floor()] : 1;
    final high = weights.isNotEmpty ? weights[(weights.length * 0.66).floor()] : 2;

    return points.asMap().entries.map((entry) {
      final p = entry.value;
      Color color;
      if (p.weight >= high) {
        color = Colors.red.withOpacity(0.6);
      } else if (p.weight >= low) {
        color = Colors.orange.withOpacity(0.6);
      } else {
        color = Colors.green.withOpacity(0.6);
      }

      return Circle(
        circleId: CircleId('circle_${entry.key}'),
        center: LatLng(p.lat, p.lng),
        radius: 200.0 + (p.weight * 50),
        fillColor: color,
        strokeColor: color.withOpacity(0.8),
        strokeWidth: 1,
      );
    }).toSet();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pollution Heatmap'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<ReportProvider>().loadHeatmap(),
          ),
        ],
      ),
      body: Consumer<ReportProvider>(
        builder: (context, provider, _) {
          final circles = _buildCircles(provider.heatmapPoints);

          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: LatLng(20.5937, 78.9629),
                  zoom: 5,
                ),
                onMapCreated: (controller) => _mapController = controller,
                circles: circles,
                myLocationButtonEnabled: !kIsWeb,
              ),

              // Empty state
              if (provider.heatmapPoints.isEmpty && !provider.isLoading)
                Center(
                  child: Container(
                    margin: const EdgeInsets.all(24),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.map_outlined, size: 48, color: AppTheme.textSecondary),
                        SizedBox(height: 8),
                        Text('No approved reports available',
                            style: TextStyle(color: AppTheme.textSecondary)),
                        SizedBox(height: 4),
                        Text('Submit and get reports approved to see hotspots',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                            textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),

              // Legend
              Positioned(
                bottom: 24, right: 16,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pollution Level',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                      SizedBox(height: 6),
                      _LegendItem(color: Colors.red,    label: 'High'),
                      _LegendItem(color: Colors.orange, label: 'Medium'),
                      _LegendItem(color: Colors.green,  label: 'Low'),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(width: 14, height: 14,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
